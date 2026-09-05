import { SocialProviderAdapter, ProviderName } from './types';

const adapters = new Map<ProviderName, SocialProviderAdapter>();

export function registerProvider(adapter: SocialProviderAdapter) {
  adapters.set(adapter.name, adapter);
}

export function getProvider(name: ProviderName): SocialProviderAdapter {
  const adapter = adapters.get(name);
  if (!adapter) throw new Error(`Provider adapter not configured: ${name}`);
  return adapter;
}

export function listProviders() {
  return [...adapters.keys()];
}
