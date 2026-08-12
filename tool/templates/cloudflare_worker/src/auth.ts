// Auth helper placeholder.
//
// Real apps replace this with their own scheme (e.g. Supabase JWT
// verification). This helper shows the safe pattern for comparing a shared
// secret without timing side channels.

export async function verifyBearerToken(
  request: Request,
  expected: string,
): Promise<boolean> {
  const header = request.headers.get("Authorization");
  if (!header?.startsWith("Bearer ")) return false;
  const token = header.slice("Bearer ".length);
  return timingSafeEqualStrings(token, expected);
}

export async function requireAuth(
  request: Request,
  env: { AUTH_TOKEN: string },
): Promise<Response | null> {
  const ok = await verifyBearerToken(request, env.AUTH_TOKEN);
  return ok ? null : Response.json(
    { error: { code: "UNAUTHORIZED", message: "Unauthorized" } },
    { status: 401 },
  );
}

async function timingSafeEqualStrings(a: string, b: string): Promise<boolean> {
  const digest = async (value: string) =>
    new Uint8Array(
      await crypto.subtle.digest(
        "SHA-256",
        new TextEncoder().encode(value),
      ),
    );
  const [da, db] = await Promise.all([digest(a), digest(b)]);
  if (da.length !== db.length) return false;
  let diff = 0;
  for (let i = 0; i < da.length; i++) {
    diff |= da[i]! ^ db[i]!;
  }
  return diff === 0;
}
