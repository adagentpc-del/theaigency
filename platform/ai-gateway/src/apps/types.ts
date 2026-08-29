import type { ZodTypeAny } from "zod";

export interface GatewayAppDefinition {
  id: string;
  task: string;
  requestSchema: ZodTypeAny;
  responseSchema: ZodTypeAny;
  responseJsonSchema: Record<string, unknown>;
  schemaName: string;
  buildSystemPrompt: () => string;
  buildUserPrompt: (input: any) => string;
  model?: string;
  temperature?: number;
  maxTokens?: number;
}
