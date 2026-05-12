# Ghostinject – ASPX persistent reverse shell for IIS

Pure .NET / C# payload for **Windows IIS** servers.  
Provides system reconnaissance, command execution, and a **persistent reverse shell** (auto‑reconnect via background thread).

## Features

- 📡 **Target info** – Windows OS, machine name, user, current directory, .NET version, IIS version.
- 💻 **Command execution** – run any Windows command via `cmd.exe /c`.
- 🔌 **Persistent reverse shell** – C# `TcpClient` running in a background thread; reconnects every 10 seconds.
- 🛡️ **No external dependencies** – pure .NET (no PowerShell, no PHP).
- ⚡ **Async command runner** – commands execute without page reload (fetch API).

## Usage

1. **Upload** `ghostinject.aspx` to an IIS web directory (e.g., `C:\inetpub\wwwroot\`).
2. **Access** `http://target.com/ghostinject.aspx`.
3. **Recon** – system information is displayed automatically.
4. **Run commands** – type a Windows command and click **Run**.
5. **Start reverse shell** – on your attacker machine, start a listener:  
   `nc -lvnp 4444`  
   Fill your IP and port, click **🚀 Start Ghostinject**.  
   The payload will spawn a background thread that connects back and **reconnects automatically if the connection drops** (sleep 10 seconds between attempts).

## Requirements on target

- **IIS** with ASP.NET support (any version from 2.0 to 4.8+).
- .NET Framework **2.0+** (almost all Windows systems with IIS).
- The application pool must have **execute permissions** and allow outgoing TCP connections (usually default).

## Limitations

- The reverse shell runs in a background thread inside the ASP.NET worker process. If IIS recycles the application pool or restarts, the shell dies.
- Firewall outbound rules may block the connection – ensure the target allows TCP out on the chosen port.
- No GUI for the reverse shell process (it’s a background thread – no window).

## Legal disclaimer

**This tool is for educational purposes and authorized security testing only.**  
Unauthorized access is illegal. The author assumes no liability for misuse.

## License

MIT