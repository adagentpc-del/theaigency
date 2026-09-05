export type EngagementSettings = {
  aiDraftReplies: boolean;
  autoReplyEnabled: boolean;
  autoReplyMinConfidence: number;
  blockedTopics: string[];
  escalationKeywords: string[];
  maxAutoRepliesPerHour: number;
};

export type EngagementDecision = {
  action: 'draft' | 'auto_reply' | 'escalate' | 'ignore';
  reason: string;
};

export function decideEngagement(body: string, confidence: number, settings: EngagementSettings): EngagementDecision {
  const text = body.toLowerCase();
  if (settings.blockedTopics.some(topic => text.includes(topic.toLowerCase()))) {
    return { action: 'escalate', reason: 'Blocked or sensitive topic requires human review.' };
  }
  if (settings.escalationKeywords.some(keyword => text.includes(keyword.toLowerCase()))) {
    return { action: 'escalate', reason: 'Escalation keyword detected.' };
  }
  if (!settings.aiDraftReplies) return { action: 'ignore', reason: 'AI replies disabled.' };
  if (settings.autoReplyEnabled && confidence >= settings.autoReplyMinConfidence) {
    return { action: 'auto_reply', reason: 'High-confidence low-risk reply permitted by workspace policy.' };
  }
  return { action: 'draft', reason: 'Prepare a reply for human approval.' };
}
