# Marble Run World Cup — Claude Instructions

## Git & GitHub workflow

After every meaningful change, commit and push so the project is never in an unsaved state.

**Remote:** https://github.com/gwhy1788/marble-run (branch `master`)

### When to commit

- After completing any user-requested feature or improvement
- After fixing a bug
- Before and after any significant refactor
- Any time the project is in a clean, working state worth preserving

### Commit rules

- Stage only the files that changed — never `git add .` blindly
- Write concise, descriptive commit messages in the imperative mood:
  - `Add Sol de Mayo sun to Argentina marble flag`
  - `Fix Swiss cross to use compact arms instead of edge-to-edge bars`
  - `Remove Continue button requirement — tournament now fully autorun`
- Include `Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>` in every commit
- Always push immediately after committing: `git push`

### Commit message format

```
Short summary line (50 chars or less, imperative mood)

Optional body: explain WHY if the change is non-obvious. One blank
line between summary and body.

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
```

### Do not commit

- `.godot/` — editor cache, already in `.gitignore`
- Any secrets or credentials
- Half-finished work that breaks the game
