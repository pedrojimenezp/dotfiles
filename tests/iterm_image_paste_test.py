"""Tests for the pure helpers of the iTerm image paste script.

Run: python3 -I tests/iterm_image_paste_test.py
"""

import datetime
import importlib.util
import os
import shlex
import subprocess
import sys
import shutil
import tempfile
import time
import unittest

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCRIPT = os.path.join(ROOT, "iterm", "Library", "Application Support", "iTerm2", "Scripts",
                      "AutoLaunch", "dotfiles_image_paste.py")
sys.dont_write_bytecode = True  # no __pycache__ in the stow package, which links into AutoLaunch
spec = importlib.util.spec_from_file_location("dotfiles_image_paste", SCRIPT)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

TSSH_COMMAND = 'exec $SHELL -lic "tmux new-session -A -s main"'


class ParseSshArgv(unittest.TestCase):
    def check(self, argv, expected):
        self.assertEqual(mod.parse_ssh_argv(argv), expected)

    def test_plain_host(self):
        self.check(["ssh", "dev"], ([], "dev"))

    def test_full_path_and_user(self):
        self.check(["/usr/bin/ssh", "me@dev.example.com"], ([], "me@dev.example.com"))

    def test_tssh_drops_tty_and_remote_command(self):
        self.check(["ssh", "-t", "dev", TSSH_COMMAND], ([], "dev"))

    def test_tssh_with_options_after_destination(self):
        self.check(["ssh", "-t", "dev", "-p", "2222", "-i", "/k/my key", TSSH_COMMAND],
                   (["-p", "2222", "-i", "/k/my key"], "dev"))

    def test_joined_values_and_flag_groups(self):
        self.check(["ssh", "-tt", "-4Cp2222", "-oUser=me", "-A", "-L", "8080:localhost:80", "dev"],
                   (["-4", "-C", "-p", "2222", "-o", "User=me"], "dev"))

    def test_jump_config_and_control_path(self):
        self.check(["ssh", "-F", "/c", "-J", "bastion", "-S", "/s", "-l", "me", "dev", "uptime"],
                   (["-F", "/c", "-J", "bastion", "-S", "/s", "-l", "me"], "dev"))

    def test_double_dash(self):
        self.check(["ssh", "-p", "22", "--", "dev", "-ls"], (["-p", "22"], "dev"))

    def test_remote_command_starting_with_dash_after_double_dash_is_not_an_option(self):
        self.check(["ssh", "--", "dev", "-N"], ([], "dev"))

    def test_non_interactive_is_rejected(self):
        for argv in (["ssh", "-N", "-L", "1:h:1", "dev"], ["ssh", "-W", "h:22", "jump"],
                     ["ssh", "-O", "exit", "dev"], ["ssh", "-G", "dev"], ["ssh", "-V"],
                     ["ssh", "-f", "dev", "sleep 1"], ["ssh", "dev", "-N"], ["ssh", "-s", "dev", "sftp"]):
            self.assertIsNone(mod.parse_ssh_argv(argv), argv)

    def test_no_destination_or_unknown_option(self):
        for argv in (["ssh"], ["ssh", "-p"], ["ssh", "-Z", "dev"], [], ["scp", "a", "dev:"],
                     ["mosh", "dev"]):
            self.assertIsNone(mod.parse_ssh_argv(argv), argv)


class UploadCommand(unittest.TestCase):
    def test_forced_options_come_first_and_destination_is_only_host(self):
        argv = mod.upload_command("/usr/bin/ssh", ["-p", "2222"], "dev", "/tmp/claude-img/a.png")
        self.assertEqual(argv[0], "/usr/bin/ssh")
        self.assertEqual(argv[1:1 + len(mod.UPLOAD_SSH_OPTIONS)], mod.UPLOAD_SSH_OPTIONS)
        self.assertEqual(argv[-5:-2], ["-p", "2222", "--"])
        self.assertEqual(argv[-2], "dev")
        self.assertIn("BatchMode=yes", argv)

    @unittest.skipUnless(shutil.which("ssh"), "needs the ssh client")
    def test_ssh_accepts_the_options(self):
        # ssh -G parses every option and prints the resolved config without connecting.
        argv = mod.upload_command("ssh", ["-F", "/dev/null", "-p", "2222"], "dev", "/tmp/x.png")
        argv = [argv[0], "-G", *argv[1:-1]]
        out = subprocess.run(argv, capture_output=True, text=True, check=True).stdout
        self.assertIn("batchmode yes", out)
        self.assertIn("port 2222", out)
        self.assertIn("requesttty false", out)

    def test_remote_script(self):
        argv = mod.upload_command("ssh", [], "dev", "/tmp/claude-img/a.png")
        words = shlex.split(argv[-1])
        self.assertEqual(words[:2], ["sh", "-c"])
        self.assertEqual(words[2], "mkdir -p -m 700 /tmp/claude-img && "
                                   "find /tmp/claude-img -type f -mtime +0 -delete; "
                                   "cat > /tmp/claude-img/a.png")

    def test_remote_script_runs_locally(self):
        # The remote half, run by a local sh in a temp folder.
        with tempfile.TemporaryDirectory() as tmp:
            folder = os.path.join(tmp, "claude-img")
            old = os.path.join(folder, "old.png")
            os.makedirs(folder)
            open(old, "w").close()
            os.utime(old, (0, 0))                                   # 1970: older than a day
            original = mod.REMOTE_DIR
            mod.REMOTE_DIR = folder
            try:
                argv = mod.upload_command("ssh", [], "dev", os.path.join(folder, "new.png"))
            finally:
                mod.REMOTE_DIR = original
            subprocess.run(shlex.split(argv[-1]), input=b"PNGDATA", check=True)
            self.assertEqual(os.listdir(folder), ["new.png"])
            with open(os.path.join(folder, "new.png"), "rb") as f:
                self.assertEqual(f.read(), b"PNGDATA")

    def test_remote_image_path(self):
        now = datetime.datetime(2026, 10, 31, 14, 25, 1, 123456)
        self.assertEqual(mod.remote_image_path(now), "/tmp/claude-img/20261031-142501-123.png")


class Clipboard(unittest.TestCase):
    def test_screenshot_is_image_only(self):
        info = "«class PNGf», 81234, «class 8BPS», 300000, GIF picture, 4000, «class jp2 », 9000, " \
               "JPEG picture, 7000, TIFF picture, 400000, «class BMP », 1, «class TPIC», 1"
        self.assertTrue(mod.clipboard_is_image_only(info))

    def test_text_is_not_image(self):
        self.assertFalse(mod.clipboard_is_image_only(
            "«class utf8», 127, «class ut16», 256, string, 127, Unicode text, 254"))

    def test_image_with_text_or_file_is_normal_paste(self):
        self.assertFalse(mod.clipboard_is_image_only("TIFF picture, 100, string, 5"))
        self.assertFalse(mod.clipboard_is_image_only("«class furl», 40, «class icns», 9, TIFF picture, 100"))

    def test_empty(self):
        self.assertFalse(mod.clipboard_is_image_only(""))


class ProcessArgv(unittest.TestCase):
    def test_parse_buffer(self):
        data = (3).to_bytes(4, "little") + b"/usr/bin/ssh\0\0\0\0ssh\0-t\0a b\0FOO=1\0"
        self.assertEqual(mod.parse_procargs2(data), ("/usr/bin/ssh", ["ssh", "-t", "a b"]))
        self.assertIsNone(mod.parse_procargs2(b"\1"))

    @unittest.skipUnless(sys.platform == "darwin", "sysctl KERN_PROCARGS2 is macOS only")
    def test_real_process_keeps_spaces(self):
        argv = ["/bin/sh", "-c", "sleep 30; :", "x y"]
        proc = subprocess.Popen(argv)
        time.sleep(0.3)                                             # let exec finish
        try:
            self.assertEqual(mod.process_argv(proc.pid)[1], argv)
        finally:
            proc.kill()
            proc.wait()


if __name__ == "__main__":
    unittest.main()
