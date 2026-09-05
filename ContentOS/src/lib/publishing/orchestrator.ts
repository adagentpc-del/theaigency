import { getProvider } from '@/lib/providers/registry';
import type { ProviderName } from '@/lib/providers/types';

export type TargetExecution = {
  targetId: string;
  provider: ProviderName;
  accountId: string;
  accessToken: string;
  mediaUrl: string;
  caption: string;
};

export async function publishTargets(targets: TargetExecution[]) {
  const results = [];
  for (const target of targets) {
    try {
      const adapter = getProvider(target.provider);
      const published = await adapter.publish({
        accountId: target.accountId,
        mediaUrl: target.mediaUrl,
        caption: target.caption
      }, target.accessToken);
      results.push({ targetId: target.targetId, ok: true, published });
    } catch (error) {
      results.push({ targetId: target.targetId, ok: false, error: error instanceof Error ? error.message : 'Unknown publish error' });
    }
  }
  return results;
}

export function shouldRetry(statusCode?: number, retryCount = 0) {
  if (retryCount >= 5) return false;
  if (!statusCode) return true;
  return statusCode === 408 || statusCode === 409 || statusCode === 425 || statusCode === 429 || statusCode >= 500;
}

export function retryDelayMs(retryCount: number) {
  return Math.min(15 * 60_000, 15_000 * 2 ** retryCount);
}
