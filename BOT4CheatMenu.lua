local options = {
    ESP = true,
    Armor = true,
    HP = true,
    Ammo = true,
    Name = true,
    Bunnyhop = false,
    ESPColor = Color(0, 255, 255, 255),
    AIM_SNAPLINE = true,
    NoSpread = false,
    NoRecoil = false,

    -- AIMBOT
    AIM = true,
    AIM_FOV = 30,
    AIM_SHOWCIRCLE = true,
    AIM_HITBOX = "head",
    AIM_KEY = MOUSE_LEFT,
    AIM_AUTOSHOOT = false,
    AIM_PREDICTION = false,
    AIM_BULLETSPEED = 10000,
    FOVColor = Color(255, 0, 0, 255),
    SnaplineColor = Color(0, 255, 255, 255),
}

options.HPMode = "BAR+TEXT"
options.ArmorMode = "BAR+TEXT"

local fontCache = {}

local function GetDynamicFont(baseName, size)
    local fontName = baseName .. tostring(size)
    if not fontCache[fontName] then
        surface.CreateFont(fontName, {
            font = "Tahoma",
            size = size,
            weight = 700,
            antialias = true,
        })
        fontCache[fontName] = true
    end
    return fontName
end

hook.Add("HUDPaint", "BOT4_AllBarsAndESP", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    for _, target in ipairs(player.GetAll()) do
        if target == ply or not IsValid(target) or not target:Alive() then continue end

        local dist = ply:GetPos():Distance(target:GetPos())
        if dist > 5000 then continue end

        local mins, maxs = target:GetModelBounds()
        if not mins or not maxs then continue end

        local corners = {
            Vector(mins.x, mins.y, mins.z),
            Vector(mins.x, mins.y, maxs.z),
            Vector(mins.x, maxs.y, mins.z),
            Vector(mins.x, maxs.y, maxs.z),
            Vector(maxs.x, mins.y, mins.z),
            Vector(maxs.x, mins.y, maxs.z),
            Vector(maxs.x, maxs.y, mins.z),
            Vector(maxs.x, maxs.y, maxs.z),
        }
        local minX, minY = math.huge, math.huge
        local maxX, maxY = -math.huge, -math.huge
        local screenPoints = {}
        for i = 1, 8 do
            local world = target:LocalToWorld(corners[i])
            local screen = world:ToScreen()
            screenPoints[i] = screen
            if screen.visible then
                minX = math.min(minX, screen.x)
                minY = math.min(minY, screen.y)
                maxX = math.max(maxX, screen.x)
                maxY = math.max(maxY, screen.y)
            end
        end

        local scale = math.Clamp(400 / dist, 0.5, 1.0)

        -- ESP
        if options.ESP then
            local boxPad = 2
            minX = minX - boxPad
            maxX = maxX + boxPad
            minY = minY - boxPad
            maxY = maxY + boxPad

            local boxHeight = maxY - minY
            local len = math.Clamp(boxHeight * 0.11, 8, boxHeight * 0.33)
            local thick = 3

            local function FatLine(x1, y1, x2, y2, w, color)
                surface.SetDrawColor(color)
                for i = -math.floor(w/2), math.floor(w/2) do
                    surface.DrawLine(x1 + i, y1, x2 + i, y2)
                    surface.DrawLine(x1, y1 + i, x2, y2 + i)
                end
            end

            FatLine(minX, minY, minX + len, minY, thick, Color(0,0,0,255))
            FatLine(minX, minY, minX, minY + len, thick, Color(0,0,0,255))
            FatLine(maxX, minY, maxX - len, minY, thick, Color(0,0,0,255))
            FatLine(maxX, minY, maxX, minY + len, thick, Color(0,0,0,255))
            FatLine(minX, maxY, minX + len, maxY, thick, Color(0,0,0,255))
            FatLine(minX, maxY, minX, maxY - len, thick, Color(0,0,0,255))
            FatLine(maxX, maxY, maxX - len, maxY, thick, Color(0,0,0,255))
            FatLine(maxX, maxY, maxX, maxY - len, thick, Color(0,0,0,255))

            local espCol = options.ESPColor or Color(0,255,255,255)
            surface.SetDrawColor(espCol)
            surface.DrawLine(minX, minY, minX + len, minY)
            surface.DrawLine(minX, minY, minX, minY + len)
            surface.DrawLine(maxX, minY, maxX - len, minY)
            surface.DrawLine(maxX, minY, maxX, minY + len)
            surface.DrawLine(minX, maxY, minX + len, maxY)
            surface.DrawLine(minX, maxY, minX, maxY - len)
            surface.DrawLine(maxX, maxY, maxX - len, maxY)
            surface.DrawLine(maxX, maxY, maxX, maxY - len)
        end

        -- HP Bar
        if options.HP then
            local hp = target:Health()
            local maxHp = target.GetMaxHealth and target:GetMaxHealth() or 100
            local barHeight = math.max(maxY - minY, 10)
            local barWidth = math.Clamp(math.floor(4 * scale), 2, 8)
            local x = minX - barWidth - math.floor(8 * scale)
            local y = minY
            local fillHeight = math.Clamp((hp / maxHp) * barHeight, 0, barHeight)
            local fontSize = math.Clamp(math.floor(18 * scale), 10, 18)
            local fontName = GetDynamicFont("HPBarFontDynamic", fontSize)

            if options.HPMode == "BAR" or options.HPMode == "BAR+TEXT" then
                surface.SetDrawColor(0, 0, 0, 255)
                surface.DrawOutlinedRect(x, y, barWidth, barHeight)
                surface.SetDrawColor(0, 255, 0, 255)
                surface.DrawRect(x + 1, y + barHeight - fillHeight + 1, barWidth - 2, fillHeight - 2)
            end

            if options.HPMode == "TEXT" or options.HPMode == "BAR+TEXT" then
                draw.SimpleTextOutlined(
                    tostring(hp),
                    fontName,
                    x - math.floor(8 * scale),
                    y + barHeight / 2,
                    Color(0, 255, 0, 255),
                    TEXT_ALIGN_RIGHT,
                    TEXT_ALIGN_CENTER,
                    2,
                    Color(0,0,0,255)
                )
            end
        end

        -- Armor Bar
        if options.Armor then
            local armor = target:Armor()
            local maxArmor = target.GetMaxArmor and target:GetMaxArmor() or 100
            local barHeight = math.max(maxY - minY, 10)
            local barWidth = math.Clamp(math.floor(4 * scale), 2, 8)
            local x = maxX + 6
            local y = minY
            local fillHeight = math.Clamp((armor / maxArmor) * barHeight, 0, barHeight)
            local fontSize = math.Clamp(math.floor(18 * scale), 10, 18)
            local fontName = GetDynamicFont("ArmorBarFontDynamic", fontSize)

            if options.ArmorMode == "BAR" or options.ArmorMode == "BAR+TEXT" then
                surface.SetDrawColor(0, 0, 0, 255)
                surface.DrawOutlinedRect(x, y, barWidth, barHeight)
                surface.SetDrawColor(0, 128, 255, 255)
                surface.DrawRect(x + 1, y + barHeight - fillHeight + 1, barWidth - 2, fillHeight - 2)
            end

            if options.ArmorMode == "TEXT" or options.ArmorMode == "BAR+TEXT" then
                draw.SimpleTextOutlined(
                    tostring(armor),
                    fontName,
                    x + barWidth + math.floor(6 * scale),
                    y + barHeight / 2,
                    Color(0, 128, 255, 255),
                    TEXT_ALIGN_LEFT,
                    TEXT_ALIGN_CENTER,
                    2,
                    Color(0,0,0,255)
                )
            end
        end

        -- Ammo Bar
        if options.Ammo then
            local boxWidth = maxX - minX
            local barWidth = math.Clamp(boxWidth * 0.8 * scale, 24 * scale, boxWidth)
            local barHeight = math.Clamp(8 * scale, 4, 12)
            local barX = minX + (boxWidth - barWidth) / 2
            local barY = maxY + 8

            local wep = target:GetActiveWeapon()
            local ammo = IsValid(wep) and wep:Clip1() or 0
            local maxAmmo = IsValid(wep) and wep:GetMaxClip1() or 100
            local ammoFrac = (maxAmmo > 0) and math.Clamp(ammo / maxAmmo, 0, 1) or 0

            local fontSize = math.Clamp(math.floor(18 * scale), 10, 18)
            local fontName = GetDynamicFont("AmmoBarFontDynamic", fontSize)

            surface.SetDrawColor(0, 0, 0, 255)
            surface.DrawRect(barX, barY, barWidth * ammoFrac, barHeight)
            surface.SetDrawColor(0, 0, 0, 255)
            surface.DrawOutlinedRect(barX, barY, barWidth, barHeight)

            draw.SimpleTextOutlined(
                ammo,
                fontName,
                barX + barWidth / 2,
                barY + barHeight / 2,
                Color(0, 128, 255, 255),
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER,
                2,
                Color(0,0,0,255)
            )
        end

        -- Name
        if options.Name then
            local name = target:Name()
            local fontSize = math.Clamp(math.floor(18 * scale), 10, 18)
            local fontName = GetDynamicFont("NameFontDynamic", fontSize)
            draw.SimpleTextOutlined(
                name,
                fontName,
                (minX + maxX) / 2,
                minY - math.floor(10 * scale),
                Color(255, 255, 0, 255),
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_BOTTOM,
                2,
                Color(0,0,0,255)
            )
        end
    end
end)

-- AIMBOT DATA
local aim_hitbox_bones = {
    head = "ValveBiped.Bip01_Head1",
    body = "ValveBiped.Bip01_Spine2"
}
local aim_key_names = {
    [MOUSE_LEFT] = "LMB",
    [MOUSE_RIGHT] = "RMB",
    [KEY_LALT] = "Left Alt",
}
local aim_key_values = {
    ["LMB"] = MOUSE_LEFT,
    ["RMB"] = MOUSE_RIGHT,
    ["Left Alt"] = KEY_LALT,
}

local function GetAimHitboxPos(ply)
    local bone = ply:LookupBone(aim_hitbox_bones[options.AIM_HITBOX])
    if not bone then return nil end
    local pos, _ = ply:GetBonePosition(bone)
    return pos
end

local function PredictAimPos(target, from)
    if not options.AIM_PREDICTION then return GetAimHitboxPos(target) end
    local pos = GetAimHitboxPos(target)
    if not pos then return nil end
    local vel = target:GetVelocity()
    local dist = pos:Distance(from)
    local time = dist / options.AIM_BULLETSPEED
    return pos + vel * time
end

local function GetBestAimTarget()
    local bestTarget = nil
    local lowestFov = options.AIM_FOV
    local ply = LocalPlayer()
    local eyeAng = ply:EyeAngles()

    for _, target in ipairs(player.GetAll()) do
        if target == ply or not target:Alive() or not target:IsPlayer() then continue end

        local predPos = PredictAimPos(target, ply:EyePos())
        if not predPos then continue end

        local dir = (predPos - ply:EyePos()):Angle()
        local yawDiff = math.AngleDifference(eyeAng.yaw, dir.yaw)
        local pitchDiff = math.AngleDifference(eyeAng.pitch, dir.pitch)
        local totalDiff = math.sqrt(yawDiff ^ 2 + pitchDiff ^ 2)

        if totalDiff < lowestFov then
            lowestFov = totalDiff
            bestTarget = target
        end
    end

    return bestTarget
end

local function IsAimingAtTarget(target)
    if not IsValid(target) or not target:Alive() then return false end
    local ply = LocalPlayer()
    local eyePos = ply:EyePos()
    local aimVec = ply:GetAimVector()
    local hitboxPos = PredictAimPos(target, eyePos)
    if not hitboxPos then return false end

    local dir = (hitboxPos - eyePos):GetNormalized()
    local dot = aimVec:Dot(dir)
    return dot > 0.999
end

-- AIMBOT LOGIC
local lastAimedTarget = nil
local lastAttackTime = 0

hook.Add("Think", "BOT4_AimbotLogic", function()
    if not options.AIM then return end

    local key_down = (options.AIM_KEY >= MOUSE_LEFT and options.AIM_KEY <= MOUSE_LAST)
        and input.IsMouseDown(options.AIM_KEY)
        or input.IsKeyDown(options.AIM_KEY)

    local target = GetBestAimTarget()

    if not key_down and not options.AIM_AUTOSHOOT then
        RunConsoleCommand("-attack")
        lastAimedTarget = nil
        return
    end

    if IsValid(target) then
        local predPos = PredictAimPos(target, LocalPlayer():EyePos())
        if predPos then
            local ang = (predPos - LocalPlayer():EyePos()):Angle()
            LocalPlayer():SetEyeAngles(ang)
        end
    end

    if options.AIM_AUTOSHOOT then
    if IsValid(target) and IsAimingAtTarget(target) and target:Alive() and IsTargetVisible(target) then
        if lastAimedTarget ~= target or CurTime() - lastAttackTime > 0.25 then
            RunConsoleCommand("+attack")
            timer.Simple(0.03, function() RunConsoleCommand("-attack") end)
            lastAimedTarget = target
            lastAttackTime = CurTime()
        end
    else
        RunConsoleCommand("-attack")
        lastAimedTarget = nil
    end
end
end)

-- FOV CIRCLE
hook.Add("HUDPaint", "BOT4_AimFOVCircle", function()
    if not options.AIM or not options.AIM_SHOWCIRCLE then return end
    local scrW, scrH = ScrW(), ScrH()
    local radius = math.tan(math.rad(options.AIM_FOV / 2)) * scrW / 2
    local col = options.FOVColor or Color(255, 0, 0, 255)
    surface.SetDrawColor(col)
    surface.DrawCircle(scrW / 2, scrH / 2, radius, col.r, col.g, col.b, col.a)
end)

-- === AIMBOT SUBMENU ===
local function OpenAIMSubMenu()
    if IsValid(_aim_submenu) then _aim_submenu:Remove() end
    _aim_submenu = vgui.Create("DFrame")
    _aim_submenu:SetTitle("AIM Settings")
    _aim_submenu:SetSize(300, 480) 
    _aim_submenu:Center()
    _aim_submenu:MakePopup()
    _aim_submenu:SetBackgroundBlur(true)
    _aim_submenu.Paint = function(self, w, h)
        draw.RoundedBox(12, 0, 0, w, h, Color(25, 25, 35, 230))
        draw.RoundedBox(12, 0, 0, w, 40, Color(180, 40, 40, 255))
        draw.SimpleText("AIM Settings", "Trebuchet24", w/2, 20, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local y = 50

    local fov_slider = vgui.Create("DNumSlider", _aim_submenu)
    fov_slider:SetPos(20, y)
    fov_slider:SetSize(260, 30)
    fov_slider:SetText("FOV")
    fov_slider:SetMin(1)
    fov_slider:SetMax(180)
    fov_slider:SetDecimals(0)
    fov_slider:SetValue(options.AIM_FOV)
    fov_slider.OnValueChanged = function(_, val) options.AIM_FOV = val end
    y = y + 40

    local show_circle = vgui.Create("DCheckBoxLabel", _aim_submenu)
    show_circle:SetPos(20, y)
    show_circle:SetText("Aimbot Show Circle")
    show_circle:SetValue(options.AIM_SHOWCIRCLE)
    show_circle:SizeToContents()
    show_circle.OnChange = function(_, val) options.AIM_SHOWCIRCLE = val end
    y = y + 30

    local snapline_checkbox = vgui.Create("DCheckBoxLabel", _aim_submenu)
    snapline_checkbox:SetPos(20, y)
    snapline_checkbox:SetText("Aimbot Snapline")
    snapline_checkbox:SetValue(options.AIM_SNAPLINE)
    snapline_checkbox:SizeToContents()
    snapline_checkbox.OnChange = function(_, val) options.AIM_SNAPLINE = val end
    y = y + 30

    local hitbox = vgui.Create("DComboBox", _aim_submenu)
    hitbox:SetPos(20, y)
    hitbox:SetSize(120, 20)
    hitbox:SetValue(options.AIM_HITBOX)
    hitbox:AddChoice("head")
    hitbox:AddChoice("body")
    hitbox.OnSelect = function(_, _, val) options.AIM_HITBOX = val end

    local keybox = vgui.Create("DComboBox", _aim_submenu)
    keybox:SetPos(160, y)
    keybox:SetSize(120, 20)
    local current_key = nil
    for k, v in pairs(aim_key_names) do
        if k == options.AIM_KEY then current_key = v end
        keybox:AddChoice(v)
    end
    keybox:SetValue(current_key or "LMB")
    keybox.OnSelect = function(_, _, val)
        options.AIM_KEY = aim_key_values[val] or MOUSE_LEFT
    end
    y = y + 30

    local auto_shoot = vgui.Create("DCheckBoxLabel", _aim_submenu)
    auto_shoot:SetPos(20, y)
    auto_shoot:SetText("Auto Shoot")
    auto_shoot:SetValue(options.AIM_AUTOSHOOT)
    auto_shoot:SizeToContents()
    auto_shoot.OnChange = function(_, val) options.AIM_AUTOSHOOT = val end
    y = y + 30

    local prediction = vgui.Create("DCheckBoxLabel", _aim_submenu)
    prediction:SetPos(20, y)
    prediction:SetText("predict target")
    prediction:SetValue(options.AIM_PREDICTION)
    prediction:SizeToContents()
    prediction.OnChange = function(_, val) options.AIM_PREDICTION = val end
    y = y + 30

    local bullet_speed = vgui.Create("DNumSlider", _aim_submenu)
    bullet_speed:SetPos(20, y)
    bullet_speed:SetSize(260, 30)
    bullet_speed:SetText("Bullet Speed")
    bullet_speed:SetMin(500)
    bullet_speed:SetMax(10000)
    bullet_speed:SetDecimals(0)
    bullet_speed:SetValue(options.AIM_BULLETSPEED)
    bullet_speed.OnValueChanged = function(_, val) options.AIM_BULLETSPEED = val end
    y = y + 40

    local fov_mixer = vgui.Create("DColorMixer", _aim_submenu)
    fov_mixer:SetPos(20, y)
    fov_mixer:SetSize(260, 50)
    fov_mixer:SetPalette(true)
    fov_mixer:SetAlphaBar(true)
    fov_mixer:SetWangs(true)
    fov_mixer:SetColor(options.FOVColor)
    fov_mixer.ValueChanged = function(_, col)
        options.FOVColor = col
    end
    y = y + 60

    local snapline_mixer = vgui.Create("DColorMixer", _aim_submenu)
    snapline_mixer:SetPos(20, y)
    snapline_mixer:SetSize(260, 50)
    snapline_mixer:SetPalette(true)
    snapline_mixer:SetAlphaBar(true)
    snapline_mixer:SetWangs(true)
    snapline_mixer:SetColor(options.SnaplineColor)
    snapline_mixer.ValueChanged = function(_, col)
        options.SnaplineColor = col
    end
    y = y + 60

    local nospread = vgui.Create("DCheckBoxLabel", _aim_submenu)
    nospread:SetPos(20, y)
    nospread:SetText("NoSpread")
    nospread:SetValue(options.NoSpread)
    nospread:SizeToContents()
    nospread.OnChange = function(_, val) options.NoSpread = val end
    y = y + 30

    local norecoil = vgui.Create("DCheckBoxLabel", _aim_submenu)
    norecoil:SetPos(20, y)
    norecoil:SetText("NoRecoil")
    norecoil:SetValue(options.NoRecoil)
    norecoil:SizeToContents()
    norecoil.OnChange = function(_, val) options.NoRecoil = val end
    y = y + 30
end

hook.Add("CreateMove", "BOT4_NoRecoil", function(cmd)
    if not options.NoRecoil then return end
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    if ply:GetViewPunchAngles() ~= Angle(0,0,0) then
        ply:SetViewPunchAngles(Angle(0,0,0))
    end
end)

if CLIENT then
    hook.Add("CreateMove", "BOT4_NoSpread", function(cmd)
        if not options.NoSpread then return end
        if cmd.SetRandomSeed then
            cmd:SetRandomSeed(0)
        end
    end)
end

-- Submenu ESP selection variable colors
local function OpenESPSubMenu()
    if IsValid(_esp_submenu) then _esp_submenu:Remove() end
    _esp_submenu = vgui.Create("DFrame")
    _esp_submenu:SetTitle("ESP Settings")
    _esp_submenu:SetSize(260, 180)
    _esp_submenu:Center()
    _esp_submenu:MakePopup()
    _esp_submenu:SetBackgroundBlur(true)
    _esp_submenu.Paint = function(self, w, h)
        draw.RoundedBox(12, 0, 0, w, h, Color(25, 25, 35, 230))
        draw.RoundedBox(12, 0, 0, w, 40, Color(40, 40, 60, 255))
        draw.SimpleText("ESP Settings", "Trebuchet24", w/2, 20, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local mixer = vgui.Create("DColorMixer", _esp_submenu)
    mixer:SetPos(10, 50)
    mixer:SetSize(240, 100)
    mixer:SetPalette(true)
    mixer:SetAlphaBar(false)
    mixer:SetWangs(true)
    mixer:SetColor(options.ESPColor)
    mixer.ValueChanged = function(_, col)
        options.ESPColor = col
    end
end

-- Submenu HP and Armor selection
local function OpenBarTextSubMenu(varName, displayName)
    if IsValid(_bartext_submenu) then _bartext_submenu:Remove() end
    _bartext_submenu = vgui.Create("DFrame")
    _bartext_submenu:SetTitle(displayName .. " Settings")
    _bartext_submenu:SetSize(260, 160)
    _bartext_submenu:Center()
    _bartext_submenu:MakePopup()
    _bartext_submenu:SetBackgroundBlur(true)
    _bartext_submenu.Paint = function(self, w, h)
        draw.RoundedBox(12, 0, 0, w, h, Color(25, 25, 35, 230))
        draw.RoundedBox(12, 0, 0, w, 40, Color(40, 40, 60, 255))
        draw.SimpleText(displayName .. " Settings", "Trebuchet24", w/2, 20, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local modes = {"BAR", "TEXT", "BAR+TEXT"}
    local y = 60
    for _, mode in ipairs(modes) do
        local btn = vgui.Create("DButton", _bartext_submenu)
        btn:SetPos(30, y)
        btn:SetSize(200, 28)
        btn:SetText(mode)
        btn.Paint = function(self, w, h)
            local isActive = options[varName .. "Mode"] == mode
            local col = isActive and Color(0, 200, 255, 220) or Color(60, 60, 60, 180)
            draw.RoundedBox(8, 0, 0, w, h, col)
            draw.SimpleText(mode, "Trebuchet24", w/2, h/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        btn.DoClick = function()
            options[varName .. "Mode"] = mode
            _bartext_submenu:Close()
        end
        y = y + 32
    end
end

-- Main menu
local function OpenBOT4CHeatMenu()
    if IsValid(_BOT4CHeatMenu) then _BOT4CHeatMenu:Remove() end
    _BOT4CHeatMenu = vgui.Create("DFrame")
    _BOT4CHeatMenu:SetTitle("")
    _BOT4CHeatMenu:SetSize(420, 400)
    _BOT4CHeatMenu:Center()
    _BOT4CHeatMenu:MakePopup()
    _BOT4CHeatMenu:SetBackgroundBlur(true)
    _BOT4CHeatMenu.Paint = function(self, w, h)
        draw.RoundedBox(10, 0, 0, w, h, Color(22, 24, 32, 245))
        draw.RoundedBox(0, 0, 0, w, 44, Color(0, 180, 255, 255))
        draw.SimpleText("BOT4CheatMenu", "Trebuchet24", 16, 22, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local sheet = vgui.Create("DPropertySheet", _BOT4CHeatMenu)
    sheet:SetPos(8, 52)
    sheet:SetSize(404, 340)

    local playerPanel = vgui.Create("DPanel", sheet)
    playerPanel.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(30, 32, 44, 220))
    end

    y = 48
    local function addOption(label, var, rightClick)
        local btn = vgui.Create("DButton", playerPanel)
        btn:SetPos(12, y)
        btn:SetSize(180, 28)
        btn:SetText("")
        btn.Paint = function(self, w, h)
            local col = options[var] and Color(0, 180, 255, 220) or Color(60, 60, 60, 180)
            draw.RoundedBox(6, 0, 0, w, h, col)
            draw.SimpleText(label, "Trebuchet18", w/2, h/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        btn.OnMousePressed = function(self, m)
            if m == MOUSE_LEFT then
                options[var] = not options[var]
            elseif m == MOUSE_RIGHT and rightClick then
                rightClick()
            end
        end
        y = y + 34
    end

    addOption("AIM", "AIM", OpenAIMSubMenu)
    addOption("ESP", "ESP", OpenESPSubMenu)
    addOption("HP", "HP", function() OpenBarTextSubMenu("HP", "HP") end)
    addOption("Armor", "Armor", function() OpenBarTextSubMenu("Armor", "Armor") end)
    addOption("Ammo", "Ammo")
    addOption("Name", "Name")
    addOption("Bunnyhop", "Bunnyhop")

    sheet:AddSheet("PLAYER", playerPanel, "icon16/user.png")
end

hook.Add("Think", "OpenBOT4CHeatMenuF6", function()
    if input.IsKeyDown(KEY_F6) and not IsValid(_BOT4CHeatMenu) then
        OpenBOT4CHeatMenu()
    end
    if not input.IsKeyDown(KEY_F6) and IsValid(_BOT4CHeatMenu) and _BOT4CHeatMenu:HasFocus() == false then
        _BOT4CHeatMenu:Close()
    end
end)

hook.Add("HUDPaint", "BOT4_AimSnapline", function()
    if not options.AIM or not options.AIM_SNAPLINE then return end
    local target = GetBestAimTarget()
    if not IsValid(target) then return end

    local hitboxPos = PredictAimPos(target, LocalPlayer():EyePos())
    if not hitboxPos then return end

    local screen = hitboxPos:ToScreen()
    local scrW, scrH = ScrW(), ScrH()

    local col = options.SnaplineColor or Color(0, 255, 255, 255)
    surface.SetDrawColor(col)
    surface.DrawLine(scrW / 2, scrH / 2, screen.x, screen.y)
end)

function IsTargetVisible(target)
    if not IsValid(target) then return false end
    local from = LocalPlayer():EyePos()
    local to = GetAimHitboxPos(target)
    local tr = util.TraceLine({
        start = from,
        endpos = to,
        filter = LocalPlayer(),
        mask = MASK_SHOT
    })
    return tr.Entity == target or tr.Fraction > 0.98
end

local lastStrafe = 0
local strafeDir = 1
local lastOnGround = false

-- bunnyhop
hook.Add("CreateMove", "CheatBunnyhop", function(cmd)
    if not options.Bunnyhop then return end
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end

    local onGround = ply:OnGround()

    if input.IsKeyDown(KEY_SPACE) then
        if onGround and not lastOnGround then
            cmd:SetButtons(bit.bor(cmd:GetButtons(), IN_JUMP))
        elseif not onGround then
            cmd:RemoveKey(IN_JUMP)
        end
        if CurTime() > lastStrafe + 0.08 then
            strafeDir = -strafeDir
            lastStrafe = CurTime()
        end

        if not cmd:KeyDown(IN_MOVELEFT) and not cmd:KeyDown(IN_MOVERIGHT) then
            cmd:SetSideMove(200 * strafeDir)
        end
    else
        cmd:RemoveKey(IN_JUMP)
    end

    lastOnGround = onGround
end)
