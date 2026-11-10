if not game:IsLoaded() then game.Loaded:Wait() end
if game.GameId ~= 66654135 then
    game:GetService("Players").LocalPlayer:Kick("This script is only for Murder Mystery 2")
    return
end
if getgenv().MM2FarmCleanup then pcall(getgenv().MM2FarmCleanup) end

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/hoquocluc9182-del/library-ui/refs/heads/main/Arsenic-Toxic.lua"))()

local Win = Library:Window({
    Title = "MM2 Farm",
    Size = UDim2.fromOffset(540, 420),
})

local CONFIG = {
    CoinSkipTime = 3, Noclip = true, AutoDie = true, TargetCoins = 50,
    AntiAfk = true, CacheMapTime = 5, OverlayRefresh = 1.0,
    TeleportDelay = 1.5, SpinDuration = 0.5, TeleSpeed = 300, FarmSpeed = 20,
    FarmMode = "Teleport"
}

local STATE = {
    Running = false, BagCurrent = 0, BagMax = 0, Status = "Ready",
    CoinsTotal = 0, CoinsThisRound = 0, Rounds = 0,
    SkippedCoins = {}, NoclipConn = nil, Mover = nil, Attachment = nil,
    HasDiedThisRound = false, LastBagCount = 0,
    CachedMap = nil, CachedContainer = nil,
    LastMapCheck = 0, CachedCoinList = nil, LastCoinListTime = 0,
    Phase = "Idle", CurrentCoin = nil,
    TeleStartTime = 0, TeleDuration = 0,
    SpinStartTime = 0, WaitStartTime = 0,
}

local CONNECTIONS = {}
local function Track(conn) CONNECTIONS[#CONNECTIONS + 1] = conn return conn end
local function DisconnectAll()
    for _, conn in ipairs(CONNECTIONS) do pcall(function() conn:Disconnect() end) end
    table.clear(CONNECTIONS)
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local TweenService = game:GetService("TweenService")
local LP = Players.LocalPlayer

local CoinCollected, CoinsStarted, RoundStart
do
    local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
    local gameplay = remotes and remotes:WaitForChild("Gameplay", 10)
    if gameplay then
        CoinCollected = gameplay:FindFirstChild("CoinCollected")
        CoinsStarted = gameplay:FindFirstChild("CoinsStarted")
        RoundStart = gameplay:FindFirstChild("RoundStart")
    end
end

if CoinCollected then
    Track(CoinCollected.OnClientEvent:Connect(function(_, current, maximum)
        STATE.BagCurrent = tonumber(current) or 0
        STATE.BagMax = tonumber(maximum) or 0
        STATE.CoinsTotal += 1
        STATE.CoinsThisRound += 1
    end))
end

local function OnNewRound()
    STATE.BagCurrent = 0; STATE.BagMax = 0; STATE.CoinsThisRound = 0
    STATE.Rounds += 1; STATE.HasDiedThisRound = false; STATE.LastBagCount = 0
    STATE.Phase = "Idle"; STATE.CurrentCoin = nil
    table.clear(STATE.SkippedCoins)
    STATE.CachedMap = nil; STATE.CachedContainer = nil; STATE.LastMapCheck = 0; STATE.CachedCoinList = nil
end

if CoinsStarted then Track(CoinsStarted.OnClientEvent:Connect(OnNewRound)) end
if RoundStart then Track(RoundStart.OnClientEvent:Connect(OnNewRound)) end

local function GetRoot() local c = LP.Character return c and c:FindFirstChild("HumanoidRootPart") end
local function GetHumanoid() local c = LP.Character return c and c:FindFirstChildOfClass("Humanoid") end

local function GetMap()
    local now = os.clock()
    if STATE.CachedMap and STATE.CachedMap.Parent and now - STATE.LastMapCheck < CONFIG.CacheMapTime then 
        return STATE.CachedMap, STATE.CachedContainer 
    end
    STATE.LastMapCheck = now
    for _, child in ipairs(workspace:GetChildren()) do
        if child.Name ~= "RegularLobby" and child:IsA("Model") then
            local container = child:FindFirstChild("CoinContainer", true)
            if container then
                STATE.CachedMap = child; STATE.CachedContainer = container; STATE.CachedCoinList = nil
                return child, container
            end
        end
    end
    STATE.CachedMap = nil; STATE.CachedContainer = nil; STATE.CachedCoinList = nil
    return nil, nil
end

local function GetCoinList()
    local container = STATE.CachedContainer
    if not container or not container.Parent then return nil end
    local now = os.clock()
    if STATE.CachedCoinList and now - STATE.LastCoinListTime < 1 then return STATE.CachedCoinList end
    STATE.LastCoinListTime = now
    local list = container:GetChildren()
    STATE.CachedCoinList = list
    return list
end

local function CountCoins()
    local list = GetCoinList()
    if not list then return 0 end
    local n = 0
    for i = 1, #list do
        local v = list[i]:FindFirstChild("CoinVisual")
        if v and not v:GetAttribute("Collected") then n += 1 end
    end
    return n
end

local function FindNearestCoin(origin)
    local list = GetCoinList()
    if not list then return nil end
    local best, bestDist
    local now = os.clock()
    local ox, oy, oz = origin.X, origin.Y, origin.Z
    for i = 1, #list do
        local coin = list[i]
        if coin:IsA("BasePart") then
            local visual = coin:FindFirstChild("CoinVisual")
            if visual and not visual:GetAttribute("Collected") then
                local skippedAt = STATE.SkippedCoins[coin]
                if not (skippedAt and now - skippedAt < CONFIG.CoinSkipTime) then
                    local p = coin.Position
                    local dist = math.sqrt((p.X-ox)^2 + (p.Y-oy)^2 + (p.Z-oz)^2)
                    if not bestDist or dist < bestDist then best, bestDist = coin, dist end
                end
            end
        end
    end
    return best
end

local function GetTarget() return STATE.BagMax > 0 and STATE.BagMax or CONFIG.TargetCoins end
local function BagFull() return STATE.BagCurrent > 0 and STATE.BagCurrent >= GetTarget() end

local function SetNoclip(enabled)
    if STATE.NoclipConn then STATE.NoclipConn:Disconnect(); STATE.NoclipConn = nil end
    if enabled then
        STATE.NoclipConn = RunService.Stepped:Connect(function()
            local c = LP.Character
            if not c then return end
            for _, part in ipairs(c:GetChildren()) do
                if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
            end
        end)
    end
end

local function AttachMover(hrp)
    if STATE.Mover then return end
    local att = Instance.new("Attachment")
    att.Parent = hrp
    local mover = Instance.new("LinearVelocity")
    mover.Attachment0 = att
    mover.MaxForce = math.huge
    mover.RelativeTo = Enum.ActuatorRelativeTo.World
    mover.VectorVelocity = Vector3.zero
    mover.Parent = hrp
    STATE.Mover = mover
    STATE.Attachment = att
end

local function DetachMover()
    if STATE.Mover then STATE.Mover:Destroy(); STATE.Mover = nil end
    if STATE.Attachment then STATE.Attachment:Destroy(); STATE.Attachment = nil end
end

Track(LP.Idled:Connect(function()
    if not CONFIG.AntiAfk then return end
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.zero)
end))

task.spawn(function()
    while task.wait(0.03) do
        pcall(function()
            if not STATE.Running then 
                STATE.Phase = "Idle"
                DetachMover()
                return 
            end
            
            local hrp = GetRoot()
            local hum = GetHumanoid()
            
            if not hrp or not hum or hum.Health <= 0 then
                STATE.Status = "Waiting for character..."
                STATE.Phase = "Idle"
                DetachMover()
                return
            end
            
            if STATE.Phase == "Teleporting" then
                if os.clock() >= STATE.TeleStartTime + STATE.TeleDuration then
                    STATE.Phase = "Spinning"
                    STATE.SpinStartTime = os.clock()
                end
                return
            end
            
            if STATE.Phase == "Flying" then
                local coin = STATE.CurrentCoin
                if not coin or not coin.Parent then
                    DetachMover()
                    STATE.Phase = "Idle"
                    return
                end
                local dist = (hrp.Position - coin.Position).Magnitude
                if dist < 5 then
                    DetachMover()
                    STATE.Phase = "Spinning"
                    STATE.SpinStartTime = os.clock()
                else
                    if not STATE.Mover or STATE.Mover.Parent ~= hrp then
                        DetachMover()
                        AttachMover(hrp)
                    end
                    local delta = coin.Position - hrp.Position
                    STATE.Mover.VectorVelocity = delta.Unit * CONFIG.FarmSpeed
                end
                return
            end
            
            if STATE.Phase == "Spinning" then
                local coin = STATE.CurrentCoin
                if not coin or not coin.Parent then
                    STATE.Phase = "Idle"
                    return
                end
                
                local elapsed = os.clock() - STATE.SpinStartTime
                if elapsed >= CONFIG.SpinDuration then
                    if CONFIG.FarmMode == "Teleport" then
                        STATE.Phase = "Waiting"
                        STATE.WaitStartTime = os.clock()
                    else
                        if STATE.CurrentCoin then
                            STATE.SkippedCoins[STATE.CurrentCoin] = os.clock()
                            STATE.CurrentCoin = nil
                        end
                        STATE.Phase = "Idle"
                    end
                    return
                end
                
                local targetCFrame = CFrame.new(coin.Position)
                local angle = (elapsed / CONFIG.SpinDuration) * math.pi * 4
                
                local currentHrp = GetRoot()
                if currentHrp then
                    currentHrp.CFrame = targetCFrame * CFrame.Angles(0, angle, 0)
                    currentHrp.AssemblyLinearVelocity = Vector3.zero
                    currentHrp.AssemblyAngularVelocity = Vector3.zero
                end
                return
            end
            
            if STATE.Phase == "Waiting" then
                if os.clock() >= STATE.WaitStartTime + CONFIG.TeleportDelay then
                    if STATE.CurrentCoin then
                        STATE.SkippedCoins[STATE.CurrentCoin] = os.clock()
                        STATE.CurrentCoin = nil
                    end
                    STATE.Phase = "Idle"
                end
                return
            end
            
            if STATE.Phase == "Idle" then
                if BagFull() and not STATE.HasDiedThisRound then
                    STATE.Status = ("Reached %d -> Dying"):format(GetTarget())
                    if CONFIG.AutoDie then 
                        STATE.HasDiedThisRound = true
                        hum.Health = 0 
                    end
                    return
                end
                
                local map, container = GetMap()
                if not map then
                    STATE.Status = "Map not found..."
                    return
                end
                
                local coin = FindNearestCoin(hrp.Position)
                if coin and coin.Parent then
                    STATE.CurrentCoin = coin
                    if CONFIG.FarmMode == "Teleport" then
                        STATE.Phase = "Teleporting"
                        STATE.Status = ("Teleporting (%d/%d)"):format(STATE.BagCurrent, GetTarget())
                        local distance = (hrp.Position - coin.Position).Magnitude
                        STATE.TeleDuration = math.clamp(distance / CONFIG.TeleSpeed, 0.05, 0.8)
                        STATE.TeleStartTime = os.clock()
                        local tween = TweenService:Create(hrp, TweenInfo.new(STATE.TeleDuration, Enum.EasingStyle.Linear), {CFrame = CFrame.new(coin.Position)})
                        tween:Play()
                    else
                        STATE.Phase = "Flying"
                        STATE.Status = ("Flying (%d/%d)"):format(STATE.BagCurrent, GetTarget())
                        AttachMover(hrp)
                    end
                else
                    STATE.Status = "No coins left."
                end
            end
        end)
    end
end)

local overlay = Instance.new("ScreenGui")
overlay.Name = "MM2FarmStatus"; overlay.ResetOnSpawn = false; overlay.IgnoreGuiInset = true
overlay.Parent = (gethui and gethui()) or game.CoreGui

local oFrame = Instance.new("Frame")
oFrame.Size = UDim2.new(0, 200, 0, 85); oFrame.Position = UDim2.new(1, -210, 0, 10)
oFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25); oFrame.BackgroundTransparency = 0.2
oFrame.BorderSizePixel = 0; oFrame.Active = true; oFrame.Draggable = true; oFrame.Parent = overlay
Instance.new("UICorner", oFrame).CornerRadius = UDim.new(0, 6)
local oStroke = Instance.new("UIStroke"); oStroke.Color = Color3.fromRGB(200, 200, 210); oStroke.Thickness = 1.2; oStroke.Parent = oFrame
local oLabel = Instance.new("TextLabel")
oLabel.Size = UDim2.new(1, -12, 1, -12); oLabel.Position = UDim2.new(0, 6, 0, 6)
oLabel.BackgroundTransparency = 1; oLabel.TextColor3 = Color3.fromRGB(230, 230, 240)
oLabel.Font = Enum.Font.Code; oLabel.TextSize = 12; oLabel.TextXAlignment = Enum.TextXAlignment.Left; oLabel.TextYAlignment = Enum.TextYAlignment.Top
oLabel.TextWrapped = true; oLabel.Text = "Ready"; oLabel.Parent = oFrame

task.spawn(function()
    while overlay.Parent do
        task.wait(CONFIG.OverlayRefresh)
        pcall(function()
            local coins = STATE.Running and CountCoins() or 0
            local died = STATE.HasDiedThisRound and " (Dead)" or ""
            oLabel.Text = table.concat({
                STATE.Status .. died,
                ("Bag: %d/%d | Coin: %d"):format(STATE.BagCurrent, GetTarget(), coins),
                ("Total: %d | Round: %d"):format(STATE.CoinsTotal, STATE.Rounds),
            }, "\n")
        end)
    end
end)

local FarmTab = Win:Tab("Farm")
local FarmSec = FarmTab:Section("Auto Farm Coin")

FarmSec:Toggle({
    Text = "Enable Farm Coin",
    Default = false,
    Callback = function(state)
        STATE.Running = state
        if state then
            STATE.SkippedCoins = {}; STATE.HasDiedThisRound = false; STATE.LastBagCount = 0
            STATE.Phase = "Idle"; STATE.CurrentCoin = nil
            STATE.Status = "Farming..."
            if CONFIG.Noclip then SetNoclip(true) end
        else
            SetNoclip(false); STATE.Status = "Stopped"
            STATE.Phase = "Idle"; STATE.CurrentCoin = nil
            DetachMover()
        end
    end,
})

FarmSec:Dropdown({
    Text = "Farm Mode",
    Options = {"Teleport", "Fly"},
    Default = "Teleport",
    Callback = function(v) 
        CONFIG.FarmMode = v 
    end,
})

FarmSec:Slider({
    Text = "Target Coins",
    Min = 10, Max = 100, Default = 50,
    Callback = function(v) CONFIG.TargetCoins = tonumber(v) or 50 end,
})

FarmSec:Slider({
    Text = "Teleport Delay (s)",
    Min = 1, Max = 5, Default = 1.5, Decimals = 1,
    Callback = function(v) CONFIG.TeleportDelay = tonumber(v) or 1.5 end,
})

FarmSec:Slider({
    Text = "Fly Speed",
    Min = 16, Max = 50, Default = 20,
    Callback = function(v) CONFIG.FarmSpeed = tonumber(v) or 20 end,
})

FarmSec:Button({
    Text = "Die Now",
    Callback = function() 
        local hum = GetHumanoid()
        if hum then hum.Health = 0 end 
    end,
})

local AntiBanTab = Win:Tab("Anti-Ban")
local MainABSec = AntiBanTab:Section("Protection")

MainABSec:Toggle({ Text = "Noclip", Default = true, Callback = function(s) CONFIG.Noclip = s; if STATE.Running then SetNoclip(s) end end })
MainABSec:Toggle({ Text = "Anti-AFK", Default = true, Callback = function(s) CONFIG.AntiAfk = s end })
MainABSec:Toggle({ Text = "Auto Die", Default = true, Callback = function(s) CONFIG.AutoDie = s end })

local ActionSec = AntiBanTab:Section("Actions")
ActionSec:Button({ Text = "Emergency Stop", Callback = function() STATE.Running = false; SetNoclip(false); STATE.Phase = "Idle"; STATE.CurrentCoin = nil; DetachMover() end })

getgenv().MM2FarmCleanup = function()
    STATE.Running = false
    SetNoclip(false)
    DetachMover()
    DisconnectAll()
    if overlay and overlay.Parent then overlay:Destroy() end
end
