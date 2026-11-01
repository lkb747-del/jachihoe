# src/app.src.html + src/audio/*.mp3 + firebase.json 값  ->  index.html, s.html
# 쓰는 법: .\build.ps1          실제 배포본
#         .\build.ps1 -Test     미리보기·에뮬레이터 시험본 (out/ 에 만든다)
param([switch]$Test)
$r   = Split-Path -Parent $MyInvocation.MyCommand.Path
$enc = [System.Text.UTF8Encoding]::new($false)
$cfgPath = Join-Path $r "firebase-web.json"
$cfg = if (Test-Path $cfgPath) { Get-Content $cfgPath -Raw -Encoding UTF8 | ConvertFrom-Json } else { $null }

$html = [System.IO.File]::ReadAllText("$r\src\app.src.html", $enc)
$s    = [System.IO.File]::ReadAllText("$r\s.src.html", $enc)

$audioDir = if ($Test -and (Test-Path "$r\out\micro")) { "$r\out\micro" } else { "$r\src\audio" }
foreach ($p in @(@("__AUDIO_PLEDGE__","pledge"),@("__AUDIO_ANTHEM__","anthem"),@("__AUDIO_SONG__","song"))) {
  $b64 = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes("$audioDir\$($p[1]).mp3"))
  $html = $html.Replace($p[0], "data:audio/mpeg;base64,$b64")
}

if ($Test) {
  $live = '{"apiKey":"fake-key","projectId":"demo-jachihoe","authDomain":"demo-jachihoe.firebaseapp.com","emu":"127.0.0.1"}'
  $sUrl = "http://127.0.0.1:5199/s.html"; $proj="demo-jachihoe"; $key="fake-key"; $api="http://127.0.0.1:8080"
} elseif ($cfg) {
  $live = ($cfg | ConvertTo-Json -Compress)
  $sUrl = "https://lkb747-del.github.io/jachihoe/s.html"; $proj=$cfg.projectId; $key=$cfg.apiKey; $api="https://firestore.googleapis.com"
} else {
  $live = "null"; $sUrl=""; $proj=""; $key=""; $api=""
}
$html = $html.Replace('__FB_CONFIG__', $live).Replace('__STUDENT_URL__', $sUrl)
$s    = $s.Replace('__FB_PROJECT__',$proj).Replace('__FB_KEY__',$key).Replace('__FB_API__',$api)
if ($html -match '__AUDIO_|__FB_|__STUDENT_') { throw "치환되지 않은 자리표시자가 남아 있습니다" }

$outDir = if ($Test) { "$r\out" } else { $r }
New-Item -ItemType Directory -Force $outDir | Out-Null
[System.IO.File]::WriteAllText("$outDir\index.html", $html, $enc)
[System.IO.File]::WriteAllText("$outDir\s.html", $s, $enc)
"완성: {0}\index.html ({1:N2} MB), s.html ({2:N1} KB)" -f $outDir, ((Get-Item "$outDir\index.html").Length/1MB), ((Get-Item "$outDir\s.html").Length/1KB)
