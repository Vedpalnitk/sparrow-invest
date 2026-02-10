import { Module } from '@nestjs/common';
import { ChatController } from './chat.controller';
import { ChatService } from './chat.service';
import { AuthModule } from '../auth/auth.module';
import { GoalsModule } from '../goals/goals.module';
import { ClientsModule } from '../clients/clients.module';
import { TransactionsModule } from '../transactions/transactions.module';
import { createLLMProvider } from './providers';

@Module({
  imports: [AuthModule, GoalsModule, ClientsModule, TransactionsModule],
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
