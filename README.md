```
TMW SPECIFICATION
=================

1.  Overview

   TMW manages tmuxp configs and git worktrees for feature development.
   Each project gets two configs: static (main branch) and parameterized
   (worktree sessions).


2.  Installation

   git clone https://github.com/arthurtyukayev/tmw
   cd tmw
   make install

   Or copy tmw to any directory in $PATH:
   cp tmw /usr/local/bin/


3.  Commands

   init NAME --type=TYPE --backend=PATH [--frontend=PATH]
      Generate tmuxp configs for a new project.

      TYPE must be "fullstack" (backend + frontend) or "single" (one repo).
      Examples:
         tmw init myapp --type=fullstack \
              --backend=~/Projects/backend \
              --frontend=~/Projects/frontend
         tmw init myproject --type=single --backend=~/Projects/myproject

   new CONFIG [FEATURE]
      If FEATURE is omitted, loads the static config (main-branch
      session).

      If FEATURE is provided, creates worktrees and starts tmuxp
      session. Creates branch <branch_prefix><FEATURE> from the repo
      default branch (origin/HEAD when available; fallback order:
      main, master, trunk, develop). If worktrees exist, skips
      creation and launches.

   attach CONFIG [FEATURE]
      If FEATURE is omitted, attaches to static session.

      If FEATURE is provided, re-attaches to an existing worktree
      session.

      attach only attaches to an existing tmux session. If the
      requested session does not exist, command fails and suggests
      tmw new.

   kill CONFIG FEATURE
      Kill tmux session and remove worktrees. Git branches preserved.
      Does not run git worktree prune automatically.

   list [CONFIG]
      List active worktree sessions. Without CONFIG, shows all projects.

   version
      Display version information.


4.  File Locations

   ~/.local/bin/tmw                   Main executable
   ~/.tmuxp/NAME.yaml                 Static config (main branch)
   ~/.tmuxp/NAME.worktree.yaml        Worktree config (parameterized)
   ~/.tmuxp/NAME.yml                  Also recognized for static config
   ~/.tmuxp/NAME.worktree.yml         Also recognized for worktree config


5.  Template Generation

   tmuxp templates are embedded directly in the tmw script (heredocs).
   tmw init renders these templates and writes files into ~/.tmuxp on
   demand.

   There are no standalone .tmuxp template files committed in this
   repository.


6.  Configuration

   TMW uses a config file at
   ${XDG_CONFIG_HOME:-~/.config}/tmw/config.yml for settings.

   Settings:
      branch_prefix     Prefix for git branches created by 'new' command
                        Set to "" for no prefix, or use "feature/", "at/", etc.

   Example config.yml:
      branch_prefix: "feature/"


7.  Version Management

   make version    Show current version
   make patch      Bump patch (0.1.0 -> 0.1.1)
   make minor      Bump minor (0.1.0 -> 0.2.0)
   make major      Bump major (0.1.0 -> 1.0.0)
   make tag        Create git tag vX.X.X
   make install    Copy to /usr/local/bin
   make uninstall  Remove from /usr/local/bin


8.  Dependencies

     Required:
        tmux [1], tmuxp [2], git [3]

     tmw validates required commands at runtime and exits with a clear
     error if a dependency is missing from PATH.

     Default generated windows also assume these commands exist:
        nvim, opencode, pnpm, gitui

     After tmw init, edit generated configs if your dev commands differ
     (especially in the srv window).

    [1]: https://github.com/tmux/tmux
    [2]: https://github.com/tmux-python/tmuxp
    [3]: https://git-scm.com/


Author's Address

   Arthur Tyukayev
   https://github.com/arthurtyukayev
```
