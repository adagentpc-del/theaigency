# theAIgincy Content OS

Multi-tenant AI content distribution platform for creators, brands, agencies, and franchises.

## Product loop
Capture/upload -> transcribe/analyze -> edit/clip -> create variants -> route to connected accounts -> schedule/publish -> unified inbox -> analytics/learning.

## Core modules
- Workspace + RBAC
- Social OAuth account connections and token health
- Recording/upload content inbox
- AI transcription, hook detection, clip plans, captions, covers, CTAs
- Video edit decision lists and render jobs
- Network Builder for differentiated satellite-account strategy
- Cross-platform scheduler and queue with rate-limit awareness
- Publishing adapters for Instagram, TikTok, YouTube and extensible providers
- Unified comments/mentions/messages inbox where platform APIs permit access
- AI-assisted reply drafts with human approval controls
- Notifications for comments, failures, expiring tokens, approvals, viral posts and account health
- Analytics normalization and AI strategy recommendations
- Audit log, retry/dead-letter handling, consent and moderation controls

## Important platform rule
The system does not mass-create social identities, fake engagement, coordinate deceptive repost networks, or bypass platform controls. Users create/own accounts and authorize them via official OAuth/API flows. The Network Builder creates positioning, names, bios and launch plans; account registration remains user/platform controlled.

## Local setup
1. Copy `.env.example` to `.env.local`.
2. Configure Postgres and provider OAuth credentials.
3. `npm install`
4. `npx prisma migrate dev`
5. `npm run dev`

## Deployment
Use a persistent Postgres database, object storage for source/rendered media, a worker/queue runtime for render/publish/analytics jobs, and HTTPS OAuth callback URLs. Keep all provider secrets server-side.
