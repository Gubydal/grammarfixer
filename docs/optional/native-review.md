# Optional: Native Review Prompt

The template ships a `PlayServices.openStoreListing()` helper and the
`in_app_review` package. A native review prompt is deliberately **not**
auto-triggered in the base; the future app decides its success milestone.

Pattern to follow when adding it:

1. Pick a real success moment (e.g. after the Nth completed task).
2. Gate it with a SharedPreferences flag (`review_prompted`) so it shows at
   most once.
3. Call `InAppReview.instance.requestReview()` (or
   `PlayServices.maybeShowNativeReview()` once that helper is added per app).
4. Keep private star ratings and the store review prompt separate.

VidBrief's private rating sheet (stars -> Supabase `reviews` table) is
product-specific and was not migrated.
