import { IsString, IsOptional, IsArray, IsBoolean, IsEmail, MinLength, IsEnum, IsDateString } from 'class-validator';

export enum StaffRoleDto {
  RM = 'RM',
  OPERATIONS = 'OPERATIONS',
  COMPLIANCE_OFFICER = 'COMPLIANCE_OFFICER',
  BRANCH_MANAGER = 'BRANCH_MANAGER',
  SENIOR_ADVISOR = 'SENIOR_ADVISOR',
}

export class CreateStaffDto {
  @IsString()
  displayName: string;

  @IsEmail()
  email: string;

  @IsString()
  @MinLength(6)
  password: string;

  @IsOptional()
  @IsString()
  phone?: string;

  @IsArray()
  @IsString({ each: true })
  allowedPages: string[];

  @IsOptional()
  @IsEnum(StaffRoleDto)
  staffRole?: StaffRoleDto;

  @IsOptional()
  @IsString()
  euin?: string;

  @IsOptional()
  @IsDateString()
  euinExpiry?: string;

  @IsOptional()
  @IsString()
  branchId?: string;
}

export class UpdateStaffDto {
  @IsOptional()
  @IsString()
  displayName?: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  allowedPages?: string[];

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;

  @IsOptional()
  @IsEnum(StaffRoleDto)
  staffRole?: StaffRoleDto;

  @IsOptional()
  @IsString()
  euin?: string;

  @IsOptional()
  @IsDateString()
  euinExpiry?: string;

  @IsOptional()
  @IsString()
  branchId?: string;
}
