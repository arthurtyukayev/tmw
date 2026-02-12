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

   new CONFIG FEATURE
      Create worktrees and start tmuxp session. Creates branch FEATURE
      from main. If worktrees exist, skips creation and launches.

   attach CONFIG FEATURE
      Re-attach to an existing worktree session. If session missing but
      worktrees exist, re-launches tmuxp.

   kill CONFIG FEATURE
      Kill tmux session and remove worktrees. Git branches preserved.

   list [CONFIG]
      List active worktree sessions. Without CONFIG, shows all projects.

   version
      Display version information.


4.  File Locations

   ~/.local/bin/tmw                   Main executable
   ~/.tmuxp/NAME.yaml                 Static config (main branch)
   ~/.tmuxp/NAME.worktree.yaml        Worktree config (parameterized)


5.  Version Management

   make version    Show current version
   make patch      Bump patch (0.1.0 -> 0.1.1)
   make minor      Bump minor (0.1.0 -> 0.2.0)
   make major      Bump major (0.1.0 -> 1.0.0)
   make tag        Create git tag vX.X.X
   make install    Copy to /usr/local/bin
   make uninstall  Remove from /usr/local/bin


6.  Dependencies

   tmux(1), tmuxp(1), git(1)


Author's Address

   TMW Contributors
   https://github.com/arthurtyukayev/tmw
```
