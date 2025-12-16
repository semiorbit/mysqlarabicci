# Developer Notes (DEV.md)

## Purpose of this document

This document is for **maintainers and contributors**, not end users.

It explains:
- non-obvious design decisions
- platform-specific steps
- things that must be done **once** and then never repeated
- pitfalls when working from Windows for a Linux-targeted tool

If you are only installing or using `mysqlarabicci`, **read README.md instead**.

---

## Repository is Linux-targeted, development may happen on Windows

This project is intended to run on **Linux servers** (systemd, MySQL, bash),
but it may be **developed on Windows**.

Because of that, two things must be handled carefully:
1. **Executable permissions**
2. **Line endings**

---

## Executable permissions on Windows (IMPORTANT)

### Problem

Windows does **not** support Unix executable permissions (`chmod +x`).

However, Linux **requires** executable permissions for scripts like:
- `install.sh`
- `mysqlarabicci`
- internal helper scripts

### Solution

Git stores executable permissions **in the repository**, not in the filesystem.

So we must explicitly tell Git which files are executable.

This is done **once**, using **Git Bash**, not CMD or PowerShell.

---

## One-time Git Bash commands (already done)

From **Git Bash**, at the repository root:

```bash
git update-index --chmod=+x install.sh
git update-index --chmod=+x src/installer/install.sh
git update-index --chmod=+x src/installer/uninstall.sh
git update-index --chmod=+x src/bin/mysqlarabicci
git update-index --chmod=+x src/lib/detect_mysql.sh
git update-index --chmod=+x src/lib/inject.sh
git update-index --chmod=+x src/lib/reject.sh
```

Then commit:

```bash
git commit -m "Mark scripts executable"
git push
```

### Result

- Git now tracks these files with mode `100755`
- Any Linux user cloning the repo gets executable scripts automatically
- **No `chmod` is required on Linux**
- This step does **NOT** need to be repeated unless new scripts are added

---

## How to verify executable bits

From Git Bash:

```bash
git ls-files --stage | grep install.sh
```

Expected output contains:

```
100755 install.sh
```

If `100644` appears, the file is **not executable**.

---

## Windows paths vs Git Bash paths (common pitfall)

In Git Bash:
- `C:\` → `/c/`
- `D:\` → `/d/`
- `E:\` → `/e/`

Example:

```bash
cd /e/Projects/www/semiorbit/linux-packages/mysqlarabicci
```

Using `E:\Projects\...` in Git Bash will fail.

---

## Line endings (CRLF vs LF)

All shell scripts **must use LF**, not CRLF.

Rules:
- PhpStorm line endings: **LF**
- `.gitattributes` enforces LF for `.sh` files
- Never commit CRLF shell scripts

CRLF can cause errors like:

```
/bin/bash^M: bad interpreter
```

---

## Why we do NOT rely on chmod in install scripts

The installer **assumes scripts are already executable**.

This is intentional:
- Avoids fragile runtime chmod hacks
- Keeps install logic clean
- Works consistently with RPM/DNF packaging later

---

## Design philosophy reminder

- Detection scripts are **read-only**
- Installers and CLI commands are **controllers**
- systemd watchers are **dumb and deterministic**
- Configuration is written once and trusted

Do not blur these responsibilities.

---

## If you add a new shell script

You MUST:
1. Ensure LF line endings
2. Mark it executable in Git:

```bash
git update-index --chmod=+x path/to/script.sh
git commit -m "Make new script executable"
```


