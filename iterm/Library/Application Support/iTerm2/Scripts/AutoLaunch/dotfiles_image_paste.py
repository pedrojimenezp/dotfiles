#!/usr/bin/env python3
"""iTerm2 script function dotfiles_image_paste(): paste, or upload a clipboard image over SSH.

When the session's foreground job is ssh and the clipboard holds only an image, it asks
"Upload image to <host>?". Upload saves the image with pngpaste, copies it over the same
ssh connection settings to /tmp/claude-img/<timestamp>.png on that host (files there older
than a day are deleted), and types the remote path into the session. Cancel does nothing.
In every other case it runs iTerm's own Edit > Paste.

Bind a key to it with the "Invoke Script Function" action: dotfiles_image_paste()
"""

import asyncio
import ctypes
import datetime
import os
import shlex
import shutil
import subprocess
import tempfile

REMOTE_DIR = "/tmp/claude-img"  # upload folder on the server
UPLOAD_TIMEOUT = 60             # seconds before an upload is abandoned

# ssh options without a value, and options that take one (OpenSSH `man ssh`).
SSH_FLAGS = set("46AaCfGgKkMNnqsTtVvXxYy")
SSH_VALUE_OPTIONS = set("BbcDEeFIiJLlmOoPpQRSWw")
# Options that mean no interactive shell: never upload through these.
SSH_NON_INTERACTIVE = set("fGNOQsVW")
# Options that choose the host, user, port, keys and config: reused for the upload.
SSH_KEEP_FLAGS = set("46Cq")
SSH_KEEP_VALUE_OPTIONS = set("BbcFIiJlmoPpS")

# Placed before the session's own options: for -o settings, ssh uses the first value it gets.
UPLOAD_SSH_OPTIONS = [
    "-T",                                   # no terminal
    "-o", "BatchMode=yes",                  # never ask for a password or a host key
    "-o", "ConnectTimeout=10",              # fail fast on a dead host
    "-o", "RequestTTY=no",
    "-o", "RemoteCommand=none",             # a RemoteCommand in ~/.ssh/config would clash with ours
    "-o", "ClearAllForwardings=yes",        # no port forwards that could clash with the open session
    "-o", "ForwardAgent=no",
    "-o", "ForwardX11=no",
    "-o", "PermitLocalCommand=no",
    "-o", "ControlMaster=no",               # reuse an open master connection, never become one
    "-o", "LogLevel=ERROR",                 # no banners in the error text
]

TEXT_TYPES = {"«class utf8»", "«class ut16»", "string", "Unicode text", "«class furl»"}
IMAGE_TYPES = {"«class PNGf»", "TIFF picture", "JPEG picture", "GIF picture", "«class jp2 »", "«class heic»"}


def _parse_ssh_options(args, i, keep):
    """Reads ssh options from args[i:], appending the reusable ones to keep.

    Returns the index of the first non-option argument, or None for an unknown or
    non-interactive option. A "--" ends the options and is skipped.
    """
    while i < len(args):
        arg = args[i]
        if arg == "--":
            return i + 1
        if not arg.startswith("-") or arg == "-":
            return i
        j = 1
        while j < len(arg):
            opt = arg[j]
            if opt in SSH_NON_INTERACTIVE:
                return None
            if opt in SSH_VALUE_OPTIONS:
                value = arg[j + 1:]
                if not value:                       # value is the next argument
                    i += 1
                    if i >= len(args):
                        return None
                    value = args[i]
                if opt in SSH_KEEP_VALUE_OPTIONS:
                    keep += ["-" + opt, value]
                break
            if opt not in SSH_FLAGS:
                return None
            if opt in SSH_KEEP_FLAGS:
                keep.append("-" + opt)
            j += 1
        i += 1
    return i


def parse_ssh_argv(argv):
    """Splits an interactive ssh command line into (connection options, destination).

    The remote command after the destination is dropped. Options after the destination
    are read too, as ssh does. Returns None when argv is not an interactive ssh login
    (no destination, -N, -W, -O, ...).
    """
    if not argv or os.path.basename(argv[0]) != "ssh":
        return None
    args, keep = argv[1:], []
    i = _parse_ssh_options(args, 0, keep)
    if i is None or i >= len(args):
        return None
    dest = args[i]
    if i + 1 < len(args) and args[i - 1] != "--" and args[i + 1].startswith("-"):
        if _parse_ssh_options(args, i + 1, keep) is None:
            return None
    return keep, dest


def remote_image_path(now):
    """Returns the upload path for a datetime, e.g. /tmp/claude-img/20261031-142501-123.png."""
    return f"{REMOTE_DIR}/{now:%Y%m%d-%H%M%S}-{now.microsecond // 1000:03d}.png"


def upload_command(ssh_path, options, dest, remote_path):
    """Returns the argv that reads a PNG on stdin and writes it to remote_path on dest.

    The remote side creates REMOTE_DIR (mode 700) and deletes files there older than a day.
    """
    folder = shlex.quote(REMOTE_DIR)
    script = (f"mkdir -p -m 700 {folder} && find {folder} -type f -mtime +0 -delete; "
              f"cat > {shlex.quote(remote_path)}")
    return [ssh_path, *UPLOAD_SSH_OPTIONS, *options, "--", dest, "sh -c " + shlex.quote(script)]


def clipboard_types(info):
    """Returns the type names in the output of AppleScript `clipboard info`."""
    parts = [p.strip() for p in info.strip().split(", ")]
    return set(parts[0::2]) if len(parts) > 1 else set()


def clipboard_is_image_only(info):
    """True when `clipboard info` lists an image type and no text or file type."""
    types = clipboard_types(info)
    return bool(types & IMAGE_TYPES) and not types & TEXT_TYPES


def process_argv(pid):
    """Returns (executable path, argv) of a process, exact even when arguments hold spaces.

    Reads sysctl KERN_PROCARGS2 (macOS). Returns None if the process is gone or not ours.
    """
    libc = ctypes.CDLL(None, use_errno=True)
    argmax = ctypes.c_int(0)
    size = ctypes.c_size_t(ctypes.sizeof(argmax))
    mib = (ctypes.c_int * 2)(1, 8)                        # CTL_KERN, KERN_ARGMAX
    if libc.sysctl(mib, 2, ctypes.byref(argmax), ctypes.byref(size), None, 0) != 0:
        return None
    buf = ctypes.create_string_buffer(argmax.value)
    size = ctypes.c_size_t(argmax.value)
    mib = (ctypes.c_int * 3)(1, 49, pid)                  # CTL_KERN, KERN_PROCARGS2, pid
    if libc.sysctl(mib, 3, buf, ctypes.byref(size), None, 0) != 0:
        return None
    return parse_procargs2(buf.raw[:size.value])


def parse_procargs2(data):
    """Parses a KERN_PROCARGS2 buffer: argc, executable path, padding, then argv."""
    if len(data) < 4:
        return None
    argc = int.from_bytes(data[:4], "little")
    exe, _, rest = data[4:].partition(b"\0")
    argv = rest.lstrip(b"\0").split(b"\0")[:argc]
    if len(argv) < argc:
        return None
    return exe.decode(errors="replace"), [a.decode(errors="replace") for a in argv]


def find_tool(name):
    """Finds a command on PATH or in the Homebrew folders (iTerm scripts get a short PATH)."""
    path = os.pathsep.join([os.environ.get("PATH", ""), "/opt/homebrew/bin", "/usr/local/bin"])
    return shutil.which(name, path=path)


async def run(argv, stdin=None, timeout=UPLOAD_TIMEOUT):
    """Runs argv and returns (exit code, stdout, stderr) as text; exit code 124 on timeout."""
    proc = await asyncio.create_subprocess_exec(
        *argv, stdin=stdin if stdin is not None else subprocess.DEVNULL,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    try:
        out, err = await asyncio.wait_for(proc.communicate(), timeout)
    except asyncio.TimeoutError:
        proc.kill()
        await proc.wait()
        return 124, "", f"timed out after {timeout} seconds"
    return proc.returncode, out.decode(errors="replace"), err.decode(errors="replace")


async def ssh_target(session):
    """Returns (ssh path, options, destination) for the session's foreground ssh, or None."""
    if await session.async_get_variable("jobName") != "ssh":
        return None
    pid = await session.async_get_variable("jobPid")
    found = process_argv(int(pid)) if pid else None
    if not found:
        return None
    exe, argv = found
    parsed = parse_ssh_argv(argv)
    if not parsed:
        return None
    ssh_path = exe if os.path.isabs(exe) else (find_tool("ssh") or "/usr/bin/ssh")
    return ssh_path, parsed[0], parsed[1]


async def describe_host(ssh_path, options, dest):
    """Returns "user@hostname:port" as ssh resolves it from ~/.ssh/config, or dest."""
    code, out, _ = await run([ssh_path, "-G", *options, "--", dest], timeout=5)
    if code != 0:
        return dest
    conf = dict(line.split(" ", 1) for line in out.splitlines() if " " in line)
    host = f"{conf.get('user', '?')}@{conf.get('hostname', dest)}"
    return host if conf.get("port", "22") == "22" else f"{host}:{conf['port']}"


async def main(connection):
    import iterm2

    app = await iterm2.async_get_app(connection)
    tasks = set()  # keeps running handlers referenced until they finish

    async def paste():
        await iterm2.MainMenu.async_select_menu_item(
            connection, iterm2.MainMenu.Edit.PASTE.value.identifier)

    async def alert(title, text, window_id, buttons=()):
        box = iterm2.Alert(title, text, window_id)
        for button in buttons:
            box.add_button(button)
        return await box.async_run(connection)

    async def upload(session, window_id, target):
        ssh_path, options, dest = target
        pngpaste = find_tool("pngpaste")
        if not pngpaste:
            await alert("pngpaste not found", "Install it with: brew install pngpaste", window_id)
            return
        host = await describe_host(ssh_path, options, dest)
        choice = await alert(f"Upload image to {dest}?",
                             f"Copies the clipboard image to {REMOTE_DIR} on {host} and types its path.",
                             window_id, ["Upload", "Cancel"])
        if choice != 1000:                                  # 1000 = first button
            return
        with tempfile.TemporaryDirectory() as tmp:
            local = os.path.join(tmp, "clipboard.png")
            code, _, err = await run([pngpaste, local], timeout=10)
            if code != 0:
                await alert("Could not read the clipboard image", err.strip(), window_id)
                return
            remote = remote_image_path(datetime.datetime.now())
            with open(local, "rb") as image:
                code, _, err = await run(upload_command(ssh_path, options, dest, remote), stdin=image)
        if code != 0:
            await alert(f"Upload to {dest} failed", err.strip()[-800:] or f"ssh exit code {code}", window_id)
            return
        await session.async_send_text(remote, suppress_broadcast=True)

    async def handle(session_id):
        session = app.get_session_by_id(session_id)
        if session is None:
            return
        window, _ = app.get_window_and_tab_for_session(session)
        window_id = window.window_id if window else None
        target = await ssh_target(session)
        if target:
            code, info, _ = await run(["/usr/bin/osascript", "-e", "clipboard info"], timeout=5)
            if code == 0 and clipboard_is_image_only(info):
                await upload(session, window_id, target)
                return
        await paste()

    async def guarded(session_id):
        try:
            await handle(session_id)
        except Exception as error:  # an error must never leave Cmd+V dead: fall back to Paste
            print(f"dotfiles_image_paste: {error!r}")
            await paste()

    @iterm2.RPC
    async def dotfiles_image_paste(session_id=iterm2.Reference("id")):
        # Return at once so iTerm's RPC timeout never cuts the dialog or the upload short.
        task = asyncio.create_task(guarded(session_id))
        tasks.add(task)
        task.add_done_callback(tasks.discard)

    await dotfiles_image_paste.async_register(connection)


if __name__ == "__main__":
    import iterm2
    iterm2.run_forever(main)
