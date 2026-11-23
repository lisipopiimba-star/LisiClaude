#!/usr/bin/python3 -I
"""Привилегированный помощник LisiOS Game Mode. Запускается через pkexec (root), ничего не читает из
пользовательских файлов и умеет ровно три вещи:

  apply --games PID,PID,... [--throttle] [--protect имя,имя]   применить приоритеты
  restore                                                      вернуть всё как было
  status                                                       показать, что сейчас изменено

Что он делает с процессами ТОЛЬКО того пользователя, который вызвал pkexec (PKEXEC_UID):
  * игровые процессы (их список передаёт демон)   -> nice -4 (не меньше -5, реального времени нет);
  * остальные пользовательские процессы           -> nice +5 (не выше +10), только с --throttle,
    то есть когда процессору реально не хватает;
  * критичные службы (Hyprland, Quickshell, PipeWire, WirePlumber, NetworkManager, D-Bus, Xwayland, polkit,
    предки игры, программы из protect) не трогаются никогда;
  * процессы root и других пользователей не трогаются вообще.
Исходные значения nice хранятся в /run/lisios-gamemode/<uid>.json, поэтому `restore` возможен всегда,
в том числе после аварийного завершения демона. Никаких жёстких лимитов CPU, cgroup и убийства процессов нет.
"""
import fcntl
import json
import os
import sys

STATE_DIR = "/run/lisios-gamemode"
GAME_NICE = -4
BG_STEP = 5
BG_MAX = 10

CRITICAL_PREFIX = ("hyprland", "start-hyprland", "quickshell", "pipewire", "wireplumber", "networkmanager", "nm-",
                   "dbus", "systemd", "(sd-pam)", "polkit", "hyprpolkitagent", "xwayland", "pulseaudio", "bluetoothd",
                   "udisks", "upower", "xdg-", "gvfs", "gnome-keyring", "login", "agetty", "lisios-", "gamemode",
                   "wpa_supplicant", "rtkit", "kwin", "mutter")


def die(msg, code=1):
    print(json.dumps({"ok": False, "error": msg}))
    sys.exit(code)


def read_stat(path):
    """-> (comm, ppid, nice, start) или None"""
    try:
        s = open(path).read()
    except OSError:
        return None
    a = s.rfind(")")
    if a < 0:
        return None
    comm = s[s.find("(") + 1:a]
    f = s[a + 2:].split()
    try:
        return comm, int(f[1]), int(f[16]), int(f[19])
    except (IndexError, ValueError):
        return None


def is_critical(comm, protect):
    c = comm.lower()
    return c.startswith(CRITICAL_PREFIX) or any(p and p in c for p in protect)


def load_state(uid):
    try:
        return json.load(open(os.path.join(STATE_DIR, "%d.json" % uid)))
    except (OSError, ValueError):
        return {}


def save_state(uid, st):
    os.makedirs(STATE_DIR, mode=0o755, exist_ok=True)
    p = os.path.join(STATE_DIR, "%d.json" % uid)
    if not st:
        try:
            os.remove(p)
        except OSError:
            pass
        return
    tmp = p + ".tmp"
    with open(tmp, "w") as f:
        json.dump(st, f)
    os.replace(tmp, p)


def setnice(tid, value):
    try:
        os.setpriority(os.PRIO_PROCESS, tid, value)
        return True
    except OSError:
        return False


def restore_entries(st, only=None):
    n = 0
    for tid in list(st):
        e = st[tid]
        if only is not None and tid not in only:
            continue
        cur = read_stat("/proc/%s/stat" % e["pid"])   # старт процесса (у потоков тот же PID-владелец)
        if cur and cur[3] == e["start"] and os.path.exists("/proc/%s/task/%s" % (e["pid"], tid)):          # тот же процесс, а не новый с повторно использованным PID
            if setnice(int(tid), e["nice"]):
                n += 1
        del st[tid]
    return n


def cmd_restore(uid):
    st = load_state(uid)
    n = restore_entries(st)
    save_state(uid, {})
    return {"ok": True, "restored": n}


def cmd_apply(uid, games, throttle, protect):
    st = load_state(uid)
    procs = {}
    for d in os.listdir("/proc"):
        if not d.isdigit():
            continue
        try:
            if os.stat("/proc/" + d).st_uid != uid:
                continue
        except OSError:
            continue
        s = read_stat("/proc/%s/stat" % d)
        if s:
            procs[int(d)] = s

    # игровые процессы: только свои, не критичные
    gset = {p for p in games if p in procs and not is_critical(procs[p][0], ())}
    # предки игры (лаунчер, сессия) не трогаем
    keep = set()
    for p in gset:
        q = procs[p][1]
        while q in procs and q not in keep:
            keep.add(q)
            q = procs[q][1]

    seen = set()
    boosted = throttled = 0
    for pid, (comm, ppid, _nice, start) in procs.items():
        if pid in gset:
            role = "game"
        elif pid in keep or is_critical(comm, protect):
            role = "keep"
        else:
            role = "bg"
        try:
            tids = [int(t) for t in os.listdir("/proc/%d/task" % pid)]
        except OSError:
            continue
        for tid in tids:
            key = str(tid)
            ts = read_stat("/proc/%d/task/%d/stat" % (pid, tid))
            if not ts:
                continue
            cur = ts[2]
            seen.add(key)
            ent = st.get(key)
            if ent and ent["start"] != start:
                ent = None                      # PID переиспользован
                st.pop(key, None)
            if role == "keep":
                if ent:
                    restore_entries(st, {key})
                continue
            if role == "game":
                target = max(-5, GAME_NICE)
            elif throttle:
                orig = ent["nice"] if ent else cur
                if orig < 0 or orig >= BG_MAX:
                    if ent:
                        restore_entries(st, {key})
                    continue
                target = min(orig + BG_STEP, BG_MAX)
            else:
                if ent:
                    restore_entries(st, {key})
                continue
            if not ent:
                orig = cur
                # новый процесс/поток унаследовал nice от родителя, которого изменили мы -> настоящий исходный nice у родителя
                for parent in (str(ppid), str(pid)):
                    pe = st.get(parent)
                    if pe and pe["set"] == cur and parent != key:
                        orig = pe["nice"]
                        break
                st[key] = {"pid": pid, "nice": orig, "start": start, "set": target}
            if cur != target and setnice(tid, target):
                if role == "game":
                    boosted += 1
                else:
                    throttled += 1
            st[key]["set"] = target
    # записи о процессах, которых больше нет
    for key in list(st):
        if key not in seen:
            del st[key]
    save_state(uid, st)
    return {"ok": True, "game_threads": sum(1 for e in st.values() if e["set"] < 0),
            "throttled_threads": sum(1 for e in st.values() if e["set"] > 0),
            "changed": boosted + throttled}


def main():
    try:
        uid = int(os.environ.get("PKEXEC_UID", ""))
    except ValueError:
        die("запускать только через pkexec")
    if uid == 0:
        die("для root не применяется")
    if len(sys.argv) < 2:
        die("команда: apply | restore | status")
    os.makedirs(STATE_DIR, mode=0o755, exist_ok=True)
    lock = open(os.path.join(STATE_DIR, "%d.lock" % uid), "w")
    fcntl.flock(lock, fcntl.LOCK_EX)
    c = sys.argv[1]
    if c == "restore":
        out = cmd_restore(uid)
    elif c == "status":
        out = {"ok": True, "entries": len(load_state(uid))}
    elif c == "apply":
        a = sys.argv[2:]
        games, protect, thr = [], [], "--throttle" in a
        if "--games" in a:
            games = [int(x) for x in a[a.index("--games") + 1].split(",") if x.isdigit()][:512]
        if "--protect" in a:
            protect = [x.lower() for x in a[a.index("--protect") + 1].split(",") if x][:32]
        out = cmd_apply(uid, games, thr, protect)
    else:
        die("неизвестная команда")
    print(json.dumps(out))


if __name__ == "__main__":
    main()
