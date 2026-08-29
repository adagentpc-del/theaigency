/**
 * Minimal in-memory, fixed-window rate limiter, keyed by caller IP.
 *
 * IP-based (not device- or account-based) is deliberate: this app has no
 * accounts and must never collect a device identifier (see
 * PRIVACY_DATA_MAP.md), so IP is the only caller signal available
 * without adding one. This is a real, working limiter for a single
 * long-running process (unlike a serverless function, this process
 * doesn't reset the map on every cold start) — but it is still
 * single-instance and in-memory: running multiple replicas behind a load
 * balancer means each replica enforces its own independent limit rather
 * than a shared one. That is an accepted, documented scaling gap (see
 * README.md), not a claim of distributed correctness.
 */

interface Bucket {
  count: number;
  resetAt: number;
}

const buckets = new Map<string, Bucket>();

export function checkRateLimit(key: string, windowMs: number, max: number): boolean {
  const now = Date.now();
  const bucket = buckets.get(key);

  if (!bucket || now >= bucket.resetAt) {
    buckets.set(key, { count: 1, resetAt: now + windowMs });
    return true;
  }

  if (bucket.count >= max) {
    return false;
  }

  bucket.count += 1;
  return true;
}

/** Periodic sweep so the map doesn't grow unbounded over the process's lifetime. */
export function startRateLimiterCleanup(intervalMs = 5 * 60_000): NodeJS.Timeout {
  return setInterval(() => {
    const now = Date.now();
    for (const [key, bucket] of buckets) {
      if (now >= bucket.resetAt) {
        buckets.delete(key);
      }
    }
  }, intervalMs).unref();
}

/** Test-only escape hatch. */
export function resetRateLimiterForTests(): void {
  buckets.clear();
}
