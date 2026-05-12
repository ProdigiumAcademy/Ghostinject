# Ghostinject – Linux PHP persistent RFI payload

Compact PHP payload for **Remote File Inclusion (RFI)** on Linux servers.  
Provides system reconnaissance, command execution, and a **persistent reverse shell** (auto‑reconnect + keepalive).

## Features

- 📡 **Target info** – OS, user, working directory, PHP version, server software, `disable_functions`.
- 💻 **Command execution** – run any Linux command; output is displayed in the page.
- 🔌 **Persistent reverse shell** – two methods (Bash `/dev/tcp` → PHP socket) with auto‑reconnect every 10 seconds.
- 🛡️ **Error resilient** – no output breaks the page; fallback to absolute paths (`/bin/sh`, `/bin/bash`).
- ⚡ **Async command runner** – commands execute without full page reload (fetch API).

## Usage

1. **Upload / include** the payload via RFI or LFI + file upload.
2. **Access** the generated web page at the target URL (e.g., `http://target.com/ghostinject.php`).
3. **Recon** – automatically displayed system information.
4. **Run commands** – type a command (e.g., `id`, `ls -la`, `whoami`) and click **Run**.
5. **Start reverse shell** – on your attacker machine, start a listener:  
   `nc -lvnp 4444`  
   Then fill the form with your IP and port, click **🚀 Start Ghostinject**.  
   The payload will try Bash first, then PHP socket, and will **reconnect automatically** if the connection drops.

## Requirements on target

- PHP **5.3+** (compatible up to 8.x)
- `allow_url_include=On` for RFI (or local inclusion via file upload)
- Functions **not** disabled: `shell_exec`, `exec`, `fsockopen` (at least one for reverse shell)

## Limitations

- Reverse shell persistence requires the background PHP process to stay alive (restarting Apache kills it).
- If `shell_exec` is disabled, the PHP socket method will fail (but Bash method may still work).
- Some hardened systems disable `/dev/tcp` (SELinux/AppArmor) – then only the PHP fallback works.

## Legal disclaimer

**This tool is for educational purposes and authorized security testing only.**  
Unauthorized access is illegal. The author assumes no liability for misuse.

## License

MIT