import { Injectable, Inject, Logger, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service';
import { AuthService } from '../auth/auth.service';
import { GoalsService } from '../goals/goals.service';
import { ClientsService } from '../clients/clients.service';
import { TransactionsService } from '../transactions/transactions.service';
import type { LLMProvider, LLMMessage } from './providers';
import {
  SendMessageDto,
  MessageResponseDto,
  MessageStatusResponseDto,
  ChatMessageDto,
} from './dto/send-message.dto';
import { CreateSessionDto, SessionResponseDto } from './dto/create-session.dto';

// In-memory store for processing messages (in production, use Redis)
interface ProcessingMessage {
  status: 'processing' | 'complete' | 'error';
  content?: string;
  audioUrl?: string;
  error?: string;
  createdAt: Date;
}

@Injectable()
export class ChatService {
  private readonly logger = new Logger(ChatService.name);
  private readonly processingMessages = new Map<string, ProcessingMessage>();
  private readonly ttsServerUrl: string;

  constructor(
    private prisma: PrismaService,
    private authService: AuthService,
    private goalsService: GoalsService,
    private clientsService: ClientsService,
    private transactionsService: TransactionsService,
    @Inject('LLM_PROVIDER') private llmProvider: LLMProvider,
    private configService: ConfigService,
  ) {
    this.ttsServerUrl = this.configService.get<string>('TTS_SERVER_URL') || 'http://localhost:7860';
  }

  async createSession(userId: string, dto: CreateSessionDto): Promise<SessionResponseDto> {
    const session = await this.prisma.aIChatSession.create({
      data: {
        userId,
        title: dto.title || 'New Chat',
        isActive: true,
      },
    });

    return {
      id: session.id,
      userId: session.userId,
      title: session.title,
      isActive: session.isActive,
      createdAt: session.createdAt.toISOString(),
    };
  }

  async getSession(userId: string, sessionId: string): Promise<SessionResponseDto> {
    const session = await this.prisma.aIChatSession.findFirst({
      where: {
        id: sessionId,
        userId,
      },
    });

    if (!session) {
      throw new NotFoundException('Session not found');
    }

    return {
      id: session.id,
      userId: session.userId,
      title: session.title,
      isActive: session.isActive,
      createdAt: session.createdAt.toISOString(),
    };
  }

  async getUserSessions(userId: string): Promise<SessionResponseDto[]> {
    const sessions = await this.prisma.aIChatSession.findMany({
      where: { userId },
      orderBy: { updatedAt: 'desc' },
      take: 20,
    });

    return sessions.map((s) => ({
      id: s.id,
      userId: s.userId,
      title: s.title,
      isActive: s.isActive,
      createdAt: s.createdAt.toISOString(),
    }));
  }

  async getSessionMessages(userId: string, sessionId: string): Promise<ChatMessageDto[]> {
    // Verify session belongs to user
    const session = await this.prisma.aIChatSession.findFirst({
      where: {
        id: sessionId,
        userId,
      },
    });

    if (!session) {
      throw new NotFoundException('Session not found');
    }

    const messages = await this.prisma.aIChatMessage.findMany({
      where: { sessionId },
      orderBy: { createdAt: 'asc' },
    });

    return messages.map((m) => ({
      id: m.id,
      role: m.role as 'user' | 'assistant',
      content: m.content,
      createdAt: m.createdAt.toISOString(),
    }));
  }

  async sendMessage(userId: string, role: string, dto: SendMessageDto): Promise<MessageResponseDto> {
    // Verify session belongs to user
    const session = await this.prisma.aIChatSession.findFirst({
      where: {
        id: dto.sessionId,
        userId,
      },
    });

    if (!session) {
      throw new NotFoundException('Session not found');
    }

    // Save user message
    const userMessage = await this.prisma.aIChatMessage.create({
      data: {
        sessionId: dto.sessionId,
        role: 'user',
        content: dto.content,
      },
    });

    // Create placeholder for AI response
    const aiMessagePlaceholder = await this.prisma.aIChatMessage.create({
      data: {
        sessionId: dto.sessionId,
        role: 'assistant',
        content: '',
        metadata: { status: 'processing' },
      },
    });

    // Mark as processing
    this.processingMessages.set(aiMessagePlaceholder.id, {
      status: 'processing',
      createdAt: new Date(),
    });

    // Process asynchronously
    this.processMessageAsync(userId, role, dto.sessionId, aiMessagePlaceholder.id, dto.speakResponse);

    return {
      messageId: aiMessagePlaceholder.id,
      status: 'processing',
      createdAt: aiMessagePlaceholder.createdAt.toISOString(),
    };
  }

  async getMessageStatus(userId: string, messageId: string): Promise<MessageStatusResponseDto> {
    // Check in-memory processing status first, but only after verifying ownership
    // We verify ownership via the database query below if not in processing map
    const processing = this.processingMessages.get(messageId);

    if (processing) {
      // Verify the message actually belongs to this user before returning in-memory status
      const message = await this.prisma.aIChatMessage.findFirst({
        where: {
          id: messageId,
          session: { userId },
        },
      });

      if (!message) {
        throw new NotFoundException('Message not found');
      }

      return {
        messageId,
        status: processing.status,
        content: processing.content,
        audioUrl: processing.audioUrl,
        error: processing.error,
      };
    }

    // Query with compound filter to prevent timing attacks — userId checked in same query
    const message = await this.prisma.aIChatMessage.findFirst({
      where: {
        id: messageId,
        session: { userId },
      },
    });

    if (!message) {
      throw new NotFoundException('Message not found');
    }

    const metadata = message.metadata as any;

    return {
      messageId,
      status: metadata?.status === 'processing' ? 'processing' : 'complete',
      content: message.content || undefined,
      audioUrl: metadata?.audioUrl,
      error: metadata?.error,
    };
  }

  private async processMessageAsync(
    userId: string,
    role: string,
    sessionId: string,
    messageId: string,
    speakResponse?: boolean,
  ): Promise<void> {
    this.logger.log(`[processMessageAsync] Starting for message ${messageId} (role: ${role}, provider: ${this.llmProvider.getProviderName()})`);
    try {
      // Build system prompt with user context
      this.logger.log(`[processMessageAsync] Building system prompt for user ${userId} (role: ${role})`);
      const systemPrompt = await this.buildSystemPrompt(userId, role);
      this.logger.log(`[processMessageAsync] System prompt built, length: ${systemPrompt.length}`);

      // Get conversation history
      const history = await this.prisma.aIChatMessage.findMany({
        where: {
          sessionId,
          NOT: { id: messageId },
        },
        orderBy: { createdAt: 'asc' },
        take: 20, // Last 20 messages for context
      });

      // Build messages array
      const messages: LLMMessage[] = [
        { role: 'system', content: systemPrompt },
        ...history
          .filter((m) => m.content) // Filter out empty messages
          .map((m) => ({
            role: m.role as 'user' | 'assistant',
            content: m.content,
          })),
      ];

      // For FA role, resolve client context from the latest user message
      if (role === 'advisor') {
        const latestUserMsg = history.filter((m) => m.role === 'user').pop();
        if (latestUserMsg?.content) {
          const clientContext = await this.resolveClientContext(userId, latestUserMsg.content);
          if (clientContext) {
            messages.push({
              role: 'system',
              content: clientContext,
            });
          }
        }
      }

      // Call LLM provider
      this.logger.log(`[processMessageAsync] Calling ${this.llmProvider.getProviderName()} with ${messages.length} messages`);
      const response = await this.llmProvider.chat(messages);
      this.logger.log(`[processMessageAsync] LLM response received, length: ${response.length}`);

      // Generate audio if requested
      let audioUrl: string | undefined;
      if (speakResponse) {
        try {
          audioUrl = await this.generateSpeechUrl(response);
        } catch (error) {
          this.logger.warn(`TTS generation failed: ${error.message}`);
        }
      }

      // Update database
      await this.prisma.aIChatMessage.update({
        where: { id: messageId },
        data: {
          content: response,
          metadata: { status: 'complete', audioUrl },
        },
      });

      // Update session title if first message
      const messageCount = await this.prisma.aIChatMessage.count({
        where: { sessionId },
      });

      if (messageCount <= 2) {
        // User message + AI response
        const title = this.generateSessionTitle(history[history.length - 1]?.content || '');
        await this.prisma.aIChatSession.update({
          where: { id: sessionId },
          data: { title },
        });
      }

      // Update in-memory status
      this.processingMessages.set(messageId, {
        status: 'complete',
        content: response,
        audioUrl,
        createdAt: new Date(),
      });

      // Clean up old processing entries after 5 minutes
      setTimeout(() => {
        this.processingMessages.delete(messageId);
      }, 5 * 60 * 1000);
    } catch (error) {
      this.logger.error(`Failed to process message: ${error.message}`);

      await this.prisma.aIChatMessage.update({
        where: { id: messageId },
        data: {
          content: 'Sorry, I encountered an error processing your request.',
          metadata: { status: 'error', error: error.message },
        },
      });

      this.processingMessages.set(messageId, {
        status: 'error',
        error: error.message,
        createdAt: new Date(),
      });
    }
  }

  // ============================================================
  // System Prompt Builders
  // ============================================================

  async buildSystemPrompt(userId: string, role: string): Promise<string> {
    if (role === 'advisor') {
      return this.buildAdvisorSystemPrompt(userId);
    }
    return this.buildConsumerSystemPrompt(userId);
  }

  private async buildConsumerSystemPrompt(userId: string): Promise<string> {
    let portfolio: any = null;
    let goals: any[] = [];

    try {
      portfolio = await this.authService.getClientPortfolio(userId);
    } catch (error) {
      this.logger.warn(`Failed to get portfolio for user ${userId}: ${error.message}`);
    }

    try {
      goals = await this.goalsService.findAllByUser(userId);
    } catch (error) {
      this.logger.warn(`Failed to get goals for user ${userId}: ${error.message}`);
    }

    // Get user profile
    let profile: any = null;
    try {
      profile = await this.authService.getProfile(userId);
    } catch (error) {
      this.logger.warn(`Failed to get profile for user ${userId}: ${error.message}`);
    }

    // Build context sections
    const contextParts: string[] = [];

    if (profile) {
      contextParts.push(`- User: ${profile.name || 'Investor'}`);
      if (profile.riskProfile) {
        contextParts.push(`- Risk Profile: ${profile.riskProfile}`);
      }
      if (profile.clientType) {
        contextParts.push(`- Client Type: ${profile.clientType === 'managed' ? 'Advisor-managed' : 'Self-directed'}`);
      }
    }

    if (portfolio?.portfolio) {
      const p = portfolio.portfolio;
      contextParts.push(`- Portfolio Value: ₹${this.formatAmount(p.totalValue)}`);
      contextParts.push(`- Total Invested: ₹${this.formatAmount(p.totalInvested)}`);
      contextParts.push(`- Returns: ₹${this.formatAmount(p.totalReturns)} (${p.returnsPercentage?.toFixed(2)}%)`);
      contextParts.push(`- Holdings: ${p.holdingsCount || 0} funds`);
      contextParts.push(`- Active SIPs: ${p.activeSIPs || 0}`);

      // Add top holdings
      if (p.holdings?.length > 0) {
        const topHoldings = p.holdings.slice(0, 3).map((h: any) => h.fundName).join(', ');
        contextParts.push(`- Top Holdings: ${topHoldings}`);
      }
    }

    if (goals?.length > 0) {
      const activeGoals = goals.filter((g) => g.status === 'ACTIVE');
      const goalNames = activeGoals.slice(0, 3).map((g) => g.name).join(', ');
      contextParts.push(`- Goals: ${goalNames}${activeGoals.length > 3 ? ` (+${activeGoals.length - 3} more)` : ''}`);
    }

    // Get user's transactions (includes family members via FAClient linkage)
    let transactions: any[] = [];
    try {
      transactions = await this.transactionsService.getMyTradeRequests(userId);
    } catch (error) {
      this.logger.warn(`Failed to get transactions for user ${userId}: ${error.message}`);
    }

    if (transactions.length > 0) {
      contextParts.push(`\nRECENT TRANSACTIONS (${transactions.length} total):`);
      transactions.slice(0, 10).forEach((t: any) => {
        contextParts.push(`  - ${t.date}: ${t.type} ${t.fundName} — ₹${this.formatAmount(Number(t.amount))} (${t.status})`);
      });
      // Summary
      const totalBuy = transactions.filter((t: any) => t.type === 'Buy' || t.type === 'SIP').reduce((s: number, t: any) => s + Number(t.amount), 0);
      const totalSell = transactions.filter((t: any) => t.type === 'Sell' || t.type === 'SWP').reduce((s: number, t: any) => s + Number(t.amount), 0);
      if (totalBuy > 0) contextParts.push(`  Total Invested: ₹${this.formatAmount(totalBuy)}`);
      if (totalSell > 0) contextParts.push(`  Total Redeemed: ₹${this.formatAmount(totalSell)}`);
    }

    const contextSection = contextParts.length > 0
      ? `\nCONTEXT:\n${contextParts.join('\n')}`
      : '';

    return `You are Avya, an AI assistant for Sparrow Invest - a mutual fund portfolio management platform.
${contextSection}

RULES:
- Be concise and helpful (2-4 sentences per response)
- Use INR (₹) for all amounts
- Format large numbers in Indian notation (lakhs, crores)
- Don't give specific buy/sell recommendations
- For major financial decisions, remind users to consult their financial advisor
- Focus on education, insights, and general guidance
- Be friendly and conversational

CAPABILITIES:
- Explain portfolio performance and holdings
- Discuss SIP strategies and goal planning
- Provide general investment education
- Answer questions about mutual fund categories
- Help understand risk and diversification
- Show and explain recent transactions and trade history`;
  }

  private async buildAdvisorSystemPrompt(advisorId: string): Promise<string> {
    // Get advisor profile
    let profile: any = null;
    try {
      profile = await this.authService.getProfile(advisorId);
    } catch (error) {
      this.logger.warn(`Failed to get advisor profile: ${error.message}`);
    }

    // Get client roster
    let clientData: any = null;
    try {
      clientData = await this.clientsService.findAll(advisorId, { limit: 20, sortBy: 'aum' as any, sortOrder: 'desc' as any });
    } catch (error) {
      this.logger.warn(`Failed to get clients for advisor ${advisorId}: ${error.message}`);
    }

    // Get all advisor goals
    let goals: any[] = [];
    try {
      goals = await this.goalsService.findAllByAdvisor(advisorId);
    } catch (error) {
      this.logger.warn(`Failed to get advisor goals: ${error.message}`);
    }

    const contextParts: string[] = [];

    if (profile) {
      contextParts.push(`- Advisor: ${profile.name || 'Financial Advisor'}`);
    }

    if (clientData?.data) {
      const clients = clientData.data;
      const totalAUM = clients.reduce((sum: number, c: any) => sum + (c.aum || 0), 0);
      contextParts.push(`- Total Clients: ${clientData.total}`);
      contextParts.push(`- Total AUM: ₹${this.formatAmount(totalAUM)}`);

      // Client roster summary
      if (clients.length > 0) {
        contextParts.push(`\nCLIENT ROSTER:`);
        clients.forEach((client: any) => {
          const clientLine = `  - ${this.sanitizeForPrompt(client.name)}: AUM ₹${this.formatAmount(client.aum)}, Risk: ${client.riskProfile}, Returns: ${client.returns?.toFixed(1) || '0'}%`;
          contextParts.push(clientLine);
        });
      }
    }

    // At-risk goals
    if (goals.length > 0) {
      const atRiskGoals = goals.filter((g) => {
        return g.status === 'ACTIVE' && g.progress < 50 && g.daysRemaining < 365;
      });
      if (atRiskGoals.length > 0) {
        contextParts.push(`\nAT-RISK GOALS:`);
        atRiskGoals.slice(0, 5).forEach((g: any) => {
          contextParts.push(`  - ${g.clientName || 'Client'}: ${g.name} (${g.progress?.toFixed(0)}% complete, ${g.daysRemaining} days left)`);
        });
      }
    }

    // Get recent transactions across all clients
    let txnData: any = null;
    try {
      txnData = await this.transactionsService.findAll(advisorId, { limit: 15, sortBy: 'date' as any, sortOrder: 'desc' as any } as any);
    } catch (error) {
      this.logger.warn(`Failed to get transactions for advisor ${advisorId}: ${error.message}`);
    }

    if (txnData?.data?.length > 0) {
      const txns = txnData.data;
      const pendingCount = txns.filter((t: any) => t.status === 'Pending').length;
      const completedCount = txns.filter((t: any) => t.status === 'Completed').length;
      contextParts.push(`\nRECENT TRANSACTIONS (${txnData.total} total, ${pendingCount} pending, ${completedCount} completed):`);
      txns.slice(0, 10).forEach((t: any) => {
        contextParts.push(`  - ${t.date}: ${t.clientName} — ${t.type} ${t.fundName} ₹${this.formatAmount(Number(t.amount))} (${t.status})`);
      });
    }

    const contextSection = contextParts.length > 0
      ? `\nCONTEXT:\n${contextParts.join('\n')}`
      : '';

    return `You are Avya, an AI assistant for Sparrow Invest - helping Financial Advisors manage their client portfolios.
${contextSection}

RULES:
- Be concise and professional (2-4 sentences per response)
- Use INR (₹) for all amounts
- Format large numbers in Indian notation (lakhs, crores)
- When discussing specific clients, use data from the client roster above
- Never expose PAN numbers, bank account numbers, or other sensitive data
- Focus on actionable insights for the advisor
- Be data-driven: reference specific numbers and metrics
- For compliance-sensitive topics, recommend consulting compliance team

CAPABILITIES:
- Analyze client portfolios and performance
- Identify rebalancing opportunities
- Summarize client book and AUM trends
- Flag at-risk goals and underperforming portfolios
- Help prepare for client reviews
- Answer questions about specific clients
- Show recent transactions, pending orders, and trade history across clients`;
  }

  // ============================================================
  // Client Context Resolution (FA only)
  // ============================================================

  private async resolveClientContext(advisorId: string, message: string): Promise<string | null> {
    try {
      const clientData = await this.clientsService.findAll(advisorId, { limit: 50 });
      if (!clientData?.data?.length) return null;

      const normalizedMsg = message.toLowerCase();

      // Find matching client by name
      const matchedClient = clientData.data.find((client: any) => {
        const name = client.name?.toLowerCase() || '';
        const parts = name.split(' ');
        return (
          normalizedMsg.includes(name) ||
          parts.some((part: string) => part.length > 2 && normalizedMsg.includes(part))
        );
      });

      if (!matchedClient) return null;

      // Get detailed client info
      const detail = await this.clientsService.findOne(matchedClient.id, advisorId);

      const lines: string[] = [
        `\n[DETAILED CLIENT DATA for ${this.sanitizeForPrompt(detail.name)}]`,
        `AUM: ₹${this.formatAmount(detail.currentValue || detail.aum)}`,
        `Invested: ₹${this.formatAmount(detail.totalInvested)}`,
        `Returns: ${detail.absoluteGainPercent?.toFixed(2)}%`,
        `Risk Profile: ${detail.riskProfile}`,
        `Holdings: ${detail.holdingsCount || 0}`,
      ];

      // Top 5 holdings
      if (detail.holdings?.length > 0) {
        lines.push(`\nTop Holdings:`);
        detail.holdings.slice(0, 5).forEach((h: any) => {
          lines.push(`  - ${h.fundName}: ₹${this.formatAmount(h.currentValue)} (${h.absoluteGainPct?.toFixed(1)}%)`);
        });
      }

      // Active SIPs
      if (detail.sips?.length > 0) {
        const activeSips = detail.sips.filter((s: any) => s.status === 'ACTIVE');
        if (activeSips.length > 0) {
          lines.push(`\nActive SIPs: ${activeSips.length}`);
          activeSips.slice(0, 3).forEach((s: any) => {
            lines.push(`  - ${s.fundName}: ₹${this.formatAmount(s.amount)}/month`);
          });
        }
      }

      // Family members
      if (detail.familyMembers?.length > 0) {
        lines.push(`\nFamily Members:`);
        detail.familyMembers.forEach((fm: any) => {
          lines.push(`  - ${this.sanitizeForPrompt(fm.name)} (${fm.relationship}): AUM ₹${this.formatAmount(fm.aum)}`);
        });
      }

      // Client transactions
      try {
        const clientTxns = await this.transactionsService.findByClient(matchedClient.id, advisorId);
        if (clientTxns?.length > 0) {
          lines.push(`\nRecent Transactions (${clientTxns.length} total):`);
          clientTxns.slice(0, 8).forEach((t: any) => {
            lines.push(`  - ${t.date}: ${t.type} ${t.fundName} — ₹${this.formatAmount(Number(t.amount))} (${t.status})`);
          });
        }
      } catch (error) {
        this.logger.warn(`Failed to get client transactions: ${error.message}`);
      }

      return lines.join('\n');
    } catch (error) {
      this.logger.warn(`Failed to resolve client context: ${error.message}`);
      return null;
    }
  }

  // ============================================================
  // Data Sanitization
  // ============================================================

  private sanitizeForPrompt(text: string): string {
    if (!text) return '';
    return text
      .replace(/[A-Z]{5}[0-9]{4}[A-Z]/g, '[PAN REDACTED]') // PAN numbers
      .replace(/\b\d{9,18}\b/g, '[ACCOUNT REDACTED]') // Bank account numbers
      .replace(/[A-Z]{4}0[A-Z0-9]{6}/g, '[IFSC REDACTED]'); // IFSC codes
  }

  // ============================================================
  // Utility Methods
  // ============================================================

  private formatAmount(amount: number | undefined): string {
    if (!amount) return '0';

    if (amount >= 10000000) {
      return `${(amount / 10000000).toFixed(2)} Cr`;
    } else if (amount >= 100000) {
      return `${(amount / 100000).toFixed(2)} L`;
    } else if (amount >= 1000) {
      return `${(amount / 1000).toFixed(2)} K`;
    }
    return amount.toFixed(0);
  }

  private generateSessionTitle(content: string): string {
    // Generate a short title from the first user message
    const maxLength = 30;
    const cleaned = content.replace(/[^\w\s]/g, '').trim();

    if (cleaned.length <= maxLength) {
      return cleaned || 'New Chat';
    }

    return cleaned.substring(0, maxLength).trim() + '...';
  }

  private async generateSpeechUrl(text: string): Promise<string> {
    const encodedText = encodeURIComponent(text);
    const voice = 'avya_voice';

    // Return the URL that iOS can fetch to get audio
    // The actual audio generation happens when iOS calls this endpoint
    return `${this.ttsServerUrl}/synthesize_speech/?text=${encodedText}&voice=${voice}`;
  }

  async transcribeAudio(audioBuffer: Buffer, filename: string): Promise<{ text: string; language?: string; duration?: number }> {
    const formData = new FormData();
    const blob = new Blob([audioBuffer as unknown as BlobPart], { type: 'audio/wav' });
    formData.append('file', blob, filename);

    const response = await fetch(`${this.ttsServerUrl}/transcribe/`, {
      method: 'POST',
      body: formData,
    });

    if (!response.ok) {
      throw new Error(`TTS server transcription failed: ${response.status}`);
    }

    return response.json();
  }
}
