import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Query,
  Res,
  Inject,
  UseInterceptors,
  UploadedFile,
  BadRequestException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { Throttle, ThrottlerGuard } from '@nestjs/throttler';
import { UseGuards } from '@nestjs/common';
import type { Response } from 'express';
import { ChatService } from './chat.service';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Public } from '../common/decorators/public.decorator';
import { CreateSessionDto, SessionResponseDto } from './dto/create-session.dto';
import {
  SendMessageDto,
  MessageResponseDto,
  MessageStatusResponseDto,
  ChatMessageDto,
  TranscribeResponseDto,
} from './dto/send-message.dto';
import type { LLMProvider } from './providers';

@Controller('api/v1/chat')
@UseGuards(ThrottlerGuard)
export class ChatController {
  constructor(
    private readonly chatService: ChatService,
    @Inject('LLM_PROVIDER') private readonly llmProvider: LLMProvider,
  ) {}

  // ===== SESSION ENDPOINTS =====

  @Post('sessions')
  @Throttle({ 'chat-sessions': { ttl: 3600000, limit: 20 } })
  async createSession(
    @CurrentUser('id') userId: string,
    @Body() dto: CreateSessionDto,
  ): Promise<SessionResponseDto> {
    return this.chatService.createSession(userId, dto);
  }

  @Get('sessions')
  async getUserSessions(@CurrentUser('id') userId: string): Promise<SessionResponseDto[]> {
    return this.chatService.getUserSessions(userId);
  }

  @Get('sessions/:id')
  async getSession(
    @CurrentUser('id') userId: string,
    @Param('id') sessionId: string,
  ): Promise<SessionResponseDto> {
    return this.chatService.getSession(userId, sessionId);
  }

  @Get('sessions/:id/messages')
  async getSessionMessages(
    @CurrentUser('id') userId: string,
    @Param('id') sessionId: string,
  ): Promise<ChatMessageDto[]> {
    return this.chatService.getSessionMessages(userId, sessionId);
  }

  // ===== MESSAGE ENDPOINTS =====

  @Post('messages')
  @Throttle({ 'chat-messages': { ttl: 60000, limit: 10 } })
  async sendMessage(
    @CurrentUser() user: { id: string; role: string },
    @Body() dto: SendMessageDto,
  ): Promise<MessageResponseDto> {
    return this.chatService.sendMessage(user.id, user.role, dto);
  }

  @Get('messages/:id/status')
  async getMessageStatus(
    @CurrentUser('id') userId: string,
    @Param('id') messageId: string,
  ): Promise<MessageStatusResponseDto> {
    return this.chatService.getMessageStatus(userId, messageId);
  }

  // ===== VOICE ENDPOINTS =====

  @Post('transcribe')
  @Throttle({ 'chat-voice': { ttl: 600000, limit: 5 } })
  @UseInterceptors(FileInterceptor('file'))
  async transcribe(
    @CurrentUser('id') userId: string,
    @UploadedFile() file: { buffer: Buffer; originalname?: string; mimetype?: string; size?: number },
  ): Promise<TranscribeResponseDto> {
    if (!file) {
      throw new BadRequestException('No audio file provided');
    }

    // Validate file type
    if (file.mimetype && !file.mimetype.startsWith('audio/')) {
      throw new BadRequestException('Invalid file type. Only audio files are accepted.');
    }

    // Validate file size (10MB max)
    if (file.size && file.size > 10 * 1024 * 1024) {
      throw new BadRequestException('File too large. Maximum size is 10MB.');
    }

    const result = await this.chatService.transcribeAudio(file.buffer, file.originalname || 'audio.wav');

    return {
      text: result.text,
      language: result.language,
      duration: result.duration,
    };
  }

  @Get('synthesize')
  @Throttle({ 'chat-voice': { ttl: 600000, limit: 20 } })
  async synthesize(
    @CurrentUser('id') userId: string,
    @Query('text') text: string,
    @Query('voice') voice: string = 'avya_voice',
    @Res() res: Response,
  ): Promise<void> {
    // Validate text length
    if (!text || text.length > 2000) {
      res.status(400).send('Text is required and must be under 2000 characters.');
      return;
    }

    // Proxy to TTS server
    const ttsUrl = process.env.TTS_SERVER_URL || 'http://localhost:7860';
    const encodedText = encodeURIComponent(text);

    try {
      const response = await fetch(
        `${ttsUrl}/synthesize_speech/?text=${encodedText}&voice=${voice}`,
      );

      if (!response.ok) {
        res.status(response.status).send('TTS generation failed');
        return;
      }

      // Stream the audio response
      res.setHeader('Content-Type', 'audio/wav');
      res.setHeader('Cache-Control', 'no-cache');

      const arrayBuffer = await response.arrayBuffer();
      res.send(Buffer.from(arrayBuffer));
    } catch (error) {
      res.status(500).send('TTS server unavailable');
    }
  }

  // ===== HEALTH CHECK =====

  @Public()
  @Get('health')
  async healthCheck(): Promise<{ status: string; llm: boolean; provider: string; tts: boolean }> {
    const ttsUrl = process.env.TTS_SERVER_URL || 'http://localhost:7860';

    let llmHealthy = false;
    let ttsHealthy = false;

    try {
      llmHealthy = await this.llmProvider.isHealthy();
    } catch {
      llmHealthy = false;
    }

    try {
      const ttsResponse = await fetch(`${ttsUrl}/docs`);
      ttsHealthy = ttsResponse.ok;
    } catch {
      ttsHealthy = false;
    }

    return {
      status: llmHealthy ? 'healthy' : 'degraded',
      llm: llmHealthy,
      provider: this.llmProvider.getProviderName(),
      tts: ttsHealthy,
    };
  }
}
