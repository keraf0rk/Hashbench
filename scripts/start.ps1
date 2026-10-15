<#
=============================================================================
 hashbench — Windows (PowerShell) runner
 Два теста из журнала «Хакер»: бенчмарк vs реальная атака + стабильность.

   Запуск (PowerShell):
     powershell -ExecutionPolicy Bypass -File scripts\start.ps1 *> results\result.txt

 Зависимости (ставятся через Scoop — https://scoop.sh):
     scoop install hashcat
     scoop install openssl        # либо openssl из git: scoop install git

 ВАЖНО: файл сохранён в UTF-8 с BOM — иначе Windows PowerShell 5.1 читает
 его как cp1251 и ломает кириллицу. Подробности: docs\TROUBLESHOOTING.md
=============================================================================
#>
$ErrorActionPreference = 'Continue'
$WorkDir = Join-Path $HOME 'hashbench-run'

# --- авто-поиск НАСТОЯЩЕГО hashcat.exe (с папкой OpenCL/ рядом) --------------
# hashcat ищет OpenCL/, modules/, hashcat.hcstat2 относительно рабочей папки,
# поэтому нужен путь к реальному exe, а не к shim-обёртке Scoop.
$HashcatCandidates = @(
  "$env:USERPROFILE\scoop\apps\hashcat\current\hashcat.exe",
  "C:\tools\hashcat\hashcat.exe"
)
$Hashcat = $null
foreach ($c in $HashcatCandidates) { if (Test-Path $c) { $Hashcat = $c; break } }
if (-not $Hashcat) {
  $g = Get-Command hashcat -ErrorAction SilentlyContinue
  if ($g) {
    $dir = Split-Path $g.Source
    if (Test-Path (Join-Path $dir 'OpenCL')) { $Hashcat = $g.Source }
    else { Write-Output "[!] hashcat найден ($($g.Source)), но рядом нет OpenCL/ (похоже на shim). Впиши путь к настоящему hashcat.exe в `$Hashcat." }
  }
}
if (-not $Hashcat) { Write-Output "[!] hashcat.exe не найден. Поставь: scoop install hashcat"; exit 1 }
$HashcatDir = Split-Path $Hashcat
Write-Output "hashcat: $Hashcat"

# --- авто-поиск openssl.exe -------------------------------------------------
$OpenSSL = $null
$g = Get-Command openssl -ErrorAction SilentlyContinue
if ($g) { $OpenSSL = $g.Source }
if (-not $OpenSSL) {
  foreach ($c in @(
    "$env:USERPROFILE\scoop\shims\openssl.exe",
    "$env:USERPROFILE\scoop\apps\openssl\current\bin\openssl.exe",
    "$env:USERPROFILE\scoop\apps\git\current\usr\bin\openssl.exe",
    "C:\Program Files\Git\usr\bin\openssl.exe"
  )) { if (Test-Path $c) { $OpenSSL = $c; break } }
}
if (-not $OpenSSL) { Write-Output "[!] openssl.exe не найден — пропущу sha256crypt. Поставь: scoop install openssl" }

# запуск hashcat из ЕГО папки, но с абсолютными путями к данным
function Invoke-Hashcat {
  param([string[]]$HcArgs)
  Push-Location $HashcatDir
  try { & $Hashcat @HcArgs 2>&1 } finally { Pop-Location }
}

function Get-Sha256Hex([string]$text) {
  $sha = [System.Security.Cryptography.SHA256]::Create()
  $bytes = [System.Text.Encoding]::ASCII.GetBytes($text)
  ($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') }) -join ''
}

Write-Output "=================================================="
Write-Output " ПОДГОТОВКА"
Write-Output "=================================================="
New-Item -ItemType Directory -Force -Path $WorkDir | Out-Null
$Hashes  = Join-Path $WorkDir 'hashes.txt'
$HashesC = Join-Path $WorkDir 'hashesC.txt'
$Work    = Join-Path $WorkDir 'work.txt'
$RockYou = Join-Path $WorkDir 'rockyou.txt'

# 1. SHA-256 (ASCII-байты = без переноса строки)
$h1 = Get-Sha256Hex 'Qwerty12!'
$h2 = Get-Sha256Hex '123password456'
Set-Content -Path $Hashes -Value $h1
Add-Content -Path $Hashes -Value $h2
Write-Output "--- hashes.txt (SHA-256) ---"; Get-Content $Hashes
if ($h1 -like 'b188cb9b*') { Write-Output "[OK] SHA-256 совпал с журналом" } else { Write-Output "[!] SHA-256 не совпал" }

# 2. sha256crypt через openssl (соль xyz, 5000 раундов)
if ($OpenSSL) {
  $c1 = (& $OpenSSL passwd -5 -salt xyz 'Qwerty12!') 2>$null
  $c2 = (& $OpenSSL passwd -5 -salt xyz '123password456') 2>$null
  Set-Content -Path $HashesC -Value $c1
  Add-Content -Path $HashesC -Value $c2
  Write-Output "--- hashesC.txt (sha256crypt) ---"; Get-Content $HashesC
  if ($c1 -like '$5$xyz$DmIBRKf*') { Write-Output "[OK] sha256crypt совпал с журналом" } else { Write-Output "[!] sha256crypt не совпал" }
}

# 3. словарь
if (-not (Test-Path $RockYou)) {
  Write-Output "Качаю rockyou.txt..."
  Invoke-WebRequest -Uri 'https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt' -OutFile $RockYou
}
Copy-Item $RockYou $Work -Force
Add-Content -Path $Work -Value "Qwerty12!"
Add-Content -Path $Work -Value "123password456"
Write-Output ("Строк в словаре: " + (Get-Content $Work | Measure-Object -Line).Lines)

Write-Output ""
Write-Output "=================================================="
Write-Output " ЭКСПЕРИМЕНТ 1: реальная атака vs бенчмарк"
Write-Output "=================================================="
Write-Output ""
Write-Output ">>> SHA-256 (1400) — РЕАЛЬНАЯ атака маской (?a x8, 30 сек)"
Invoke-Hashcat @('-m','1400','-a','3',$Hashes,'?a?a?a?a?a?a?a?a','--runtime=30','--potfile-disable','--status','--status-timer=10') | Select-String 'Speed.#'
Write-Output ">>> SHA-256 (1400) — БЕНЧМАРК"
Invoke-Hashcat @('-b','-m','1400') | Select-String 'Speed.#'

if ($OpenSSL) {
  Write-Output ""
  Write-Output ">>> sha256crypt (7400) — РЕАЛЬНАЯ атака словарём"
  Invoke-Hashcat @('-m','7400','-a','0',$HashesC,$Work,'--runtime=30','--potfile-disable','--status','--status-timer=10') | Select-String 'Speed.#|Recovered'
  Write-Output ">>> sha256crypt (7400) — БЕНЧМАРК"
  Invoke-Hashcat @('-b','-m','7400') | Select-String 'Speed.#'
}

Write-Output ""
Write-Output "=================================================="
Write-Output " ЭКСПЕРИМЕНТ 2: стабильность бенчмарка (5x 1400)"
Write-Output "=================================================="
foreach ($i in 1..5) {
  Write-Host -NoNewline "run ${i}: "
  (Invoke-Hashcat @('-b','-m','1400') | Select-String 'Speed.#' | Select-Object -First 1)
}

Write-Output ""
Write-Output "Готово. 'CUDA SDK Toolkit not installed' = hashcat идёт через OpenCL."
Write-Output "На NVIDIA CUDA-бэкенд обычно быстрее — поставь CUDA Toolkit (docs\TROUBLESHOOTING.md)."
