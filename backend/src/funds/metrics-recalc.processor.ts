import { Injectable, Logger, OnModuleInit, OnModuleDestroy, Inject } from '@nestjs/common'
import { Worker, Job } from 'bullmq'
import { BULLMQ_CONNECTION } from '../common/queue/queue.module'
import { MetricsCalculatorService } from './metrics-calculator.service'

@Injectable()
export class MetricsRecalcProcessor implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(MetricsRecalcProcessor.name)
  private worker!: Worker

  constructor(
    @Inject(BULLMQ_CONNECTION) private readonly connection: any,
    private metricsCalculator: MetricsCalculatorService,
  ) {}

  onModuleInit() {
    this.worker = new Worker(
      'metrics-recalc',
      async (job: Job) => {
        this.logger.log(`Starting metrics recalculation job ${job.id}`)
        const result = await this.metricsCalculator.recalculateAll()
        this.logger.log(`Metrics recalculation complete: ${JSON.stringify(result)}`)
        return result
      },
      {
        connection: this.connection,
        concurrency: 1,
        removeOnComplete: { age: 86400, count: 10 },
        removeOnFail: { age: 604800, count: 50 },
      },
    )

    this.worker.on('failed', (job, err) => {
      this.logger.error(`Metrics recalc job ${job?.id} failed: ${err.message}`)
    })
  }

  async onModuleDestroy() {
    if (this.worker) {
      await this.worker.close()
      this.logger.log('Metrics recalc worker closed')
    }
  }
}
