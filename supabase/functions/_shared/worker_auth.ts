// Stage handlers elevate to service_role and must never accept a user JWT.
export function authorizedWorker(request: Request, serviceKey: string | undefined): boolean {
  if (!serviceKey) return false;
  // Hosted projects can inject sb_secret_* as SUPABASE_SERVICE_ROLE_KEY.
  // Opaque API keys are not JWTs and belong in apikey, never decoded as claims.
  return request.headers.get("apikey") === serviceKey ||
    request.headers.get("authorization") === `Bearer ${serviceKey}`;
}
