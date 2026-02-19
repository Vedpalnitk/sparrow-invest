import {
  Controller, Get, Post, Put, Delete,
  Body, Param, Query, UseGuards, UseInterceptors, UploadedFile,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiTags, ApiBearerAuth, ApiOperation, ApiConsumes } from '@nestjs/swagger';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { StaffPageGuard, RequiredPage } from '../common/guards/staff-page.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { getEffectiveAdvisorId } from '../common/utils/effective-advisor';
import { CommissionsService } from './commissions.service';
import {
  CreateRateDto, UpdateRateDto, CommissionFilterDto,
  CalculateExpectedDto, ReconcileDto,
} from './dto';

@ApiTags('commissions')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, StaffPageGuard)
@RequiredPage('/advisor/commissions')
@Controller('api/v1/commissions')
export class CommissionsController {
  constructor(private commissionsService: CommissionsService) {}

  // ============= RATE MASTER =============

  @Get('rates')
  @ApiOperation({ summary: 'List commission rate master' })
  listRates(@CurrentUser() user: any) {
    return this.commissionsService.listRates(getEffectiveAdvisorId(user));
  }

  @Post('rates')
  @ApiOperation({ summary: 'Create commission rate entry' })
  createRate(@CurrentUser() user: any, @Body() dto: CreateRateDto) {
    return this.commissionsService.createRate(
      getEffectiveAdvisorId(user),
      user.sub || user.id,
      dto,
    );
  }

  @Put('rates/:id')
  @ApiOperation({ summary: 'Update commission rate' })
  updateRate(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body() dto: UpdateRateDto,
  ) {
    return this.commissionsService.updateRate(
      id,
      getEffectiveAdvisorId(user),
      user.sub || user.id,
      dto,
    );
  }

  @Delete('rates/:id')
  @ApiOperation({ summary: 'Delete commission rate' })
  deleteRate(@CurrentUser() user: any, @Param('id') id: string) {
    return this.commissionsService.deleteRate(
      id,
      getEffectiveAdvisorId(user),
      user.sub || user.id,
    );
  }

  // ============= EXPECTED CALCULATION =============

  @Post('calculate-expected')
  @ApiOperation({ summary: 'Calculate expected commissions from AUM x trail rates' })
  calculateExpected(@CurrentUser() user: any, @Body() dto: CalculateExpectedDto) {
    return this.commissionsService.calculateExpected(
      getEffectiveAdvisorId(user),
      user.sub || user.id,
      dto,
    );
  }

  // ============= CSV UPLOAD =============

  @Post('upload')
  @ApiOperation({ summary: 'Upload CAMS/KFintech brokerage CSV' })
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(FileInterceptor('file'))
  uploadBrokerage(
    @CurrentUser() user: any,
    @UploadedFile() file: Express.Multer.File,
  ) {
    if (!file) {
      throw new Error('No file uploaded');
    }
    return this.commissionsService.uploadBrokerage(
      getEffectiveAdvisorId(user),
      user.sub || user.id,
      file,
    );
  }

  @Get('uploads')
  @ApiOperation({ summary: 'List upload history' })
  listUploads(@CurrentUser() user: any) {
    return this.commissionsService.listUploads(getEffectiveAdvisorId(user));
  }

  // ============= RECONCILIATION =============

  @Post('reconcile')
  @ApiOperation({ summary: 'Run reconciliation for a period' })
  reconcile(@CurrentUser() user: any, @Body() dto: ReconcileDto) {
    return this.commissionsService.reconcile(
      getEffectiveAdvisorId(user),
      user.sub || user.id,
      dto,
    );
  }

  // ============= RECORDS =============

  @Get('records')
  @ApiOperation({ summary: 'List commission records' })
  listRecords(@CurrentUser() user: any, @Query() filters: CommissionFilterDto) {
    return this.commissionsService.listRecords(getEffectiveAdvisorId(user), filters);
  }

  @Get('discrepancies')
  @ApiOperation({ summary: 'List discrepancy records' })
  getDiscrepancies(@CurrentUser() user: any) {
    return this.commissionsService.getDiscrepancies(getEffectiveAdvisorId(user));
  }
}
