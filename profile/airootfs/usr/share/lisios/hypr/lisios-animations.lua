-- Значения по умолчанию (скорость 1.0). «Системные настройки» перезаписывают этот файл.
-- Lua-вариант для Hyprland 0.57+ (аналог lisios-animations.conf).
hl.curve("smooth", { type = "bezier", points = { {0.22, 1.0},  {0.36, 1.0} } })
hl.curve("pop",    { type = "bezier", points = { {0.34, 1.35}, {0.64, 1.0} } })

hl.animation({ leaf = "windowsIn",        enabled = true, speed = 5, bezier = "pop",    style = "popin 80%" })
hl.animation({ leaf = "windowsOut",       enabled = true, speed = 4, bezier = "smooth", style = "popin 80%" })
hl.animation({ leaf = "windowsMove",      enabled = true, speed = 4, bezier = "smooth" })
hl.animation({ leaf = "fade",             enabled = true, speed = 5, bezier = "smooth" })
hl.animation({ leaf = "border",           enabled = true, speed = 8, bezier = "smooth" })
hl.animation({ leaf = "workspaces",       enabled = true, speed = 6, bezier = "smooth", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 5, bezier = "smooth", style = "slidevert" })
