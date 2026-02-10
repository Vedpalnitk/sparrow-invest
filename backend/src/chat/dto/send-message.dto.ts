import { IsString, IsNotEmpty, IsUUID, IsOptional, IsBoolean } from 'class-validator';

export class SendMessageDto {
  @IsUUID()
  @IsNotEmpty()
  sessionId: string;

  @IsString()
  @IsNotEmpty()
  content: string;

  @IsBoolean()
  @IsOptional()
  speakResponse?: boolean;
}

export class MessageResponseDto {
  messageId: string;
  status: 'processing' | 'complete' | 'error';
  content?: string;
  audioUrl?: string;
  error?: string;
  createdAt: string;
}

export class MessageStatusResponseDto {
  messageId: string;
  status: 'processing' | 'complete' | 'error';
  content?: string;
  audioUrl?: string;
  error?: string;
}

export class ChatMessageDto {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  createdAt: string;
}

export class TranscribeResponseDto {
  text: string;
  language?: string;
  duration?: number;
}
