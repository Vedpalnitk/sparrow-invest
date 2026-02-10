import {
  Injectable,
  NotFoundException,
  ConflictException,
} from '@nestjs/common';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../prisma/prisma.service';

export interface UserListItem {
  id: string;
  email: string;
  phone: string | null;
  role: string;
  isActive: boolean;
  isVerified: boolean;
  lastLoginAt: Date | null;
  createdAt: Date;
  profile: {
    name: string;
  } | null;
}

export interface CreateUserDto {
  email: string;
  password: string;
  name: string;
  role: string;
  phone?: string;
}

export interface UpdateUserDto {
  email?: string;
  name?: string;
  role?: string;
  phone?: string;
  isActive?: boolean;
}

@Injectable()
export class UsersService {
  constructor(private prisma: PrismaService) {}

  async findAll(): Promise<UserListItem[]> {
    const users = await this.prisma.user.findMany({
      select: {
        id: true,
        email: true,
        phone: true,
        role: true,
        isActive: true,
        isVerified: true,
        lastLoginAt: true,
        createdAt: true,
        profile: {
          select: {
            name: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    return users;
  }

  async findOne(id: string): Promise<UserListItem> {
    const user = await this.prisma.user.findUnique({
      where: { id },
      select: {
        id: true,
        email: true,
        phone: true,
        role: true,
        isActive: true,
        isVerified: true,
        lastLoginAt: true,
        createdAt: true,
        profile: {
          select: {
            name: true,
          },
        },
      },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    return user;
  }

  async create(dto: CreateUserDto): Promise<UserListItem> {
    const existingUser = await this.prisma.user.findUnique({
      where: { email: dto.email },
    });

    if (existingUser) {
      throw new ConflictException('Email already registered');
    }

    const hashedPassword = await bcrypt.hash(dto.password, 10);

    const user = await this.prisma.user.create({
      data: {
        email: dto.email,
        passwordHash: hashedPassword,
        role: dto.role,
        phone: dto.phone,
        profile: {
          create: {
            name: dto.name,
          },
        },
      },
      select: {
        id: true,
        email: true,
        phone: true,
        role: true,
        isActive: true,
        isVerified: true,
        lastLoginAt: true,
        createdAt: true,
        profile: {
          select: {
            name: true,
          },
        },
      },
    });

    return user;
  }

  async update(id: string, dto: UpdateUserDto): Promise<UserListItem> {
    const user = await this.prisma.user.findUnique({ where: { id } });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    // Check email uniqueness if changing
    if (dto.email && dto.email !== user.email) {
      const existingUser = await this.prisma.user.findUnique({
        where: { email: dto.email },
      });
      if (existingUser) {
        throw new ConflictException('Email already in use');
      }
    }

    const updatedUser = await this.prisma.user.update({
      where: { id },
      data: {
        email: dto.email,
        role: dto.role,
        phone: dto.phone,
        isActive: dto.isActive,
        profile: dto.name
          ? {
              update: {
                name: dto.name,
              },
            }
          : undefined,
      },
      select: {
        id: true,
        email: true,
        phone: true,
        role: true,
        isActive: true,
        isVerified: true,
        lastLoginAt: true,
        createdAt: true,
        profile: {
          select: {
            name: true,
          },
        },
      },
    });

    return updatedUser;
  }

  async delete(id: string): Promise<void> {
    const user = await this.prisma.user.findUnique({ where: { id } });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    await this.prisma.user.delete({ where: { id } });
  }

  async resetPassword(id: string, newPassword: string): Promise<void> {
    const user = await this.prisma.user.findUnique({ where: { id } });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    const hashedPassword = await bcrypt.hash(newPassword, 10);

    await this.prisma.user.update({
      where: { id },
      data: { passwordHash: hashedPassword },
    });
  }

  async toggleActive(id: string): Promise<UserListItem> {
    const user = await this.prisma.user.findUnique({ where: { id } });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    const updatedUser = await this.prisma.user.update({
      where: { id },
      data: { isActive: !user.isActive },
      select: {
        id: true,
        email: true,
        phone: true,
        role: true,
        isActive: true,
        isVerified: true,
        lastLoginAt: true,
        createdAt: true,
        profile: {
          select: {
            name: true,
          },
        },
      },
    });

    return updatedUser;
  }
}
