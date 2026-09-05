export type ProviderName = 'instagram' | 'tiktok' | 'youtube' | 'facebook' | 'linkedin' | 'x' | 'pinterest' | 'threads';

export type PublishPayload = {
  accountId: string;
  mediaUrl: string;
  caption: string;
  scheduledFor?: string;
  metadata?: Record<string, unknown>;
};

export type PublishResult = {
  providerPostId: string;
  permalink?: string;
  publishedAt: string;
};

export type InboxEvent = {
  providerItemId: string;
  type: 'comment' | 'mention' | 'message' | 'review' | 'system';
  body: string;
  authorName?: string;
  authorHandle?: string;
  receivedAt: string;
  metadata?: Record<string, unknown>;
};

export interface SocialProviderAdapter {
  name: ProviderName;
  getAuthorizationUrl(state: string): Promise<string>;
  exchangeCode(code: string): Promise<{ accessToken: string; refreshToken?: string; expiresAt?: string; scopes: string[] }>;
  refreshToken?(refreshToken: string): Promise<{ accessToken: string; refreshToken?: string; expiresAt?: string }>;
  publish(payload: PublishPayload, accessToken: string): Promise<PublishResult>;
  fetchInbox?(accessToken: string, cursor?: string): Promise<{ items: InboxEvent[]; cursor?: string }>;
  fetchMetrics?(providerPostId: string, accessToken: string): Promise<Record<string, number>>;
  validateAccount?(accessToken: string): Promise<{ providerUid: string; handle: string; displayName?: string; avatarUrl?: string }>;
}
