export type ContentAnalysis = {
  summary: string;
  topics: string[];
  audience: string[];
  moments: Array<{
    startMs: number;
    endMs: number;
    hook: string;
    whyItWorks: string;
    score: number;
    recommendedAccounts: string[];
  }>;
};

export type VariantPlan = {
  name: string;
  hook: string;
  caption: string;
  cta: string;
  hashtags: string[];
  startMs?: number;
  endMs?: number;
  aspectRatio: '9:16' | '1:1' | '16:9';
  subtitles: boolean;
  pacing: 'fast' | 'medium' | 'natural';
  coverText?: string;
  accountIds: string[];
};

export type ContentBrief = {
  objective: 'reach' | 'engagement' | 'leads' | 'sales' | 'community' | 'authority';
  audience: string;
  brandVoice: string;
  prohibitedClaims?: string[];
  defaultCta?: string;
};

export function buildAnalysisPrompt(transcript: string, brief: ContentBrief) {
  return `You are the editorial intelligence layer for a multi-account social media network.\n\nOBJECTIVE: ${brief.objective}\nAUDIENCE: ${brief.audience}\nVOICE: ${brief.brandVoice}\nDEFAULT CTA: ${brief.defaultCta ?? 'none'}\nPROHIBITED CLAIMS: ${(brief.prohibitedClaims ?? []).join(', ') || 'none'}\n\nTRANSCRIPT:\n${transcript}\n\nReturn structured JSON with: summary, topics, audience segments, and high-value moments. Each moment needs exact start/end guidance when timestamp data is supplied, a rewritten hook, why it works, a 0-100 score, and which differentiated account archetypes should receive it. Do not recommend identical spam reposting. Prefer distinct editorial angles for each account.`;
}

export function buildVariantPrompt(analysis: ContentAnalysis, accountProfiles: Array<{ id: string; handle: string; editorialRole?: string | null; audience?: string | null }>) {
  return `Create platform-ready content variants from this analysis:\n${JSON.stringify(analysis)}\n\nCONNECTED ACCOUNTS:\n${JSON.stringify(accountProfiles)}\n\nFor each useful moment, create differentiated variants matched to account editorial roles. Include hook, caption, CTA, hashtags, clip boundaries, aspect ratio, subtitle recommendation, pacing, cover text and accountIds. Avoid posting the same exact package to every account.`;
}
