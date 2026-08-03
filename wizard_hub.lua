-- Wizard Hub | Universal Stable Edition
-- Powered by Orion UI Library (Fixed Rayfield Line 1305 Crash & Delta Android Compatible)

-- // Universal Mobile Executor Polyfill (Delta & Android Permission Fix)
local genv = (getgenv and getgenv()) or _G

if not genv.makefolder then genv.makefolder = function() end end
if not genv.isfolder then genv.isfolder = function(path) return true end end
if not genv.isfile then genv.isfile = function(path) return false end end
if not genv.writefile then genv.writefile = function() end end end
if not genv.readfile then genv.readfile = function() return "" end end
if not genv.appendfile then genv.appendfile = function() end end end

-- Safe filesystem wrappers to prevent crashes
local raw_makefolder = genv.makefolder
genv.makefolder = function(...)
    local ok, res = pcall(raw_makefolder, ...)
    return res
end

local raw_writefile = genv.writefile
genv.writefile = function(...)
    local ok, res = pcall(raw_writefile, ...)
    return res
end

-- // Services & Players
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- // Session Management (Prevents duplicate background loops)
_G.WizardHubSession = (_G.WizardHubSession or 0) + 1
local currentSession = _G.WizardHubSession

-- // ESP State & Setup
local ESP_State = {
    ColorMap = {
        {Keyword = "Royal", Color = Color3.fromRGB(255, 215, 0)},
        {Keyword = "Shadow", Color = Color3.fromRGB(138, 43, 226)},
        {Keyword = "Wizard", Color = Color3.fromRGB(0, 162, 255)},
    },
    DefaultColor = Color3.fromRGB(255, 255, 255)
}

-- Cleanup previous ESP sessions and drawings
if _G.ESP_Storage then 
    for _, data in pairs(_G.ESP_Storage) do
        if data.Box then data.Box:Remove() end
        if data.Tag then data.Tag:Remove() end
    end
end
_G.ESP_Storage = {}

-- Cleanup previous event connections to prevent memory leaks/performance drop
if _G.ESP_Connections then
    for _, conn in ipairs(_G.ESP_Connections) do
        if conn then conn:Disconnect() end
    end
end
_G.ESP_Connections = {}

local function GetTeamColor(player)
    if not player.Team then return ESP_State.DefaultColor end
    local teamName = player.Team.Name:lower()
    for _, entry in ipairs(ESP_State.ColorMap) do
        if string.find(teamName, entry.Keyword:lower()) then
            return entry.Color
        end
    end
    return ESP_State.DefaultColor
end

local function CreateESP(player)
    if player == LocalPlayer then return end
    
    local box = Drawing.new("Square")
    box.Visible = false
    box.Thickness = 1
    box.Transparency = 1
    box.Filled = false

    local nameTag = Drawing.new("Text")
    nameTag.Visible = false
    nameTag.Outline = true
    nameTag.Center = true
    nameTag.Size = 14
    nameTag.Color = Color3.fromRGB(255, 255, 255)

    _G.ESP_Storage[player] = {Box = box, Tag = nameTag}
end

local function RemoveESP(player)
    if _G.ESP_Storage[player] then
        if _G.ESP_Storage[player].Box then _G.ESP_Storage[player].Box:Remove() end
        if _G.ESP_Storage[player].Tag then _G.ESP_Storage[player].Tag:Remove() end
        _G.ESP_Storage[player] = nil
    end
end

table.insert(_G.ESP_Connections, Players.PlayerAdded:Connect(CreateESP))
table.insert(_G.ESP_Connections, Players.PlayerRemoving:Connect(RemoveESP))
for _, p in pairs(Players:GetPlayers()) do CreateESP(p) end

-- // Team Enemy Filter Helper (Strict Rules & Safe Instance Check)
local function IsEnemy(caster)
    if not caster then return false end
    
    local casterPlayer = nil
    
    -- Case 1: caster is already a Player instance
    if typeof(caster) == "Instance" and caster:IsA("Player") then
        casterPlayer = caster
    -- Case 2: caster is a Character Model or Part
    elseif typeof(caster) == "Instance" then
        if caster:IsA("Model") then
            casterPlayer = Players:GetPlayerFromCharacter(caster)
        elseif caster.Parent and caster.Parent:IsA("Model") then
            casterPlayer = Players:GetPlayerFromCharacter(caster.Parent)
        end
    end
    
    if casterPlayer then
        if casterPlayer == LocalPlayer then return false end
        
        local myTeam = LocalPlayer.Team and LocalPlayer.Team.Name:lower() or ""
        local enemyTeam = casterPlayer.Team and casterPlayer.Team.Name:lower() or ""
        
        local myIsShadow = string.find(myTeam, "shadow") ~= nil
        local enemyIsShadow = string.find(enemyTeam, "shadow") ~= nil
        
        -- Rule 1: If I am Shadow Wizard -> Everyone else is an enemy!
        if myIsShadow then
            return true
        end
        
        -- Rule 2: If I am Wizard or Royal Wizard -> ONLY Shadow Wizard is my enemy!
        return enemyIsShadow
    end
    
    -- Rule 3: If caster is an AI / Mob / Monster -> Treat as enemy
    return true
end

-- // Feature State Variables
local InfiniteStaminaEnabled = false
local AutoDodgeEnabled = false
local ESPEnabled = false
local AutoLootEnabled = false
local SpeedBoostEnabled = false
local CustomSpeed = 16

-- // UI Engine Creation (Orion UI Library - 100% Rock Solid Cross-Platform)
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/jensonhirst/Orion/main/source"))()

local Window = OrionLib:MakeWindow({
    Name = "Wizard Hub | Universal Stable",
    HidePremium = true,
    SaveConfig = false,
    ConfigFolder = "WizardHubConfig",
    IntroText = "Wizard Hub by Jawir"
})

local combatTab = Window:MakeTab({ Name = "Combat", Icon = "rbxassetid://4484346474", PremiumOnly = false })
local cashTab   = Window:MakeTab({ Name = "Cash",   Icon = "rbxassetid://4484346474", PremiumOnly = false })
local playerTab = Window:MakeTab({ Name = "Player", Icon = "rbxassetid://4484346474", PremiumOnly = false })

-- COMBAT TAB
combatTab:AddToggle({
    Name = "Infinite Stamina",
    Default = false, Save = false,
    Callback = function(v) InfiniteStaminaEnabled = v end
})

combatTab:AddToggle({
    Name = "Auto Backward Dodge",
    Default = false, Save = false,
    Callback = function(v) AutoDodgeEnabled = v end
})

combatTab:AddToggle({
    Name = "Player ESP",
    Default = false, Save = false,
    Callback = function(v) ESPEnabled = v end
})

-- CASH TAB
cashTab:AddToggle({
    Name = "Auto Loot (Money Bags & Items)",
    Default = false, Save = false,
    Callback = function(v) AutoLootEnabled = v end
})

cashTab:AddButton({
    Name = "Remote Sell All Trinkets",
    Callback = function()
        pcall(function()
            local TrinketSellEvent = game.ReplicatedStorage.Events:FindFirstChild("TrinketSellEvent")
            if TrinketSellEvent then TrinketSellEvent:FireServer() end
        end)
    end
})

-- PLAYER TAB
playerTab:AddToggle({
    Name = "Enable WalkSpeed Boost",
    Default = false, Save = false,
    Callback = function(v) SpeedBoostEnabled = v end
})

playerTab:AddSlider({
    Name = "WalkSpeed Multiplier",
    Min = 16, Max = 100, Default = 16,
    Color = Color3.fromRGB(0, 162, 255),
    Increment = 1, ValueName = "Speed",
    Callback = function(v) CustomSpeed = v end
})

OrionLib:Init()

-- // Infinite Stamina Task Loop
task.spawn(function()
    while task.wait(0.05) and _G.WizardHubSession == currentSession do
        if InfiniteStaminaEnabled then
            pcall(function()
                local char = LocalPlayer.Character
                if char then
                    local maxStam = char:GetAttribute("DashStaminaMax") or 100
                    if char:GetAttribute("DashStamina") ~= maxStam then
                        char:SetAttribute("DashStamina", maxStam)
                    end
                end
            end)
        end
    end
end)

-- // Auto Dodge Function
local function TriggerBackwardDodge()
    pcall(function()
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        
        local DashEvent = game.ReplicatedStorage.Events:FindFirstChild("DashEvent")
        if DashEvent then
            DashEvent:FireServer("DashBack", false)
        end
        
        local DashLogic = require(game.ReplicatedStorage.Modules.Client.Char.Dash.DashLogic)
        if DashLogic and DashLogic.Dodge then
            local backDir = -Camera.CFrame.LookVector
            DashLogic.Dodge(char, backDir, false)
        end
        
        local CamFollowHead = require(game.ReplicatedStorage.Modules.Client.Char.CamFollowHead)
        if CamFollowHead and CamFollowHead.AttachCamera then
            CamFollowHead:AttachCamera(1)
        end
    end)
end

-- 1. Skill Projectiles Listener
local ProjectileEvent = game.ReplicatedStorage.Events:FindFirstChild("ProjectileEvent")
if ProjectileEvent then
    table.insert(_G.ESP_Connections, ProjectileEvent.OnClientEvent:Connect(function(action, ...)
        if not AutoDodgeEnabled then return end
        if action == "ShootProjectile" then
            local caster, projModel, startPos, targetPos = ...
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            
            if root and caster and IsEnemy(caster) and typeof(startPos) == "Vector3" and typeof(targetPos) == "Vector3" then
                local myPos = root.Position
                local distToTarget = (targetPos - myPos).Magnitude
                local distToStart = (startPos - myPos).Magnitude
                
                local dir = (targetPos - startPos).Unit
                local toMe = (myPos - startPos).Unit
                local dot = dir:Dot(toMe)
                
                if (distToTarget < 25 or (dot > 0.85 and distToStart < 300)) then
                    TriggerBackwardDodge()
                end
            end
        end
    end))
end

-- 2. Wand Basic Attack Bullets Listener
local WandAutoEvent = game.ReplicatedStorage.Events:FindFirstChild("WandAutoAttackEffectEvent")
if WandAutoEvent then
    table.insert(_G.ESP_Connections, WandAutoEvent.OnClientEvent:Connect(function(caster, tool, hitPositions, hitData)
        if not AutoDodgeEnabled then return end
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root and caster and IsEnemy(caster) then
            local myPos = root.Position
            if typeof(hitPositions) == "table" then
                for _, pos in ipairs(hitPositions) do
                    if typeof(pos) == "Vector3" and (pos - myPos).Magnitude < 25 then
                        TriggerBackwardDodge()
                        break
                    end
                end
            elseif typeof(hitPositions) == "Vector3" and (hitPositions - myPos).Magnitude < 25 then
                TriggerBackwardDodge()
            end
        end
    end))
end

-- 3. Gun Basic Attack Bullets Listener
local GunEvent = game.ReplicatedStorage.Events:FindFirstChild("GunEvent")
if GunEvent me then
    table.insert(_G.ESP_Connections, GunEvent.OnClientEvent:Connect(function(caster, tool, hitPositions, ...)
        if not AutoDodgeEnabled then return end
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root and caster and IsEnemy(caster) then
            local myPos = root.Position
            if typeof(hitPositions) == "table" then
                for _, pos in ipairs(hitPositions) do
                    if typeof(pos) == "Vector3" and (pos - myPos).Magnitude < 25 then
                        TriggerBackwardDodge()
                        break
                    end
                end
            elseif typeof(hitPositions) == "Vector3" and (hitPositions - myPos).Magnitude < 25 then
                TriggerBackwardDodge()
            end
        end
    end))
end

-- // CASH TAB: Auto Loot Task Loop
local EntityPickUpEvent = game.ReplicatedStorage.Events:FindFirstChild("EntityPickUpEvent")
task.spawn(function()
    while task.wait(0.3) and _G.WizardHubSession == currentSession do
        if AutoLootEnabled then
            pcall(function()
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if root then
                    for _, v in ipairs(workspace:GetChildren()) do
                        if v.Name == "MoneyBag" or v.Name == "ItemDrop" or v:GetAttribute("Pickable") then
                            local part = v:IsA("BasePart") and v or v:FindFirstChildWhichIsA("BasePart")
                            if part and (root.Position - part.Position).Magnitude < 30 then
                                if EntityPickUpEvent then
                                    EntityPickUpEvent:FireServer(v)
                                end
                                if v:IsA("BasePart") then
                                    v.CFrame = root.CFrame
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- // PLAYER TAB: WalkSpeed Task Loop
task.spawn(function()
    while task.wait(0.1) and _G.WizardHubSession == currentSession do
        if SpeedBoostEnabled then
            pcall(function()
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildWhichIsA("Humanoid")
                if hum and hum.WalkSpeed ~= CustomSpeed then
                    hum.WalkSpeed = CustomSpeed
                end
            end)
        end
    end
end)

-- // ESP Render Loop
table.insert(_G.ESP_Connections, RunService.RenderStepped:Connect(function()
    local localChar = LocalPlayer.Character
    local localRoot = localChar and localChar:FindFirstChild("HumanoidRootPart")

    for player, esp in pairs(_G.ESP_Storage) do
        local character = player.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        
        if rootPart and ESPEnabled then
            local screenPos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
            
            if onScreen then
                local teamColor = GetTeamColor(player)
                local sizeX = 2000 / screenPos.Z
                local sizeY = 3000 / screenPos.Z
                
                esp.Box.Size = Vector2.new(sizeX, sizeY)
                esp.Box.Position = Vector2.new(screenPos.X - sizeX/2, screenPos.Y - sizeY/2)
                esp.Box.Color = teamColor
                esp.Box.Visible = true
                
                local distance = 0
                if localRoot then
                    distance = (localRoot.Position - rootPart.Position).Magnitude
                end
                
                local role = player.Team and player.Team.Name or "None"
                esp.Tag.Text = string.format("[%s] %s\n[%d m]", role, player.Name, math.floor(distance))
                esp.Tag.Position = Vector2.new(screenPos.X, screenPos.Y - sizeY/2 - 25)
                esp.Tag.Color = teamColor
                esp.Tag.Visible = true
            else
                esp.Box.Visible = false
                esp.Tag.Visible = false
            end
        else
            if esp.Box then esp.Box.Visible = false end
            if esp.Tag then esp.Tag.Visible = false end
        end
    end
end))