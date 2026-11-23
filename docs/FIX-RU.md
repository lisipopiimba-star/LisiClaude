# LisiOS: почему не запускалась фирменная оболочка и что исправлено

## Причины (подтверждены по исходникам Quickshell v0.3.2 и Hyprland v0.57.2 / v0.56.2)

1. **`shell.qml` не импортировал `Quickshell.Io`.** `IpcHandler` объявлен в модуле `Quickshell.Io` (src/io/ipchandler.hpp),
   отсюда «IpcHandler is not a type». При ошибке первой загрузки Quickshell завершается (rootwrapper.cpp) - оболочки нет.
2. **Hyprland 0.57+ не читает `hyprland.conf`** (только Lua). Тогда `exec-once = lisios-shell` не выполняется вообще,
   горячие клавиши и правила окон тоже не применяются.
3. **`misc { vfr = true }`** - такой опции в `misc` нет (в 0.56.2 и 0.57.2 она `debug:vfr`) - ошибка конфигурации и красная плашка Hyprland.
4. **Запуск `Hyprland` напрямую** вместо `start-hyprland` - Hyprland рисует свою плашку поверх рабочего стола.
5. **Диспетчеры окон** (`killactive`, `fullscreen 1`, `exit`) в 0.57 не работают - нужны Lua-выражения (`hl.dsp.window.close()` и т.д.).
   Кнопки красная/жёлтая/зелёная и «Выйти» в Центре управления теперь идут через `cfg.wm()`, который выбирает синтаксис.

Остальные QML-типы (PanelWindow, WlrLayershell, ToplevelManager, Hyprland, FileView, Process, NotificationServer, DesktopEntries,
IconImage, SystemClock, ScriptModel) сверены с исходниками - совместимы. Дизайн и компоненты не менялись и не удалялись.

## Изменённые и новые файлы (пути относительно корня проекта)

| Файл | Что сделано |
|---|---|
| profile/airootfs/usr/share/lisios/shell/shell.qml | `import Quickshell.Io`; id `cfgObj`/`statusObj` вместо совпадающих с именами свойств |
| .../shell/Cfg.qml | `import Quickshell.Hyprland`, `hyprLua`, функция `wm(action)` |
| .../shell/TopBar.qml, ControlCenter.qml | кнопки окон и «Выйти» через `cfg.wm()` |
| profile/airootfs/usr/local/bin/lisios-shell | одна копия, перезапуск при падении, откат на штатную оболочку, `ipc`, `--check`, журнал |
| profile/airootfs/usr/local/bin/lisios-session | выбор формата Hyprland по версии, `start-hyprland`, Lua-правила, страховочный автозапуск оболочки |
| profile/airootfs/usr/share/lisios/hypr/lisios.lua и lisios-animations.lua (новые; копии в etc/skel/.config/hypr) | конфигурация для Hyprland 0.57+ |
| .../hypr/lisios-animations.lua (новый) | анимации для Lua |
| .../hypr/hyprland.conf | убран `vfr`, клавиша лаунчера через `lisios-shell ipc` |
| profile/airootfs/usr/lib/lisios/settings/settings.py | при смене скорости пишет и `.conf`, и `.lua` |
| scripts/check-shell.py (новый) | проверка импортов QML без Qt |
| scripts/live-patch.sh (новый) | установка исправлений в запущенную систему |
| scripts/build-in-container.sh | `*.lua` в правке CRLF, проверка QML перед mkarchiso, вывод версий hyprland/quickshell |

## Установка

**Вариант А - пересборка:** замените файлы проекта содержимым архива (структура папок совпадает) и запустите сборку как обычно.
Сборка теперь остановится, если QML не проходит проверку.

**Вариант Б - без пересборки (в виртуалке с Live-ISO):**
1. Передайте архив в ВМ (общая папка или `python -m http.server` на хосте + `curl`), распакуйте.
2. В терминале LisiOS: `bash scripts/live-patch.sh`
3. Выйдите из сессии и войдите снова (при автологине сессия перезапустится сама) - применится выбор конфигурации Hyprland.

## Тестирование без пересборки ISO

- На любой машине (даже Windows): `python scripts/check-shell.py profile/airootfs/usr/share/lisios/shell` - на исходной версии выдаёт
  «IpcHandler требует import Quickshell.Io», на исправленной - 0 ошибок.
- В системе с Quickshell: `pkill quickshell; lisios-shell --check` - запускает оболочку на 10 с и ищет ошибки в журнале.
- Быстрая правка QML на лету: положите копию в `~/.config/lisios/shell/` - `lisios-shell` использует её, а при падении сам вернётся к штатной.
- Журналы: `~/.cache/lisios/session.log`, `shell.log`, `hypr-lua.log`.

## Чего я не мог проверить
Саму загрузку QML в Quickshell и запуск Hyprland я в этой среде выполнить не мог (нет Qt/Wayland/сети для pacman).
Проверено сверкой с исходниками, статическим скриптом, `bash -n` и py_compile. Первый запуск в ВМ - обязательный шаг:
пришлите `~/.cache/lisios/*.log`, если что-то не заработает.

---

## LisiOS Game Mode (добавлено)

Запуск: приложение «LisiOS Game Mode» (`lisios-gamemode gui`) или плитка «Game Mode» в Control Center (шестерёнка на плитке открывает окно). Командная строка: `lisios-gamemode status|on|off|toggle|auto on|off|add ИМЯ ФАЙЛ|remove ИМЯ|restore`.

| Файл | Назначение |
|---|---|
| `usr/lib/lisios/gamemode/core.py` | настройки (`~/.config/lisios/gamemode.json`), поиск процессов игр, демон, CLI. Работает от обычного пользователя |
| `usr/lib/lisios/gamemode/helper.py` | единственный root-компонент (через `pkexec`): только процессы вызвавшего пользователя; игры nice -4, фон nice +5 (максимум +10) и только при загрузке CPU >= 65 %; критичные службы и предки игры не трогаются; исходные nice хранятся в `/run/lisios-gamemode/<uid>.json` |
| `usr/share/polkit-1/actions/org.lisios.gamemode.policy` | разрешает запускать helper.py активной локальной сессии без пароля |
| `usr/lib/lisios/gamemode/app.py`, `games.py` | окно PyQt6, поиск установленных игр (.desktop с категорией Game, манифесты Steam) |
| `usr/local/bin/lisios-gamemode`, `usr/share/applications/lisios-gamemode.desktop` | команда и ярлык |
| `shell/Status.qml`, `ControlCenter.qml`, `Cfg.qml`, `status.sh` | плитка в Control Center |

Как это работает: демон (`lisios-gamemode ensure` запускается из конфигурации Hyprland) раз в 2 с ищет процессы выбранных игр (до трёх) и их потомков. Если режим включён вручную или включено «автоматически», а игра запущена, он вызывает helper. Закрытие или падение игры -> через 5 с приоритеты возвращаются. Выключение режима, SIGTERM демона и `lisios-gamemode restore` тоже возвращают всё как было; при следующем старте демон сам откатывает остатки после сбоя.

Чего нет: cgroups v2 / жёстких лимитов CPU. Перенос чужих процессов между cgroup'ами, которыми управляет systemd, небезопасен, поэтому используются веса планировщика (nice), которые перераспределяют CPU только при нехватке и ничего не ограничивают жёстко. Приоритет ввода-вывода не меняется.
