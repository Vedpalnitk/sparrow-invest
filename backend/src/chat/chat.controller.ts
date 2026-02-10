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
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
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
export class ChatController {
  constructor(
    private readonly chatService: ChatService,
    @Inject('LLM_PROVIDER') private readonly llmProvider: LLMProvider,
  ) {}

  // ===== SESSION ENDPOINTS =====

  @Post('sessions')
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
  @UseInterceptors(FileInterceptor('file'))
  async transcribe(
    @UploadedFile() file: { buffer: Buffer; originalname?: string },
  ): Promise<TranscribeResponseDto> {
    if (!file) {
      throw new Error('No audio file provided');
    }

    const result = await this.chatService.transcribeAudio(file.buffer, file.originalname || 'audio.wav');

    return {
      text: result.text,
      language: result.language,
      duration: result.duration,
    };
  }

  @Get('synthesize')
  async synthesize(
    @Query('text') text: string,
    @Query('voice') voice: string = 'avya_voice',
    @Res() res: Response,
  ): Promise<void> {
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
