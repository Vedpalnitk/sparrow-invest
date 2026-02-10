export interface LLMMessage {
  role: 'system' | 'user' | 'assistant';
  content: string;
}

export interface LLMOptions {
  temperature?: number;
  maxTokens?: number;
  topP?: number;
}

export interface LLMProvider {
  chat(messages: LLMMessage[], options?: LLMOptions): Promise<string>;
  isHealthy(): Promise<boolean>;
  getProviderName(): string;
}
