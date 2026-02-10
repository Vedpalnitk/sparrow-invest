import { Logger } from '@nestjs/common';
import Anthropic from '@anthropic-ai/sdk';
import { LLMProvider, LLMMessage, LLMOptions } from './llm-provider.interface';

export class ClaudeProvider implements LLMProvider {
  private readonly logger = new Logger(ClaudeProvider.name);
  private readonly client: Anthropic;
  private readonly model: string;

  constructor() {
    const apiKey = process.env.ANTHROPIC_API_KEY;
    if (!apiKey) {
      throw new Error('ANTHROPIC_API_KEY is required when LLM_PROVIDER=claude');
    }
    this.client = new Anthropic({ apiKey });
    this.model = process.env.LLM_MODEL || 'claude-sonnet-4-5-20250929';
  }

  async chat(messages: LLMMessage[], options?: LLMOptions): Promise<string> {
    this.logger.log(`Sending chat request to Claude (${this.model})`);

    try {
      // Extract system message separately (Anthropic API requires it as top-level param)
      const systemMessage = messages.find((m) => m.role === 'system');
      const conversationMessages = messages
        .filter((m) => m.role !== 'system')
        .map((m) => ({
          role: m.role as 'user' | 'assistant',
          content: m.content,
        }));

      const response = await this.client.messages.create({
        model: this.model,
        max_tokens: options?.maxTokens ?? 512,
        temperature: options?.temperature ?? 0.7,
        top_p: options?.topP ?? 0.9,
        system: systemMessage?.content || '',
        messages: conversationMessages,
      });

      const textBlock = response.content.find((b) => b.type === 'text');
      const content = textBlock?.text || '';

      this.logger.log(`Claude response received (tokens: ${response.usage.output_tokens})`);
      return content;
    } catch (error) {
      this.logger.error(`Failed to communicate with Claude: ${error.message}`);
      throw error;
    }
  }

  async isHealthy(): Promise<boolean> {
    try {
      // Simple health check — verify the API key works
      await this.client.messages.create({
        model: this.model,
        max_tokens: 5,
        messages: [{ role: 'user', content: 'hi' }],
      });
      return true;
    } catch {
      return false;
    }
  }

  getProviderName(): string {
    return 'claude';
  }
}
