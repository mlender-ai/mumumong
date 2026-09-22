import { createClient } from "@supabase/supabase-js";
import { logEvent } from "../_shared/log.ts";
import { serviceRoleClient } from "../_shared/supabase.ts";

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json" },
  });
}

Deno.serve(async (request: Request): Promise<Response> => {
  if (request.method !== "POST") return json({ error: "method_not_allowed" }, 405);
  const authorization = request.headers.get("authorization");
  const token = authorization?.startsWith("Bearer ") ? authorization.slice(7) : null;
  const url = Deno.env.get("SUPABASE_URL");
  // On hosted projects this variable resolves to the active publishable key;
  // local Supabase supplies the legacy anon JWT under the same name.
  const publicKey = Deno.env.get("SUPABASE_ANON_KEY");
  if (!token || !url || !publicKey) return json({ error: "unauthorized" }, 401);

  const authClient = createClient(url, publicKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data, error: authError } = await authClient.auth.getUser(token);
  if (authError || !data.user) return json({ error: "unauthorized" }, 401);

  const admin = serviceRoleClient();
  const userId = data.user.id;
  const { error: dataError } = await admin.rpc("delete_user_data", {
    p_user_id: userId,
  });
  if (dataError) {
    logEvent("account_delete_failed", { user_id: userId, stage: "data", code: dataError.code });
    return json({ error: "delete_failed" }, 500);
  }
  const { error: userError } = await admin.auth.admin.deleteUser(userId);
  if (userError) {
    logEvent("account_delete_failed", { user_id: userId, stage: "auth", code: "auth_delete" });
    return json({ error: "delete_failed" }, 500);
  }
  logEvent("account_deleted", { user_id: userId, status: "done" });
  return json({ deleted: true });
});
