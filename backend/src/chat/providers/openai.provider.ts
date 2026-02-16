import { Logger } from '@nestjs/common';
import OpenAI from 'openai';
import { LLMProvider, LLMMessage, LLMOptions } from './llm-provider.interface';

export class OpenAIProvider implements LLMProvider {
  private readonly logger = new Logger(OpenAIProvider.name);
  private readonly client: OpenAI;
  private readonly model: string;

  constructor() {
    const apiKey = process.env.OPENAI_API_KEY;
    if (!apiKey) {
      throw new Error('OPENAI_API_KEY is required when LLM_PROVIDER=openai');
    }
    this.client = new OpenAI({ apiKey });
    this.model = process.env.LLM_MODEL || 'gpt-4o';
  }

  async chat(messages: LLMMessage[], options?: LLMOptions): Promise<string> {
    this.logger.log(`Sending chat request to OpenAI (${this.model})`);

    try {
      const response = await this.client.chat.completions.create({
        model: this.model,
        messages: messages.map((m) => ({
          role: m.role,
          content: m.content,
        })),
        temperature: options?.temperature ?? 0.7,
        max_tokens: options?.maxTokens ?? 1024,
        top_p: options?.topP ?? 0.9,
      });

      const content = response.choices[0]?.message?.content || '';

      this.logger.log(`OpenAI response received (tokens: ${response.usage?.completion_tokens})`);
      return content;
    } catch (error) {
      this.logger.error(`Failed to communicate with OpenAI: ${error.message}`);
      throw error;
    }
  }

  async isHealthy(): Promise<boolean> {
    try {
      await this.client.models.list();
      return true;
    } catch {
      return false;
    }
  }

  getProviderName(): string {
    return 'openai';
  }
}
