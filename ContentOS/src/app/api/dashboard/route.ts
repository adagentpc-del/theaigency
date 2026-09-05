import { NextRequest, NextResponse } from 'next/server';
import { db } from '@/lib/db';

export async function GET(req: NextRequest) {
  const workspaceId = req.nextUrl.searchParams.get('workspaceId');
  if (!workspaceId) return NextResponse.json({ error: 'workspaceId required' }, { status: 400 });

  const [accounts, posts, inbox, notifications] = await Promise.all([
    db.socialAccount.findMany({ where: { workspaceId }, select: { id:true, provider:true, handle:true, status:true, editorialRole:true, lastSyncAt:true } }),
    db.scheduledPost.findMany({ where: { workspaceId }, orderBy: { scheduledFor:'asc' }, take:50, include:{ targets:{ include:{ socialAccount:{ select:{ provider:true, handle:true } } } } } }),
    db.inboxItem.findMany({ where: { workspaceId, resolvedAt:null }, orderBy:[{priority:'desc'},{receivedAt:'desc'}], take:100 }),
    db.notification.findMany({ where: { workspaceId, readAt:null }, orderBy:{createdAt:'desc'}, take:50 })
  ]);

  return NextResponse.json({ accounts, posts, inbox, notifications });
}
