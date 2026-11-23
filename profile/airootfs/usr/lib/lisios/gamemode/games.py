"""Поиск установленных игр: .desktop-файлы с категорией Game и манифесты Steam."""
import configparser
import glob
import os
import re
import shlex

HOME = os.path.expanduser("~")
APP_DIRS = ["/usr/share/applications", HOME + "/.local/share/applications", "/var/lib/flatpak/exports/share/applications",
            HOME + "/.local/share/flatpak/exports/share/applications"]
STEAM_ROOTS = [HOME + "/.local/share/Steam", HOME + "/.steam/steam", HOME + "/.var/app/com.valvesoftware.Steam/.local/share/Steam"]
SKIP_STEAM = ("proton", "steam linux runtime", "steamworks", "steamvr")
WRAP = {"env", "gamemoderun", "mangohud", "prime-run", "nice", "ionice", "taskset"}


def _exec_target(line):
    try:
        parts = shlex.split(re.sub(r"%[a-zA-Z]", "", line))
    except ValueError:
        return {}
    while parts and (parts[0] in WRAP or "=" in parts[0].split("/")[0]):
        parts = parts[1:]
    if not parts:
        return {}
    if os.path.basename(parts[0]) == "flatpak" and "run" in parts:
        app = [p for p in parts[parts.index("run") + 1:] if not p.startswith("-")]
        return {"match": app[:1]} if app else {}
    return {"exec": parts[0]}


def steam_games():
    libs = set()
    for r in STEAM_ROOTS:
        if os.path.isdir(r + "/steamapps"):
            libs.add(r + "/steamapps")
            try:
                for m in re.findall(r'"path"\s+"([^"]+)"', open(r + "/steamapps/libraryfolders.vdf", errors="ignore").read()):
                    libs.add(m + "/steamapps")
            except OSError:
                pass
    out = []
    for lib in sorted(libs):
        for mf in glob.glob(lib + "/appmanifest_*.acf"):
            try:
                t = open(mf, errors="ignore").read()
                name = re.search(r'"name"\s+"([^"]+)"', t).group(1)
                inst = re.search(r'"installdir"\s+"([^"]+)"', t).group(1)
            except (OSError, AttributeError):
                continue
            if name.lower().startswith(SKIP_STEAM):
                continue
            out.append({"name": name + " (Steam)", "exec": "", "match": ["/steamapps/common/" + inst]})
    return out


def installed(lang="ru"):
    res, seen = [], set()
    for d in APP_DIRS:
        for f in glob.glob(d + "/*.desktop"):
            cp = configparser.RawConfigParser(strict=False, interpolation=None)
            cp.optionxform = str
            try:
                cp.read(f, encoding="utf-8")
                e = cp["Desktop Entry"]
            except (configparser.Error, KeyError, OSError, UnicodeDecodeError):
                continue
            if "Game" not in (e.get("Categories", "").split(";")) or e.get("NoDisplay", "").lower() == "true":
                continue
            name = e.get("Name[%s]" % lang) or e.get("Name")
            tgt = _exec_target(e.get("Exec", ""))
            if not name or not tgt or name in seen or "steam://" in e.get("Exec", ""):
                continue
            seen.add(name)
            res.append({"name": name, "exec": tgt.get("exec", ""), "match": tgt.get("match", [])})
    for g in steam_games():
        if g["name"] not in seen:
            seen.add(g["name"])
            res.append(g)
    return sorted(res, key=lambda g: g["name"].lower())
