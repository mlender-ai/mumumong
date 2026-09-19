// Stage handlers elevate to service_role and must never accept a user JWT.
export function authorizedWorker(request: Request, serviceKey: string | undefined): boolean {
  return !!serviceKey && request.headers.get("authorization") === `Bearer ${serviceKey}`;
}
