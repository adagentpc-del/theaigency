import type { GatewayAppDefinition } from "./types.js";
import { shouldITextHimApp } from "./should-i-text-him/index.js";

const apps = new Map<string, GatewayAppDefinition>();
for (const app of [shouldITextHimApp]) apps.set(`${app.id}:${app.task}`, app);

export function getAppDefinition(appId: string, task: string): GatewayAppDefinition | undefined {
  return apps.get(`${appId}:${task}`);
}

export function listApps(): Array<{ id: string; task: string }> {
  return [...apps.values()].map(({ id, task }) => ({ id, task }));
}
