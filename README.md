<a id="en"></a>
<h1 align="center">🔥 hashbench</h1>

<p align="center"><b>🇬🇧 English</b> · <a href="#ru">🇷🇺 Русский</a></p>

<p align="center">
  A reproducible bench for password-hash cracking speed and benchmark honesty —
  hashcat &amp; John the Ripper across architectures. Replays experiments from Xakep magazine; my own run was on a
  MacBook Air (Apple M4).
</p>

<p align="center">
  <img alt="platforms" src="https://img.shields.io/badge/platforms-macOS%20%7C%20Linux%20%7C%20Windows-blue">
  <img alt="tools" src="https://img.shields.io/badge/tools-hashcat%20%7C%20JtR-green">
  <img alt="license" src="https://img.shields.io/badge/license-MIT-lightgrey">
</p>

> ⚠️ **Legal audit only.** This bench hashes known passwords locally. Running these tools against hashes you don't own, without written permission, is illegal everywhere. For learning, contracted pentests, CTF and auditing your own systems.

---

## 🎯 Why

Three questions the bench answers:

1. **What's my hardware's real hashrate** across key algorithms — from "instant" NTLM to "uncrackable" Argon2.
2. **How much does the benchmark lie** vs a real attack. The magazine I ran the tests from saw 4×–1000×. Spoiler: on Apple Silicon the gap is far smaller.
3. **Are benchmarks even stable** across repeated runs.

Along the way it demonstrates the core lesson: strength = `length × randomness of the password` × `strength of the storage algorithm`. On a fast hash a good password falls to a rented farm; on memory-hard (scrypt/Argon2) it falls to nothing.

## 🏁 Experiments

| # | Experiment | What it shows |
|---|-----------|---------------|
| **1** | Benchmark vs real attack | `hashcat -b` is a ceiling, not real speed |
| **2** | Benchmark stability | spread across 5 consecutive runs |

## 💻 Platforms

| Platform | Script | GPU backend | Status |
|----------|--------|-------------|--------|
| 🍎 **macOS** (Apple Silicon M1–M4) | `start.sh` | Metal / OpenCL | ✅ tested on M4 |
| 🐧 **Linux** (x86_64, NVIDIA/AMD/Intel) | `start.sh` | CUDA / OpenCL | ✅ |
| 🪟 **Windows** 10/11 | `start.ps1` | CUDA / OpenCL | ✅ |
| 📱 iOS / iPadOS | — | — | ❌ sandbox blocks GPU-compute |

## 📂 Layout

```
hashbench/
├── README.md                     # this file
├── scripts/
│   ├── start.sh                  # macOS / Linux runner (bash)
│   └── start.ps1                 # Windows runner (PowerShell)
├── docs/
│   ├── METHODOLOGY.md            # how both experiments work
│   ├── ALGORITHMS.md             # -m modes & strength classes
│   └── RENTAL.md                 # GPU rental + rainbow tables
└── results/
    ├── m4-apple-silicon.md       # my reference numbers (for comparison)
    └── result.txt                # a run lands here
```

## 🚀 Quick start

<details open>
<summary>🍎 macOS</summary>

```bash
brew install hashcat
brew install john-jumbo        # optional: only for *2john extractors

git clone <repo-url> hashbench && cd hashbench
bash scripts/start.sh 2>&1 | tee results/result.txt
```
</details>

<details>
<summary>🐧 Linux (Ubuntu/Debian)</summary>

```bash
sudo apt update && sudo apt install -y hashcat openssl curl
# NVIDIA GPU also needs the proprietary driver + CUDA (see docs/RENTAL.md)

git clone <repo-url> hashbench && cd hashbench
bash scripts/start.sh 2>&1 | tee results/result.txt
```
</details>

<details>
<summary>🪟 Windows 10/11</summary>

```powershell
# 1. Grab the hashcat release from https://hashcat.net/hashcat/ , unzip,
#    add the hashcat.exe folder to PATH (or set $Hashcat in the script).
# 2. Install Git for Windows — it ships openssl.exe.

git clone <repo-url> hashbench; cd hashbench
powershell -ExecutionPolicy Bypass -File scripts\start.ps1 *> results\result.txt
```
</details>

A run takes ~2–3 min (two 30-second measurements + benchmarks + 5 stability runs).

## 📊 Test — Apple M4 (MacBook Air)

Full data in [`results/m4-apple-silicon.md`](results/m4-apple-silicon.md).

**Hashrate by algorithm** (hashcat, OpenCL):

| Algorithm | `-m` | M4 speed | Class |
|-----------|------|----------|-------|
| NTLM | 1000 | 7 296.7 MH/s | compute-hard |
| SHA-256 | 1400 | 667.6 MH/s | compute-hard |
| HMAC-SHA256 | 1450 | 139.4 MH/s | compute-hard |
| sha256crypt | 7400 | 62 857 H/s | iteration-hard |
| Argon2 | 34000 | 55 H/s | memory-hard |
| scrypt | 8900 | out of memory | memory-hard |

> From NTLM to Argon2 — a **~133 million×** drop on the same hardware. That's the whole point of the storage algorithm.

**Experiment 1 — benchmark vs real attack (M4):**

| Mode | Real attack | Benchmark | Overshoot |
|------|-------------|-----------|-----------|
| SHA-256 (1400) | ~542 MH/s | 668 MH/s | **1.23×** |
| sha256crypt (7400) | ~48 700 H/s | 62 943 H/s | **1.29×** |

**Experiment 2 — stability (M4):** 5× `hashcat -b -m 1400` → 668.0 / 668.1 / 668.2 / 668.2 / 668.2 MH/s — **0.03% spread**.

> The magazine's findings (4×–1000× overshoot, unstable benchmarks) hold for discrete NVIDIA (PCIe + gaming throttle) but **don't transfer to Apple Silicon** (unified memory). The takeaway I drew: always measure your own hardware.

## 📚 Disclaimer

MIT code. Use only on systems you own or are authorised in writing to test. The authors take no responsibility for misuse.

---

<a id="ru"></a>
<h1 align="center">🔥 hashbench</h1>

<p align="center"><a href="#en">🇬🇧 English</a> · <b>🇷🇺 Русский</b></p>

<p align="center">
  Воспроизводимый стенд для проверки хешрейта и честности бенчмарков —
  hashcat и John the Ripper на разных архитектурах. Повторяет эксперименты
  из журнала «Хакер»; собственная проверка — на MacBook Air (Apple M4).
</p>

> ⚠️ **Только легальный аудит.** Стенд хеширует заведомо известные пароли локально. Применять инструменты к чужим хешам без письменного разрешения — незаконно везде. Для обучения, pentest по договору, CTF и аудита своих систем.

---

## 🎯 Зачем

Три вопроса, на которые отвечает стенд:

1. **Какой у железа реальный хешрейт** по ключевым алгоритмам — от «мгновенного» NTLM до «неберущегося» Argon2.
2. **Насколько бенчмарк врёт** относительно реальной атаки. Журнал (по которому я запускал тесты) получил 4×–1000×. Спойлер: на Apple Silicon расхождение в разы меньше.
3. **Стабильны ли бенчмарки** при повторных прогонах.

Попутно — главный урок: стойкость = `длина × случайность пароля` × `стойкость алгоритма хранения`. На быстром хеше хороший пароль берётся на арендованной ферме; на memory-hard (scrypt/Argon2) — ничем.

## 🏁 Эксперименты

| # | Эксперимент | Что показывает |
|---|-------------|----------------|
| **1** | Бенчмарк vs реальная атака | `hashcat -b` — это потолок, а не реальная скорость |
| **2** | Стабильность бенчмарка | разброс по 5 прогонам подряд |

## 💻 Платформы

| Платформа | Скрипт | GPU-бэкенд | Статус |
|-----------|--------|-----------|--------|
| 🍎 **macOS** (Apple Silicon M1–M4) | `start.sh` | Metal / OpenCL | ✅ протестировано на M4 |
| 🐧 **Linux** (x86_64, NVIDIA/AMD/Intel) | `start.sh` | CUDA / OpenCL | ✅ |
| 🪟 **Windows** 10/11 | `start.ps1` | CUDA / OpenCL | ✅ |
| 📱 iOS / iPadOS | — | — | ❌ песочница не даёт GPU-compute |

## 📂 Структура

```
hashbench/
├── README.md                     # этот файл
├── scripts/
│   ├── start.sh                  # macOS / Linux (bash)
│   └── start.ps1                 # Windows (PowerShell)
├── docs/
│   ├── METHODOLOGY.md            # как устроены оба эксперимента
│   ├── ALGORITHMS.md             # режимы -m и классы стойкости
│   └── RENTAL.md                 # аренда GPU + радужные таблицы
└── results/
    ├── m4-apple-silicon.md       # мои эталонные цифры (для сравнения)
    └── result.txt                # сюда пишется прогон
```

## 🚀 Быстрый старт

<details open>
<summary>🍎 macOS</summary>

```bash
brew install hashcat
brew install john-jumbo        # опционально: только для *2john-экстракторов

git clone <repo-url> hashbench && cd hashbench
bash scripts/start.sh 2>&1 | tee results/result.txt
```
</details>

<details>
<summary>🐧 Linux (Ubuntu/Debian)</summary>

```bash
sudo apt update && sudo apt install -y hashcat openssl curl
# для NVIDIA GPU нужен проприетарный драйвер + CUDA (см. docs/RENTAL.md)

git clone <repo-url> hashbench && cd hashbench
bash scripts/start.sh 2>&1 | tee results/result.txt
```
</details>

<details>
<summary>🪟 Windows 10/11</summary>

```powershell
# 1. Скачай релиз hashcat с https://hashcat.net/hashcat/ , распакуй,
#    добавь папку с hashcat.exe в PATH (или впиши путь в $Hashcat).
# 2. Поставь Git for Windows — он принесёт openssl.exe.

git clone <repo-url> hashbench; cd hashbench
powershell -ExecutionPolicy Bypass -File scripts\start.ps1 *> results\result.txt
```
</details>

Прогон занимает ~2–3 мин (два 30-секундных замера + бенчмарки + 5 прогонов стабильности).

## 📊 Тест — Apple M4 (MacBook Air)

Полные данные — в [`results/m4-apple-silicon.md`](results/m4-apple-silicon.md).

**Хешрейт по алгоритмам** (hashcat, OpenCL):

| Алгоритм | `-m` | Скорость M4 | Класс |
|----------|------|-------------|-------|
| NTLM | 1000 | 7 296.7 MH/s | compute-hard |
| SHA-256 | 1400 | 667.6 MH/s | compute-hard |
| HMAC-SHA256 | 1450 | 139.4 MH/s | compute-hard |
| sha256crypt | 7400 | 62 857 H/s | iteration-hard |
| Argon2 | 34000 | 55 H/s | memory-hard |
| scrypt | 8900 | не влез в память | memory-hard |

> От NTLM до Argon2 — падение в **~133 млн раз** на одном железе. Это и есть смысл выбора алгоритма хранения.

**Эксперимент 1 — бенчмарк vs реальная атака (M4):**

| Режим | Реальная атака | Бенчмарк | Завышение |
|-------|---------------|----------|-----------|
| SHA-256 (1400) | ~542 MH/s | 668 MH/s | **1.23×** |
| sha256crypt (7400) | ~48 700 H/s | 62 943 H/s | **1.29×** |

**Эксперимент 2 — стабильность (M4):** 5× `hashcat -b -m 1400` → 668.0 / 668.1 / 668.2 / 668.2 / 668.2 MH/s — **разброс 0.03%**.

> Выводы журнала (завышение 4×–1000×, нестабильность) верны для дискретных NVIDIA (PCIe + игровой троттлинг), но **не переносятся на Apple Silicon** (unified memory). Вывод, который я вынес, — всегда меряй своё железо сам.

## 📚 Дисклеймер

Код — MIT. Используй только на системах, которыми владеешь или имеешь письменное разрешение тестировать. Авторы не несут ответственности за неправомерное применение.
