/** No platform dependencies: accuracy-aware boundary transitions with a dwell period. */
export enum BoundaryState {
  Unknown,
  Inside,
  Outside
}

export class GeofenceTracker {
  confirmed: BoundaryState = BoundaryState.Unknown;
  private candidate: BoundaryState = BoundaryState.Unknown;
  private candidateSince: number = 0;
  private lastSample: number = 0;

  reset(): void {
    this.confirmed = BoundaryState.Unknown;
    this.candidate = BoundaryState.Unknown;
    this.candidateSince = 0;
    this.lastSample = 0;
  }

  /** Returns an event only after two distinct fresh fixes at least 10 seconds apart. */
  observe(distance: number, radius: number, accuracy: number, sampledAt: number, now: number): string {
    if (!isFinite(distance) || !isFinite(accuracy) || accuracy < 0 || accuracy > radius ||
      !isFinite(sampledAt) || sampledAt <= this.lastSample || sampledAt > now + 5000 || now - sampledAt > 120000) {
      return '';
    }
    this.lastSample = sampledAt;
    const margin = Math.min(15, radius / 10);
    const state = distance - accuracy > radius + margin ? BoundaryState.Outside
      : distance + accuracy < radius - margin ? BoundaryState.Inside : BoundaryState.Unknown;
    if (state === BoundaryState.Unknown || state === this.confirmed) {
      this.candidate = BoundaryState.Unknown;
      return '';
    }
    if (this.candidate !== state || sampledAt - this.candidateSince > 120000) {
      this.candidate = state;
      this.candidateSince = sampledAt;
      return '';
    }
    if (sampledAt - this.candidateSince < 10000) return '';
    const previous = this.confirmed;
    this.confirmed = state;
    this.candidate = BoundaryState.Unknown;
    // Initial confirmed outside is still actionable; an initial inside is just a baseline.
    return state === BoundaryState.Outside ? 'area_exit'
      : previous === BoundaryState.Outside ? 'area_enter' : '';
  }
}
