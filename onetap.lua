local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/Tion-D/booga-config-yes/refs/heads/main/onetap_librarymain.lua')))()

local Window = OrionLib:MakeWindow({Name = "one<font color='rgb(224, 171, 3)'>tap</font> v1 Alpha", HidePremium = false, SaveConfig = true, ConfigFolder = "OrionTest"})

local ESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/Tion-D/booga-config-yes/refs/heads/main/Player_Esp_Library.lua"))()
local ItemESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/Tion-D/booga-config-yes/refs/heads/main/Item_ESP_Library.lua"))()

local Packets = require(game.ReplicatedStorage.Modules.Packets)
local ItemIDs = require(game.ReplicatedStorage.Modules.ItemIDS)
local GameUtil = require(game.ReplicatedStorage.Modules.GameUtil)
local ItemData = require(game.ReplicatedStorage.Modules.ItemData)
local anims = require(game.Players.LocalPlayer.PlayerScripts.src.Game.Animations)
local tribeHandler = require(game.Players.LocalPlayer.PlayerScripts.src.Game.TribeHandler)

local oldHitsoundID = "rbxassetid://609351621"
local hitSound = game.ReplicatedStorage.LocalSounds.Quicks.HitMarker

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local PlayerFruits = {}

local BlacklistedItemsForFruits = {
    "Reinforced Chest",
    "Nest",
    "Fish Trap",
    "Chest",
    "Barley"
}

local AutohealEnabled = false
local AutohealFruit = "Bloodfruit"
local AutohealCPS = 18
local AutohealHealth = 50

local AutoEat_Enabled = false
local AutoEat_Threshold = 80
local AutoEat_Fruit = "Bloodfruit"
local Last_AutoEat = os.clock() - 30

local KillauraEnabled = false
local KillAuraHighlight = false
local KillauraDistance = 25
local autoTraceEnabled = false

local ChamSettings = {
    Enabled = false,
    TeamCheck = false,
    TeamColor = false,
    FillColor = Color3.fromRGB(255, 0, 0),
    OutlineColor = Color3.fromRGB(255, 255, 255),
    FillTransparency = 0.5,
    OutlineTransparency = 0,
    PulseEffect = false,
    XRay = false,
    RainbowEffect = false,
    PulseSpeed = 1,
    PulseIntensity = 0.5,
    Brightness = 1,
    Style = "Normal"
}

local ChamCache = {}

ESP.Enabled = false
ESP.ShowBox = false
ESP.BoxType = "Corner Box Esp"
ESP.ShowName = false
ESP.ShowHealth = false
ESP.ShowTracer = false
ESP.TracerThickness = 2
ESP.ShowDistance = false

ItemESP.Enabled = false
ItemESP.ShowBox = false
ItemESP.BoxType = "Corner Box Esp"
ItemESP.ShowName = false
ItemESP.ShowDistance = false

local Combat = Window:MakeTab({
    Name = "Combat",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local Healing = Window:MakeTab({
    Name = "Healing",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local Player_Visuals = Window:MakeTab({
    Name = "Player Visuals",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local World_Visuals = Window:MakeTab({
    Name = "World Visuals",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local Player_Visuals_Sectioon = Player_Visuals:AddSection({
    Name = "Player Visuals"
})

local World_Sectioon = World_Visuals:AddSection({
    Name = "World"
})

local Items_Sectioon = World_Visuals:AddSection({
    Name = "Items"
})

local Items_VisualsColor_Sectioon = World_Visuals:AddSection({
    Name = "Items Colors"
})

local Player_Chams_Sectioon = Player_Visuals:AddSection({
    Name = "Player Chams"
})

local Player_VisualsColor_Sectioon = Player_Visuals:AddSection({
    Name = "Colors"
})

local Autoeat_section = Healing:AddSection({
    Name = "Autoeat"
})

local Autoheal_section = Healing:AddSection({
    Name = "Autoheal"
})

local HitSounds = Combat:AddSection({
    Name = "Hit Sounds"
})

local CombatSection = Combat:AddSection({
    Name = "Kill Aura"
})

local isPlayersEnabled = false

Player_Visuals_Sectioon:AddBind({
    Name = "Toggle Enable Players",
    Default = Enum.KeyCode.E,
    Hold = false,
    Callback = function()
        if isPlayersEnabled then
            ESP.Enabled = not ESP.Enabled
        end
    end    
})

Player_Visuals_Sectioon:AddToggle({
    Name = "Enable Players",
    Default = false,
    Callback = function(Enable_Players)
        isPlayersEnabled = Enable_Players
        ESP.Enabled = Enable_Players
    end    
})

Player_Visuals_Sectioon:AddToggle({
    Name = "Enable Name",
    Default = false,
    Callback = function(Enable_Name)
        ESP.ShowName = Enable_Name
    end    
})

Player_Visuals_Sectioon:AddToggle({
    Name = "Enable Distance",
    Default = false,
    Callback = function(Enable_Distance)
        ESP.ShowDistance = Enable_Distance
    end   
})

Player_Visuals_Sectioon:AddToggle({
    Name = "Enable Health",
    Default = false,
    Callback = function(Enable_Heath)
        ESP.ShowHealth = Enable_Heath
    end    
})

Player_Visuals_Sectioon:AddToggle({
    Name = "Enable Boxes",
    Default = false,
    Callback = function(Enable_Boxes)
        ESP.ShowBox = Enable_Boxes
    end   
})

Player_Visuals_Sectioon:AddDropdown({
    Name = "Box Types",
    Default = "1",
    Options = {"2D", "Corner Box Esp"},
    Callback = function(SelectedBoxType)
        ESP.BoxType = SelectedBoxType
        if (ESP.Enabled) then
            ESP.Enabled = false
            task.wait(0.1)
            ESP.Enabled = true
        end
    end    
})

Player_Visuals_Sectioon:AddToggle({
    Name = "Enable Skeleton",
    Default = false,
    Callback = function(Enable_Skeleton)
        ESP.ShowSkeletons = Enable_Skeleton
    end   
})

Player_VisualsColor_Sectioon:AddColorpicker({
	Name = "Name Color",
	Default = Color3.fromRGB(224, 171, 3),
	Callback = function(NameColorValue)
        ESP.NameColor = NameColorValue
	end	  
})

Player_VisualsColor_Sectioon:AddColorpicker({
	Name = "Health Color",
	Default = Color3.fromRGB(224, 171, 3),
	Callback = function(HealthColorValue)
		ESP.HealthHighColor = HealthColorValue
        ESP.HealthLowColor = HealthColorValue
        ESP.HealthOutlineColor = HealthColorValue
	end	  
})

Player_VisualsColor_Sectioon:AddColorpicker({
	Name = "Box Color",
	Default = Color3.fromRGB(224, 171, 3),
	Callback = function(BoxColorValue)
		ESP.BoxColor = BoxColorValue
        ESP.BoxOutlineColor = BoxColorValue
	end	  
})

Player_VisualsColor_Sectioon:AddColorpicker({
	Name = "Skeleton Color",
	Default = Color3.fromRGB(224, 171, 3),
	Callback = function(SkeletonColorValue)
		ESP.SkeletonsColor = SkeletonColorValue
	end	  
})

local function GetIndex(name)
    for index, data in next, GameUtil.GetData().inventory do
        if data.name == name then
            return index
        end
    end
end

local function CreateCham(part)
    local boxHandleAdornment = Instance.new("BoxHandleAdornment")
    boxHandleAdornment.Name = "Cham"
    boxHandleAdornment.AlwaysOnTop = true
    boxHandleAdornment.ZIndex = 10
    boxHandleAdornment.Size = part.Size + Vector3.new(0.1, 0.1, 0.1)
    boxHandleAdornment.Adornee = part
    boxHandleAdornment.Color3 = ChamSettings.FillColor
    boxHandleAdornment.Transparency = ChamSettings.FillTransparency
    boxHandleAdornment.Parent = part
    return boxHandleAdornment
end

local function ApplyChams(player)
    if not player.Character or player == LocalPlayer then return end
    
    if not ChamCache[player] then
        ChamCache[player] = {}
    end

    for _, part in pairs(player.Character:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            local cham = CreateCham(part)
            table.insert(ChamCache[player], cham)
        end
    end
end

local function RemoveChams(player)
    if ChamCache[player] then
        for _, cham in pairs(ChamCache[player]) do
            cham:Destroy()
        end
        ChamCache[player] = nil
    end
end

Player_Chams_Sectioon:AddToggle({
    Name = "Enable Chams",
    Default = false,
    Callback = function(Enable_Chams)
        ChamSettings.Enabled = Enable_Chams
        if Enable_Chams then
            for _, player in ipairs(Players:GetPlayers()) do
                ApplyChams(player)
            end
        else
            for player, _ in pairs(ChamCache) do
                RemoveChams(player)
            end
        end
    end   
})

Player_Chams_Sectioon:AddToggle({
    Name = "Enable Pulse Effect",
    Default = false,
    Callback = function(Enable_ChamsPulseEffect)
        ChamSettings.PulseEffect = Enable_ChamsPulseEffect
    end   
})

Player_Chams_Sectioon:AddSlider({
	Name = "Pulse Speed",
	Min = 0.1,
	Max = 1,
	Default = 0.5,
	Color = Color3.fromRGB(224, 171, 3),
	Increment = 0.1,
	ValueName = "Pulse Speed",
	Callback = function(PulseIntensity_Value)
		ChamSettings.PulseIntensity = PulseIntensity_Value
	end    
})

Player_Chams_Sectioon:AddColorpicker({
	Name = "Chams Color",
	Default = Color3.fromRGB(224, 171, 3),
	Callback = function(ChamsColorValue)
        ChamSettings.FillColor = ChamsColorValue
        for _, chams in pairs(ChamCache) do
            for _, cham in pairs(chams) do
                cham.Color3 = ChamsColorValue
            end
        end
	end	  
})

Player_Chams_Sectioon:AddToggle({
    Name = "Enable Rainbow Effect",
    Default = false,
    Callback = function(Enable_ChamsRainbowEffect)
        ChamSettings.RainbowEffect = Enable_ChamsRainbowEffect
    end   
})

RunService.RenderStepped:Connect(function()
    if ChamSettings.Enabled and ChamSettings.PulseEffect then
        local pulse = (math.sin(tick() * ChamSettings.PulseSpeed) + 1) / 2
        local transparency = ChamSettings.FillTransparency + (pulse * ChamSettings.PulseIntensity)
        
        for _, chams in pairs(ChamCache) do
            for _, cham in pairs(chams) do
                cham.Transparency = transparency
            end
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if ChamSettings.Enabled and ChamSettings.RainbowEffect then
        local hue = tick() % 5 / 5
        local color = Color3.fromHSV(hue, 1, 1)
        
        for _, chams in pairs(ChamCache) do
            for _, cham in pairs(chams) do
                cham.Color3 = color
            end
        end
    end
end)

Players.PlayerAdded:Connect(function(player)
    if ChamSettings.Enabled then
        player.CharacterAdded:Connect(function()
            ApplyChams(player)
        end)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    RemoveChams(player)
end)

local isItemsEnabled = false

Items_Sectioon:AddBind({
    Name = "Toggle Enable Items",
    Default = Enum.KeyCode.E,
    Hold = false,
    Callback = function()
        if isItemsEnabled then
            ItemESP.Enabled = not ItemESP.Enabled
        end
    end    
})

Items_Sectioon:AddToggle({
    Name = "Enable Items",
    Default = false,
    Callback = function(Enable_Players)
        isItemsEnabled = Enable_Players
        ItemESP.Enabled = Enable_Players
    end    
})

Items_Sectioon:AddToggle({
    Name = "Enable Name",
    Default = false,
    Callback = function(Enable_Name)
        ItemESP.ShowName = Enable_Name
    end    
})

Items_Sectioon:AddToggle({
    Name = "Enable Distance",
    Default = false,
    Callback = function(Enable_Distance)
        ItemESP.ShowDistance = Enable_Distance
    end   
})

Items_Sectioon:AddToggle({
    Name = "Enable Boxes",
    Default = false,
    Callback = function(Enable_Boxes)
        ItemESP.ShowBox = Enable_Boxes
    end   
})

Items_Sectioon:AddDropdown({
    Name = "Box Types",
    Default = "1",
    Options = {"2D", "Corner Box Esp"},
    Callback = function(SelectedBoxType)
        ItemESP.BoxType = SelectedBoxType
        if (ItemESP.Enabled) then
            ItemESP.Enabled = false
            task.wait(0.1)
            ItemESP.Enabled = true
        end
    end    
})

Items_VisualsColor_Sectioon:AddColorpicker({
	Name = "Name Color",
	Default = Color3.fromRGB(224, 171, 3),
	Callback = function(NameColorValue)
        ItemESP.NameColor = NameColorValue
	end	  
})

Items_VisualsColor_Sectioon:AddColorpicker({
	Name = "Box Color",
	Default = Color3.fromRGB(224, 171, 3),
	Callback = function(BoxColorValue)
		ItemESP.BoxColor = BoxColorValue
        ItemESP.BoxOutlineColor = BoxColorValue
	end	  
})

local hitSoundEnabled = false
local hitSoundNameList = {}

local soundIds = {
    ["skeet"] = "rbxassetid://5447626464",
    ["rust"] = "rbxassetid://5043539486",
    ["bag"] = "rbxassetid://364942410",
    ["baimware"] = "rbxassetid://6607339542",
    ["1nn"] = "rbxassetid://7349055654",
    ["Cod"] = "rbxassetid://131864673",
    ["Bonk"] = "rbxassetid://3765689841",
    ["cod"] = "rbxassetid://131864673",
    ["Semi"] = "rbxassetid://7791675603",
    ["osu"] = "rbxassetid://7149919358",
    ["Tf2"] = "rbxassetid://296102734",
    ["Tf2 pan"] = "rbxassetid://3431749479",
    ["M55solix"] = "rbxassetid://364942410",
    ["Slap"] = "rbxassetid://4888372697",
    ["1"] = "rbxassetid://7349055654",
    ["Minecraft"] = "rbxassetid://7273736372",
    ["jojo"] = "rbxassetid://6787514780",
    ["vibe"] = "rbxassetid://1848288500",
    ["supersmash"] = "rbxassetid://2039907664",
    ["epic"] = "rbxassetid://7344303740",
    ["retro"] = "rbxassetid://3466984142",
    ["quek"] = "rbxassetid://4868633804",
    ["dababy"] = "rbxassetid://6559380085",
    ["Welcome"] = "rbxassetid://5149595745",
}

for i,_ in soundIds do
    table.insert(hitSoundNameList, i)
end

HitSounds:AddToggle({
    Name = "Bow Hitsound",
    Default = false,
    Callback = function(v)
        hitSoundEnabled = v
    end    
})

local oinlyplayerhsitound = false

HitSounds:AddToggle({
    Name = "Only Players",
    Default = false,
    Callback = function(v)
        oinlyplayerhsitound = v
    end    
})

HitSounds:AddDropdown({
    Name = "Hitsound",
    Default = "skeet",
    Options = hitSoundNameList,
    Callback = function(selected)
        hitSound.SoundId = soundIds[selected]
    end    
})

local old = Packets.ProjectileImpact.send
Packets.ProjectileImpact.send = function(...)
    if not hitSoundEnabled then return end
    local args = {...}
    local pos = table.unpack(args)["position"]

    if oinlyplayerhsitound then
        for _, player in game.Players:GetPlayers() do
            local char = player.Character
            if char then
                local dist = (char:GetPivot().Position - pos).Magnitude
                if dist < 3 then
                    hitSound:Play()
                end
            end
        end
    else
        hitSound:Play()
    end
    
    old(...)
end

local function fixItemName(name)
    for n, d in ItemData do
        if string.lower(n) == string.lower(name) then
            return n
        end
    end
    return nil
end

Autoheal_section:AddToggle({
    Name = "Autoheal",
    Default = false,
    Callback = function(AutohealEnabled_Value)
        AutohealEnabled = AutohealEnabled_Value
    end    
})

Autoheal_section:AddDropdown({
    Name = "Autoheal Fruit",
    Default = "Bloodfruit", 
    Options = PlayerFruits,
    Callback = function(AutohealFruit_Value)
        AutohealFruit = AutohealFruit_Value
        -- print("Selected Autoheal Fruit: " .. AutohealFruit)
    end    
})

Autoheal_section:AddSlider({
	Name = "Autoheal Health",
	Min = 1,
	Max = 100,
	Default = 82,
	Color = Color3.fromRGB(224, 171, 3),
	Increment = 1,
	ValueName = "AutoHeal Health",
	Callback = function(AutohealHealth_Value)
        AutohealHealth = tonumber(AutohealHealth_Value)
	end    
})

Autoheal_section:AddSlider({
	Name = "Autoheal CPS",
	Min = 5,
	Max = 100,
	Default = 18,
	Color = Color3.fromRGB(224, 171, 3),
	Increment = 1,
	ValueName = "AutoHeal CPS",
	Callback = function(AutohealCPS_Value)
        AutohealCPS = tonumber(AutohealCPS_Value)
	end    
})

Autoeat_section:AddToggle({
    Name = "Autoeat",
    Default = false,
    Callback = function(AutoEat_Enabled_Value)
        AutoEat_Enabled = AutoEat_Enabled_Value
    end    
})

Autoeat_section:AddDropdown({
    Name = "Autoeat Fruit",
    Default = "Bloodfruit", 
    Options = PlayerFruits,
    Callback = function(AutoEat_FruitValue)
        AutoEat_Fruit = AutoEat_FruitValue
        -- print("Selected Autoheal Fruit: " .. AutohealFruit)
    end    
})

Autoeat_section:AddSlider({
	Name = "Autoeat Threshold",
	Min = 1,
	Max = 100,
	Default = 80,
	Color = Color3.fromRGB(224, 171, 3),
	Increment = 1,
	ValueName = "Autoeat Threshold",
	Callback = function(AutoEat_ThresholdValue)
        AutoEat_Threshold = tonumber(AutoEat_ThresholdValue)
	end    
})

CombatSection:AddToggle({
    Name = "Enable Kill-Aura",
    Default = false,
    Callback = function(KillauraEnabled_Value)
        KillauraEnabled = KillauraEnabled_Value
    end    
})

CombatSection:AddSlider({
	Name = "Kill-Aura Distance",
	Min = 5,
	Max = 35,
	Default = 10,
	Color = Color3.fromRGB(224, 171, 3),
	Increment = 1,
	ValueName = "Killaura Distance",
	Callback = function(KillauraDistance_Value)
        KillauraDistance = tonumber(KillauraDistance_Value)
	end    
})

CombatSection:AddToggle({
    Name = "Auto Trace",
    Default = false,
    Callback = function(Value)
        autoTraceEnabled = Value
    end,
    Keybind = {
        Name = "Toggle Auto Trace",
        Default = Enum.KeyCode.RightShift,
        Hold = false
    }
})
local function isEnemy(player)
    local myTribe, myAllies = GameUtil.IsInATribe(LocalPlayer.UserId)
    local theirTribe, _ = GameUtil.IsInATribe(player.UserId)

    if not myTribe then
        return true
    end

    if theirTribe == myTribe or (myAllies and table.find(myAllies, theirTribe)) then
        return false
    end
    return true
end

local function getTraced()
    local myCharacter = LocalPlayer.Character
    local myRoot = myCharacter and myCharacter:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end

    local closestPlayer = nil
    local shortestDistance = math.huge
    local myPosition = myRoot.Position

    for _, player in ipairs(game.Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and isEnemy(player) then
            local enemyRoot = player.Character:FindFirstChild("HumanoidRootPart")
            if enemyRoot then
                local distance = (myPosition - enemyRoot.Position).Magnitude
                if distance <= 50 and distance < shortestDistance then
                    shortestDistance = distance
                    closestPlayer = player
                end
            end
        end
    end

    return closestPlayer
end

local function predictFuturePosition(player, seconds)
    local head = player.Character and player.Character:FindFirstChild("Head")
    local rootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if head and rootPart then
        local currentPosition = head.Position
        local velocity = rootPart.Velocity
        return currentPosition + velocity * seconds
    end
    return nil
end

local function walkTo(position)
    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChild("Humanoid")
    if humanoid then
        humanoid:MoveTo(position)
    end
end

RunService.Heartbeat:Connect(function()
    if autoTraceEnabled then
        local target = getTraced()
        if target and target.Character then
            local predictedPosition = predictFuturePosition(target, 0.1)
            if predictedPosition then
                walkTo(predictedPosition)
                local targetHead = target.Character:FindFirstChild("Head")
                if targetHead and predictedPosition.Y > targetHead.Position.Y + 0.5 then
                    local localChar = LocalPlayer.Character
                    if localChar then
                        local localHumanoid = localChar:FindFirstChild("Humanoid")
                        if localHumanoid then
                            local state = localHumanoid:GetState()
                            if state ~= Enum.HumanoidStateType.Jumping and state ~= Enum.HumanoidStateType.Freefall then
                                localHumanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                            end
                        end
                    end
                end
            end
        end
    end
end)

task.spawn(function()
    while task.wait(1/AutohealCPS) do
        if AutohealEnabled and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") ~= nil then
            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            
            if hum.Health > AutohealHealth then continue end

            local index = GetIndex(AutohealFruit)

            if index ~= nil then
                Packets.UseBagItem.send(index)
            end
        end
    end
end)

task.spawn(function()
    while task.wait() do
        if not AutoEat_Enabled or os.clock() - Last_AutoEat < 3 then continue end

        if GameUtil.GetData().stats.food < AutoEat_Threshold then
            local index = GetIndex(AutoEat_Fruit)

            local food_gain = ItemData[AutoEat_Fruit].nourishment.food
            local gained = 0

            for i = 1, 100 do
                gained += 1
                if GameUtil.GetData().stats.food + (gained * food_gain) >= 100 then
                    break
                end
            end

            if index ~= nil then
                for i = 1, gained do
                    Packets.UseBagItem.send(index)
                end
                Last_AutoEat = os.clock()
            end
        end
    end
end)

local function getClosestPlayer()
    local closest, distance = nil, tonumber(KillauraDistance)

    for _, p in game.Players:GetPlayers() do
        if p == LocalPlayer then continue end
        local char = p.Character

        if char and LocalPlayer.Character then
            local dist = (char:GetPivot().Position - LocalPlayer.Character:GetPivot().Position).Magnitude

            if dist < distance then
                closest = p
                distance = dist
            end
        end
    end

    return closest
end

task.spawn(function()
    while task.wait(1/3) do
        if KillauraEnabled then
            local player = getClosestPlayer()
            if player and isEnemy(player) and GameUtil.GetData().equipped ~= nil then
                local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
                if humanoid then
                    local prevHealth = humanoid.Health
                    Packets.SwingTool.send({player.Character:GetAttribute("EntityID")})
                    anims.playAnimation("Slash")
                    task.wait(0.1)
                    local newHealth = humanoid.Health
                    print("prevHealth =", prevHealth, "newHealth =", newHealth)
                    
                    if newHealth >= prevHealth then
                        OrionLib:MakeNotification({
                            Name = "     Resolver",
                            Content = "               <font color='rgb(224, 171, 3)'>onetap</font>: Missed shot due to spread",
                            Image = "http://www.roblox.com/Game/Tools/ThumbnailAsset.ashx?fmt=png&wd=420&ht=420&aid=112496659596819",
                            Time = 5
                        })
                    end
                end
            end
        end
    end
end)
