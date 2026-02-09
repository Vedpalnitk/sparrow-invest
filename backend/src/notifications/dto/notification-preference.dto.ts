import { IsArray, IsBoolean, IsEnum, IsOptional, IsString, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';

export class PreferenceUpdateDto {
  @IsString()
  category: string;

  @IsString()
  channel: string;

  @IsBoolean()
  enabled: boolean;
}

export class UpdatePreferencesDto {
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => PreferenceUpdateDto)
  updates: PreferenceUpdateDto[];
}

export class NotificationLogsQueryDto {
  @IsOptional()
  @IsString()
  limit?: string;

  @IsOptional()
  @IsString()
  offset?: string;
}
