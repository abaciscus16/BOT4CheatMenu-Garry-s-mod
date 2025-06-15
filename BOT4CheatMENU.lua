local menuOpen = false
local menuFrame = nil
local options = {
    ESP = true,
    Armor = true,
    HP = true,
    Ammo = true,
    Name = true,
    Bunnyhop = false
}

hook.Add("Think", "OpenCustomMenuF6", function()
    if input.IsKeyDown(KEY_F6) then
        if not menuOpen then
            menuOpen = true

            menuFrame = vgui.Create("DFrame")
            menuFrame:SetTitle("BOT4CheatMENU")
            menuFrame:SetSize(200, 320)
            menuFrame:Center()
            menuFrame:MakePopup()

            local y = 40
            local function addOption(name, var)
                local panel = vgui.Create("DPanel", menuFrame)
                panel:SetPos(10, y)
                panel:SetSize(180, 30)
                panel.Paint = function(self, w, h)
                    draw.SimpleText(name, "DermaDefault", 40, h/2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    surface.SetDrawColor(options[var] and Color(180, 0, 255) or Color(60, 60, 60))
                    surface.DrawRect(10, 7, 20, 20)
                    surface.SetDrawColor(0,0,0,255)
                    surface.DrawOutlinedRect(10, 7, 20, 20)
                end
                panel.OnMousePressed = function(_, m)
                    local mx, my = panel:CursorPos()
                    if m == MOUSE_LEFT and mx >= 10 and mx <= 30 and my >= 7 and my <= 27 then
                        options[var] = not options[var]
                    end
                end
                y = y + 35
            end

            addOption("ESP", "ESP")
            addOption("Armor", "Armor")
            addOption("HP", "HP")
            addOption("Ammo", "Ammo")
            addOption("Name", "Name")
            addOption("Bunnyhop", "Bunnyhop")

            menuFrame.OnClose = function()
                menuOpen = false
                menuFrame = nil
            end
        end
    elseif menuOpen and not input.IsKeyDown(KEY_F6) then
        hook.Add("Think", "CloseMenuOnF6", function()
            if input.IsKeyDown(KEY_F6) and menuOpen and menuFrame then
                menuFrame:Close()
                menuOpen = false
                menuFrame = nil
                hook.Remove("Think", "CloseMenuOnF6")
            elseif not input.IsKeyDown(KEY_F6) then
                hook.Remove("Think", "CloseMenuOnF6")
            end
        end)
    end
end)

-- ESP (углы)
hook.Add("HUDPaint", "WHCornerESP_Unique", function()
    if not options or not options.ESP then return end
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    for _, target in ipairs(player.GetAll()) do
        if target == ply then continue end
        if not IsValid(target) or not target:Alive() then continue end


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


        local len = math.Clamp(boxHeight * 0.18, 8, boxHeight * 0.33)
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


        surface.SetDrawColor(0, 255, 255, 255)
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
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    for _, target in ipairs(player.GetAll()) do
        if target == ply then continue end
        if not IsValid(target) or not target:Alive() then continue end

        local armor = target:Armor()
        local maxArmor = target.GetMaxArmor and target:GetMaxArmor() or 100

        local mins, maxs = target:GetModelBounds()
        if not mins or not maxs then continue end

        local headPos = target:LocalToWorld(Vector(0, 0, maxs.z))
        local feetPos = target:LocalToWorld(Vector(0, 0, mins.z))
        local center = (headPos + feetPos) / 2

        local camRight = EyeAngles():Right()
        local offsetRight = camRight * 24
        local barWorldPos = center + offsetRight

        local barScreen = barWorldPos:ToScreen()
        local headScreen = headPos:ToScreen()
        local feetScreen = feetPos:ToScreen()

        local barHeight = math.abs(headScreen.y - feetScreen.y)
        local barWidth = 4

        local x = barScreen.x
        local y = math.min(headScreen.y, feetScreen.y)

        surface.SetDrawColor(0, 0, 0, 255)
        surface.DrawOutlinedRect(x, y, barWidth, barHeight)
        local fillHeight = math.Clamp((armor / maxArmor) * barHeight, 0, barHeight)
        surface.SetDrawColor(0, 128, 255, 255)
        surface.DrawRect(x + 1, y + barHeight - fillHeight + 1, barWidth - 2, fillHeight - 2)


        draw.SimpleTextOutlined(
            tostring(armor),
            "DermaDefaultBold", 
            x - -30, -- справа от полоски
            y + barHeight / 2,
            Color(0, 128, 255, 255),
            TEXT_ALIGN_RIGHT,
            TEXT_ALIGN_CENTER,
            2,
            Color(0,0,0,255)
        )
    end
end)

-- HP Bar
hook.Add("HUDPaint", "DrawHPBarWH_Unique", function()
    if not options.HP then return end
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    for _, target in ipairs(player.GetAll()) do
        if target == ply then continue end
        if not IsValid(target) or not target:Alive() then continue end

        local hp = target:Health()
        local maxHp = target.GetMaxHealth and target:GetMaxHealth() or 100

        local mins, maxs = target:GetModelBounds()
        if not mins or not maxs then continue end

        local headPos = target:LocalToWorld(Vector(0, 0, maxs.z))
        local feetPos = target:LocalToWorld(Vector(0, 0, mins.z))
        local center = (headPos + feetPos) / 2

        local camRight = EyeAngles():Right()
        local offsetLeft = camRight * -25
        local barWorldPos = center + offsetLeft

        local barScreen = barWorldPos:ToScreen()
        local headScreen = headPos:ToScreen()
        local feetScreen = feetPos:ToScreen()

        local barHeight = math.abs(headScreen.y - feetScreen.y)
        local barWidth = 4

        local x = barScreen.x
        local y = math.min(headScreen.y, feetScreen.y)

        surface.SetDrawColor(0, 0, 0, 255)
        surface.DrawOutlinedRect(x, y, barWidth, barHeight)
        local fillHeight = math.Clamp((hp / maxHp) * barHeight, 0, barHeight)
        surface.SetDrawColor(0, 255, 0, 255)
        surface.DrawRect(x + 1, y + barHeight - fillHeight + 1, barWidth - 2, fillHeight - 2)

        draw.SimpleTextOutlined(
            tostring(hp),
            "DermaDefaultBold", 
            x - 10, -- слева от полоски
            y + barHeight / 2,
            Color(0, 255, 0, 255),
            TEXT_ALIGN_RIGHT,
            TEXT_ALIGN_CENTER,
            2,
            Color(0,0,0,255)
        )
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

        local wep = target:GetActiveWeapon()
        if not IsValid(wep) or not wep.Clip1 or not wep.GetMaxClip1 then continue end

        local ammo = wep:Clip1()
        local maxAmmo = wep:GetMaxClip1()
        if not maxAmmo or maxAmmo <= 0 then maxAmmo = 30 end

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

        local barWidth = math.max(maxX - minX, 24)
        local barHeight = 8
        local centerX = (minX + maxX) / 2
        local x = centerX - barWidth / 2
        local y = maxY + 8

        local fill = math.Clamp(ammo / maxAmmo, 0, 1)

        surface.SetDrawColor(0, 0, 0, 220)
        surface.DrawOutlinedRect(x, y, barWidth, barHeight)
        surface.SetDrawColor(0, 128, 255, 255)
        surface.DrawRect(x + 1, y + 1, (barWidth - 2) * fill, barHeight - 2)

        draw.SimpleTextOutlined(
            tostring(ammo),
            "DermaDefaultBold",
            x + barWidth / 2,
            y + barHeight / 2,
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
        local headPos = target:LocalToWorld(Vector(0, 0, maxs.z + 10))
        local headScreen = headPos:ToScreen()

        local name = target:Name()

        draw.SimpleTextOutlined(
            name,
            "DermaDefaultBold",
            headScreen.x,
            headScreen.y - 16,
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

hook.Add("CreateMove", "CheatBunnyhop", function(cmd)
    if not options.Bunnyhop then return end
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end

    if cmd:KeyDown(IN_JUMP) then
        if not ply:OnGround() then
            cmd:RemoveKey(IN_JUMP)
        end

        -- Авто-стрейф с задержкой (0.08 сек)
        if CurTime() > lastStrafe + 0.08 then
            strafeDir = -strafeDir
            lastStrafe = CurTime()
        end

        if not cmd:KeyDown(IN_MOVELEFT) and not cmd:KeyDown(IN_MOVERIGHT) then
            cmd:SetSideMove(200 * strafeDir)
        end
    end
end)