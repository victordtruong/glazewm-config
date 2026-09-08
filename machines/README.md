# Machine-specific configs

The shared `config.yaml` at the repo root is deliberately machine-agnostic, so
it can be installed unchanged on every PC. A few things genuinely can't be
shared:

- **`bind_to_monitor`** on a workspace takes a monitor *index*, which depends on
  how many displays that PC has and how Windows numbered them.
- **Launcher keybindings** that point at an app which isn't installed on every
  machine (e.g. `shell-exec wt` on a Windows 10 box without Windows Terminal).
- **`startup_commands`**, if only some machines run Zebar.

GlazeWM has no include/import mechanism — a config is a single file — so a
machine that needs different settings gets its own full copy here:

```
machines/
  DESKTOP-ABC123/config.yaml
  WORK-LAPTOP/config.yaml
```

`install.ps1` looks for `machines\$env:COMPUTERNAME\config.yaml` first and
installs that if it exists, otherwise it installs the shared `config.yaml`.
Nothing else needs changing.

## Adding a machine

Run this from the repo root on the PC in question:

```powershell
# Print the name install.ps1 will look for
$env:COMPUTERNAME

# Fork the shared config for this machine
New-Item -ItemType Directory -Force -Path "machines\$env:COMPUTERNAME" | Out-Null
Copy-Item config.yaml "machines\$env:COMPUTERNAME\config.yaml"

# Edit it, then install
.\install.ps1
```

To find the monitor indexes to use with `bind_to_monitor`, with GlazeWM
running:

```powershell
glazewm query monitors
```

## Keeping a fork in sync

Because a machine config is a full copy, improvements to the shared config
don't reach it automatically. Diff it whenever you change the shared one:

```powershell
git diff --no-index ..\..\config.yaml .\config.yaml
```

Keep the machine-specific diff as small as you can — ideally just the
`workspaces` block and a launcher binding or two. If you find yourself
maintaining a large diff, it's usually a sign the change belongs in the shared
config instead.

## Alternative: skip the fork

If a machine only needs a different config *path* rather than different
settings, you don't need a fork at all — GlazeWM accepts one directly:

```powershell
glazewm start --config "C:\path\to\some-config.yaml"
```

It also reads the `GLAZEWM_CONFIG_PATH` environment variable when no
`--config` is passed.
