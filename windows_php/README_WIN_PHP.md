# Ghostinject – Windows PHP persistent RFI payload

PHP payload for Windows servers (XAMPP, WampServer, IIS with PHP).  
Provides system reconnaissance, command execution, and a **persistent reverse shell** (auto‑reconnect + keepalive).

## Features

- 📡 **Target info** – Windows OS version, user, working directory, PHP version, server software, `disable_functions`.
- 💻 **Command execution** – run any Windows command (e.g., `whoami`, `ipconfig`, `dir C:\`).
- 🔌 **Persistent reverse shell** – two methods (PHP socket → PowerShell) with auto‑reconnect every 10 seconds.
- 🛡️ **Error resilient** – no output breaks the page; fallback to `exec()` if `shell_exec` is disabled.
- ⚡ **Async command runner** – commands execute without full page reload.

## Usage

1. **Upload** `ghostinject_win.php` to a web‑accessible directory (e.g., `C:\xampp\htdocs\`).
2. **Access** `http://target.com/ghostinject_win.php`.
3. **Recon** – system information appears at the top.
4. **Run commands** – type a Windows command and click **Run**.
5. **Start reverse shell** – on your attacker machine, start a listener:  
   `nc -lvnp 4444`  
   Fill your IP and port, click **🚀 Start Ghostinject**.  
   The payload will try PHP socket first, then PowerShell, and will **reconnect automatically** every 10 seconds if the connection drops.

## Requirements on target

- PHP **5.3+** (any thread‑safe version)
- `allow_url_include=On` for RFI (or local inclusion if file is uploaded)
- PHP functions **not** disabled: `shell_exec` and/or `exec`, `fsockopen` (for PHP socket method)
- PowerShell is optional (fallback method)

## Limitations

- The background PHP process must stay alive – restarting Apache/IIS kills it.
- Windows Defender or other AV may flag the PowerShell command; obfuscation may be needed.
- If `disable_functions` blocks both `shell_exec` and `exec`, command execution fails.

## Legal disclaimer

**This tool is for educational purposes and authorized security testing only.**  
Unauthorized access is illegal. The author assumes no liability for misuse.

## License

MIT