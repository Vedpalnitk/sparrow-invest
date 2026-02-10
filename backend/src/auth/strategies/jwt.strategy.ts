import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../prisma/prisma.service';

export interface JwtPayload {
  sub: string;
  email: string;
  role: string;
}

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(
    configService: ConfigService,
    private prisma: PrismaService,
  ) {
    const secret = configService.get<string>('jwt.secret') || 'super-secret';
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: secret,
    });
  }

  async validate(payload: JwtPayload) {
    console.log('[JwtStrategy] Validating payload:', payload);
    const user = await this.prisma.user.findUnique({
      where: { id: payload.sub },
    });

    console.log('[JwtStrategy] User found:', user ? { id: user.id, email: user.email, isActive: user.isActive } : null);

    if (!user || !user.isActive) {
      console.log('[JwtStrategy] Unauthorized - user not found or inactive');
      throw new UnauthorizedException();
    }

    return {
      id: user.id,
      email: user.email,
      role: user.role,
    };
  }
}
