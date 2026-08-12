// Structured error handling: every failure becomes a JSON error response
// with a stable code and status instead of a generic 500.

export class AppError extends Error {
  constructor(
    message: string,
    public readonly status: number = 500,
    public readonly code: string = "ERROR",
  ) {
    super(message);
    this.name = "AppError";
  }
}

export function errorResponse(err: unknown): Response {
  if (err instanceof AppError) {
    return Response.json(
      { error: { code: err.code, message: err.message } },
      { status: err.status },
    );
  }
  console.error("Unhandled error", err);
  return Response.json(
    { error: { code: "INTERNAL_ERROR", message: "Internal error" } },
    { status: 500 },
  );
}
