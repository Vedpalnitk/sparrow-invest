import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateInsurancePolicyDto } from './dto/create-insurance-policy.dto';
import { UpdateInsurancePolicyDto } from './dto/update-insurance-policy.dto';

const LIFE_COVER_TYPES = ['TERM_LIFE', 'WHOLE_LIFE', 'ENDOWMENT', 'ULIP'];
const HEALTH_COVER_TYPES = ['HEALTH', 'CRITICAL_ILLNESS'];

@Injectable()
export class InsuranceService {
  constructor(private prisma: PrismaService) {}

  async findAll(clientId: string, advisorId: string) {
    await this.verifyClientOwnership(clientId, advisorId);

    const policies = await this.prisma.insurancePolicy.findMany({
      where: { clientId },
      orderBy: { createdAt: 'desc' },
    });

    return policies.map(this.transformPolicy);
  }

  async create(clientId: string, advisorId: string, dto: CreateInsurancePolicyDto) {
    await this.verifyClientOwnership(clientId, advisorId);

    const policy = await this.prisma.insurancePolicy.create({
      data: {
        clientId,
        policyNumber: dto.policyNumber,
        provider: dto.provider,
        type: dto.type,
        status: dto.status || 'ACTIVE',
        sumAssured: dto.sumAssured,
        premiumAmount: dto.premiumAmount,
        premiumFrequency: dto.premiumFrequency || 'ANNUAL',
        startDate: new Date(dto.startDate),
        maturityDate: dto.maturityDate ? new Date(dto.maturityDate) : null,
        nominees: dto.nominees,
        notes: dto.notes,
      },
    });

    return this.transformPolicy(policy);
  }

  async update(clientId: string, id: string, advisorId: string, dto: UpdateInsurancePolicyDto) {
    await this.verifyClientOwnership(clientId, advisorId);
    await this.findPolicyOrThrow(id, clientId);

    const data: any = {};
    if (dto.policyNumber !== undefined) data.policyNumber = dto.policyNumber;
    if (dto.provider !== undefined) data.provider = dto.provider;
    if (dto.type !== undefined) data.type = dto.type;
    if (dto.status !== undefined) data.status = dto.status;
    if (dto.sumAssured !== undefined) data.sumAssured = dto.sumAssured;
    if (dto.premiumAmount !== undefined) data.premiumAmount = dto.premiumAmount;
    if (dto.premiumFrequency !== undefined) data.premiumFrequency = dto.premiumFrequency;
    if (dto.startDate !== undefined) data.startDate = new Date(dto.startDate);
    if (dto.maturityDate !== undefined) data.maturityDate = new Date(dto.maturityDate);
    if (dto.nominees !== undefined) data.nominees = dto.nominees;
    if (dto.notes !== undefined) data.notes = dto.notes;

    const policy = await this.prisma.insurancePolicy.update({
      where: { id },
      data,
    });

    return this.transformPolicy(policy);
  }

  async remove(clientId: string, id: string, advisorId: string) {
    await this.verifyClientOwnership(clientId, advisorId);
    await this.findPolicyOrThrow(id, clientId);

    await this.prisma.insurancePolicy.delete({ where: { id } });
    return { message: 'Policy deleted successfully' };
  }

  async gapAnalysis(
    clientId: string,
    advisorId: string,
    annualIncome?: number,
    age?: number,
    familySize?: number,
  ) {
    await this.verifyClientOwnership(clientId, advisorId);

    const policies = await this.prisma.insurancePolicy.findMany({
      where: { clientId, status: 'ACTIVE' },
    });

    // Life insurance gap (HLV method)
    const retirementAge = 60;
    const yearsToRetirement = age ? Math.max(retirementAge - age, 0) : 25;
    const lifeRecommended = annualIncome ? annualIncome * yearsToRetirement : 0;
    const lifeCurrent = policies
      .filter((p) => LIFE_COVER_TYPES.includes(p.type))
      .reduce((sum, p) => sum + Number(p.sumAssured), 0);
    const lifeGap = Math.max(lifeRecommended - lifeCurrent, 0);

    // Health insurance gap (family-size based)
    const effectiveFamilySize = familySize || 1;
    let healthRecommended: number;
    if (effectiveFamilySize <= 1) {
      healthRecommended = 500000;
    } else if (effectiveFamilySize <= 2) {
      healthRecommended = 1000000;
    } else if (effectiveFamilySize <= 4) {
      healthRecommended = 1500000;
    } else {
      healthRecommended = 2500000;
    }

    const healthCurrent = policies
      .filter((p) => HEALTH_COVER_TYPES.includes(p.type))
      .reduce((sum, p) => sum + Number(p.sumAssured), 0);
    const healthGap = Math.max(healthRecommended - healthCurrent, 0);

    return {
      life: {
        recommended: lifeRecommended,
        current: lifeCurrent,
        gap: lifeGap,
        adequate: lifeGap === 0,
      },
      health: {
        recommended: healthRecommended,
        current: healthCurrent,
        gap: Math.max(healthRecommended - healthCurrent, 0),
        adequate: healthCurrent >= healthRecommended,
      },
      policies: policies.map(this.transformPolicy),
    };
  }

  private async verifyClientOwnership(clientId: string, advisorId: string) {
    const client = await this.prisma.fAClient.findFirst({
      where: { id: clientId, advisorId },
    });
    if (!client) {
      throw new NotFoundException('Client not found');
    }
    return client;
  }

  private async findPolicyOrThrow(id: string, clientId: string) {
    const policy = await this.prisma.insurancePolicy.findFirst({
      where: { id, clientId },
    });
    if (!policy) {
      throw new NotFoundException('Insurance policy not found');
    }
    return policy;
  }

  private transformPolicy(policy: any) {
    return {
      id: policy.id,
      clientId: policy.clientId,
      policyNumber: policy.policyNumber,
      provider: policy.provider,
      type: policy.type,
      status: policy.status,
      sumAssured: Number(policy.sumAssured),
      premiumAmount: Number(policy.premiumAmount),
      premiumFrequency: policy.premiumFrequency,
      startDate: policy.startDate,
      maturityDate: policy.maturityDate,
      nominees: policy.nominees,
      notes: policy.notes,
      createdAt: policy.createdAt,
      updatedAt: policy.updatedAt,
    };
  }
}
