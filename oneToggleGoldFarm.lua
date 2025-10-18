local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local Root = Character:WaitForChild("HumanoidRootPart")

local GameUtil = require(RS.Modules.GameUtil)
local Packets = require(RS.Modules.Packets)
local ItemIDS = require(RS.Modules.ItemIDS)

local S = {
    positionList = {},
    walkSpeed = 16,
    fruit = "Lemon",
    HUNGER_CAP = 100,
    EAT_AT_OR_BELOW = 90,
    TOOL_NEED_GOLD = 12,
    TOOL_NEED_CRYSTAL = 3,
    GOLD_ID = 597,
    CRYSTAL_ID = 436,
    GOD_PICK_ID = 132,
}

local function GetQuantity(name)
    for x,v in pairs(GameUtil.getData().inventory) do
        if v.name == name then
            return v.quantity, x
        end
    end
end

local function getHunger()
    local stats = GameUtil and GameUtil.Data and GameUtil.Data.stats
    return stats and stats.food or nil
end

local function findFruitIndex(fruitName)
    for index, data in pairs(GameUtil.getData().inventory) do
        if data.name == fruitName then
            return index
        end
    end
    return nil
end

print("Loading default positions...")
local defaultConfigUrl = "https://raw.githubusercontent.com/Tion-D/booga-config-yes/refs/heads/main/MidasConfig.txt"
local configContent = game:HttpGet(defaultConfigUrl)
writefile("MidasConfig.txt", configContent)

local contents = readfile("MidasConfig.txt")
local entries = contents:gsub("%[", ""):gsub("%]", ""):split("},")
for _, entry in ipairs(entries) do
    local y, x, z = entry:match('"Y":([%d%.%-]+),"X":([%d%.%-]+),"Z":([%d%.%-]+)')
    local xVal, yVal, zVal = tonumber(x), tonumber(y), tonumber(z)
    if xVal and yVal and zVal then
        table.insert(S.positionList, {Y = yVal, X = xVal, Z = zVal})
    end
end
print("Loaded " .. #S.positionList .. " positions")

task.spawn(function()
    local lastEatTime = 0
    while true do
        local current = getHunger()
        if current and current <= S.EAT_AT_OR_BELOW and (tick() - lastEatTime) >= 2 then
            local fruitIndex = findFruitIndex(S.fruit)
            if fruitIndex then
                Packets.UseBagItem.send(fruitIndex)
                lastEatTime = tick()
            end
        end
        task.wait(1)
    end
end)

task.spawn(function()
    while true do
        local nearbyEntities = {}
        for _, resource in ipairs(workspace.Resources:GetChildren()) do
            local distance = (Character:GetPivot().Position - resource:GetPivot().Position).Magnitude
            if distance <= 100 then
                local id = resource:GetAttribute("EntityID")
                if id then
                    table.insert(nearbyEntities, id)
                end
            end
        end
        if #nearbyEntities > 0 then
            Packets.SwingTool.send(nearbyEntities)
        end
        task.wait(0.1)
    end
end)

task.spawn(function()
    while true do
        local Items = workspace:FindFirstChild("Items")
        if Items then
            for _, item in ipairs(Items:GetChildren()) do
                if item.Name == "Raw Gold" then
                    local id = item:GetAttribute("EntityID")
                    if id then
                        Packets.Pickup.send(id)
                    end
                end
            end
        end
        task.wait(0.5)
    end
end)

task.spawn(function()
    while true do
        local equipped = GameUtil.Data.equipped
        local toolbar = GameUtil.Data.toolbar
        
        local isEquipped = false
        if type(equipped) == "number" and toolbar[equipped] then
            isEquipped = toolbar[equipped].name == "God Pick"
        end
        
        if not isEquipped then
            local slot = nil
            for s, entry in pairs(toolbar) do
                if entry.name == "God Pick" then
                    slot = s
                    break
                end
            end
            
            if slot then
                Packets.EquipTool.send(slot)
            else
                local gold = GetQuantity("Gold") or 0
                local crystal = GetQuantity("Crystal Chunk") or 0
                
                if gold < S.TOOL_NEED_GOLD then
                    for i = 1, S.TOOL_NEED_GOLD - gold do
                        Packets.PurchaseFromShop.send(S.GOLD_ID)
                        task.wait(0.1)
                    end
                end
                
                if crystal < S.TOOL_NEED_CRYSTAL then
                    for i = 1, S.TOOL_NEED_CRYSTAL - crystal do
                        Packets.PurchaseFromShop.send(S.CRYSTAL_ID)
                        task.wait(0.1)
                    end
                end
                
                Packets.CraftItem.send(S.GOD_PICK_ID)
                task.wait(1)
            end
        end
        
        task.wait(2)
    end
end)

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    if not LocalPlayer:GetAttribute("hasSpawned") then
        local SpawnFirst = RS:WaitForChild("Events"):WaitForChild("SpawnFirst")
        pcall(function()
            SpawnFirst:InvokeServer(true)
            LocalPlayer:SetAttribute("hasSpawned", true)
        end)
    end
end)

task.spawn(function()
    local curIndex = 1
    
    while true do
        if not Root or not Root.Parent then
            Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            Root = Character:WaitForChild("HumanoidRootPart")
            Humanoid = Character:WaitForChild("Humanoid")
        end
        
        local pos = S.positionList[curIndex]
        if pos then
            local targetPos = Vector3.new(pos.X, pos.Y, pos.Z)
            local distance = (Root.Position - targetPos).Magnitude
            local duration = distance / S.walkSpeed
            
            local ti = TweenInfo.new(duration, Enum.EasingStyle.Linear)
            local tween = TweenService:Create(Root, ti, {CFrame = CFrame.new(targetPos)})
            
            tween:Play()
            tween.Completed:Wait()
            
            curIndex = (curIndex % #S.positionList) + 1
        end
        
        task.wait(0.1)
    end
end)
