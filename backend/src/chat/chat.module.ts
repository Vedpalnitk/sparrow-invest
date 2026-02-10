import { Module } from '@nestjs/common';
import { ThrottlerModule } from '@nestjs/throttler';
import { ChatController } from './chat.controller';
import { ChatService } from './chat.service';
import { AuthModule } from '../auth/auth.module';
import { GoalsModule } from '../goals/goals.module';
import { ClientsModule } from '../clients/clients.module';
import { TransactionsModule } from '../transactions/transactions.module';
import { createLLMProvider } from './providers';

@Module({
  imports: [
    AuthModule,
    GoalsModule,
    ClientsModule,
    TransactionsModule,
    ThrottlerModule.forRoot([
      {
        name: 'chat-messages',
        ttl: 60000,  // 1 minute
        limit: 10,   // 10 messages per minute per user
      },
      {
        name: 'chat-sessions',
        ttl: 3600000, // 1 hour
        limit: 20,    // 20 sessions per hour per user
      },
      {
        name: 'chat-voice',
        ttl: 600000,  // 10 minutes
        limit: 5,     // 5 transcriptions per 10 minutes per user
      },
    ]),
  ],
  controllers: [ChatController],
  providers: [
    ChatService,
    {
      provide: 'LLM_PROVIDER',
      useFactory: () => createLLMProvider(),
    },
  ],
  exports: [ChatService],
})
export class ChatModule {}
