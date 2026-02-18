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
- Use real line breaks via a body file, then verify rendered markdown.

## Create a Pull Request
1. Create and switch to a new branch: `git checkout -b <topic-branch>`
2. Write the PR body in a file with real line breaks.
3. Create the PR with `gh pr create --title "<title>" --body-file <path-to-body-file>`
4. Verify rendering with `gh pr view --web` or `gh pr view <number> --json body,url`

## Edit an Existing Pull Request
1. Update the same body file or create a new file with real line breaks.
2. Run `gh pr edit <number> --title "<title>" --body-file <path-to-body-file>`
3. Verify rendered markdown again.

## Template
- Use `references/pr-body-template.md` as the base.
- Keep sections that are not used as `N/A` instead of deleting headers.
