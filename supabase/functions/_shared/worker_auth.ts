// Stage handlers elevate to service_role and must never accept a user JWT.
export function authorizedWorker(request: Request, serviceKey: string | undefined): boolean {
  if (!serviceKey) return false;
  // Hosted projects can inject sb_secret_* as SUPABASE_SERVICE_ROLE_KEY.
  // Opaque API keys are not JWTs and belong in apikey, never decoded as claims.
  return request.headers.get("apikey") === serviceKey ||
    request.headers.get("authorization") === `Bearer ${serviceKey}`;
}

// Scheduler credential grants only worker invocation, never stage/DB access.
export function authorizedScheduler(request: Request, token: string | undefined): boolean {
  if (!token || token.length < 32) return false;
  const supplied = request.headers.get("x-worker-schedule-token") ?? "";
  if (supplied.length !== token.length) return false;
  let difference = 0;
  for (let i = 0; i < token.length; i++) difference |= supplied.charCodeAt(i) ^ token.charCodeAt(i);
  return difference === 0;
}
