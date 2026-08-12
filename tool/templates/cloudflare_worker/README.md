# Generic Cloudflare Worker Starter

A minimal, production-shaped Worker for apps that need a server-side API
(paid API keys, webhooks, quotas). Copy this folder into the new app only
when the app prompt explicitly requires a Worker.

## What it includes

- TypeScript with strict types and generated `Env` bindings (`wrangler types`)
- `wrangler.jsonc` (JSON config, compatibility date, observability,
  `nodejs_compat`)
- Structured JSON errors (`src/errors.ts`)
- `/health` route
- Auth helper placeholder (`src/auth.ts`, timing-safe secret comparison)
- Vitest tests using the Workers test pool

## What it deliberately excludes

- Any app-specific endpoints (`/summarize`, `/ask`, YouTube validation,
  Gemini, credit logic, models)
- VidBrief's Worker code
- Secrets (set them with `npx wrangler secret put`, never in config)

## Setup

```bash
npm install
npm run types          # regenerate worker-configuration.d.ts from wrangler.jsonc
npm run typecheck
npm test
npx wrangler dev
```

## Deploy

```bash
npx wrangler deploy
```

Set secrets per environment:

```bash
npx wrangler secret put AUTH_TOKEN
```

Update `compatibility_date` in `wrangler.jsonc` periodically (see
https://developers.cloudflare.com/workers/configuration/compatibility-dates/).
