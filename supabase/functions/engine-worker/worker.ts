export const RETRY_SECONDS = [1, 4, 15] as const;

export function retryDelaySeconds(attempt: number): number {
  return RETRY_SECONDS[Math.max(0, Math.min(attempt - 1, RETRY_SECONDS.length - 1))];
}

export function stageFunction(type: string): string | null {
  return ["extract", "link", "plan", "write", "validate", "commit", "remember"].includes(type)
    ? `engine-${type}`
    : null;
}

export function isTerminalFailure(
  status: number | null,
  attempt: number,
  stageTerminal: boolean,
): boolean {
  return stageTerminal || (status !== null && status >= 400 && status < 500) || attempt >= 3;
}
