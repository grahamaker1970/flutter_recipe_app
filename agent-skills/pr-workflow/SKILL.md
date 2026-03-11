---
name: pr-workflow
description: Create and edit GitHub pull requests with safe branch hygiene, Japanese-by-default PR writing, and markdown-safe PR descriptions. Use when Codex needs to create a PR, update a PR body or title, prepare PR body templates, or verify that PR markdown renders with real line breaks instead of escaped newline text.
---

# PR Workflow

## Required Rules
- Create a dedicated new branch for each pull request.
- Never create a pull request from a reused branch.
- Write pull request titles and descriptions in Japanese by default.
- Never pass escaped newline sequences like `\n` as PR body content.
- Always save PR body files as UTF-8 (without BOM). Do not rely on shell default encodings.
- Use real line breaks via a body file, then verify rendered markdown.
- After creating or editing a PR, verify `body` via `gh pr view <number> --json body,title,url`.
- If mojibake is detected, rewrite the body file in UTF-8 (without BOM) and run `gh pr edit --body-file` immediately.
- For functional changes, confirm related docs are updated or include a clear reason in the PR body for why updates are unnecessary.

## Create a Pull Request
1. Create and switch to a new branch: `git checkout -b <topic-branch>`
2. Write the PR body in a UTF-8 (without BOM) file with real line breaks, and include document impact:
   - Updated docs (for example: `docs/functional-requirements.md`, `docs/architecture.md`)
   - Or a short reason if no documentation update was needed
3. Create the PR with `gh pr create --title "<title>" --body-file <path-to-body-file>`
4. Verify rendering and encoding with `gh pr view <number> --json body,title,url`

## Edit an Existing Pull Request
1. Update the same body file or create a new UTF-8 (without BOM) file with real line breaks.
2. Run `gh pr edit <number> --title "<title>" --body-file <path-to-body-file>`
3. Verify rendered markdown and encoding again with `gh pr view <number> --json body,title,url`.

## PowerShell Encoding Tip
- In PowerShell, prefer explicit UTF-8 (without BOM) writes:
  - `$utf8NoBom = New-Object System.Text.UTF8Encoding($false)`
  - `[System.IO.File]::WriteAllText((Resolve-Path <path>), <content>, $utf8NoBom)`

## Template
- Use `references/pr-body-template.md` as the base.
- Keep sections that are not used as `N/A` instead of deleting headers.
