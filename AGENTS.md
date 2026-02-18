# Agent Rules

## Pull Request Rule
- Use the `pr-workflow` skill for branch hygiene, Japanese PR writing, PR description formatting, and post-create checks.
- Skill file: `c:/Projects/ws/flutter_recipe_app/.codex/skills/pr-workflow/SKILL.md`

## Git History Hygiene Rule
- Use the `git-history-hygiene` skill before starting a new goal-oriented work unit and before creating a PR/review request.
- Skill file: `c:/Projects/ws/flutter_recipe_app/.codex/skills/git-history-hygiene/SKILL.md`

## Rule Update Meta Rule
- Treat user instructions that indicate recurring behavior (for example: "always", "every time", "from now on", "rule") as persistent rule candidates.
- For each persistent rule candidate, propose where to record it (`AGENTS.md` or a Skill) and provide a draft rule text.
- Update files only after explicit user confirmation ("confirm before append" is the default behavior).
- Before finishing a task, report in one line whether any new persistent rule candidate was detected.

## Git History Hygiene (General)
- Here, "work" means a single goal-oriented work unit (usually one PR branch), not a single commit.
- Before starting a new goal-oriented work unit, run `git status -sb` and `git log --oneline origin/main..HEAD` to confirm history cleanliness.
- If unrelated commits or diffs are present, create a new working branch from the latest `main`, then carry only required diffs (for example, by cherry-pick) before starting.
- Multiple commits during the same work unit are allowed.
- Before creating a PR (or requesting review), re-check that no unrelated diffs are mixed in.
