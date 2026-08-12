import { exports } from "cloudflare:workers";
import { describe, expect, it } from "vitest";

describe("generic worker", () => {
  it("GET /health returns ok", async () => {
    const res = await exports.default.fetch(
      new Request("https://example.com/health"),
    );
    expect(res.status).toBe(200);
    expect(await res.json()).toEqual(
      expect.objectContaining({ status: "ok" }),
    );
  });

  it("unknown routes return a structured 404", async () => {
    const res = await exports.default.fetch(
      new Request("https://example.com/nope"),
    );
    expect(res.status).toBe(404);
    const body = (await res.json()) as { error: { code: string } };
    expect(body.error.code).toBe("NOT_FOUND");
  });
});
