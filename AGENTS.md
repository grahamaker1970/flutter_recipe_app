# Agent Rules

## Pull Request Rule
- Always create a dedicated new branch before creating a pull request.
- Do not create pull requests from a reused existing branch.
- Create pull request titles and descriptions in Japanese by default.
- Use the `pr-workflow` skill for PR description formatting and post-create checks.
- Skill file: `c:/Projects/ws/flutter_recipe_app/.codex/skills/pr-workflow/SKILL.md`

## Rule Update Meta Rule
- Treat user instructions that indicate recurring behavior (for example: "always", "every time", "from now on", "rule") as persistent rule candidates.
- For each persistent rule candidate, propose where to record it (`AGENTS.md` or a Skill) and provide a draft rule text.
- Update files only after explicit user confirmation ("confirm before append" is the default behavior).
- Before finishing a task, report in one line whether any new persistent rule candidate was detected.
