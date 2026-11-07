# Terminals: Ghostty and iTerm

A terminal app is the window you type commands in. This repo configures two: Ghostty and iTerm2. Both use the same font and colors (from [theme.md](theme.md)).

You'll use this page to choose a terminal, change its settings, and fix font or key problems.

- [Which terminal should I use?](#which-terminal-should-i-use)
- [Requirements](#requirements)
- [Ghostty](#ghostty)
- [iTerm2 (macOS only)](#iterm2-macos-only)
- [Paste an image to a server (any terminal)](#paste-an-image-to-a-server-any-terminal)
- [Paste an image to a server (iTerm2 only)](#paste-an-image-to-a-server-iterm2-only)
- [How it works](#how-it-works)

## Which terminal should I use?

**macOS:** Ghostty or iTerm2. Both are supported and look the same. Ghostty is the simpler choice: one text config file. iTerm2 has a graphical settings window, but this repo manages its profile for you.

**Linux:** Ghostty. iTerm2 is macOS only.

If you have neither, install one and run `./install.sh` again: it links the config of the terminal it finds.

| Package | File | Platform |
| --- | --- | --- |
| `ghostty` | `~/.config/ghostty/config` | macOS and Linux. Linked only if Ghostty is installed. |
| `iterm` | `~/.config/iterm/dotfiles-profile.plist` (template) and the AutoLaunch script `dotfiles_image_paste.py` | **macOS only** |
| `skhd` | `~/.config/skhd/skhdrc` (the `Ctrl+Cmd+V` image-paste key) | **macOS only** |

## Requirements

The **Monaspice Nerd Font**. A [Nerd Font](glossary.md#nerd-font) is a font patched with extra icons. Without it, `eza`, starship and nvim show empty boxes instead of icons. The font is [Monaspace](https://monaspace.githubnext.com) (GitHub Next) with Nerd Fonts' icons added.

The terminal uses **Neon** for code and **Radon** (handwriting style) for italics.

**macOS:** the Brewfile cask `font-monaspice-nerd-font` installs it.

**Linux desktop:** `install.sh` downloads it into `~/.local/share/fonts` and runs `fc-cache`. It skips this on a headless server, because your local terminal draws the font.

Check it worked: open a new terminal tab and run `ls`. Folder and file icons should appear, not boxes.

## Ghostty

Docs: <https://ghostty.org/docs/config>. Handy commands: `ghostty +show-config`, `ghostty +list-fonts`, `ghostty +list-themes`, `ghostty +list-keybinds`. On macOS the `ghostty` command lives inside the app bundle; `.zshrc` adds it to `PATH`.

### What the config sets

| Setting | Value | Meaning |
| --- | --- | --- |
| `font-family` / `font-family-italic` | MonaspiceNe / MonaspiceRn Nerd Font | Code font and italic font |
| `font-size` | 14 | Points |
| `config-file` | `?theme.conf` | Includes the generated theme file (`?` = no error if missing). See [theme.md](theme.md). |
| `background-opacity` | 1 | Fully opaque |
| `window-padding-x` / `y` | 8 / 6 | Pixels around the text |
| `cursor-style` | block | Block cursor |
| `mouse-hide-while-typing` | true | Hide the pointer while you type |
| `copy-on-select` | clipboard | Selecting text copies it to the system clipboard |
| `confirm-close-surface` | false | No question when closing a finished shell |
| `macos-option-as-alt` | true | **macOS only.** `Option` works as `Alt` (`Alt+j` and `Alt+k` in nvim, tmux Alt keys). |
| `macos-titlebar-style` | tabs | **macOS only.** Native tabs in the title bar |
| `shell-integration` | zsh | Force zsh integration |
| `shell-integration-features` | cursor, sudo, title, ssh-terminfo, ssh-env | See [How it works](#how-it-works) |

### Keybinds in the config

| Keys | What it does |
| --- | --- |
| `Cmd+D` | Split right (macOS) |
| `Cmd+Shift+D` | Split down (macOS) |
| `Cmd+Shift+Enter` | Zoom the current split (macOS) |
| `Cmd+Shift+R` | Reload the config (macOS) |
| `Cmd+K` | Clear the tmux pane in a shell (in vim/nvim it never changes text; in normal mode it can move to the right split): sends `Ctrl+Space`, then `Ctrl+L` (macOS) |
| `Ctrl+Shift+K` | Same as `Cmd+K` (Linux, which has no Cmd key) |

On Linux, the four `cmd+` binds do nothing useful: use Ghostty's Linux defaults instead (see `ghostty +list-keybinds --default`). `Cmd+K` works with tmux's `prefix Ctrl+L` (which ignores panes running vim or nvim); without tmux, `Ctrl+L` in zsh clears the screen and the scrollback ([zsh.md](zsh.md)).

Default Ghostty keys used in these docs (not in the config): macOS `Cmd+T` new tab, `Cmd+1`...`9` go to tab, `Cmd+Shift+,` reload config. Linux `Ctrl+Shift+T` new tab, `Alt+1`...`9` or `Ctrl+PageUp/PageDown` switch tab.

### Change something

Edit `ghostty/.config/ghostty/config` in the repo, then reload with `Cmd+Shift+R` (macOS). Do not edit `theme.conf`: `theme sync` generates it. Settings only for one machine: add a second include line `config-file = ?local.conf` to the config and keep `~/.config/ghostty/local.conf` untracked (the tracked config has no such line).

## iTerm2 (macOS only)

The `iterm` package installs a **template**: font, Option keys, terminal type, scrollback and the `Cmd+K` mapping, with no colors. `theme sync` adds the colors of the light/dark pair and writes the real Dynamic Profile `~/Library/Application Support/iTerm2/DynamicProfiles/dotfiles.plist`, named **Dotfiles**. `theme sync` runs from `install.sh`, `theme set` and `theme pick`.

Profile settings from the template:

| Setting | Value |
| --- | --- |
| Font | `MonaspiceNeNF 14` |
| Ligatures | on (needed for Monaspace texture healing) |
| Left Option | Esc+ (works as Alt) |
| Right Option | normal, to type accents (Spanish) |
| Terminal type | `xterm-256color` |
| Scrollback | unlimited |
| New session folder | home |
| `Cmd+K` | sends `Ctrl+Space` + `Ctrl+L` (clear the tmux pane; never edits text in vim/nvim) |
| `Ctrl+Opt+Cmd+V` | runs the script function `dotfiles_image_paste()`: normal Paste, or an image upload in an SSH tab ([below](#paste-an-image-to-a-server-iterm2-only)). `Cmd+V` stays iTerm's normal Paste |

One manual step per machine: iTerm Settings > Profiles > select **Dotfiles** > Other Actions > Set as Default. The profile keeps the same Guid, so this survives every sync.

Dynamic Profiles are **read-only** in the iTerm UI. To change something, edit the template in the repo, then run `theme sync`. iTerm reloads the profile by itself. If it misses a change, quit with `Cmd+Q` and open it again.

## Paste an image to a server (any terminal)

Claude Code on a server cannot read your Mac's clipboard. `img-to-server` fixes that in any terminal (Ghostty, iTerm2, anything): copy an image, switch to a tab that runs `ssh`, press `Ctrl+Cmd+V`. The image is copied with `scp` to `/tmp/claude-img/<date>-<time>.png` (or the file's own extension) on that server and the path is pasted at the prompt, with no `Enter`. Claude Code reads the file at that path when you send the prompt.

macOS only. It needs `pngpaste` (the Brewfile installs it; or run `brew install pngpaste`). Files in that folder older than one day are deleted on each upload.

### One-time setup

The key comes from [skhd.zig](https://github.com/jackielii/skhd.zig), a small hotkey daemon. It runs in the background and needs only the **Accessibility** permission. The script sends `Cmd+V` with that same permission.

1. Run `./install.sh`. It installs `skhd-zig` and `pngpaste` with Homebrew and links `~/.config/skhd/skhdrc` (the key binding) and `~/.local/bin/img-to-server`.
2. Start the service. In a terminal:

   ```sh
   skhd --install-service
   skhd --start-service
   ```

3. Turn on Accessibility: System Settings > Privacy & Security > **Accessibility** > switch **skhd** on. macOS usually opens that pane for you on the first start. If **skhd** is not in the list, click **+** and pick `~/Applications/skhd.app` (where the Brewfile's Homebrew cask puts it; `/Applications/skhd.app` if you installed it by hand). skhd notices the switch within a second; if not, run `skhd --restart-service`.
4. If you once made an **Image to server** shortcut in the Shortcuts app, delete it. It would compete for the same key.

Check it worked: the path `/tmp/claude-img/...png` appears at the prompt of your ssh tab.

### Use it

1. Put an image on the clipboard: a screenshot (`Cmd+Ctrl+Shift+4`, then drag over the area), **Copy Image** in a browser, `Cmd+C` in an image app, or `Cmd+C` on one image file in Finder.
2. Click the terminal tab that runs `ssh` (or `tssh`) to your server, with Claude Code open there.
3. Press `Ctrl+Cmd+V`. The path appears at the prompt.
4. Write the rest of your prompt and send it.

What the key does with the clipboard:

| Clipboard | What happens |
| --- | --- |
| One image file copied in Finder (png, jpg, jpeg, gif, webp, heic, tiff, bmp) | Uploads that file as is, keeping its extension |
| Image data (screenshot, Copy Image), even with text or HTML beside it | Uploads it as a PNG |
| Text only, several files, or a file that is not an image | Normal `Cmd+V` |

So the key is safe to press anywhere. An upload replaces the clipboard with the remote path.

### How it picks the server

1. If the front app is iTerm2, it takes the `ssh` running in the current tab (the foreground job on that tab's terminal). The first time, macOS asks whether skhd may control iTerm2: click **Allow**. If you refuse, it silently uses step 2.
2. Otherwise, or when the iTerm2 tab runs no `ssh` (for example `ssh` inside a local tmux), it looks at every interactive `ssh` on the Mac and groups them by the host `ssh -G` resolves (user, hostname, port).
   - One host: it uses it.
   - Several hosts: a list asks **Upload image to which server?**. Cancel does nothing.
   - None: a notification says **No ssh session found**.

`ssh -N`, `-W`, `-O`, `-f`, `ssh host <command>` without `-t`, `scp`, `sftp`, `git` and `mosh` do not count. The upload reuses the session's user, port, `-i` key, `-J` jump host and `-F` config file, with `BatchMode=yes` (never asks for a password) and a 60-second limit. It reuses an open `ControlMaster` connection. The host must already be in `~/.ssh/known_hosts`: connect once by hand first.

Ghostty cannot say which tab is in front, so with several `ssh` sessions open to different servers you get the list. Close the ones you do not need to skip it.

To see what it would do without uploading: `img-to-server --dry-run` prints the target and the commands and pastes nothing.

### Troubleshooting

- **The key does nothing.** Run `skhd --status` and read `~/Library/Logs/skhd.log`. The usual causes: the service is not running (`skhd --start-service`), **skhd** is off under Accessibility (setup step 3), or another app already uses `Ctrl+Cmd+V`. Run `img-to-server --dry-run` in a terminal to see what the script finds. After editing `~/.config/skhd/skhdrc`, skhd reloads it by itself.
- **The image uploads but nothing is pasted.** The path is already on the clipboard: press `Cmd+V`. Check that skhd has Accessibility (setup step 3), then `skhd --restart-service`.
- **Anything else with the upload.** Each run adds a block to `~/Library/Logs/img-to-server.log`: front app, clipboard kind, the target or why there is none, every command with its exit code and error text, how it pasted. It never holds the clipboard contents, and it is cut to its last 200 KB when it passes 1 MB.
- **A notification says "No ssh session found".** No interactive `ssh` is running on this Mac. Check with `ps -axo tty,args | grep ssh`. `mosh` and `ssh -N` are not supported.
- **The list appears when you expected none.** More than one server is connected (Ghostty case above). Pick one, or close the other sessions.
- **"Upload to ... failed" with `Permission denied (publickey)` or `Host key verification failed`.** Set up key login, or connect once by hand with `ssh my-server` to save the host key.
- **"pngpaste not found".** Run `brew install pngpaste`.
- **On a server with several users**, `/tmp/claude-img` belongs to the first user who uploads. Others get "Permission denied" (see [server.md](server.md#7-several-users)).

## Paste an image to a server (iTerm2 only)

This is the older iTerm2-only way. It is kept for comparison with [`img-to-server`](#paste-an-image-to-a-server-any-terminal), which now owns `Ctrl+Cmd+V`. The iTerm2 version is on **`Ctrl+Opt+Cmd+V`**. With an image on the clipboard, in a tab that runs `ssh` or `tssh`, it copies the image to that server and types its path.

**This works only in iTerm2 on macOS**, with the Python API script below. `Cmd+V` is always the normal paste, text or image, and never depends on the script. The upload has its own key because `Cmd+Shift+V` is iTerm's Advanced Paste.

### What Ctrl+Opt+Cmd+V does

| Tab and clipboard | What happens |
| --- | --- |
| Foreground job is `ssh` (also `tssh`), clipboard holds only an image | Asks **Upload image to `<host>`?** `Enter` = Upload, `Esc` = Cancel |
| Upload | Copies the image to `/tmp/claude-img/<date>-<time>.png` on that host and types the path, with no `Enter`, so you can keep writing |
| Cancel | Nothing. A terminal cannot paste an image anyway. |
| Text on the clipboard (also text plus an image, or a file copied in Finder) | Normal Paste |
| Image in a local tab (no `ssh`) | Normal Paste |

The upload goes only to the host of the `ssh` running in that tab. It reuses that command's host, user, port, `-i` key, `-J` jump host and `~/.ssh/config` entry, with `BatchMode=yes`: it never asks for a password. It reuses an open `ControlMaster` connection if there is one.

The path is typed, not pasted, so Claude Code shows it as text, not as `[Image #1]`. That is enough: Claude reads the file at that path.

### One-time setup

1. Run `./install.sh`. It installs `pngpaste` (Brewfile) and links the script into `~/Library/Application Support/iTerm2/Scripts/AutoLaunch/`.
2. Run `theme sync` (install.sh does it). The **Dotfiles** profile now maps `Ctrl+Opt+Cmd+V` to the script. If the old key still shows in Settings > Profiles > Keys, quit iTerm with `Cmd+Q` and open it again.
3. In iTerm: Settings > General > Magic > turn on **Enable Python API**.
4. Scripts > Manage > **Check for Updated Runtime**. Accept the download.
5. Quit iTerm with `Cmd+Q` and open it again.
6. Start the script once: Scripts > AutoLaunch > `dotfiles_image_paste.py`. If iTerm asks whether the script may use the API, allow it.
7. Check it runs: Scripts > Manage > Console (`⌥⌘J`) shows `dotfiles_image_paste.py` running.

If the script is not running, `Ctrl+Opt+Cmd+V` does nothing (harmless) and `Cmd+V` still pastes. Fix the setup when you want the upload (see [Troubleshooting](#troubleshooting)).

### Use it

1. Take a screenshot to the clipboard: `Cmd+Ctrl+Shift+4`, then drag over the area. Or copy an image in any app.
2. Click the iTerm tab that runs `tssh my-server` (Claude Code open on the server).
3. Press `Ctrl+Opt+Cmd+V`.
4. Press `Enter` to upload. The path appears at the prompt.
5. Write the rest of your prompt and send it.

### Files on the server

- Folder: `/tmp/claude-img`, created with mode 700 (only you can read it).
- Name: the date and time, for example `/tmp/claude-img/20261031-142501-123.png`.
- Cleanup: each upload first deletes files in that folder older than one day. `/tmp` is also emptied when the server reboots.

### Limits

- iTerm2 on macOS only, and only in the **Dotfiles** profile (it holds the `Ctrl+Opt+Cmd+V` mapping).
- SSH must log in with a key (agent or `-i`), no password. The host must already be in `~/.ssh/known_hosts`: connect once by hand first.
- Only for an `ssh` that iTerm sees as the tab's job. `mosh`, `ssh` inside a local tmux, and `ssh -N` or `-W` get the normal Paste.
- On a server with several users, `/tmp/claude-img` belongs to the first user who uploads. Other users get "Permission denied" (see [server.md](server.md#7-several-users)).

### Troubleshooting

- **After pulling an update, the key does not change.** Run `theme sync` so the profile picks it up.
- **`Ctrl+Opt+Cmd+V` does nothing, or iTerm reports a script function error.** The script is not running. Check Scripts > Manage > Console. If it is missing, check **Enable Python API** is on, then run it once from Scripts > AutoLaunch > `dotfiles_image_paste.py`.
- **The Console shows Python errors on start, or the runtime is missing.** Scripts > Manage > Check for Updated Runtime (accept the download), then restart iTerm.
- **Image in an `ssh` tab, but no question, only the normal Paste.** The tab does not use the **Dotfiles** profile, `theme sync` has not run since the update, or iTerm does not see `ssh` as the job (for example `ssh` inside a local tmux). The Console prints errors as `dotfiles_image_paste: ...`.
- **"Upload to ... failed" with `Permission denied (publickey)` or `Host key verification failed`.** Set up key login, or connect once by hand with `ssh my-server` to save the host key.
- **"pngpaste not found".** Run `brew install pngpaste` (or `./install.sh` again).

## How it works

**Switch fonts.** Change these together: `NERD_FONT` and `NERD_FONT_FAMILY` in `install.sh`, the cask in the `Brewfile`, `font-family` and `font-family-italic` in the Ghostty config, and `Normal Font` in the iTerm template.

**iTerm font name.** iTerm wants the PostScript name of the font (`MonaspiceNeNF`), not the family name. Find it with:

```sh
mdls -name com_apple_ats_name_postscript <font file>
```

**Ghostty shell integration.**

- `cursor` sets the cursor shape at the prompt. `title` updates the window title. `sudo` keeps the terminfo under `sudo`.
- `ssh-terminfo`: when you `ssh` to a server, Ghostty installs its terminfo there (`xterm-ghostty`). If that fails, `ssh-env` falls back to `TERM=xterm-256color`. So you need no `SetEnv TERM` in `~/.ssh/config`.

**Generated files.** `theme sync` writes `~/.config/ghostty/theme.conf` and the iTerm profile `~/Library/Application Support/iTerm2/DynamicProfiles/dotfiles.plist`. Never edit them.

## Related pages

- [theme.md](theme.md): colors for both terminals
- [server.md](server.md#5-daily-use): Claude Code on the server, `tssh`
- [tmux.md](tmux.md): `Cmd+K` and `prefix Ctrl+l`
- [server.md](server.md#2-on-your-laptop-once): SSH settings on your laptop (`~/.ssh/config`, connection reuse, `mosh`)
- [glossary.md](glossary.md#nerd-font)
