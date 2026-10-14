<#
=============================================================================
 hashbench — Windows (PowerShell) runner
 Эксперимент из журнала: бенчмарк vs реальная атака + стабильность бенчмарка.

   Запуск (PowerShell):
     powershell -ExecutionPolicy Bypass -File scripts\start.ps1 *> results\result.txt

 Зависимости:
   - hashcat.exe в PATH (распакуй релиз с hashcat.net и добавь папку в PATH,
     либо правь $Hashcat ниже на полный путь к hashcat.exe)
   - OpenSSL в PATH (идёт с Git for Windows: ...\usr\bin\openssl.exe)
   - PowerShell 5+ (есть в Windows 10/11 из коробки)
=============================================================================
#>
$ErrorActionPreference = 'Continue'

$Hashcat = 'hashcat'                         # или полный путь: 'C:\tools\hashcat\hashcat.exe'
$WorkDir = Join-Path $HOME 'hashbench-run'

function Get-Sha256Hex([string]$text) {
  $sha = [System.Security.Cryptography.SHA256]::Create()
  $bytes = [System.Text.Encoding]::ASCII.GetBytes($text)   # ASCII = без переноса строки
  ($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') }) -join ''
}

Write-Output "=================================================="
Write-Output " ПОДГОТОВКА"
Write-Output "=================================================="
New-Item -ItemType Directory -Force -Path $WorkDir | Out-Null
Set-Location $WorkDir

# --- 1. SHA-256 хеши ---------------------------------------------------------
$h1 = Get-Sha256Hex 'Qwerty12!'
$h2 = Get-Sha256Hex '123password456'
Set-Content -Path hashes.txt -Value $h1
Add-Content -Path hashes.txt -Value $h2
Write-Output "--- hashes.txt (SHA-256) ---"
Get-Content hashes.txt
if ($h1 -like 'b188cb9b*') { Write-Output "[OK] SHA-256 Qwerty12! совпал с журналом" }
else { Write-Output "[!] SHA-256 не совпал" }

# --- 2. sha256crypt через openssl -------------------------------------------
# PowerShell не умеет sha256crypt сам — зовём openssl (из Git for Windows).
$c1 = (& openssl passwd -5 -salt xyz 'Qwerty12!')      2>$null
$c2 = (& openssl passwd -5 -salt xyz '123password456') 2>$null
Set-Content -Path hashesC.txt -Value $c1
Add-Content -Path hashesC.txt -Value $c2
Write-Output "--- hashesC.txt (sha256crypt) ---"
Get-Content hashesC.txt
if ($c1 -like '$5$xyz$DmIBRKf*') { Write-Output "[OK] sha256crypt совпал с журналом" }
else { Write-Output "[!] sha256crypt не совпал — проверь, что openssl в PATH. См. README." }

# --- 3. Словарь --------------------------------------------------------------
if (-not (Test-Path rockyou.txt)) {
  Write-Output "Качаю rockyou.txt..."
  Invoke-WebRequest -Uri 'https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt' -OutFile rockyou.txt
}
Copy-Item rockyou.txt work.txt -Force
Add-Content -Path work.txt -Value "Qwerty12!"
Add-Content -Path work.txt -Value "123password456"
Write-Output ("Строк в словаре: " + (Get-Content work.txt | Measure-Object -Line).Lines)

if (-not (Get-Command $Hashcat -ErrorAction SilentlyContinue)) {
  Write-Output "[!] hashcat не найден. Укажи путь в `$Hashcat или добавь в PATH. См. README."
  exit 1
}

Write-Output ""
Write-Output "=================================================="
Write-Output " ЭКСПЕРИМЕНТ 1: реальная атака vs бенчмарк"
Write-Output "=================================================="

Write-Output ""
Write-Output ">>> SHA-256 (1400) — РЕАЛЬНАЯ атака маской (?a x8, 30 сек)"
& $Hashcat -m 1400 -a 3 hashes.txt '?a?a?a?a?a?a?a?a' --runtime=30 --potfile-disable --status --status-timer=10 2>&1 |
  Select-String 'Speed.#'
Write-Output ">>> SHA-256 (1400) — БЕНЧМАРК"
& $Hashcat -b -m 1400 2>&1 | Select-String 'Speed.#'

Write-Output ""
Write-Output ">>> sha256crypt (7400) — РЕАЛЬНАЯ атака словарём"
& $Hashcat -m 7400 -a 0 hashesC.txt work.txt --runtime=30 --potfile-disable --status --status-timer=10 2>&1 |
  Select-String 'Speed.#|Recovered'
Write-Output ">>> sha256crypt (7400) — БЕНЧМАРК"
& $Hashcat -b -m 7400 2>&1 | Select-String 'Speed.#'

Write-Output ""
Write-Output "=================================================="
Write-Output " ЭКСПЕРИМЕНТ 2: стабильность бенчмарка (5 прогонов 1400)"
Write-Output "=================================================="
foreach ($i in 1..5) {
  Write-Host -NoNewline "run $i`: "
  (& $Hashcat -b -m 1400 2>&1 | Select-String 'Speed.#' | Select-Object -First 1)
}

Write-Output ""
Write-Output "Готово. Сравни Speed реальной атаки с бенчмарком (см. docs/METHODOLOGY.md)."
