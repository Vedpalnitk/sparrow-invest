import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

interface OllamaMessage {
  role: 'system' | 'user' | 'assistant';
  content: string;
}

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

@Injectable()
export class OllamaService {
  private readonly logger = new Logger(OllamaService.name);
  private readonly ollamaUrl: string;
  private readonly model: string;

  constructor(private configService: ConfigService) {
    this.ollamaUrl = this.configService.get<string>('OLLAMA_URL') || 'http://localhost:11434';
    this.model = this.configService.get<string>('OLLAMA_MODEL') || 'llama3.2:latest';
  }

  async chat(messages: OllamaMessage[]): Promise<string> {
    const url = `${this.ollamaUrl}/api/chat`;

    this.logger.log(`Sending chat request to Ollama (${this.model})`);

    try {
      const response = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          model: this.model,
          messages,
          stream: false,
          options: {
            temperature: 0.7,
            top_p: 0.9,
            num_predict: 512,
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

  async listModels(): Promise<string[]> {
    try {
      const response = await fetch(`${this.ollamaUrl}/api/tags`);
      if (!response.ok) return [];

      const data = await response.json();
      return data.models?.map((m: any) => m.name) || [];
    } catch {
      return [];
    }
  }
}
