# glazewm-config

My [GlazeWM](https://github.com/glzr-io/glazewm) config, kept in one place so
every PC I use gets the same window management.

- `config.yaml` — the shared config. Machine-agnostic: no monitor bindings, no
  apps that aren't on every box.
- `install.ps1` — links it into `%USERPROFILE%\.glzr\glazewm\config.yaml`.
- `machines/` — full config forks for PCs that need something different. See
  [machines/README.md](machines/README.md).

## Setting up a new PC

```powershell
winget install GlazeWM
git clone https://github.com/victordtruong/glazewm-config.git
cd glazewm-config
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

Then start GlazeWM. That's it.

`install.ps1` symlinks the config, so after the first setup a `git pull` plus
`alt+shift+r` is enough to pick up changes on that machine. Symlinks on Windows
need [Developer Mode](ms-settings:developers) or an elevated shell — without
either, the script falls back to copying the file and tells you so (re-run it
after each pull in that case).

Useful flags:

| Flag | What it does |
| --- | --- |
| `-Copy` | Copy instead of symlinking. |
| `-Autostart` | Add GlazeWM to this user's startup folder so it runs at login. |
| `-ConfigPath <path>` | Install a specific file instead of the auto-detected one. |
| `-NoBackup` | Don't back up the config that's already installed. |
| `-NoReload` | Don't reload a running GlazeWM afterwards. |

Any config already at the target path is backed up next to it as
`config.yaml.<timestamp>.bak` before being replaced.

## Changing the config

Edit `config.yaml` here, then press `alt+shift+r` to reload — no reinstall
needed if it's symlinked. Commit and push, then `git pull` on the other PCs.

If a change only makes sense on one machine, it belongs in `machines/` rather
than in the shared config.

## Keybindings

`alt` is the modifier throughout. Direction keys are vim-style `hjkl`, and the
arrow keys work everywhere `hjkl` do.

### Focus and movement

| Keys | Action |
| --- | --- |
| `alt` + `h` `j` `k` `l` | Focus the window left / down / up / right |
| `alt` + `shift` + `h` `j` `k` `l` | Move the focused window in that direction |
| `alt` + `1`–`9` | Focus workspace 1–9 |
| `alt` + `shift` + `1`–`9` | Send the focused window to that workspace and follow it |
| `alt` + `a` / `s` | Focus the previous / next active workspace |
| `alt` + `d` | Focus the last workspace you were on |
| `alt` + `shift` + `a` `s` `d` `f` | Move the current workspace to the monitor left / down / up / right |

### Window state

| Keys | Action |
| --- | --- |
| `alt` + `v` | Flip tiling direction (where the next window is inserted) |
| `alt` + `space` | Cycle focus: tiling → floating → fullscreen |
| `alt` + `shift` + `space` | Toggle floating (centered) |
| `alt` + `t` | Toggle tiling |
| `alt` + `f` | Toggle fullscreen |
| `alt` + `m` | Minimize |
| `alt` + `shift` + `q` | Close the window |

### Resizing

| Keys | Action |
| --- | --- |
| `alt` + `u` / `p` | Shrink / grow width by 2% |
| `alt` + `i` / `o` | Shrink / grow height by 2% |
| `alt` + `r` | Resize mode — then `hjkl` or arrows to resize, `escape` or `enter` to exit |

### Launchers

| Keys | Action |
| --- | --- |
| `alt` + `enter` | Terminal (`cmd`) |

`cmd` rather than `wt` so the binding works on machines without Windows
Terminal. `config.yaml` has the `wt` and Git Bash alternatives commented next
to it.

### Window manager

| Keys | Action |
| --- | --- |
| `alt` + `shift` + `r` | Reload the config |
| `alt` + `shift` + `p` | Pause GlazeWM and all its keybindings (useful inside RDP or a VM) |
| `alt` + `shift` + `w` | Redraw all windows |
| `alt` + `shift` + `e` | Exit GlazeWM |

## Notes on what's set

- **Zebar** (the status bar) is launched at startup and killed on shutdown, and
  `gaps.outer_gap.top` is 40px to leave room for it. On a PC without Zebar the
  startup command fails harmlessly, but that 40px strip is then just dead
  space — fork the config for that machine, or install Zebar there too.
- **Gaps** are 4px between windows and 4px at the screen edges, apart from the
  40px top.
- **Borders** are drawn on every window: `#8dbcff` when focused, `#a1a1a1`
  otherwise. Windows 11 only — the API doesn't exist on Windows 10.
- **Taskbar** shows windows from every workspace, not just the visible ones
  (`show_all_in_taskbar: true`).
- **Workspaces** 1–9 exist on every machine and aren't pinned to monitors, which
  is what lets one file work everywhere.
- **Window rules** ignore things that shouldn't be tiled: Zebar, Snipping Tool
  and its clipping overlay, browser picture-in-picture, PowerToys overlays,
  Lively, and the Office helper windows.

Commented-out starting points in `config.yaml` — floating Task Manager, pinning
an app to a workspace, `single_window_outer_gap`, and upstream's newer
PowerToys Command Palette rule — are there to uncomment if you want them.

To find the process name, class, or title to write a new window rule with,
focus the window and run:

```powershell
glazewm query windows
```
