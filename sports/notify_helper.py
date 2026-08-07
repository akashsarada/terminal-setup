"""Cross-platform desktop notification dispatch for the live sports agents.

Detects the host OS once at import and routes send() to the right backend:
macOS terminal-notifier, Linux notify-send, or a Windows toast via powershell.exe
(works from WSL too). Silently no-ops when no backend is available -- callers
already write their own log files, so a missing notifier must never crash an agent.
"""

import platform
import shutil
import subprocess

_MAC_NOTIFIER_FALLBACKS = [
    "/opt/homebrew/Cellar/terminal-notifier/2.0.0/bin/terminal-notifier",
    "/opt/homebrew/bin/terminal-notifier",
    "/usr/local/bin/terminal-notifier",
]

_TIMEOUT_SECONDS = 5
_WINDOWS_TIMEOUT_SECONDS = 15  # powershell.exe cold start is slow

# Toasts require a *registered* AppUserModelID -- an arbitrary string makes
# CreateToastNotifier throw or silently drop the toast. This is the AUMID of the
# built-in Windows PowerShell Start Menu shortcut, which always exists.
_WINDOWS_AUMID = r"{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe"


def _find_mac_notifier():
    found = shutil.which("terminal-notifier")
    if found:
        return found
    for candidate in _MAC_NOTIFIER_FALLBACKS:
        if shutil.which(candidate):
            return candidate
    return None


def _is_wsl():
    return "microsoft" in platform.release().lower()


def _detect_backend():
    system = platform.system()
    if system == "Darwin":
        return "macos" if _find_mac_notifier() else "osascript"
    if system == "Windows":
        return "windows" if shutil.which("powershell.exe") else None
    if system == "Linux":
        if shutil.which("notify-send"):
            return "linux"
        if _is_wsl() and shutil.which("powershell.exe"):
            return "windows"
    return None


BACKEND = _detect_backend()


def _run(cmd, timeout=_TIMEOUT_SECONDS):
    kwargs = {"capture_output": True, "timeout": timeout}
    # Suppress the console window that would otherwise flash on native Windows
    no_window = getattr(subprocess, "CREATE_NO_WINDOW", None)
    if no_window and platform.system() == "Windows":
        kwargs["creationflags"] = no_window
    try:
        subprocess.run(cmd, **kwargs)
    except Exception:
        pass


def _send_macos(title, message, subtitle, group, open_path):
    notifier = _find_mac_notifier()
    if not notifier:
        return
    cmd = [notifier, "-title", title, "-message", message, "-sound", "default"]
    if group:
        cmd += ["-group", group]
    if open_path:
        cmd += ["-open", f"file://{open_path}"]
    if subtitle:
        cmd += ["-subtitle", subtitle]
    _run(cmd)


def _send_osascript(title, message, subtitle, group, open_path):
    script_title = title.replace('"', '\\"')
    script_message = message.replace('"', '\\"')
    script = f'display notification "{script_message}" with title "{script_title}"'
    if subtitle:
        script += f' subtitle "{subtitle.replace(chr(34), chr(92) + chr(34))}"'
    script += ' sound name "default"'
    _run(["osascript", "-e", script])


def _send_linux(title, message, subtitle, group, open_path):
    body = f"{subtitle}\n{message}" if subtitle else message
    cmd = ["notify-send", title, body]
    if group:
        # Replaces the previous notification in the same group rather than stacking
        cmd += ["-h", f"string:x-canonical-private-synchronous:{group}"]
    _run(cmd)


def _ps_quote(text):
    """Escape for embedding in a PowerShell single-quoted string.

    XML escaping is deliberately NOT applied -- CreateTextNode escapes its own input,
    so pre-escaping would double-encode and render '&' as '&amp;'.
    """
    return text.replace("'", "''")


def _send_windows(title, message, subtitle, group, open_path):
    body = f"{subtitle} - {message}" if subtitle else message
    tag = (group or "live")[:64]  # Tag/Group are capped at 64 chars by Windows
    script = (
        "[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, "
        "ContentType = WindowsRuntime] > $null; "
        "$template = [Windows.UI.Notifications.ToastNotificationManager]::"
        "GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02); "
        "$nodes = $template.GetElementsByTagName('text'); "
        f"$nodes.Item(0).AppendChild($template.CreateTextNode('{_ps_quote(title)}')) > $null; "
        f"$nodes.Item(1).AppendChild($template.CreateTextNode('{_ps_quote(body)}')) > $null; "
        "$toast = [Windows.UI.Notifications.ToastNotification]::new($template); "
        f"$toast.Tag = '{_ps_quote(tag)}'; $toast.Group = '{_ps_quote(tag)}'; "
        "[Windows.UI.Notifications.ToastNotificationManager]::"
        f"CreateToastNotifier('{_WINDOWS_AUMID}').Show($toast)"
    )
    _run(
        ["powershell.exe", "-NoProfile", "-NonInteractive", "-Command", script],
        timeout=_WINDOWS_TIMEOUT_SECONDS,
    )


_DISPATCH = {
    "macos": _send_macos,
    "osascript": _send_osascript,
    "linux": _send_linux,
    "windows": _send_windows,
}


def send(title, message, subtitle=None, group=None, open_path=None):
    """Show a desktop notification on whichever platform we're running on.

    group replaces same-group notifications on macOS/Linux and sets the toast app id
    on Windows. open_path is a click-to-open target honoured on macOS only.
    """
    handler = _DISPATCH.get(BACKEND)
    if handler:
        handler(title, message, subtitle, group, open_path)


def backend_name():
    """Human-readable backend for startup logging."""
    return BACKEND or "none (desktop notifications disabled)"
