# Optional: Notifications / Reminders

Local re-engagement reminders are **not** enabled in the base template.
Add them per app when the product genuinely benefits:

- One-use tools: one reminder after about a week, then stop.
- AI/productivity tools: light weekly reminder.
- Habit/learning/wellness apps: ask the user for the intended cadence.

Implementation notes:

- Use local notifications by default (no push infrastructure needed).
- Include a setting to disable reminders.
- Request notification permission only when the feature is about to be
  used, after explaining why.
