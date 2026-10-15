<h1 align="center">🛠️ Troubleshooting</h1>

<p align="center">Грабли, на которые натыкаешься при запуске стенда. В основном Windows.</p>

---

## 🪟 Windows

На Windows нет Homebrew — ставим через **[Scoop](https://scoop.sh)**:

```powershell
scoop install hashcat
scoop install openssl        # либо openssl из git: scoop install git
```

### 1. Кодировка скрипта (кириллица превращается в кракозябры)

**Симптом:** `start.ps1` падает с ошибками парсинга, кириллица в выводе битая.
**Причина:** Windows PowerShell 5.1 читает `.ps1` без BOM как cp1251, а не UTF-8.
**Решение:** файл в репозитории сохранён в **UTF-8 с BOM** — этого достаточно. Если правишь скрипт своим редактором, сохраняй обратно в UTF-8 с BOM (или запускай через PowerShell 7+, который понимает UTF-8 без BOM).

### 2. hashcat/openssl не в PATH

**Симптом:** `hashcat: command not found` / `openssl: command not found`.
**Причина:** Scoop кладёт shim'ы в `~\scoop\shims`, но сессия PowerShell может их не видеть.
**Решение:** скрипт сам ищет exe в типовых местах Scoop. Если не нашёл — впиши полный путь к `hashcat.exe` в переменную `$Hashcat` в начале скрипта.

### 3. hashcat не находит OpenCL/ (главная грабля)

**Симптом:** `Cannot find kernel` / падение сразу после старта, если скрипт уводит рабочую папку.
**Причина:** hashcat ищет `OpenCL/`, `modules/`, `hashcat.hcstat2` **относительно текущей папки**, а не относительно exe. Если сделать `cd` в рабочую папку — он их не находит.
**Решение:** скрипт запускает hashcat **из его собственной папки** (`Push-Location`), а файлы хешей и словаря передаёт **абсолютными путями**. Junction-и (как временный костыль) больше не нужны.

> Важно: указывай путь к **настоящему** `hashcat.exe` (`~\scoop\apps\hashcat\current\`), а не к shim-обёртке Scoop (`~\scoop\shims\`) — рядом с shim нет папки `OpenCL/`.

### 4. Две видеокарты (NVIDIA + Intel UHD)

**Симптом:** в выводе две строки `Speed`, iGPU занижает результат.
**Причина:** hashcat по умолчанию берёт все устройства.
**Решение:** посмотри номера устройств через `hashcat -I`, выбери нужное флагом `-d`:

```powershell
hashcat -b -m 1400 -d 1        # только устройство №1 (например, RTX 3060)
```

### 5. CUDA SDK Toolkit not installed

**Симптом:** предупреждение `CUDA SDK Toolkit not installed... disabled`, hashcat идёт через OpenCL.
**Причина:** без CUDA Toolkit CUDA-бэкенд hashcat выключен.
**Решение:** не критично (OpenCL работает), но на NVIDIA **CUDA-бэкенд обычно быстрее** (+5–15 %). Поставь [CUDA Toolkit](https://developer.nvidia.com/cuda-downloads) — hashcat'у нужен рантайм (`nvrtc`/`cudart`), полный SDK для компиляции не обязателен. Это ~3 ГБ и перезагрузка.

## 🍎 macOS

- Metal в hashcat auto-skip в пользу OpenCL — это нормально, OpenCL тут даже чуть быстрее.
- `openssl passwd -5` на системном LibreSSL может не поддерживаться (`unknown option '-5'`). Тогда ставь `brew install openssl` или считай sha256crypt через Python `passlib`.

## 🐧 Linux

- Для NVIDIA нужен проприетарный драйвер + CUDA/OpenCL (см. [`RENTAL.md`](RENTAL.md)).
- `hashcat` из репозиториев дистрибутива бывает старым — для Argon2 (режим 34000) нужен hashcat ≥ 7.0.
