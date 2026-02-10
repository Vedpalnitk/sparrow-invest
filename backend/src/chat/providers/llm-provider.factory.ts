import { Logger } from '@nestjs/common';
import { LLMProvider } from './llm-provider.interface';
import { OllamaProvider } from './ollama.provider';
import { ClaudeProvider } from './claude.provider';
import { OpenAIProvider } from './openai.provider';

const logger = new Logger('LLMProviderFactory');

export function createLLMProvider(): LLMProvider {
  const providerName = (process.env.LLM_PROVIDER || 'ollama').toLowerCase();

  logger.log(`Initializing LLM provider: ${providerName}`);

  switch (providerName) {
    case 'claude':
      return new ClaudeProvider();
    case 'openai':
      return new OpenAIProvider();
    case 'ollama':
    default:
      return new OllamaProvider();
  }
}
