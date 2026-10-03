/** A time-of-day greeting with the first word of the entered name, e.g. "Good evening, Halina". */
export function greeting(displayName: string, now: Date): string {
  const hour = now.getHours();
  const salutation = hour < 5 ? 'Good evening' : hour < 12 ? 'Good morning' : hour < 18 ? 'Good afternoon' :
    'Good evening';
  const firstName = displayName.trim().split(/\s+/)[0];
  return firstName === '' ? salutation : `${salutation}, ${firstName}`;
}
