local options = {
    ESP = true,
    Armor = true,
    HP = true,
    Ammo = true,
    Name = true,
    Bunnyhop = false,
    ESPColor = Color(0, 255, 255, 255),
}

options.HPMode = "BAR+TEXT"
options.ArmorMode = "BAR+TEXT"

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

-- ESP
hook.Add("HUDPaint", "WHCornerESP_Unique", function()
    if not options.ESP then return end
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    for _, target in ipairs(player.GetAll()) do
        if target == ply then continue end
        if not IsValid(target) or not target:Alive() then continue end


        local dist = ply:GetPos():Distance(target:GetPos())
        if dist > 5000 then continue end

        local mins, maxs = target:GetModelBounds()
        if not mins or not maxs then continue end


        local center = (mins + maxs) / 2


        local scale = 0.93
        local newMins = center + (mins - center) * scale
        local newMaxs = center + (maxs - center) * scale


        local corners = {
            Vector(newMins.x, newMins.y, newMins.z),
            Vector(newMins.x, newMins.y, newMaxs.z),
            Vector(newMins.x, newMaxs.y, newMins.z),
            Vector(newMins.x, newMaxs.y, newMaxs.z),
            Vector(newMaxs.x, newMins.y, newMins.z),
            Vector(newMaxs.x, newMins.y, newMaxs.z),
            Vector(newMaxs.x, newMaxs.y, newMins.z),
            Vector(newMaxs.x, newMaxs.y, newMaxs.z),
        }

        local screenPoints = {}
        for i = 1, 8 do
            local world = target:LocalToWorld(corners[i])
            local screen = world:ToScreen()
            table.insert(screenPoints, screen)
        end

        local minX, minY = math.huge, math.huge
        local maxX, maxY = -math.huge, -math.huge
        for _, pt in ipairs(screenPoints) do
            if pt.visible then
                minX = math.min(minX, pt.x)
                minY = math.min(minY, pt.y)
                maxX = math.max(maxX, pt.x)
                maxY = math.max(maxY, pt.y)
            end
        end

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
end)

-- Armor Bar
hook.Add("HUDPaint", "DrawArmorBarWH_Unique", function()
    if not options.Armor then return end
    for _, target in ipairs(player.GetAll()) do
        if target == LocalPlayer() or not IsValid(target) or not target:Alive() then continue end

        local armor = target:Armor()
        local maxArmor = target.GetMaxArmor and target:GetMaxArmor() or 100

        local mins, maxs = target:GetModelBounds()
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
        for i = 1, 8 do
            local screen = target:LocalToWorld(corners[i]):ToScreen()
            if screen.visible then
                minX = math.min(minX, screen.x)
                minY = math.min(minY, screen.y)
                maxX = math.max(maxX, screen.x)
                maxY = math.max(maxY, screen.y)
            end
        end

        local barWidth = 4
        local barHeight = math.max(maxY - minY, 10)
        local x = maxX + 6
        local y = minY
        local fillHeight = math.Clamp((armor / maxArmor) * barHeight, 0, barHeight)

        if options.ArmorMode == "BAR" or options.ArmorMode == "BAR+TEXT" then
            surface.SetDrawColor(0, 0, 0, 255)
            surface.DrawOutlinedRect(x, y, barWidth, barHeight)
            surface.SetDrawColor(0, 128, 255, 255)
            surface.DrawRect(x + 1, y + barHeight - fillHeight + 1, barWidth - 2, fillHeight - 2)
        end

        if options.ArmorMode == "TEXT" or options.ArmorMode == "BAR+TEXT" then
            draw.SimpleTextOutlined(
                tostring(armor),
                "DermaDefaultBold",
                x + barWidth + 6,
                y + barHeight / 2,
                Color(0, 128, 255, 255),
                TEXT_ALIGN_LEFT,
                TEXT_ALIGN_CENTER,
                2,
                Color(0,0,0,255)
            )
        end
    end
end)

-- HP Bar
hook.Add("HUDPaint", "DrawHPBarWH_Unique", function()
    if not options.HP then return end
    for _, target in ipairs(player.GetAll()) do
        if target == LocalPlayer() or not IsValid(target) or not target:Alive() then continue end

        local hp = target:Health()
        local maxHp = target.GetMaxHealth and target:GetMaxHealth() or 100

        local mins, maxs = target:GetModelBounds()
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
        for i = 1, 8 do
            local screen = target:LocalToWorld(corners[i]):ToScreen()
            if screen.visible then
                minX = math.min(minX, screen.x)
                minY = math.min(minY, screen.y)
                maxX = math.max(maxX, screen.x)
                maxY = math.max(maxY, screen.y)
            end
        end

        local barWidth = 4
        local barHeight = math.max(maxY - minY, 10)
        local x = minX - barWidth - 4
        local y = minY
        local fillHeight = math.Clamp((hp / maxHp) * barHeight, 0, barHeight)

        if options.HPMode == "BAR" or options.HPMode == "BAR+TEXT" then
            surface.SetDrawColor(0, 0, 0, 255)
            surface.DrawOutlinedRect(x, y, barWidth, barHeight)
            surface.SetDrawColor(0, 255, 0, 255)
            surface.DrawRect(x + 1, y + barHeight - fillHeight + 1, barWidth - 2, fillHeight - 2)
        end

        if options.HPMode == "TEXT" or options.HPMode == "BAR+TEXT" then
            draw.SimpleTextOutlined(
                tostring(hp),
                "DermaDefaultBold",
                x - 6,
                y + barHeight / 2,
                Color(0, 255, 0, 255),
                TEXT_ALIGN_RIGHT,
                TEXT_ALIGN_CENTER,
                2,
                Color(0,0,0,255)
            )
        end
    end
end)

-- Ammo Bar
hook.Add("HUDPaint", "DrawAmmoBarWH_Unique", function()
    if not options.Ammo then return end
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    for _, target in ipairs(player.GetAll()) do
        if target == ply then continue end
        if not IsValid(target) or not target:Alive() then continue end

        local dist = ply:GetPos():Distance(target:GetPos())
        if dist > 5000 then continue end

        local mins, maxs = target:GetModelBounds()
        if not mins or not maxs then continue end

        local scale = 0.93
        local center = (mins + maxs) / 2
        local newMins = center + (mins - center) * scale
        local newMaxs = center + (maxs - center) * scale

        local corners = {
            Vector(newMins.x, newMins.y, newMins.z),
            Vector(newMins.x, newMins.y, newMaxs.z),
            Vector(newMins.x, newMaxs.y, newMins.z),
            Vector(newMins.x, newMaxs.y, newMaxs.z),
            Vector(newMaxs.x, newMins.y, newMins.z),
            Vector(newMaxs.x, newMins.y, newMaxs.z),
            Vector(newMaxs.x, newMaxs.y, newMins.z),
            Vector(newMaxs.x, newMaxs.y, newMaxs.z),
        }

        local screenPoints = {}
        for i = 1, 8 do
            local world = target:LocalToWorld(corners[i])
            local screen = world:ToScreen()
            table.insert(screenPoints, screen)
        end

        local minX, minY = math.huge, math.huge
        local maxX, maxY = -math.huge, -math.huge
        for _, pt in ipairs(screenPoints) do
            if pt.visible then
                minX = math.min(minX, pt.x)
                minY = math.min(minY, pt.y)
                maxX = math.max(maxX, pt.x)
                maxY = math.max(maxY, pt.y)
            end
        end

        local boxWidth = maxX - minX
        local barWidth = math.Clamp(boxWidth * 0.8, 24, boxWidth)
        local barHeight = 8
        local barX = minX + (boxWidth - barWidth) / 2
        local barY = maxY + 8 

        local wep = target:GetActiveWeapon()
        local ammo = IsValid(wep) and wep:Clip1() or 0
        local maxAmmo = IsValid(wep) and wep:GetMaxClip1() or 100
        local ammoFrac = (maxAmmo > 0) and math.Clamp(ammo / maxAmmo, 0, 1) or 0

        surface.SetDrawColor(0, 0, 0, 255)
        surface.DrawRect(barX, barY, barWidth * ammoFrac, barHeight)
        surface.SetDrawColor(0, 0, 0, 255)
        surface.DrawOutlinedRect(barX, barY, barWidth, barHeight)

        draw.SimpleTextOutlined(
            ammo,
            "Trebuchet18",
            barX + barWidth / 2,
            barY + barHeight / 2,
            Color(0, 128, 255, 255),
            TEXT_ALIGN_CENTER,
            TEXT_ALIGN_CENTER,
            2,
            Color(0,0,0,255)
        )
    end
end)

-- Player Name
hook.Add("HUDPaint", "DrawNameAboveHeadWH_Unique", function()
    if not options or not options.Name then return end
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    for _, target in ipairs(player.GetAll()) do
        if target == ply then continue end
        if not IsValid(target) or not target:Alive() then continue end

        local mins, maxs = target:GetModelBounds()
        if not mins or not maxs then continue end

        local scale = 0.93
        local center = (mins + maxs) / 2
        local newMins = center + (mins - center) * scale
        local newMaxs = center + (maxs - center) * scale

        local corners = {
            Vector(newMins.x, newMins.y, newMins.z),
            Vector(newMins.x, newMins.y, newMaxs.z),
            Vector(newMins.x, newMaxs.y, newMins.z),
            Vector(newMins.x, newMaxs.y, newMaxs.z),
            Vector(newMaxs.x, newMins.y, newMins.z),
            Vector(newMaxs.x, newMins.y, newMaxs.z),
            Vector(newMaxs.x, newMaxs.y, mins.z),
            Vector(newMaxs.x, newMaxs.y, newMaxs.z),
        }

        local minX, minY = math.huge, math.huge
        local maxX, maxY = -math.huge, -math.huge
        for i = 1, 8 do
            local screen = target:LocalToWorld(corners[i]):ToScreen()
            if screen.visible then
                minX = math.min(minX, screen.x)
                minY = math.min(minY, screen.y)
                maxX = math.max(maxX, screen.x)
                maxY = math.max(maxY, screen.y)
            end
        end

        local name = target:Name()
        draw.SimpleTextOutlined(
            name,
            "DermaDefaultBold",
            (minX + maxX) / 2,
            minY - 8, 
            Color(255, 255, 0, 255),
            TEXT_ALIGN_CENTER,
            TEXT_ALIGN_BOTTOM,
            2,
            Color(0,0,0,255)
        )
    end
end)

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