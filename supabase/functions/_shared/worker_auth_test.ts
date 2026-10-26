import { assertEquals } from "@std/assert";
import { authorizedScheduler, authorizedWorker } from "./worker_auth.ts";

Deno.test("invoke-only scheduler token never authorizes a stage or a user/public request", () => {
  const secret = "s".repeat(64);
  const scheduled = new Request("http://localhost", {
    headers: { "x-worker-schedule-token": secret },
  });
  assertEquals(authorizedScheduler(scheduled, secret), true);
  assertEquals(authorizedWorker(scheduled, "service-key"), false);
  for (const token of [undefined, "", "short", "x".repeat(64)]) {
    assertEquals(authorizedScheduler(scheduled, token), false);
  }
  assertEquals(
    authorizedScheduler(
      new Request("http://localhost", { headers: { authorization: `Bearer ${secret}` } }),
      secret,
    ),
    false,
  );
});

Deno.test("engine stages accept only the configured worker credential", () => {
  for (const token of [undefined, "user-jwt", "anon-jwt", "service-key"]) {
    const request = new Request("http://localhost", {
      headers: token ? { authorization: `Bearer ${token}` } : {},
    });
    assertEquals(authorizedWorker(request, "service-key"), token === "service-key");
    assertEquals(authorizedWorker(request, undefined), false);
  }
});

Deno.test("opaque hosted service secrets authenticate via apikey, public keys never do", () => {
  const secret = "sb_secret_test";
  for (const key of ["sb_publishable_test", "user-jwt", secret, ""]) {
    const request = new Request("http://localhost", { headers: { apikey: key } });
    assertEquals(authorizedWorker(request, secret), key === secret);
    assertEquals(authorizedWorker(request, undefined), false);
  }
});
