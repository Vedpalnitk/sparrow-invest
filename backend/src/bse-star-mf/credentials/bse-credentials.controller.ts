import { Controller, Get, Post, Body, UseGuards } from '@nestjs/common'
import { ApiTags, ApiBearerAuth, ApiOperation, ApiResponse } from '@nestjs/swagger'
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard'
import { CurrentUser } from '../../common/decorators/current-user.decorator'
import { BseCredentialsService, SetCredentialsDto } from './bse-credentials.service'

@ApiTags('BSE Credentials')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('api/v1/bse/credentials')
export class BseCredentialsController {
  constructor(private credentialsService: BseCredentialsService) {}

  @Get()
  @ApiOperation({ summary: 'Get BSE credential configuration status' })
  async getStatus(@CurrentUser() user: any) {
    return this.credentialsService.getStatus(user.id)
  }

  @Post()
  @ApiOperation({ summary: 'Set or update BSE partner credentials' })
  async setCredentials(
    @CurrentUser() user: any,
    @Body() dto: SetCredentialsDto,
  ) {
    return this.credentialsService.setCredentials(user.id, dto)
  }

  @Post('test')
  @ApiOperation({ summary: 'Test BSE connection with stored credentials' })
  async testConnection(@CurrentUser() user: any) {
    return this.credentialsService.testConnection(user.id)
  }
}
