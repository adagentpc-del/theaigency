import { db } from '@/lib/db';

export async function notify(workspaceId: string, input: { type: 'ENGAGEMENT'|'POST_FAILED'|'APPROVAL_REQUIRED'|'TOKEN_EXPIRING'|'ACCOUNT_HEALTH'|'VIRAL_MOMENT'|'STRATEGY'|'SYSTEM'; title: string; body: string; actionUrl?: string }) {
  return db.notification.create({ data: { workspaceId, ...input } });
}

export async function markRead(workspaceId: string, notificationId: string) {
  return db.notification.updateMany({ where: { id: notificationId, workspaceId }, data: { readAt: new Date() } });
}

export async function unreadCount(workspaceId: string) {
  return db.notification.count({ where: { workspaceId, readAt: null } });
}
