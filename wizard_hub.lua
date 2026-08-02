-- Wizard Hub | Rayfield Gen 2
-- Remade UI to official sirius.menu/gen2

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

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
... (306 lines left)