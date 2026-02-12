# Plan: `tmw` — tmux-worktree CLI tool

## Summary

Bash script at `~/.local/bin/tmw`. Manages tmuxp configs
and git worktrees. Two project types: fullstack
(backend+frontend) and single (one repo). Subcommands
follow tmux/git-worktree naming: `init`, `new`, `kill`,
`attach`, `list`. Generates both static and parameterized
tmuxp configs. Chezmoi-compatible.

---

## Project Types

### Fullstack (backend + frontend)

- 2 repos, 2 worktrees per feature
- Split panes: nvim(2), srv(2), gitui(2), opencode(1)
- Env vars: `${BACKEND}`, `${FRONTEND}`, `${WORKTREE}`
- Metadata in tmuxp environment block:
  `BACKEND_REPO`, `FRONTEND_REPO`

### Single (one repo)

- 1 repo, 1 worktree per feature
- Single panes: nvim(1), srv(1), gitui(1), opencode(1)
- Env vars: `${BACKEND}`, `${WORKTREE}`
  (`BACKEND` reused for consistency, documented in help)
- Metadata: `BACKEND_REPO` only

---

## Subcommands

### `tmw init`

Generates two tmuxp configs in `~/.tmuxp/`:

1. **`<name>.yaml`** — static config pointing to actual
   repo paths. Day-to-day work on main branch.
2. **`{PROJECT}.worktree.yaml`** — parameterized config using
   `${BACKEND}`, `${FRONTEND}`, `${WORKTREE}` env vars.
   Includes `BACKEND_REPO`/`FRONTEND_REPO` in the
   `environment` block for other subcommands to read.

**Validation:**
- `--frontend` required when `--type=fullstack`
- `--frontend` rejected when `--type=single`
- Paths must exist and be git repos

**Generated windows (fullstack):**

```
Window  | Left Pane               | Right Pane
--------|-------------------------|--------------------
nvim    | cd $BE; nvim .          | cd $FE; nvim .
oc      | opencode (dir=$BACKEND) | -
srv     | cd $BE; pnpm run dev    | cd $FE; pnpm run dev
gitui   | cd $BE; gitui           | cd $FE; gitui
```

**Generated windows (single):**

```
Window  | Pane
--------|-----------------------------
nvim    | cd $BACKEND; nvim .
oc      | opencode (start_dir=$BACKEND)
srv     | cd $BACKEND; pnpm run dev
gitui   | cd $BACKEND; gitui
```

User edits `srv` window commands after generation.

---

### `tmw new`

Like `tmux new-session` + `git worktree add`. Creates
worktrees and starts a new tmuxp session.

**Steps:**
1. Read `BACKEND_REPO` (and `FRONTEND_REPO` if present)
   from `~/.tmuxp/{config-name}.worktree.yaml`
2. Derive worktree dirs:
   - `backend_dir = ${BACKEND_REPO}-${feature}`
   - `frontend_dir = ${FRONTEND_REPO}-${feature}`
     (fullstack only)
3. Create worktrees if dirs don't exist:
   ```bash
   git -C $BACKEND_REPO worktree add \
     -b at/$feature $backend_dir main
   ```
   - Same for frontend if fullstack
   - If branch already exists, attach to existing branch
4. Export env vars and launch tmuxp:
   ```bash
   WORKTREE=$feature \
   BACKEND=$backend_dir \
   FRONTEND=$frontend_dir \
   tmuxp load {config-name}.worktree
   ```

**If worktree dirs already exist:** skip creation, just
launch tmuxp (handles re-open after session was killed).

---

### `tmw kill`

Like `tmux kill-session` + `git worktree remove`. Tears
down session and cleans up worktrees.

**Steps:**
1. Derive session name from config's `session_name`
   template — replace `${WORKTREE}` with feature arg
2. Kill tmux session if exists:
   `tmux kill-session -t $session_name`
3. Remove worktrees:
   ```bash
   git -C $BACKEND_REPO worktree remove \
     $backend_dir --force
   ```
   - Same for frontend if fullstack
4. Prune: `git -C $BACKEND_REPO worktree prune`
   (and frontend)
5. Does **NOT** delete git branches (keeps for
   push/revisit)

**If session not found:** warn, continue with worktree
cleanup.

---

### `tmw attach`

Like `tmux attach-session`. Reattaches to an existing
worktree session.

**Smart attach behavior:**
1. Derive session name (same as `kill`)
2. If tmux session exists →
   `tmux attach-session -t $name`
3. If no session but worktree dirs exist → re-launch
   tmuxp (same as `new` with existing worktrees), then
   attach
4. If no session and no worktrees → error, suggest
   `tmw new`

---

### `tmw list`

Like `tmux list-sessions`. Shows active tmw-managed
sessions.

**Without args (`tmw list`):**
- Scan all `*.worktree.yaml` in `~/.tmuxp/`
- For each, check `git worktree list` in the repos
- Cross-reference with `tmux list-sessions`
- Show: config name, feature, session status

**With config arg (`tmw list <config-name>`):**
- Same but filtered to that project only

**Output format:**

```
CONFIG    FEATURE              STATUS
myapp   feature-name   attached
myapp   another-feat        detached
myproject   new-feature       no session
```

---

## Help Text

### `tmw --help`

```
tmw - tmux worktree manager

Usage: tmw <command> [args]

Commands:
  init     Generate tmuxp configs for a new project
  new      Create worktrees and start a tmuxp session
  kill     Kill session and remove worktrees
  attach   Re-attach to a worktree session
  list     List active worktree sessions

Run 'tmw <command> --help' for details and examples.
```

### `tmw init --help`

```
Generate tmuxp configs for a new project.

Creates two configs in ~/.tmuxp/:
  <name>.yaml            Static config for main branch
  <name>.worktree.yaml   Parameterized for worktrees

Usage:
  tmw init <name> --type=<type> --backend=<path>
    [--frontend=<path>]

Options:
  --type       fullstack or single (required)
  --backend    Path to backend/main repo (required)
  --frontend   Path to frontend repo (fullstack only)

Examples:
  # Fullstack project (backend + frontend)
  tmw init myapp \
    --type=fullstack \
    --backend=~/Projects/myapp/backend \
    --frontend=~/Projects/myapp/frontend

  # Single repo project
  tmw init myproject \
    --type=single \
    --backend=~/Projects/Personal/myproject
```

### `tmw new --help`

```
Create git worktrees and start a tmuxp session.

Creates branch at/<feature> from main in each repo,
sets up worktree directories as siblings of the repos,
and launches the tmuxp session.

If worktrees already exist, skips creation and just
launches the session.

Usage:
  tmw new <config> <feature>

Arguments:
  config    Project name (matches tmuxp config)
  feature   Feature name (branch and dir suffix)

Examples:
  tmw new myapp feature-name
  tmw new myproject new-feature

What happens (myapp example):
  git worktree add -b at/feature-name \
    .../backend-feature-name main
  git worktree add -b at/feature-name \
    .../frontend-feature-name main
  tmuxp load myapp.worktree  # with env vars set
```

### `tmw kill --help`

```
Kill tmux session and remove worktrees.

Kills the tmux session, removes worktree directories
from all repos, and prunes. Does not delete branches.

Usage:
  tmw kill <config> <feature>

Arguments:
  config    Project name
  feature   Feature name

Examples:
  tmw kill myapp feature-name
  tmw kill myproject new-feature

What happens (myapp example):
  tmux kill-session -t myapp-feature-name
  git worktree remove .../backend-crud-orgs
  git worktree remove .../frontend-crud-orgs
  git worktree prune  # in both repos
```

### `tmw attach --help`

```
Re-attach to a worktree session.

If the tmux session is running, attaches to it.
If the session was killed but worktrees still exist,
re-launches tmuxp and attaches.

Usage:
  tmw attach <config> <feature>

Arguments:
  config    Project name
  feature   Feature name

Examples:
  tmw attach myapp feature-name
  tmw attach myproject new-feature
```

### `tmw list --help`

```
List active worktree sessions.

Shows all tmw-managed worktree sessions with status.
Without arguments, lists all projects. With a config
name, filters to that project.

Usage:
  tmw list [config]

Arguments:
  config    Project name (optional, filters output)

Examples:
  # List all projects
  tmw list

  # List worktrees for one project
  tmw list myapp

Output:
  CONFIG    FEATURE              STATUS
  myapp   feature-name   attached
  myapp   another-feat        detached
  myproject   new-feature       no session
```

---

## File Structure

```
~/.local/bin/tmw              # Script (chmod +x)

~/.tmuxp/
  myapp.yaml                # Static (exists)
  myapp.worktree.yaml       # Parameterized (exists)
  myproject.yaml                # Static (exists)
  myproject.worktree.yaml       # Generated by init
  plans/
    tmw-tool.md               # This plan
```

---

## Config Templates

### Fullstack worktree template

```yaml
session_name: <name>-${WORKTREE}
environment:
  BACKEND_REPO: <backend-path>
  FRONTEND_REPO: <frontend-path>
windows:
- window_name: nvim
  layout: <split-vertical>
  panes:
  - focus: 'true'
    shell_command:
    - cd ${BACKEND}
    - nvim .
  - shell_command:
    - cd ${FRONTEND}
    - nvim .
- window_name: oc
  panes:
  - focus: 'true'
    shell_command: opencode
  start_directory: ${BACKEND}
- window_name: srv
  focus: 'true'
  layout: <split-vertical>
  panes:
  - focus: 'true'
    shell_command:
    - cd ${BACKEND}
    - pnpm run dev
  - shell_command:
    - cd ${FRONTEND}
    - pnpm run dev
- window_name: gitui
  layout: <split-vertical>
  panes:
  - focus: 'true'
    shell_command:
    - cd ${BACKEND}
    - gitui
  - shell_command:
    - cd ${FRONTEND}
    - gitui
```

### Fullstack static template

Same structure but actual paths replace env vars. No
`environment` block. `session_name: <name>`.

### Single worktree template

```yaml
session_name: <name>-${WORKTREE}
environment:
  BACKEND_REPO: <repo-path>
windows:
- window_name: nvim
  panes:
  - focus: 'true'
    shell_command:
    - cd ${BACKEND}
    - nvim .
- window_name: oc
  panes:
  - focus: 'true'
    shell_command: opencode
  start_directory: ${BACKEND}
- window_name: srv
  focus: 'true'
  panes:
  - focus: 'true'
    shell_command:
    - cd ${BACKEND}
    - pnpm run dev
- window_name: gitui
  panes:
  - focus: 'true'
    shell_command:
    - cd ${BACKEND}
    - gitui
```

### Single static template

Same but actual paths, no env vars, no environment block.

---

## Script Implementation Details

**Language:** Bash (`set -euo pipefail`)

**Parsing repo paths:** grep+sed from tmuxp YAML. No
external YAML parser — we control the format.

**Session name derivation:** Grep `session_name:` from
worktree config, replace `${WORKTREE}` with feature arg.

**Detecting project type:** Check if `FRONTEND_REPO`
exists in the config. Present = fullstack, absent = single.

**Error handling:**
- Missing config file → error + exit
- Missing repo paths → error + exit
- Git worktree add fails → show git error, exit
- tmux session not found on kill → warn, continue cleanup
- No worktrees on attach → error, suggest `tmw new`

**Help/usage:** `tmw --help` and `tmw <cmd> --help`

---

## Implementation Steps

1. Create `~/.local/bin/tmw` — shebang, set -euo pipefail,
   main dispatcher, usage/help functions
2. Implement shared helpers: `parse_config()`,
   `derive_session_name()`, `derive_paths()`
3. Implement `init` — flag parsing, validation, template
   generation for both static and worktree configs
4. Implement `new` — config parsing, worktree creation,
   tmuxp launch
5. Implement `kill` — session kill, worktree removal, prune
6. Implement `attach` — smart attach with re-launch
   fallback
7. Implement `list` — scan configs, cross-ref git worktree
   list + tmux ls
8. chmod +x, test all subcommands
9. Update existing `myapp.worktree.yaml` to match
   template format (minor layout tweaks)

---

## Resolved Decisions

- **Tool name:** `tmw` (tmux-worktree)
- **Subcommands:** `init`, `new`, `kill`, `attach`, `list`
  (matches tmux/git-worktree naming)
- **No `detach`:** Ctrl+B D is sufficient
- **Env var for single repos:** `${BACKEND}` for
  consistency, documented in help
- **Branch cleanup on kill:** No — only worktree dirs
- **Dependency install on new:** No — user handles it
- **Re-open (new w/ existing worktrees):** silently skip
  creation, launch tmuxp
- **Attach without session:** smart — re-launch tmuxp if
  worktrees exist
- **List:** global or config-scoped via optional arg
- **Server window:** generic `pnpm run dev` placeholder,
  user edits after init
- **Single type layout:** single pane per window
- **Config generation:** both static + worktree variants
- **Help:** global `--help` + per-subcommand `--help`
  with full examples baked in

## Chezmoi Integration

Script: `~/.local/bin/tmw` → chezmoi source as
`dot_local/bin/executable_tmw`.
Configs: `~/.tmuxp/*.yaml` → `dot_tmuxp/` in chezmoi.
