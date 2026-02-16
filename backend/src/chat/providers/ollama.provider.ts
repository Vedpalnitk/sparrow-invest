import { Logger } from '@nestjs/common';
import { LLMProvider, LLMMessage, LLMOptions } from './llm-provider.interface';

interface OllamaResponse {
  model: string;
  created_at: string;
  message: {
    role: string;
    content: string;
  };
  done: boolean;
  total_duration?: number;
  load_duration?: number;
  prompt_eval_count?: number;
  eval_count?: number;
}

export class OllamaProvider implements LLMProvider {
  private readonly logger = new Logger(OllamaProvider.name);
  private readonly ollamaUrl: string;
  private readonly model: string;

  constructor() {
    this.ollamaUrl = process.env.OLLAMA_URL || 'http://localhost:11434';
    this.model = process.env.LLM_MODEL || 'llama3.2:latest';
  }

  async chat(messages: LLMMessage[], options?: LLMOptions): Promise<string> {
    const url = `${this.ollamaUrl}/api/chat`;

    this.logger.log(`Sending chat request to Ollama (${this.model})`);

    try {
      const response = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          model: this.model,
          messages,
          stream: false,
          options: {
            temperature: options?.temperature ?? 0.7,
            top_p: options?.topP ?? 0.9,
            num_predict: options?.maxTokens ?? 1024,
          },
        }),
      });

      if (!response.ok) {
        const errorText = await response.text();
        this.logger.error(`Ollama API error: ${response.status} - ${errorText}`);
        throw new Error(`Ollama API error: ${response.status}`);
      }

      const data: OllamaResponse = await response.json();
      this.logger.log(`Ollama response received (eval_count: ${data.eval_count})`);

      return data.message.content;
    } catch (error) {
      this.logger.error(`Failed to communicate with Ollama: ${error.message}`);
      throw error;
    }
  }

  async isHealthy(): Promise<boolean> {
    try {
      const response = await fetch(`${this.ollamaUrl}/api/tags`);
      return response.ok;
    } catch {
      return false;
    }
  }

  getProviderName(): string {
    return 'ollama';
  }
}
