import { IsString, IsOptional } from 'class-validator';

export class CreateSessionDto {
  @IsString()
  @IsOptional()
  title?: string;
}

export class SessionResponseDto {
  id: string;
  userId: string;
  title: string | null;
  isActive: boolean;
  createdAt: string;
}
