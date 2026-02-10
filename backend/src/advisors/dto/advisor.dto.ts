import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, IsInt, IsOptional, Min, Max } from 'class-validator';

export class AdvisorFilterDto {
  @ApiPropertyOptional({ description: 'Filter by city' })
  @IsString()
  @IsOptional()
  city?: string;

  @ApiPropertyOptional({ description: 'Filter by specialization' })
  @IsString()
  @IsOptional()
  specialization?: string;

  @ApiPropertyOptional({ description: 'Filter by minimum rating (1-5)' })
  @IsInt()
  @Min(1)
  @Max(5)
  @IsOptional()
  minRating?: number;

  @ApiPropertyOptional({ description: 'Filter by verified advisors only' })
  @IsOptional()
  verifiedOnly?: boolean;

  @ApiPropertyOptional({ description: 'Filter by accepting new clients' })
  @IsOptional()
  acceptingNew?: boolean;

  @ApiPropertyOptional({ description: 'Search by name' })
  @IsString()
  @IsOptional()
  search?: string;
}

export class CreateReviewDto {
  @ApiProperty({ description: 'Rating 1-5' })
  @IsInt()
  @Min(1)
  @Max(5)
  rating: number;

  @ApiPropertyOptional({ description: 'Review comment' })
  @IsString()
  @IsOptional()
  comment?: string;

  @ApiPropertyOptional({ description: 'Post anonymously' })
  @IsOptional()
  isAnonymous?: boolean;
}

export class AdvisorResponseDto {
  @ApiProperty()
  id: string;

  @ApiProperty()
  displayName: string;

  @ApiPropertyOptional()
  bio?: string;

  @ApiProperty()
  specializations: string[];

  @ApiProperty()
  experienceYears: number;

  @ApiPropertyOptional()
  sebiRegNo?: string;

  @ApiPropertyOptional()
  arnNo?: string;

  @ApiProperty()
  rating: number;

  @ApiProperty()
  totalReviews: number;

  @ApiProperty()
  totalClients: number;

  @ApiProperty()
  aumManaged: number;

  @ApiProperty()
  isAcceptingNew: boolean;

  @ApiPropertyOptional()
  minInvestment?: number;

  @ApiPropertyOptional()
  feeStructure?: string;

  @ApiPropertyOptional()
  avatarUrl?: string;

  @ApiPropertyOptional()
  city?: string;

  @ApiProperty()
  languages: string[];

  @ApiProperty()
  isVerified: boolean;
}

export class ReviewResponseDto {
  @ApiProperty()
  id: string;

  @ApiProperty()
  rating: number;

  @ApiPropertyOptional()
  comment?: string;

  @ApiProperty()
  isAnonymous: boolean;

  @ApiPropertyOptional()
  reviewerName?: string;

  @ApiProperty()
  createdAt: string;
}
