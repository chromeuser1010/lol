--==============================================================
-- LINORIA-STYLE KEY SYSTEM (FIXED LAYOUT + NO OVERFLOW)
--==============================================================

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local UIS = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--========================
-- CONFIG
--========================
local CORRECT_KEY  = "guard1"
local GET_KEY_LINK = "https://link-target.net/1251036/key"
local DISCORD_LINK = "SOON"

--========================
-- NOTIFY HELPER
--========================
local function Notify(title, text, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = tostring(title),
            Text = tostring(text),
            Duration = dur or 3
        })
    end)
end

--========================
-- START HUB (PUT YOUR HUB CODE HERE)
--========================
local function StartHub()
    print("Key verified, hub loading...")
	--==============================================================
--  GUARDS HUB (ORGANIZED)
--  - Linoria UI
--  - HWID copy + webhook log
--  - HWID whitelist gate
--  - Movement: Fly / WalkSpeed / NoClip
--  - ESP: Player ESP + Area ESP
--  - Combat: Back Glide
--  - AutoBuy / Auto Mission
--==============================================================

--==============================================================
-- SERVICES (ONE PLACE ONLY)
--==============================================================
local Players            = game:GetService("Players")
local RunService          = game:GetService("RunService")
local UIS                = game:GetService("UserInputService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local HttpService        = game:GetService("HttpService")
local AnalyticsService   = game:GetService("RbxAnalyticsService")
local Workspace          = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

--==============================================================
-- LINORIA
--==============================================================
local repo = "https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager  = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

--==============================================================
-- UI TOGGLE (CTRL)
--==============================================================

local UIS = game:GetService("UserInputService")

UIS.InputBegan:Connect(function(input, gp)
    if gp then return end

    if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
        Library:Toggle()
    end
end)

print("[UI] Ctrl toggle enabled")


--==============================================================
-- CONFIG
--==============================================================
local WEBHOOK_URL = "https://discord.com/api/webhooks/1459303843098660894/i6bhclt6eqTia1i7D52tecEkCTo-1Zl5b_bZOmth6NBmfwzSoEY1nCQLw4mB3lbH-m7j"
local WHITELIST_URL = "https://raw.githubusercontent.com/gyuard/hub/refs/heads/main/guard.Lua"

--==============================================================
-- HWID (single source of truth)
--==============================================================
local HWID = AnalyticsService:GetClientId()

--==============================================================
-- HWID COPY (console + clipboard)
--==============================================================
print("Copying your HWID:", HWID)
if setclipboard then
    setclipboard(HWID)
    print("Your HWID has been copied to your clipboard.")
else
    warn("setclipboard is not supported by your executor.")
end

--==============================================================
-- WEBHOOK LOGGER
--==============================================================
local function sendExecutionLog()
    local data = {
        embeds = {
            {
                color = 0x00FF88,
                author = {
                    name = "Script Execution Detected",
                    icon_url = "https://cdn-icons-png.flaticon.com/512/1828/1828640.png"
                },
                thumbnail = {
                    url = string.format(
                        "https://www.roblox.com/headshot-thumbnail/image?userId=%s&width=420&height=420&format=png",
                        LocalPlayer.UserId
                    )
                },
                fields = {
                    {
                        name = "👤 Player",
                        value = string.format("**Name:** %s\n**UserId:** %s", LocalPlayer.Name, LocalPlayer.UserId),
                        inline = true
                    },
                    {
                        name = "🎮 Session",
                        value = string.format("**PlaceId:** %s\n**JobId:** %s", game.PlaceId, game.JobId),
                        inline = true
                    },
                    {
                        name = "💻 HWID",
                        value = string.format("`%s`", HWID),
                        inline = false
                    }
                },
                footer = {
                    text = "Execution Logger • Roblox",
                    icon_url = "https://cdn-icons-png.flaticon.com/512/5968/5968756.png"
                },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }
        }
    }

    if http_request then
        http_request({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode(data)
        })
    else
        warn("http_request is not available in this environment.")
    end
end

-- fire once on load
sendExecutionLog()

--==============================================================
-- HWID WHITELIST GATE
--==============================================================
local function isHWIDWhitelisted()
    local ok, HWIDTable = pcall(function()
        return loadstring(game:HttpGet(WHITELIST_URL, true))()
    end)

    if not ok or type(HWIDTable) ~= "table" then
        warn("Failed to load whitelist table.")
        return false
    end

    for _, v in pairs(HWIDTable) do
        if v == HWID then
            print("The HWID is Whitelisted. HWID:", HWID)
            return true
        end
    end

    return false
end

if not isHWIDWhitelisted() then
    LocalPlayer:Kick("Please wait to be whitelisted.")
    return
end

--==============================================================
-- WINDOW / TABS
--==============================================================
local Window = Library:CreateWindow({
    Title = "Guards Hub",
    Center = true,
    AutoShow = true
})

local Tabs = {
    Main = Window:AddTab("Main"),
    ESP      = Window:AddTab("ESP"),
    Combat   = Window:AddTab("Combat"),
    Mission  = Window:AddTab("Auto Mission"),
    AutoBuy  = Window:AddTab("Auto Buy"),
    Settings = Window:AddTab("Settings")
}

--==============================================================
-- SHARED / VARIABLES
--==============================================================
-- Fly
local flying = false
local flySpeed = 80
local control = { F = 0, B = 0, L = 0, R = 0 }
local bodyGyro, bodyVelocity

-- WalkSpeed
local NORMAL_SPEED = 16

-- NoClip
local noClipConn

-- ESP
local espEnabled = false
local espCache = {}

-- Area ESP
local AreaESPObjects = {}
local Areas = {
    ["China Town"]        = Workspace:WaitForChild("Areas"):FindFirstChild("China Town"),
    ["Residential Area"]  = Workspace.Areas:FindFirstChild("Residential Area"),
    ["Outskirts"]         = Workspace.Areas:FindFirstChild("Outskirts"),
}

-- Auto Buy
local RemoteFunction = ReplicatedStorage:WaitForChild("Files")
    :WaitForChild("Framework")
    :WaitForChild("Network")
    :WaitForChild("RemoteFunction")

local itemsToBuy = {
    "Heart","Arm","Leg","Eye",
    "Rare Devil Flesh","Eraser Devil",
    "Common Devil Flesh","Uncommon Devil Flesh"
}
local selectedItem = itemsToBuy[1]

-- Auto Mission
local autoMission = false

--==============================================================
-- AREA ESP HELPERS
--==============================================================
local function getAdornee(area)
    if not area then return end
    if area:IsA("BasePart") then
        return area
    elseif area:IsA("Model") then
        return area.PrimaryPart or area:FindFirstChildWhichIsA("BasePart")
    end
end

local function enableAreaESP()
    for name, area in pairs(Areas) do
        if AreaESPObjects[name] or not area then continue end

        local adornee = getAdornee(area)
        if not adornee then continue end

        local billboard = Instance.new("BillboardGui")
        billboard.Name = "AreaESP"
        billboard.Adornee = adornee
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 8, 0)
        billboard.AlwaysOnTop = true

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = name
        label.TextColor3 = Color3.fromRGB(0, 255, 140)
        label.TextStrokeTransparency = 0.4
        label.Font = Enum.Font.GothamBold
        label.TextScaled = true
        label.Parent = billboard

        billboard.Parent = adornee
        AreaESPObjects[name] = billboard
    end
end

local function disableAreaESP()
    for _, gui in pairs(AreaESPObjects) do
        gui:Destroy()
    end
    table.clear(AreaESPObjects)
end

--==============================================================
-- MOVEMENT: FLY
--==============================================================
local MoveBox = Tabs.Main:AddLeftGroupbox("Fly")

MoveBox:AddToggle("FlyEnabled", { Text = "Enable Fly", Default = false })
MoveBox:AddSlider("FlySpeed",  { Text = "Fly Speed", Min = 20, Max = 200, Default = 80, Rounding = 0 })

Toggles.FlyEnabled:OnChanged(function()
    flying = Toggles.FlyEnabled.Value

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if flying then
        bodyGyro = Instance.new("BodyGyro")
        bodyGyro.P = 100000
        bodyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
        bodyGyro.Parent = hrp

        bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        bodyVelocity.Parent = hrp
    else
        if bodyGyro then bodyGyro:Destroy(); bodyGyro = nil end
        if bodyVelocity then bodyVelocity:Destroy(); bodyVelocity = nil end
    end
end)

Options.FlySpeed:OnChanged(function()
    flySpeed = Options.FlySpeed.Value
end)

UIS.InputBegan:Connect(function(i, g)
    if g then return end
    if i.KeyCode == Enum.KeyCode.W then control.F = 1 end
    if i.KeyCode == Enum.KeyCode.S then control.B = 1 end
    if i.KeyCode == Enum.KeyCode.A then control.L = 1 end
    if i.KeyCode == Enum.KeyCode.D then control.R = 1 end
end)

UIS.InputEnded:Connect(function(i)
    if i.KeyCode == Enum.KeyCode.W then control.F = 0 end
    if i.KeyCode == Enum.KeyCode.S then control.B = 0 end
    if i.KeyCode == Enum.KeyCode.A then control.L = 0 end
    if i.KeyCode == Enum.KeyCode.D then control.R = 0 end
end)

RunService.RenderStepped:Connect(function()
    if flying and bodyGyro and bodyVelocity then
        bodyGyro.CFrame = Camera.CFrame
        local dir = Camera.CFrame.LookVector * (control.F - control.B)
                  + Camera.CFrame.RightVector * (control.R - control.L)

        bodyVelocity.Velocity = dir * flySpeed
    end
end)

--==============================================================
-- MOVEMENT: WALKSPEED
--==============================================================
local WalkBox = Tabs.Main:AddLeftGroupbox("WalkSpeed")

WalkBox:AddToggle("WalkSpeedEnabled", { Text = "Enable WalkSpeed", Default = false })
WalkBox:AddSlider("WalkSpeedValue",   { Text = "Speed", Min = 20, Max = 200, Default = 80, Rounding = 0 })

RunService.RenderStepped:Connect(function()
    if not Toggles.WalkSpeedEnabled.Value then return end

    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    hum.WalkSpeed = Options.WalkSpeedValue.Value
end)

Toggles.WalkSpeedEnabled:OnChanged(function()
    if Toggles.WalkSpeedEnabled.Value then return end

    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = NORMAL_SPEED end
end)

--==============================================================
-- MOVEMENT: NOCLIP (SMOOTH)
--==============================================================
local NoClipBox = Tabs.Main:AddLeftGroupbox("NoClip")
NoClipBox:AddToggle("NoClip", { Text = "Enable NoClip", Default = false })

local function setNoClip(char, state)
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            part.CanCollide = not state
        end
    end
end

local function enableNoClip()
    if noClipConn then return end
    noClipConn = RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end

        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Physics) end

        setNoClip(char, true)
    end)
end

local function disableNoClip()
    if noClipConn then
        noClipConn:Disconnect()
        noClipConn = nil
    end

    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
        setNoClip(char, false)
    end
end

Toggles.NoClip:OnChanged(function()
    if Toggles.NoClip.Value then
        enableNoClip()
    else
        disableNoClip()
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.3)
    if Toggles.NoClip.Value then
        enableNoClip()
    end
end)

--==============================================================
-- MOVEMENT: AUTO RESET SuperDashCD + Eating (AUTO ENTITY)
--==============================================================

local ResetBox = Tabs.Main:AddRightGroupbox("NoCDSuperDash")

ResetBox:AddToggle("ResetDashEating", {
    Text = "NO CD",
    Default = false,
    Tooltip = "Instantly clears SuperDashCD and Eating attributes"
})

local resetConnections = {}
local entityConn
local trackedEntity

local function disconnectAll()
    for _, c in ipairs(resetConnections) do
        pcall(function() c:Disconnect() end)
    end
    table.clear(resetConnections)

    if entityConn then
        pcall(function() entityConn:Disconnect() end)
        entityConn = nil
    end
end

-- ================================
-- ENTITY AUTO DETECT
-- ================================
local function findPlayerEntity()
    local World = workspace:WaitForChild("World", 5)
    local Entities = World and World:WaitForChild("Entities", 5)
    if not Entities then return nil end

    -- most games name entity = player name
    local ent = Entities:FindFirstChild(LocalPlayer.Name)
    if ent then return ent end

    -- fallback: entity with matching UserId attribute
    for _, v in ipairs(Entities:GetChildren()) do
        if v:GetAttribute("UserId") == LocalPlayer.UserId then
            return v
        end
    end

    -- fallback: entity parented to character
    local char = LocalPlayer.Character
    if char then
        for _, v in ipairs(Entities:GetChildren()) do
            if v:IsDescendantOf(char) then
                return v
            end
        end
    end

    return nil
end

-- ================================
-- RESET LOGIC
-- ================================
local function hookEntity(entity)
    trackedEntity = entity
    if not trackedEntity then return end

    local function handleAttr(attr)
        if trackedEntity:GetAttribute(attr) ~= nil then
            trackedEntity:SetAttribute(attr, nil)
            -- debug:
            -- print("[RESET]", attr)
        end
    end

    -- initial cleanup
    handleAttr("SuperDashCD")
    handleAttr("DashCD")

    resetConnections[#resetConnections+1] =
        trackedEntity:GetAttributeChangedSignal("SuperDashCD"):Connect(function()
            handleAttr("SuperDashCD")
        end)

    resetConnections[#resetConnections+1] =
        trackedEntity:GetAttributeChangedSignal("DashCD"):Connect(function()
            handleAttr("DashCD")
        end)

    print("[MOVEMENT] Dash + Eating reset ACTIVE on", trackedEntity.Name)
end

local function StartReset()
    disconnectAll()

    local entity = findPlayerEntity()
    if entity then
        hookEntity(entity)
    else
        warn("[RESET] Player entity not found, waiting...")
    end

    -- re-detect on respawn
    entityConn =
        LocalPlayer.CharacterAdded:Connect(function()
            task.wait(1)
            local newEntity = findPlayerEntity()
            if newEntity then
                hookEntity(newEntity)
            end
        end)
end

local function StopReset()
    disconnectAll()
    trackedEntity = nil
end

-- ================================
-- TOGGLE
-- ================================
Toggles.ResetDashEating:OnChanged(function()
    if Toggles.ResetDashEating.Value then
        StartReset()
        Library:Notify("Dash / Eating Reset Enabled", 3)
    else
        StopReset()
        Library:Notify("Dash / Eating Reset Disabled", 3)
    end
end)

--==============================================================
-- MOVEMENT: INFINITE JUMP (CUSTOM HEIGHT)
--==============================================================

local JumpBox = Tabs.Main:AddRightGroupbox("Jump")

JumpBox:AddToggle("InfiniteJump", {
    Text = "Infinite Jump",
    Default = false,
    Tooltip = "Jump infinitely with adjustable height"
})

JumpBox:AddSlider("JumpPower", {
    Text = "Jump Height",
    Min = 20,
    Max = 200,
    Default = 50,
    Rounding = 0
})

local jumpConn
local charConn
local currentHumanoid

local function applyJumpPower(humanoid)
    if humanoid then
        humanoid.UseJumpPower = true
        humanoid.JumpPower = Options.JumpPower.Value
    end
end

local function hookInfiniteJump(character)
    local humanoid = character:WaitForChild("Humanoid", 5)
    if not humanoid then return end
    currentHumanoid = humanoid

    applyJumpPower(humanoid)

    if jumpConn then jumpConn:Disconnect() end

    jumpConn = UIS.JumpRequest:Connect(function()
        if Toggles.InfiniteJump.Value and currentHumanoid then
            currentHumanoid.JumpPower = Options.JumpPower.Value
            currentHumanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end

local function enableInfiniteJump()
    local char = LocalPlayer.Character
    if char then
        hookInfiniteJump(char)
    end

    charConn = LocalPlayer.CharacterAdded:Connect(function(char)
        task.wait(0.3)
        hookInfiniteJump(char)
    end)
end

local function disableInfiniteJump()
    if jumpConn then
        jumpConn:Disconnect()
        jumpConn = nil
    end

    if currentHumanoid then
        currentHumanoid.JumpPower = 50 -- Roblox default
        currentHumanoid = nil
    end

    if charConn then
        charConn:Disconnect()
        charConn = nil
    end
end

Options.JumpPower:OnChanged(function()
    if currentHumanoid then
        applyJumpPower(currentHumanoid)
    end
end)

Toggles.InfiniteJump:OnChanged(function()
    if Toggles.InfiniteJump.Value then
        enableInfiniteJump()
        Library:Notify("Infinite Jump Enabled", 3)
    else
        disableInfiniteJump()
        Library:Notify("Infinite Jump Disabled", 3)
    end
end)


--==============================================================
-- MAIN TAB: REJOIN SAME SERVER
--==============================================================

local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

local MainBox = Tabs.Main:AddRightGroupbox("Server")

MainBox:AddButton({
    Text = "Rejoin Server",
    Func = function()
        local player = Players.LocalPlayer

        if game.JobId and game.JobId ~= "" then
            TeleportService:TeleportToPlaceInstance(
                game.PlaceId,
                game.JobId,
                player
            )
        else
            Library:Notify("Rejoin Failed", "JobId not available", 3)
        end
    end
})

--==============================================================
-- MAIN TAB: RESET CHARACTER
--==============================================================

local Players = game:GetService("Players")

local ResetBox = Tabs.Main:AddRightGroupbox("Character")

ResetBox:AddButton({
    Text = "Reset Character",
    Func = function()
        local player = Players.LocalPlayer
        local character = player.Character

        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.Health = 0
            end
        end
    end
})

-- ===============================
-- NO FOG (PERSISTENT)
-- ===============================

local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local NoFogEnabled = false
local FogConnection

-- Save originals
local Original = {
    FogStart = Lighting.FogStart,
    FogEnd = Lighting.FogEnd
}

local function applyNoFog()
    Lighting.FogStart = 1e6
    Lighting.FogEnd = 1e6

    for _, v in ipairs(Lighting:GetChildren()) do
        if v:IsA("Atmosphere") then
            v.Density = 0
            v.Haze = 0
            v.Glare = 0
        end
    end
end

local function enableNoFog()
    applyNoFog()

    -- Force it every frame (lightweight)
    FogConnection = RunService.RenderStepped:Connect(function()
        if NoFogEnabled then
            applyNoFog()
        end
    end)
end

local function disableNoFog()
    if FogConnection then
        FogConnection:Disconnect()
        FogConnection = nil
    end

    Lighting.FogStart = Original.FogStart
    Lighting.FogEnd = Original.FogEnd
end

-- ===============================
-- MAIN TAB (YOUR HUB STYLE)
-- ===============================
local WorldBox = Tabs.Main:AddRightGroupbox("World")

WorldBox:AddToggle("NoFogToggle", {
    Text = "Remove Fog",
    Default = false,
    Callback = function(state)
        NoFogEnabled = state
        if state then
            enableNoFog()
        else
            disableNoFog()
        end
    end
})

warn("[NO FOG] Persistent mode loaded")

--==============================================================
-- ESP TAB (PLAYER ESP + AREA ESP)
--==============================================================
local ESPBox = Tabs.ESP:AddLeftGroupbox("ESP")

ESPBox:AddToggle("ESPEnabled", { Text = "PlayerESP+SoulBar", Default = false })




local function getSoul(plr)
    local world = Workspace:FindFirstChild("World")
    local entities = world and world:FindFirstChild("Entities")
    local ent = entities and entities:FindFirstChild(plr.Name)
    local info = ent and ent:FindFirstChild("Info")
    return info and info:FindFirstChild("Soul")
end

local function createESP(plr)
    if espCache[plr] or plr == LocalPlayer then return end
    local char = plr.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local soulPart = getSoul(plr)
    if not hrp or not humanoid or not soulPart then return end

    local gui = Instance.new("BillboardGui")
    gui.Name = "ESP"
    gui.Adornee = hrp
    gui.Size = UDim2.new(0, 120, 0, 50)
    gui.StudsOffset = Vector3.new(0, 3, 0)
    gui.AlwaysOnTop = true
    gui.Parent = hrp

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 20)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 14
    nameLabel.TextStrokeTransparency = 0.5
    nameLabel.Text = plr.Name .. " [0]"
    nameLabel.Parent = gui

    local healthBG = Instance.new("Frame")
    healthBG.Size = UDim2.new(1, 0, 0, 5)
    healthBG.Position = UDim2.new(0, 0, 0, 20)
    healthBG.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    healthBG.BorderSizePixel = 0
    healthBG.Parent = gui

    local healthBar = Instance.new("Frame")
    healthBar.Size = UDim2.new(1, 0, 1, 0)
    healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    healthBar.BorderSizePixel = 0
    healthBar.Parent = healthBG

    local soulBG = Instance.new("Frame")
    soulBG.Size = UDim2.new(1, 0, 0, 5)
    soulBG.Position = UDim2.new(0, 0, 0, 27)
    soulBG.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    soulBG.BorderSizePixel = 0
    soulBG.Parent = gui

    local soulBar = Instance.new("Frame")
    soulBar.Size = UDim2.new(1, 0, 1, 0)
    soulBar.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    soulBar.BorderSizePixel = 0
    soulBar.Parent = soulBG

    espCache[plr] = {
        Gui = gui,
        HealthBar = healthBar,
        SoulBar = soulBar,
        NameLabel = nameLabel,
        Humanoid = humanoid,
        Soul = soulPart
    }
end

local function removeESP(plr)
    local data = espCache[plr]
    if data then
        data.Gui:Destroy()
        espCache[plr] = nil
    end
end

Toggles.ESPEnabled:OnChanged(function()
    espEnabled = Toggles.ESPEnabled.Value
    for _, p in ipairs(Players:GetPlayers()) do
        if espEnabled then createESP(p) else removeESP(p) end
    end
end)

Players.PlayerAdded:Connect(function(p)
    if not espEnabled then return end
    p.CharacterAdded:Connect(function()
        task.wait(1)
        createESP(p)
    end)
end)

Players.PlayerRemoving:Connect(removeESP)

RunService.RenderStepped:Connect(function()
    if not espEnabled then return end

    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    for plr, data in pairs(espCache) do
        local char = plr.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root then
            local hum = data.Humanoid
            local soul = data.Soul

            data.HealthBar.Size = UDim2.new(math.clamp(hum.Health / hum.MaxHealth, 0, 1), 0, 1, 0)
            if soul then
                data.SoulBar.Size = UDim2.new(math.clamp(soul.Value / 100, 0, 1), 0, 1, 0)
            end

            local dist = math.floor((root.Position - myRoot.Position).Magnitude)
            data.NameLabel.Text = plr.Name .. " [" .. dist .. "]"
        end
    end
end)

local MobESPBox = Tabs.ESP:AddLeftGroupbox("Mob ESP")

MobESPBox:AddToggle("MobHealthESP", {
    Text = "Mob ESP (Distance+HP+Name)",
    Default = false
})




-- ===============================
-- MOB HEALTH ESP (TOGGLE CONTROLLED)
-- ===============================

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LP = Players.LocalPlayer

local ENTITY_FOLDER = workspace
    :WaitForChild("World")
    :WaitForChild("Entities")

local MAX_DISTANCE = 500
local espObjects = {}
local espConnection

-- -------------------------------
-- HELPERS
-- -------------------------------
local function isPlayerCharacter(model)
    return Players:GetPlayerFromCharacter(model) ~= nil
end

local function getRoot(model)
    return model:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid(model)
    return model:FindFirstChildOfClass("Humanoid")
end

-- -------------------------------
-- CREATE ESP
-- -------------------------------
local function createESP(npc)
    if espObjects[npc] then return end

    local root = getRoot(npc)
    local hum = getHumanoid(npc)
    if not root or not hum then return end

    local gui = Instance.new("BillboardGui")
    gui.Name = "NPC_HEALTH_ESP"
    gui.Adornee = root
    gui.Size = UDim2.fromOffset(200, 60)
    gui.StudsOffset = Vector3.new(0, 4, 0)
    gui.AlwaysOnTop = true

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.TextStrokeTransparency = 0.35
    label.TextColor3 = Color3.fromRGB(190, 80, 255)
    label.Parent = gui

    gui.Parent = root

    espObjects[npc] = {
        Gui = gui,
        Label = label,
        Humanoid = hum
    }
end

-- -------------------------------
-- REMOVE ESP
-- -------------------------------
local function removeESP(npc)
    if espObjects[npc] then
        espObjects[npc].Gui:Destroy()
        espObjects[npc] = nil
    end
end

local function clearAllESP()
    for npc in pairs(espObjects) do
        removeESP(npc)
    end
end

-- -------------------------------
-- MAIN UPDATE LOOP
-- -------------------------------
local function startESP()
    if espConnection then return end

    espConnection = RunService.Heartbeat:Connect(function()
        local myChar = LP.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myRoot then return end

        for _, npc in ipairs(ENTITY_FOLDER:GetChildren()) do
            if npc:IsA("Model")
            and not isPlayerCharacter(npc)
            and getHumanoid(npc)
            and getRoot(npc) then

                local root = getRoot(npc)
                local hum = getHumanoid(npc)
                local dist = (root.Position - myRoot.Position).Magnitude

                if dist <= MAX_DISTANCE then
                    createESP(npc)

                    local data = espObjects[npc]
                    if data then
                        local distance = math.floor(dist)

data.Label.Text = string.format(
    "%s\n%dm • %d / %d",
    npc.Name,
    distance,
    math.floor(hum.Health),
    math.floor(hum.MaxHealth)
)

                    end
                else
                    removeESP(npc)
                end
            else
                removeESP(npc)
            end
        end

        -- cleanup despawned mobs
        for npc in pairs(espObjects) do
            if not npc.Parent then
                removeESP(npc)
            end
        end
    end)
end

local function stopESP()
    if espConnection then
        espConnection:Disconnect()
        espConnection = nil
    end
    clearAllESP()
end

-- -------------------------------
-- TOGGLE HANDLER
-- -------------------------------
Toggles.MobHealthESP:OnChanged(function()
    if Toggles.MobHealthESP.Value then
        startESP()
        Library:Notify("Mob Health ESP Enabled", 3)
    else
        stopESP()
        Library:Notify("Mob Health ESP Disabled", 3)
    end
end)



--==============================================================
-- COMBAT: BACK GLIDE
--==============================================================
local CombatBox = Tabs.Combat:AddLeftGroupbox("Movement Combat")

CombatBox:AddToggle("BackGlide", {
    Text = "RunningAttackLockOn",
    Default = false,
    Tooltip = "Glide behind nearest target on animation"
})

CombatBox:AddSlider("BackGlideSpeed", {
    Text = "Glide Speed",
    Default = 0.05,
    Min = 0.01,
    Max = 0.3,
    Rounding = 2
})

CombatBox:AddSlider("BackGlideDistance", {
    Text = "Max Target Distance",
    Default = 15,
    Min = 5,
    Max = 50,
    Rounding = 0
})

CombatBox:AddSlider("BackGlideOffset", {
    Text = "Behind Offset",
    Default = 1,
    Min = 0.5,
    Max = 5,
    Rounding = 1
})

local cleanupConnections = {}
local SETTINGS = { ANIM_ID = "91695353081923" }

local function cleanupBackGlide()
    for _, c in ipairs(cleanupConnections) do
        pcall(function() c:Disconnect() end)
    end
    table.clear(cleanupConnections)
end

local function getRoot(char)
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getClosestTarget()
    local myChar = LocalPlayer.Character
    local myRoot = getRoot(myChar)
    if not myRoot then return end

    local closest, best = nil, Options.BackGlideDistance.Value
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local root = getRoot(plr.Character)
            if root then
                local d = (root.Position - myRoot.Position).Magnitude
                if d < best then
                    best = d
                    closest = root
                end
            end
        end
    end
    return closest
end

local function hookHumanoid(hum)
    local conn = hum.AnimationPlayed:Connect(function(track)
        if not track.Animation then return end
        if not track.Animation.AnimationId:find(SETTINGS.ANIM_ID) then return end

        local glideConn
        glideConn = RunService.RenderStepped:Connect(function()
            if not track.IsPlaying or not Toggles.BackGlide.Value then
                glideConn:Disconnect()
                return
            end

            local myChar = LocalPlayer.Character
            local myRoot = getRoot(myChar)
            local targetRoot = getClosestTarget()
            if not myRoot or not targetRoot then return end

            local behindPos = targetRoot.Position - targetRoot.CFrame.LookVector * Options.BackGlideOffset.Value
            myRoot.CFrame = myRoot.CFrame:Lerp(CFrame.new(behindPos, targetRoot.Position), Options.BackGlideSpeed.Value)
        end)

        table.insert(cleanupConnections, glideConn)
    end)

    table.insert(cleanupConnections, conn)
end

local function onCharacter(char)
    local hum = char:WaitForChild("Humanoid")
    hookHumanoid(hum)
end

Toggles.BackGlide:OnChanged(function()
    cleanupBackGlide()
    if not Toggles.BackGlide.Value then return end

    if LocalPlayer.Character then
        onCharacter(LocalPlayer.Character)
    end

    table.insert(cleanupConnections, LocalPlayer.CharacterAdded:Connect(onCharacter))
end)






-- =====================================
-- DASH SPAM + MUTE DASH (COMBAT TAB)
-- =====================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

-- DASH REMOTE (FROM REMOTESPY)
local DashRemote =
    ReplicatedStorage
        :WaitForChild("Files")
        :WaitForChild("Framework")
        :WaitForChild("Network")
        :WaitForChild("RemoteEvent")

-- STATE
local DashSpamEnabled = false

-- ===============================
-- MUTE ALL DASH SOUNDS
-- ===============================
local function muteDash(sound)
    if not sound:IsA("Sound") then return end

    local name = sound.Name:lower()
    local id = tostring(sound.SoundId):lower()

    if name:find("dash") or id:find("dash") then
        sound.Volume = 0
        sound.Looped = false
        sound:Stop()
    end
end

-- Existing sounds
for _, s in ipairs(game:GetDescendants()) do
    muteDash(s)
end

-- Future sounds
game.DescendantAdded:Connect(muteDash)

-- ===============================
-- DASH SPAM LOOP (SAFE)
-- ===============================
task.spawn(function()
    while true do
        if DashSpamEnabled then
            DashRemote:FireServer(
                "Event",
                {
                    Name = "Dash",
                    Args = false
                }
            )
        end
        RunService.Heartbeat:Wait()
    end
end)

-- ===============================
-- LINORIA TOGGLE (COMBAT TAB)
-- ===============================
local DashBox = Tabs.Combat:AddLeftGroupbox("God Mode")

DashBox:AddToggle("DashSpam", {
    Text = "God Mode",
    Default = false,
    Callback = function(state)
        DashSpamEnabled = state
    end
})

warn("[COMBAT] Dash Spam toggle loaded")










--==============================================================
-- AUTO BUY
--==============================================================
local BuyBox = Tabs.AutoBuy:AddLeftGroupbox("Shop")

BuyBox:AddDropdown("BuyItem", {
    Text = "Select Item",
    Values = itemsToBuy,
    Default = 1
})

Options.BuyItem:OnChanged(function()
    selectedItem = Options.BuyItem.Value
end)

BuyBox:AddButton({
    Text = "Buy Item",
    Func = function()
        if selectedItem then
            RemoteFunction:InvokeServer("BM_Buy", { itemId = selectedItem, currency = "yen" })
        end
    end
})

--==============================================================
-- AUTO MISSION (FULL TP VERSION)
--==============================================================

local MissionBox = Tabs.Mission:AddLeftGroupbox("Missions")

MissionBox:AddToggle("AutoMission", {
    Text = "Auto Mission",
    Default = false
})

local missionRunning = false
local connections = {}
local threads = {}

local function CleanupMission()
    for _, c in ipairs(connections) do
        pcall(function() c:Disconnect() end)
    end
    for _, t in ipairs(threads) do
        pcall(function() task.cancel(t) end)
    end
    table.clear(connections)
    table.clear(threads)
end

local function StartAutoMission()
    if missionRunning then return end
    missionRunning = true

    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local RunService = game:GetService("RunService")
    local VirtualInputManager = game:GetService("VirtualInputManager")

    local LP = Players.LocalPlayer

    local MissionFeed =
        LP.PlayerGui:WaitForChild("HUD")
            :WaitForChild("Phone")
            :WaitForChild("Missions")
            :WaitForChild("MissionFeed")

    local RemoteFunction =
        ReplicatedStorage
            :WaitForChild("Files")
            :WaitForChild("Framework")
            :WaitForChild("Network")
            :WaitForChild("RemoteFunction")

    -- ================================
    -- TELEPORT POSITIONS (YOUR ORIGINAL)
    -- ================================
    local DETECT_POS = Vector3.new(-833, 6, -750)
    local TP_1 = Vector3.new(-1021, -9, -684)
    local TP_2 = Vector3.new(112, -9, -744)
    local TP_3 = Vector3.new(112, -100, -744)
    local DETECT_RADIUS = 10

    -- ================================
    -- MISSION STORAGE
    -- ================================
    local MISSION_IDS = {}
    local SEEN = {}

    local function isUUID(str)
        return type(str) == "string"
            and str:match("^%x%x%x%x%x%x%x%x%-%x%x%x%x%-4%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$")
    end

    local function addMissionId(id)
        if not SEEN[id] then
            SEEN[id] = true
            table.insert(MISSION_IDS, id)
        end
    end

    for _, v in ipairs(MissionFeed:GetChildren()) do
        if v:IsA("GuiObject") and isUUID(v.Name) then
            addMissionId(v.Name)
        end
    end

    connections[#connections+1] =
        MissionFeed.ChildAdded:Connect(function(child)
            if child:IsA("GuiObject") and isUUID(child.Name) then
                addMissionId(child.Name)
            end
        end)

    -- ================================
    -- HELPERS
    -- ================================
    local function getRoot()
        local char = LP.Character
        return char and char:FindFirstChild("HumanoidRootPart")
    end

    local holdingPos = false
    local holdCFrame

    connections[#connections+1] =
        RunService.Stepped:Connect(function()
            if holdingPos then
                local char = LP.Character
                if char then
                    for _, p in ipairs(char:GetDescendants()) do
                        if p:IsA("BasePart") then
                            p.CanCollide = false
                        end
                    end
                end
            end
        end)

    connections[#connections+1] =
        RunService.Heartbeat:Connect(function()
            if holdingPos and holdCFrame then
                local root = getRoot()
                if root then
                    root.AssemblyLinearVelocity = Vector3.zero
                    root.AssemblyAngularVelocity = Vector3.zero
                    root.CFrame = holdCFrame
                end
            end
        end)

    local function startHold(pos)
        holdingPos = true
        holdCFrame = CFrame.new(pos)
    end

    local function stopHold()
        holdingPos = false
        holdCFrame = nil
    end

    local function fireAllMissions()
        for _, id in ipairs(MISSION_IDS) do
            RemoteFunction:InvokeServer(
                "OverworldMissions",
                {
                    Identification = id,
                    Conditions = {"Flawless","Bloodlust"},
                    Directive = "Cleanup Duty",
                    Request = "Engage"
                }
            )
            task.wait(0.05)
        end
    end

    local function pressE()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        task.wait(0.03)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    end

    -- ================================
    -- MAIN LOOP (UNCHANGED FROM YOUR SCRIPT)
    -- ================================
    threads[#threads+1] =
        task.spawn(function()
            while missionRunning do
                fireAllMissions()

                repeat
                    task.wait()
                    local root = getRoot()
                    if root and (root.Position - DETECT_POS).Magnitude <= DETECT_RADIUS then
                        break
                    end
                until not missionRunning

                if not missionRunning then break end

                -- E spam
                local eThread = task.spawn(function()
                    while missionRunning do
                        pressE()
                        task.wait(0.08)
                    end
                end)
                table.insert(threads, eThread)

                task.wait(0.5)
                local root = getRoot()
                if not root then break end

                root.CFrame = CFrame.new(TP_1)
                startHold(TP_1)
                task.wait(3)

                root.CFrame = CFrame.new(TP_2)
                startHold(TP_2)
                task.wait(2)

                root.CFrame = CFrame.new(TP_3)
                startHold(TP_3)
                task.wait(6.5)

                fireAllMissions()
                task.cancel(eThread)
                stopHold()
                task.wait(0.5)
            end
        end)
end

local function StopAutoMission()
    missionRunning = false
    CleanupMission()
end

Toggles.AutoMission:OnChanged(function()
    if Toggles.AutoMission.Value then
        StartAutoMission()
        Library:Notify("Auto Mission Enabled", 3)
    else
        StopAutoMission()
        Library:Notify("Auto Mission Disabled", 3)
    end
end)



--==============================================================
-- SETTINGS (THEME / CONFIG)
--==============================================================

Library.ToggleKeybind = Options.MenuKeybind
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

ThemeManager:ApplyToTab(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
Library:Notify("Custom Hub Loaded", 3)
end

--========================
-- KEY SYSTEM UI
--========================
local function CreateKeyUI(onSuccess)
    local old = PlayerGui:FindFirstChild("KeySystemGui")
    if old then old:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "KeySystemGui"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = PlayerGui

    local overlay = Instance.new("Frame")
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.35
    overlay.BorderSizePixel = 0
    overlay.Parent = screenGui

    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, 420, 0, 0)         -- height auto
    main.AutomaticSize = Enum.AutomaticSize.Y   -- 🔥 auto-fit contents
    main.AnchorPoint = Vector2.new(0.5, 0.5)
    main.Position = UDim2.new(0.5, 0, 0.5, 0)
    main.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    main.BorderSizePixel = 0
    main.Parent = overlay

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 10)
    mainCorner.Parent = main

    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = Color3.fromRGB(40, 40, 40)
    mainStroke.Thickness = 1
    mainStroke.Parent = main

    --========================
    -- TOP BAR
    --========================
    local topBar = Instance.new("Frame")
    topBar.Name = "TopBar"
    topBar.Size = UDim2.new(1, 0, 0, 44)
    topBar.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
    topBar.BorderSizePixel = 0
    topBar.Parent = main

    local topCorner = Instance.new("UICorner")
    topCorner.CornerRadius = UDim.new(0, 10)
    topCorner.Parent = topBar

    -- mask so only top corners look rounded
    local mask = Instance.new("Frame")
    mask.Size = UDim2.new(1, 0, 0, 10)
    mask.Position = UDim2.new(0, 0, 1, -10)
    mask.BackgroundColor3 = topBar.BackgroundColor3
    mask.BorderSizePixel = 0
    mask.Parent = topBar

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -80, 1, 0)
    title.Position = UDim2.new(0, 14, 0, 0)
    title.BackgroundTransparency = 1
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "Guards Hub  •  Key System"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextColor3 = Color3.fromRGB(235, 235, 235)
    title.Parent = topBar

    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0, 32, 0, 26)
    close.Position = UDim2.new(1, -42, 0.5, -13)
    close.Text = "✕"
    close.Font = Enum.Font.GothamBold
    close.TextSize = 14
    close.TextColor3 = Color3.fromRGB(220, 220, 220)
    close.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    close.BorderSizePixel = 0
    close.Parent = topBar

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = close

    --========================
    -- BODY (STACKED LAYOUT)
    --========================
    local body = Instance.new("Frame")
    body.Name = "Body"
    body.Size = UDim2.new(1, 0, 0, 0)
    body.AutomaticSize = Enum.AutomaticSize.Y
    body.Position = UDim2.new(0, 0, 0, 44)
    body.BackgroundTransparency = 1
    body.Parent = main

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 14)
    pad.PaddingRight = UDim.new(0, 14)
    pad.PaddingTop = UDim.new(0, 14)
    pad.PaddingBottom = UDim.new(0, 14)
    pad.Parent = body

    local stack = Instance.new("UIListLayout")
    stack.FillDirection = Enum.FillDirection.Vertical
    stack.SortOrder = Enum.SortOrder.LayoutOrder
    stack.Padding = UDim.new(0, 10)
    stack.Parent = body

    local info = Instance.new("TextLabel")
    info.LayoutOrder = 1
    info.Size = UDim2.new(1, 0, 0, 18)
    info.BackgroundTransparency = 1
    info.TextXAlignment = Enum.TextXAlignment.Left
    info.Text = "Enter your key to continue."
    info.Font = Enum.Font.Gotham
    info.TextSize = 13
    info.TextColor3 = Color3.fromRGB(170, 170, 170)
    info.Parent = body

    local keyBox = Instance.new("TextBox")
    keyBox.LayoutOrder = 2
    keyBox.Size = UDim2.new(1, 0, 0, 36)
    keyBox.PlaceholderText = "Key..."
    keyBox.ClearTextOnFocus = false
    keyBox.Font = Enum.Font.Gotham
    keyBox.TextSize = 13
    keyBox.TextColor3 = Color3.fromRGB(235, 235, 235)
    keyBox.PlaceholderColor3 = Color3.fromRGB(130, 130, 130)
    keyBox.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
    keyBox.BorderSizePixel = 0
    keyBox.Parent = body

    local keyCorner = Instance.new("UICorner")
    keyCorner.CornerRadius = UDim.new(0, 8)
    keyCorner.Parent = keyBox

    local keyStroke = Instance.new("UIStroke")
    keyStroke.Color = Color3.fromRGB(45, 45, 45)
    keyStroke.Thickness = 1
    keyStroke.Parent = keyBox

    local function makeButton(text, subText, order)
        local btn = Instance.new("TextButton")
        btn.LayoutOrder = order
        btn.Size = UDim2.new(1, 0, 0, 44) -- taller for subtext
        btn.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
        btn.Text = ""
        btn.BorderSizePixel = 0
        btn.Parent = body

        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 8)
        c.Parent = btn

        local s = Instance.new("UIStroke")
        s.Color = Color3.fromRGB(45, 45, 45)
        s.Thickness = 1
        s.Parent = btn

        local t = Instance.new("TextLabel")
        t.BackgroundTransparency = 1
        t.Size = UDim2.new(1, -14, 0, 20)
        t.Position = UDim2.new(0, 12, 0, 6)
        t.TextXAlignment = Enum.TextXAlignment.Left
        t.Text = text
        t.TextColor3 = Color3.fromRGB(235, 235, 235)
        t.Font = Enum.Font.GothamBold
        t.TextSize = 13
        t.Parent = btn

        local st = Instance.new("TextLabel")
        st.BackgroundTransparency = 1
        st.Size = UDim2.new(1, -14, 0, 16)
        st.Position = UDim2.new(0, 12, 0, 24)
        st.TextXAlignment = Enum.TextXAlignment.Left
        st.Text = subText
        st.TextColor3 = Color3.fromRGB(150, 150, 150)
        st.Font = Enum.Font.Gotham
        st.TextSize = 11
        st.Parent = btn

        btn.MouseEnter:Connect(function()
            btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        end)
        btn.MouseLeave:Connect(function()
            btn.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
        end)

        return btn
    end

    local submit = makeButton("Submit", "Verify key and load hub", 3)
    local getKey = makeButton("Get Key", "Copy key link to clipboard", 4)
    local discord = makeButton("Join Discord", "Copy discord invite to clipboard", 5)

    --========================
    -- DRAGGING (WORKS WITH ANCHORPOINT)
    --========================
    do
        local dragging, dragStart, startPos

        topBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = main.Position
            end
        end)

        topBar.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)

        UIS.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - dragStart
                main.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            end
        end)
    end

    --========================
    -- ACTIONS
    --========================
    close.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)

    submit.MouseButton1Click:Connect(function()
        if keyBox.Text == CORRECT_KEY then
            Notify("Success", "Key Verified ✅", 3)
            screenGui:Destroy()
            onSuccess()
        else
            Notify("Error", "Wrong key! Please get the correct key.", 5)
        end
    end)

    getKey.MouseButton1Click:Connect(function()
        if setclipboard then
            setclipboard(GET_KEY_LINK)
            Notify("Key", "Link copied. Paste it in your browser to get the key.", 6)
        else
            Notify("Key", "setclipboard not supported by your executor.", 5)
        end
    end)

    discord.MouseButton1Click:Connect(function()
        if setclipboard then
            setclipboard(DISCORD_LINK)
            Notify("Discord", "Discord link copied to clipboard.", 3)
        else
            Notify("Discord", "setclipboard not supported by your executor.", 5)
        end
    end)

    keyBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            submit:Activate()
        end
    end)
end

--==============================================================
-- SHOW KEY UI -> START HUB ON SUCCESS
--==============================================================
CreateKeyUI(StartHub)
