"""Tests for img-to-server with every system command stubbed.

Run: python3 -I tests/img_to_server_test.py
"""

import contextlib
import datetime
import importlib.machinery
import importlib.util
import io
import os
import shutil
import stat
import subprocess
import sys
import tempfile
import unittest

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCRIPT = os.path.join(ROOT, "bin", ".local", "bin", "img-to-server")
sys.dont_write_bytecode = True
loader = importlib.machinery.SourceFileLoader("img_to_server", SCRIPT)
spec = importlib.util.spec_from_loader("img_to_server", loader)
mod = importlib.util.module_from_spec(spec)
loader.exec_module(mod)

IMAGE_INFO = "«class PNGf», 1234, TIFF picture, 5678"
TEXT_INFO = "«class utf8», 12, string, 12"
TSSH_COMMAND = 'exec $SHELL -lic "tmux new-session -A -s main"'


class ParseSshArgv(unittest.TestCase):
    def check(self, argv, expected):
        self.assertEqual(mod.parse_ssh_argv(argv), expected)

    def test_plain_host(self):
        self.check(["ssh", "dev"], ([], "dev"))

    def test_full_path_and_user(self):
        self.check(["/usr/bin/ssh", "me@dev.example.com"], ([], "me@dev.example.com"))

    def test_other_programs_are_not_ssh(self):
        for argv in (["scp", "f", "dev:/x"], ["sftp", "dev"], ["mosh", "dev"], ["git", "ssh"],
                     ["ssh: /tmp/ctl [mux]"], []):
            self.check(argv, None)

    def test_flags_and_value_options(self):
        self.check(["ssh", "-tt", "-4Cp2222", "-oUser=me", "-A", "-L", "8080:localhost:80", "dev"],
                   (["-4", "-C", "-p", "2222", "-o", "User=me"], "dev"))

    def test_port_identity_jump_config(self):
        self.check(["ssh", "-p", "2200", "-i", "/k/my key", "-J", "bastion", "-F", "/c", "dev"],
                   (["-p", "2200", "-i", "/k/my key", "-J", "bastion", "-F", "/c"], "dev"))

    def test_options_after_destination(self):
        self.check(["ssh", "dev", "-p", "2222"], (["-p", "2222"], "dev"))

    def test_remote_command_is_not_interactive(self):
        self.check(["ssh", "dev", "uptime"], None)
        self.check(["ssh", "-p", "22", "dev", "ls", "-l"], None)

    def test_remote_command_with_tty_is_interactive(self):
        self.check(["ssh", "-t", "dev", TSSH_COMMAND], ([], "dev"))
        self.check(["ssh", "-t", "dev", "-p", "2222", TSSH_COMMAND], (["-p", "2222"], "dev"))

    def test_skipped_options(self):
        for argv in (["ssh", "-N", "dev"], ["ssh", "-W", "h:22", "jump"], ["ssh", "-O", "check", "dev"],
                     ["ssh", "-f", "dev"], ["ssh", "-G", "dev"], ["ssh", "-p"], ["ssh", "-Z", "dev"],
                     ["ssh"], ["ssh", "-p", "22"]):
            self.check(argv, None)

    def test_double_dash(self):
        self.check(["ssh", "-p", "22", "--", "dev"], (["-p", "22"], "dev"))


class ScpOptions(unittest.TestCase):
    def test_same_and_translated(self):
        opts = ["-4", "-C", "-p", "2222", "-i", "/k", "-J", "b", "-F", "/c", "-l", "me",
                "-S", "/ctl", "-o", "User=x", "-b", "1.2.3.4"]
        self.assertEqual(mod.to_scp_options(opts),
                         ["-4", "-C", "-o", "Port=2222", "-i", "/k", "-J", "b", "-F", "/c",
                          "-o", "User=me", "-o", "ControlPath=/ctl", "-o", "User=x",
                          "-o", "BindAddress=1.2.3.4"])

    def test_commands(self):
        target = mod.Target("/usr/bin/ssh", ["-p", "2222", "-i", "/k"], "me@dev")
        copy = mod.copy_command("scp", target, "/t/a.png", "/tmp/claude-img/x.png")
        self.assertEqual(copy[-3:], ["--", "/t/a.png", "me@dev:/tmp/claude-img/x.png"])
        self.assertIn("BatchMode=yes", copy)
        self.assertIn("Port=2222", copy)
        prep = mod.prepare_command("/usr/bin/ssh", target)
        self.assertEqual(prep[-3:-1], ["--", "me@dev"])
        self.assertIn("mkdir -p -m 700 /tmp/claude-img", prep[-1])
        self.assertIn("-mtime +0 -delete", prep[-1])
        self.assertIn("ConnectTimeout=10", prep)

    def test_remote_path(self):
        now = datetime.datetime(2026, 11, 7, 14, 25, 1, 123456)
        self.assertEqual(mod.remote_image_path(now), "/tmp/claude-img/20261107-142501-123.png")


class Clipboard(unittest.TestCase):
    def test_image_data(self):
        self.assertEqual(mod.clipboard_kind(IMAGE_INFO), "image")

    def test_image_data_with_text_types_is_still_an_image(self):
        self.assertEqual(mod.clipboard_kind(IMAGE_INFO + ", «class HTML», 9, string, 3"), "image")
        self.assertEqual(mod.clipboard_kind("«class PNGf», 1, «class utf8», 3"), "image")

    def test_file_wins_over_its_icon_image(self):
        self.assertEqual(mod.clipboard_kind("«class furl», 40, TIFF picture, 5678"), "file")

    def test_text_or_empty_is_not_an_image(self):
        self.assertIsNone(mod.clipboard_kind(TEXT_INFO))
        self.assertIsNone(mod.clipboard_kind(""))


class FakeSystem:
    """Replaces run() and the lookups; records every command, runs nothing."""

    def __init__(self):
        self.clip = IMAGE_INFO
        self.front = "Ghostty"
        self.iterm_tty = "/dev/ttys003"
        self.iterm_error = "no window"   # stderr when the iTerm2 lookup fails
        self.ps_tty = ""
        self.ps_all = ""
        self.hosts = {}          # dest -> (user, hostname, port)
        self.pick = None         # label chosen in the picker; None = cancel
        self.fail = {}           # program name -> (code, stderr)
        self.argvs = {}          # pid -> argv for process_argv
        self.calls = []
        self.pasted = 0
        self.notes = []
        self.clipboard_text = None
        self.local_files = []
        self.files = []          # paths reported as copied files

    def run(self, argv, timeout=10, data=None):
        self.calls.append(argv)
        name = os.path.basename(argv[0])
        if name in self.fail:
            code, err = self.fail[name]
            return code, "", err
        if name == "osascript":
            return self.osascript(argv[-1], "-l" in argv)
        if name == "ps":
            return 0, (self.ps_tty if argv[1] == "-t" else self.ps_all), ""
        if name == "ssh" and argv[1] == "-G":
            dest = argv[-1]
            if dest not in self.hosts:
                return 255, "", "bad"
            user, host, port = self.hosts[dest]
            return 0, f"user {user}\nhostname {host}\nport {port}\n", ""
        if name == "pngpaste":
            self.local_files.append(argv[1])
            with open(argv[1], "wb") as f:
                f.write(b"png")
            return 0, "", ""
        if name == "pbcopy":
            self.clipboard_text = data.decode()
            return 0, "", ""
        return 0, "", ""

    def osascript(self, script, javascript=False):
        if javascript:
            if "frontmostApplication" in script:
                return 0, self.front + "\n", ""
            return 0, "\n".join(self.files), ""
        if script == "clipboard info":
            return 0, self.clip, ""
        if "tty of current session" in script:
            return (0, self.iterm_tty + "\n", "") if self.iterm_tty else (1, "", self.iterm_error)
        if script.startswith("choose from list"):
            return 0, (self.pick or "false") + "\n", ""
        if "display notification" in script:
            self.notes.append(script)
            return 0, "", ""
        raise AssertionError(script)

    def names(self):
        return [os.path.basename(c[0]) for c in self.calls]


class MainFlow(unittest.TestCase):
    def setUp(self):
        self.sys = FakeSystem()
        self.saved = {n: getattr(mod, n) for n in ("run", "find_tool", "process_argv", "post_cmd_v", "LOG_PATH")}
        mod.run = self.sys.run
        mod.post_cmd_v = self.post_cmd_v      # never posts real key events
        self.log_dir = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, self.log_dir, ignore_errors=True)
        mod.LOG_PATH = os.path.join(self.log_dir, "img-to-server.log")
        self.post_error = None
        mod.find_tool = lambda name: "/stub/" + name
        mod.process_argv = lambda pid: self.sys.argvs.get(pid)
        self.out, self.err = io.StringIO(), io.StringIO()

    def tearDown(self):
        for name, fn in self.saved.items():
            setattr(mod, name, fn)

    def post_cmd_v(self):
        if self.post_error:
            raise OSError(self.post_error)
        self.sys.pasted += 1

    def log_text(self):
        with open(mod.LOG_PATH) as f:
            return f.read()

    def main(self, *args):
        with contextlib.redirect_stdout(self.out), contextlib.redirect_stderr(self.err):
            return mod.main(list(args))

    def one_host(self):
        self.sys.hosts = {"dev": ("me", "dev.example.com", "22")}
        self.sys.ps_all = "101 ttys001 ssh dev\n"

    def make_file(self, name):
        tmp = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, tmp, ignore_errors=True)
        path = os.path.join(tmp, name)
        with open(path, "wb") as f:
            f.write(b"x")
        return path

    def scp_call(self):
        return next(c for c in self.sys.calls if os.path.basename(c[0]) == "scp")

    def test_image_data_with_text_types_uploads(self):
        self.one_host()
        self.sys.clip = IMAGE_INFO + ", «class HTML», 9, «class utf8», 3"
        self.assertEqual(self.main(), 0)
        self.assertIn("pngpaste", self.sys.names())
        self.assertTrue(self.scp_call()[-1].endswith(".png"))
        self.assertEqual(self.sys.pasted, 1)

    def test_one_copied_image_file_uploads_as_is_and_keeps_extension(self):
        self.one_host()
        path = self.make_file("Photo.JPG")
        self.sys.clip = "«class furl», 40, TIFF picture, 5678"
        self.sys.files = [path]
        self.assertEqual(self.main(), 0)
        self.assertNotIn("pngpaste", self.sys.names())
        scp = self.scp_call()
        self.assertIn(path, scp)
        self.assertRegex(scp[-1], r"^dev:/tmp/claude-img/\d{8}-\d{6}-\d{3}\.jpg$")
        self.assertTrue(os.path.exists(path))
        self.assertEqual(self.sys.pasted, 1)

    def test_several_copied_files_paste_normally(self):
        self.one_host()
        self.sys.clip = "«class furl», 40"
        self.sys.files = [self.make_file("a.png"), self.make_file("b.png")]
        self.assertEqual(self.main(), 0)
        self.assertNotIn("scp", self.sys.names())
        self.assertEqual(self.sys.pasted, 1)

    def test_copied_file_that_is_not_an_image_pastes_normally(self):
        self.one_host()
        self.sys.clip = "«class furl», 40"
        self.sys.files = [self.make_file("notes.txt")]
        self.assertEqual(self.main(), 0)
        self.assertNotIn("scp", self.sys.names())
        self.assertEqual(self.sys.pasted, 1)

    def test_copied_image_file_dry_run(self):
        self.one_host()
        path = self.make_file("a.png")
        self.sys.clip = "«class furl», 40"
        self.sys.files = [path]
        self.assertEqual(self.main("--dry-run"), 0)
        self.assertIn(f"clipboard: {path}", self.out.getvalue())
        self.assertNotIn("scp", self.sys.names())
        self.assertEqual(self.sys.pasted, 0)

    def two_hosts(self):
        self.sys.hosts = {"dev": ("me", "dev.example.com", "22"), "prod": ("me", "prod.example.com", "2222")}
        self.sys.ps_all = ("101 ttys001 ssh dev\n102 ttys002 ssh -p 22 prod\n"
                           "103 ?? ssh -N dev\n104 ttys004 scp a b\n")

    def test_no_image_sends_cmd_v_only(self):
        self.sys.clip = TEXT_INFO
        self.assertEqual(self.main(), 0)
        self.assertEqual(self.sys.pasted, 1)
        self.assertEqual(self.sys.names(), ["osascript", "osascript"])   # front app, clipboard info
        self.assertEqual(self.sys.notes, [])

    def test_no_image_dry_run_pastes_nothing(self):
        self.sys.clip = TEXT_INFO
        self.assertEqual(self.main("--dry-run"), 0)
        self.assertEqual(self.sys.pasted, 0)
        self.assertIn("would send Cmd-V", self.out.getvalue())

    def test_one_host_uploads_and_pastes(self):
        self.sys.hosts = {"dev": ("me", "dev.example.com", "22")}
        self.sys.ps_all = "101 ttys001 ssh -p 2200 -i /k dev\n102 ttys002 ssh dev\n"
        self.assertEqual(self.main(), 0)
        names = self.sys.names()
        self.assertEqual(names.count("scp"), 1)
        self.assertEqual(names[-2:], ["scp", "pbcopy"])
        self.assertEqual(self.sys.pasted, 1)
        self.assertRegex(self.sys.clipboard_text, r"^/tmp/claude-img/\d{8}-\d{6}-\d{3}\.png$")
        scp = next(c for c in self.sys.calls if os.path.basename(c[0]) == "scp")
        self.assertEqual(scp[-1], "dev:" + self.sys.clipboard_text)
        self.assertIn("Port=2200", scp)
        self.assertFalse(any(os.path.exists(p) for p in self.sys.local_files))

    def test_several_hosts_use_the_picker(self):
        self.two_hosts()
        self.sys.pick = "prod (me@prod.example.com:2222)"
        self.assertEqual(self.main(), 0)
        scp = next(c for c in self.sys.calls if os.path.basename(c[0]) == "scp")
        self.assertTrue(scp[-1].startswith("prod:/tmp/claude-img/"))
        picker = [c for c in self.sys.calls if "choose from list" in c[-1]]
        self.assertEqual(len(picker), 1)
        self.assertIn("me@dev.example.com", picker[0][-1])
        self.assertIn("prod (me@prod.example.com:2222)", picker[0][-1])

    def test_picker_cancel_does_nothing(self):
        self.two_hosts()
        self.assertEqual(self.main(), 0)
        self.assertNotIn("scp", self.sys.names())
        self.assertEqual(self.sys.pasted, 0)
        self.assertEqual(self.sys.notes, [])

    def test_same_host_under_two_aliases_is_one_group(self):
        self.sys.hosts = {"dev": ("me", "dev.example.com", "22"), "me@dev.example.com": ("me", "dev.example.com", "22")}
        self.sys.ps_all = "101 ttys001 ssh dev\n102 ttys002 ssh me@dev.example.com\n"
        self.assertEqual(self.main(), 0)
        self.assertEqual([c for c in self.sys.calls if "choose from list" in c[-1]], [])
        self.assertEqual(self.sys.names().count("scp"), 1)

    def test_no_session_notifies(self):
        self.sys.ps_all = "101 ?? ssh -N dev\n102 ttys001 ssh dev uptime\n103 ttys002 zsh\n"
        self.assertEqual(self.main(), 0)
        self.assertEqual(len(self.sys.notes), 1)
        self.assertIn("No ssh session found", self.sys.notes[0])
        self.assertNotIn("scp", self.sys.names())
        self.assertEqual(self.sys.pasted, 0)

    def test_iterm_uses_the_tty_of_the_current_session(self):
        self.sys.front = "iTerm2"
        self.sys.hosts = {"dev": ("me", "dev.example.com", "22")}
        self.sys.ps_tty = "201 Ss zsh\n202 S+ ssh dev\n"
        self.sys.ps_all = "301 ttys009 ssh prod\n"          # must be ignored
        self.assertEqual(self.main(), 0)
        ps_calls = [c for c in self.sys.calls if os.path.basename(c[0]) == "ps"]
        self.assertEqual(ps_calls, [["/stub/ps", "-t", "ttys003", "-o", "pid=,stat=,args="]])
        self.assertTrue(next(c for c in self.sys.calls if os.path.basename(c[0]) == "scp")[-1].startswith("dev:"))

    def test_iterm_background_ssh_is_not_the_target(self):
        self.sys.front = "iTerm2"
        self.sys.hosts = {"prod": ("me", "prod.example.com", "22")}
        self.sys.ps_tty = "201 S+ zsh\n202 S ssh dev\n"      # not in the foreground
        self.sys.ps_all = "301 ttys009 ssh prod\n"
        self.assertEqual(self.main(), 0)
        self.assertTrue(next(c for c in self.sys.calls if os.path.basename(c[0]) == "scp")[-1].startswith("prod:"))

    def test_iterm_without_ssh_falls_back_to_process_list(self):
        self.sys.front = "iTerm2"
        self.sys.hosts = {"dev": ("me", "dev.example.com", "22")}
        self.sys.ps_tty = "201 S+ tmux\n"
        self.sys.ps_all = "301 ttys009 ssh dev\n"
        self.assertEqual(self.main(), 0)
        self.assertEqual(self.sys.names().count("scp"), 1)

    def test_exact_argv_from_the_kernel_wins_over_ps_text(self):
        self.sys.hosts = {"dev": ("me", "dev.example.com", "22")}
        self.sys.ps_all = "101 ttys001 ssh -i /k/my key dev\n"
        self.sys.argvs = {101: ("/usr/bin/ssh", ["ssh", "-i", "/k/my key", "dev"])}
        self.assertEqual(self.main(), 0)
        scp = next(c for c in self.sys.calls if os.path.basename(c[0]) == "scp")
        self.assertIn("/k/my key", scp)

    def test_dry_run_uploads_nothing(self):
        self.sys.hosts = {"dev": ("me", "dev.example.com", "22")}
        self.sys.ps_all = "101 ttys001 ssh dev\n"
        self.assertEqual(self.main("--dry-run"), 0)
        self.assertNotIn("scp", self.sys.names())
        self.assertNotIn("pngpaste", self.sys.names())
        self.assertNotIn("pbcopy", self.sys.names())
        self.assertEqual(self.sys.pasted, 0)
        text = self.out.getvalue()
        self.assertIn("target: dev (me@dev.example.com)", text)
        self.assertIn("would run:", text)
        self.assertIn("scp", text)

    def test_scp_failure_notifies_cleans_up_and_does_not_paste(self):
        self.sys.hosts = {"dev": ("me", "dev.example.com", "22")}
        self.sys.ps_all = "101 ttys001 ssh dev\n"
        self.sys.fail["scp"] = (1, "Permission denied (publickey).")
        self.assertEqual(self.main(), 1)
        self.assertEqual(self.sys.pasted, 0)
        self.assertEqual(len(self.sys.notes), 1)
        self.assertIn("Permission denied", self.sys.notes[0])
        self.assertIn("Permission denied", self.err.getvalue())
        self.assertFalse(any(os.path.exists(p) for p in self.sys.local_files))

    def test_pngpaste_failure_cleans_up(self):
        self.sys.hosts = {"dev": ("me", "dev.example.com", "22")}
        self.sys.ps_all = "101 ttys001 ssh dev\n"
        self.sys.fail["pngpaste"] = (1, "No image data")
        self.assertEqual(self.main(), 1)
        self.assertNotIn("scp", self.sys.names())

    def test_missing_pngpaste_falls_back_to_cmd_v(self):
        mod.find_tool = lambda name: None if name == "pngpaste" else "/stub/" + name
        self.assertEqual(self.main(), 1)
        self.assertEqual(self.sys.pasted, 1)
        self.assertIn("pngpaste not found", self.sys.notes[0])

    def test_front_app_comes_from_nsworkspace_without_system_events(self):
        self.sys.clip = TEXT_INFO
        self.assertEqual(self.main(), 0)
        scripts = [c[-1] for c in self.sys.calls if os.path.basename(c[0]) == "osascript"]
        self.assertTrue(any("NSWorkspace" in sc for sc in scripts))

    def test_no_system_events_anywhere(self):
        self.one_host()
        self.assertEqual(self.main(), 0)
        self.sys.front = "iTerm2"
        self.sys.ps_tty = "201 S+ ssh dev\n"
        self.assertEqual(self.main(), 0)
        self.assertFalse(any("System Events" in " ".join(c) or "keystroke" in " ".join(c) for c in self.sys.calls))
        with open(SCRIPT) as f:
            source = f.read()
        self.assertNotIn('tell application "System Events"', source)
        self.assertNotIn("keystroke", source)

    def test_upload_pastes_with_quartz(self):
        self.one_host()
        self.assertEqual(self.main(), 0)
        self.assertEqual(self.sys.pasted, 1)
        self.assertIn("paste: cgevent", self.log_text())

    def test_paste_fallback_keeps_path_on_clipboard_and_notifies(self):
        self.one_host()
        self.post_error = "CoreGraphics is not available"
        self.assertEqual(self.main(), 0)
        self.assertEqual(self.sys.pasted, 0)
        self.assertRegex(self.sys.clipboard_text, r"^/tmp/claude-img/\d{8}-\d{6}-\d{3}\.png$")
        self.assertEqual(len(self.sys.notes), 1)
        self.assertIn("Path copied: press Cmd+V", self.sys.notes[0])
        self.assertIn("paste: clipboard", self.log_text())

    def test_paste_fallback_without_image_leaves_clipboard_alone(self):
        self.sys.clip = TEXT_INFO
        self.post_error = "no quartz"
        self.assertEqual(self.main(), 0)
        self.assertIsNone(self.sys.clipboard_text)
        self.assertIn("press Cmd+V", self.sys.notes[0])

    def test_iterm_not_authorized_falls_back_to_process_list(self):
        self.sys.front = "iTerm2"
        self.sys.iterm_tty = ""
        self.sys.iterm_error = "execution error: Not authorized to send Apple events to iTerm2. (-1743)"
        self.sys.hosts = {"dev": ("me", "dev.example.com", "22")}
        self.sys.ps_all = "301 ttys009 ssh dev\n"
        self.assertEqual(self.main(), 0)
        self.assertEqual(self.sys.names().count("scp"), 1)
        self.assertEqual(self.sys.notes, [])
        self.assertEqual(self.err.getvalue(), "")
        self.assertIn("not authorized to control iTerm2", self.log_text())

    def test_log_block_has_the_run_and_no_clipboard_contents(self):
        self.one_host()
        path = self.make_file("secret-name.png")
        with open(path, "wb") as f:
            f.write(b"SECRETBYTES")
        self.sys.clip = "«class furl», 40"
        self.sys.files = [path]
        self.assertEqual(self.main(), 0)
        text = self.log_text()
        for expected in ("front app: Ghostty", "clipboard: file", "target: dev (me@dev.example.com)",
                         "paste: cgevent", "result: exit 0"):
            self.assertIn(expected, text)
        self.assertNotIn("SECRETBYTES", text)
        self.assertNotIn(self.sys.clipboard_text, text)

    def test_failed_command_is_logged_with_exit_code_and_stderr(self):
        self.one_host()
        self.sys.fail["scp"] = (1, "Permission denied (publickey).")
        self.assertEqual(self.main(), 1)
        text = self.log_text()
        self.assertIn("upload failed: scp failed: Permission denied", text)
        self.assertIn("result: exit 1", text)

    def test_dry_run_prints_the_log_and_writes_none(self):
        self.one_host()
        self.assertEqual(self.main("--dry-run"), 0)
        self.assertIn("would log:", self.out.getvalue())
        self.assertIn("front app: Ghostty", self.out.getvalue())
        self.assertFalse(os.path.exists(mod.LOG_PATH))

    def test_each_run_appends_one_block(self):
        self.sys.clip = TEXT_INFO
        self.main()
        self.main()
        self.assertEqual(self.log_text().count("=== 20"), 2)

    def test_bad_arguments(self):
        self.assertEqual(self.main("--nope"), 2)
        self.assertEqual(self.sys.calls, [])


class WriteLog(unittest.TestCase):
    def setUp(self):
        self.dir = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, self.dir, ignore_errors=True)
        self.path = os.path.join(self.dir, "Library", "Logs", "img-to-server.log")

    def test_creates_folder_and_appends(self):
        mod.write_log(["a"], self.path)
        mod.write_log(["b"], self.path)
        with open(self.path) as f:
            self.assertEqual(f.read(), "a\n\nb\n\n")

    def test_big_file_is_cut_to_the_newest_part(self):
        os.makedirs(os.path.dirname(self.path))
        line = "old line %06d\n"
        with open(self.path, "w") as f:
            for i in range(mod.LOG_MAX_BYTES // len(line % 0) + 10):
                f.write(line % i)
        before = os.path.getsize(self.path)
        self.assertGreater(before, mod.LOG_MAX_BYTES)
        mod.write_log(["new block"], self.path)
        size = os.path.getsize(self.path)
        self.assertLess(size, mod.LOG_KEEP_BYTES + 100)
        with open(self.path) as f:
            lines = f.read().splitlines()
        self.assertTrue(lines[0].startswith("old line "))     # cut at a line start
        self.assertEqual(len(lines[0]), len(line % 0) - 1)
        self.assertIn("new block", lines)
        self.assertEqual(lines[-3], "old line %06d" % (before // len(line % 0) - 1))

    def test_small_file_is_kept(self):
        mod.write_log(["x" * 1000], self.path)
        mod.write_log(["y"], self.path)
        self.assertGreater(os.path.getsize(self.path), 1000)

    def test_unwritable_log_does_not_raise(self):
        with contextlib.redirect_stderr(io.StringIO()):
            mod.write_log(["a"], "/dev/null/nope/log")


class RunHelper(unittest.TestCase):
    def test_timeout_kills_and_reports_124(self):
        code, _, err = mod.run(["/bin/sleep", "30"], timeout=0.3)
        self.assertEqual(code, 124)
        self.assertIn("timed out", err)

    def test_missing_program(self):
        self.assertEqual(mod.run(["/nonexistent/x"])[0], 127)

    def test_stdin_data(self):
        self.assertEqual(mod.run(["/bin/cat"], data=b"hi")[1], "hi")


class StubbedPath(unittest.TestCase):
    """Runs the real script with shell stubs first on PATH; nothing leaves the temp folder."""

    STUBS = {
        "osascript": '''#!/bin/sh
for last; do :; done
echo "osascript $last" >> "$LOG"
case "$last" in
  "clipboard info") echo "$CLIP_INFO" ;;
  *frontmostApplication*) echo Ghostty ;;
esac
''',
        "ps": '#!/bin/sh\necho "ps $*" >> "$LOG"\necho "999999 ttys001 ssh -p 2200 dev"\necho "999998 ?? ssh -N dev"\n',
        "ssh": '#!/bin/sh\necho "ssh $*" >> "$LOG"\n[ "$1" = "-G" ] && printf "user me\\nhostname dev.example.com\\nport 2200\\n"\nexit 0\n',
        "scp": '#!/bin/sh\necho "scp $*" >> "$LOG"\nexit 0\n',
        "pngpaste": '#!/bin/sh\necho "pngpaste $*" >> "$LOG"\necho png > "$1"\necho "$1" > "$TMPFILE_LOG"\n',
        "pbcopy": '#!/bin/sh\necho "pbcopy $(cat)" >> "$LOG"\n',
    }

    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, self.tmp, ignore_errors=True)
        for name, body in self.STUBS.items():
            path = os.path.join(self.tmp, name)
            with open(path, "w") as f:
                f.write(body)
            os.chmod(path, os.stat(path).st_mode | stat.S_IXUSR)
        self.log = os.path.join(self.tmp, "log")
        self.tmpfile_log = os.path.join(self.tmp, "tmpfile")

    @staticmethod
    def read(path):
        if not os.path.exists(path):
            return ""
        with open(path) as f:
            return f.read()

    # Loads the real script but replaces the Quartz call, so no key event is ever posted.
    RUNNER = """
import importlib.machinery, importlib.util, os, sys
loader = importlib.machinery.SourceFileLoader("img_to_server", sys.argv[1])
mod = importlib.util.module_from_spec(importlib.util.spec_from_loader("img_to_server", loader))
loader.exec_module(mod)
def fake_post():
    with open(os.environ["LOG"], "a") as f:
        f.write("post_cmd_v\\n")
mod.post_cmd_v = fake_post
sys.exit(mod.main(sys.argv[2:]))
"""

    def run_script(self, clip, *args):
        env = {"PATH": self.tmp + ":/usr/bin:/bin", "LOG": self.log, "CLIP_INFO": clip,
               "TMPFILE_LOG": self.tmpfile_log, "HOME": self.tmp}
        proc = subprocess.run([sys.executable, "-I", "-c", self.RUNNER, SCRIPT, *args], env=env,
                              capture_output=True, text=True, timeout=60)
        log = self.read(self.log)
        return proc, log

    def app_log(self):
        return self.read(os.path.join(self.tmp, "Library", "Logs", "img-to-server.log"))

    def test_full_run(self):
        proc, log = self.run_script(IMAGE_INFO)
        self.assertEqual(proc.returncode, 0, proc.stderr)
        self.assertIn("scp -q -o BatchMode=yes", log)
        self.assertIn("-o Port=2200 -- ", log)
        self.assertRegex(log, r"pbcopy /tmp/claude-img/\d{8}-\d{6}-\d{3}\.png")
        self.assertEqual(log.count("post_cmd_v"), 1)
        self.assertNotIn("System Events", log)
        self.assertFalse(os.path.exists(self.read(self.tmpfile_log).strip()))
        app_log = self.app_log()
        self.assertIn("front app: Ghostty", app_log)
        self.assertIn("cmd: /", app_log)
        self.assertIn("-> exit 0", app_log)
        self.assertIn("paste: cgevent", app_log)

    def test_no_image(self):
        proc, log = self.run_script("«class utf8», 5, string, 5")
        self.assertEqual(proc.returncode, 0)
        self.assertNotIn("scp", log)
        self.assertEqual(log.count("post_cmd_v"), 1)

    def test_dry_run(self):
        proc, log = self.run_script(IMAGE_INFO, "--dry-run")
        self.assertEqual(proc.returncode, 0, proc.stderr)
        self.assertIn("target: dev (me@dev.example.com:2200)", proc.stdout)
        self.assertNotIn("post_cmd_v", log)
        self.assertIn("would log:", proc.stdout)
        self.assertEqual(self.app_log(), "")
        self.assertNotIn("scp ", log)
        self.assertNotIn("pngpaste", log)


if __name__ == "__main__":
    unittest.main()
