// Account deletion edge function.
//
// Deletes the auth user plus every generic template table (profiles,
// feedback). When an app adds its own tables to the app_<slug> schema, add
// them to the `tables` array below and redeploy:
//
//   supabase functions deploy delete-account
//
// The external deletion page lives at
// https://<slug>.mogate.tech/delete-account (template only links to it).

import { createClient } from "npm:@supabase/supabase-js@2";

Deno.serve(async (req) => {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return new Response("Unauthorized", { status: 401 });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    {
      global: {
        headers: { Authorization: authHeader },
      },
    },
  );

  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser();

  if (userError || !user) {
    return new Response("Unauthorized", { status: 401 });
  }

  let schema = "app_starter";
  try {
    const body = await req.json();
    schema = typeof body?.schema === "string" ? body.schema : schema;
  } catch {
    // Keep the default schema when no body is provided.
  }

  // Generic template tables. Extend per app with any app-specific tables.
  const tables = ["feedback"];
  for (const table of tables) {
    await supabase.schema(schema).from(table).delete().eq("user_id", user.id);
  }
  await supabase.schema(schema).from("profiles").delete().eq("id", user.id);

  const { error } = await supabase.auth.admin.deleteUser(user.id);
  if (error) {
    return new Response(error.message, { status: 500 });
  }

  return new Response("Account deleted", { status: 200 });
});
