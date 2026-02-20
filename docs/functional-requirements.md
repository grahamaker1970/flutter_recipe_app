# Functional Requirements

## Scope
- Manage master recipes with ingredient rows.
- Apply one ratio to all ingredient amounts in real time.
- Save adjustment history notes.

## Recipe Create/Edit
- A recipe must have a non-empty recipe name.
- A recipe must include at least one valid ingredient row.
- Ingredient row fields:
  - `name` (required)
  - `base amount` (required, numeric)
  - `unit` (optional, free text, max 20 chars)
- Empty row handling:
  - Ignore rows where `name`, `base amount`, and `unit` are all empty.
  - Reject save if only one of `name` / `base amount` is filled.

## Unit Handling
- Unit is stored as `String` and is not managed by a master list.
- Unit can be empty and must not block save.
- Display rules:
  - With unit: `<amount><space><unit>` (example: `100 g`)
  - Without unit: `<amount>` (example: `2`)

## Live Calculator
- If a user edits one adjusted amount, the app recalculates ratio from `adjusted / base`.
- The same ratio is applied to every ingredient row.
- Base display and history display must follow the unit display rules above.

## History Notes
- Save note title, memo text, and per-ingredient snapshot.
- Ingredient snapshot stores:
  - `name`
  - `base amount`
  - `adjusted amount`
  - `unit`
