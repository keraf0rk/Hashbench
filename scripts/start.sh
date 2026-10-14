#!/usr/bin/env bash
# =============================================================================
# hashbench — macOS / Linux runner
# Эксперимент из журнала: бенчмарк vs реальная атака + стабильность бенчмарка.
# Воспроизводит два теста на твоём железе и сравнивает с эталоном (Apple M4).
#
#   Запуск:  bash scripts/start.sh 2>&1 | tee results/result.txt
#
# Зависимости: hashcat (brew install hashcat / apt install hashcat),
#              openssl, curl, shasum|sha256sum.
# =============================================================================
set -u

WORKDIR="${HASHBENCH_WORKDIR:-$HOME/hashbench-run}"

# --- выбор инструмента sha256 (macOS: shasum, Linux: sha256sum) -------------
if command -v shasum >/dev/null 2>&1; then
  SHA256() { shasum -a 256 | cut -d' ' -f1; }
elif command -v sha256sum >/dev/null 2>&1; then
  SHA256() { sha256sum | cut -d' ' -f1; }
else
  echo "[!] Нет ни shasum, ни sha256sum"; exit 1
fi

echo "=================================================="
echo " ПОДГОТОВКА"
echo "=================================================="
mkdir -p "$WORKDIR" && cd "$WORKDIR" || { echo "Не могу войти в $WORKDIR"; exit 1; }

# --- 1. SHA-256 хеши (printf без переноса строки!) --------------------------
printf '%s' 'Qwerty12!'      | SHA256 >  hashes.txt
printf '%s' '123password456' | SHA256 >> hashes.txt
echo "--- hashes.txt (SHA-256) ---"; cat hashes.txt
if grep -q '^b188cb9b' hashes.txt; then
  echo "[OK] SHA-256 Qwerty12! совпал с журналом"
else
  echo "[!] SHA-256 не совпал — проверь ввод"
fi

# --- 2. sha256crypt через openssl (соль xyz, 5000 раундов) ------------------
openssl passwd -5 -salt xyz 'Qwerty12!'      >  hashesC.txt 2>/dev/null
openssl passwd -5 -salt xyz '123password456' >> hashesC.txt 2>/dev/null
echo "--- hashesC.txt (sha256crypt) ---"; cat hashesC.txt
if grep -q '^\$5\$xyz\$DmIBRKf' hashesC.txt; then
  echo "[OK] sha256crypt совпал с журналом"
else
  echo "[!] sha256crypt не совпал — возможно openssl без -5 (LibreSSL). См. README."
fi

# --- 3. Словарь -------------------------------------------------------------
if [ ! -f rockyou.txt ]; then
  echo "Качаю rockyou.txt..."
  curl -L -o rockyou.txt \
    https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt \
    || { echo "[!] Не удалось скачать словарь"; exit 1; }
fi
cp rockyou.txt work.txt
printf 'Qwerty12!\n123password456\n' >> work.txt
echo "Строк в словаре: $(wc -l < work.txt)"

command -v hashcat >/dev/null 2>&1 || { echo "[!] hashcat не найден. См. README."; exit 1; }

echo ""
echo "=================================================="
echo " ЭКСПЕРИМЕНТ 1: реальная атака vs бенчмарк"
echo "=================================================="

echo ""
echo ">>> SHA-256 (1400) — РЕАЛЬНАЯ атака маской (?a x8, 30 сек, грузит GPU)"
hashcat -m 1400 -a 3 hashes.txt '?a?a?a?a?a?a?a?a' --runtime=30 --potfile-disable \
  --status --status-timer=10 2>&1 | grep -i 'Speed.#'
echo ">>> SHA-256 (1400) — БЕНЧМАРК"
hashcat -b -m 1400 2>&1 | grep -i 'Speed.#'

echo ""
echo ">>> sha256crypt (7400) — РЕАЛЬНАЯ атака словарём"
hashcat -m 7400 -a 0 hashesC.txt work.txt --runtime=30 --potfile-disable \
  --status --status-timer=10 2>&1 | grep -Ei 'Speed.#|Recovered'
echo ">>> sha256crypt (7400) — БЕНЧМАРК"
hashcat -b -m 7400 2>&1 | grep -i 'Speed.#'

echo ""
echo "=================================================="
echo " ЭКСПЕРИМЕНТ 2: стабильность бенчмарка (5 прогонов 1400)"
echo "=================================================="
for i in 1 2 3 4 5; do
  echo -n "run $i: "
  hashcat -b -m 1400 2>&1 | grep -i 'Speed.#' | head -1
done

echo ""
echo "Готово. Сравни Speed реальной атаки с бенчмарком (см. docs/METHODOLOGY.md)."
