export type PerformanceWindow = {
  accountId: string;
  weekday: number;
  hour: number;
  score: number;
  sampleSize: number;
};

export type ScheduleCandidate = {
  accountId: string;
  earliest: Date;
  latest: Date;
  timezone: string;
};

export function chooseBestSlot(candidate: ScheduleCandidate, windows: PerformanceWindow[], occupied: Date[] = []) {
  const relevant = windows
    .filter(w => w.accountId === candidate.accountId && w.sampleSize >= 3)
    .sort((a, b) => b.score - a.score);

  const cursor = new Date(candidate.earliest);
  const latest = candidate.latest.getTime();
  while (cursor.getTime() <= latest) {
    const occupiedNearby = occupied.some(d => Math.abs(d.getTime() - cursor.getTime()) < 30 * 60 * 1000);
    if (!occupiedNearby) {
      const match = relevant.find(w => w.weekday === cursor.getDay() && w.hour === cursor.getHours());
      if (match) return new Date(cursor);
    }
    cursor.setMinutes(cursor.getMinutes() + 30);
  }

  return candidate.earliest;
}

export function enforceSpacing(slots: Date[], minimumMinutes = 90) {
  return [...slots].sort((a, b) => a.getTime() - b.getTime()).filter((slot, index, all) => {
    if (index === 0) return true;
    return slot.getTime() - all[index - 1].getTime() >= minimumMinutes * 60 * 1000;
  });
}
