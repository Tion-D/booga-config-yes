setthreadidentity(5)
local RS = game:GetService("ReplicatedStorage")
-- local ClientAnimalReady = RS:WaitForChild("ClientAnimalReady")
-- local oldNamecall
-- oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
--     local method = getnamecallmethod and getnamecallmethod() or ""
--     if not checkcaller() and method == "FireServer" and self == ClientAnimalReady then
--         warn("Blocked ClientAnimalReady:FireServer")
--         return
--     end
--     return oldNamecall(self, ...)
-- end)


local PathfindingService = game:GetService("PathfindingService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Items = Workspace:FindFirstChild("Items")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CurrentCamera = workspace.CurrentCamera
local LocalPlayerMouse = Players.LocalPlayer:GetMouse()
local Events = RS:WaitForChild("Events")
local SpawnFirst = Events:WaitForChild("SpawnFirst")

local GameUtil = require(RS.Modules.GameUtil)
local ItemData = require(RS.Modules.ItemData)
local ItemIDS = require(RS.Modules.ItemIDS)
local Packets = require(RS.Modules.Packets)
local SkinHandler = require(RS.Game.skins)
local Clock = require(RS.Modules.Clock)

local Character = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
local LocalPlayer = game.Players.LocalPlayer
local Humanoid = Character:WaitForChild("Humanoid")
local Root = Character:WaitForChild("HumanoidRootPart")
local PG = LocalPlayer:WaitForChild("PlayerGui")

Players.LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    Root = char:WaitForChild("HumanoidRootPart")
end)

local farm = {}
local positionList = {}
local interactingWithResources = false
local walkingEnabled = false
local tweeningEnabled = false
local selectedFileName = "Positions.txt"
local icenodeRun
local cavenodeRun
local antRun
local crewRun
local fruitRun
local autoEat
local noclip
local fruitJumpEnabled = false
local fruitJumpThread = nil
local bushesVisible = true

local tween2
local autoHealEnabled
local pressEnabled
local campEnabled
local coinEnabled
local essenceEnabled
local pickUpGoldEnabled

local selectedDropItem = nil
local autoDropEnabled = false
local autoDropTask

local pickUpPressedGold
local CoinpressEnabled
local pickupGold

local plantEnabled
local harEnabled
local tweenEnabled
local posBlobs = {}

local tween
local tweenInfo
local chest
local tweenConn

local moving = false
local fruit = "Bloodfruit"
local selectedFruit
local fruitOptions = {}
local tweenSpeed = 1
local walkSpeed = 16
local trackingStartTime = nil
local autoleaves = false
local autowood = false
local autolog = false
local wasteLeavesTo = 50
local wasteLeavesLoopThread = nil
local wasteWoodTo = 50
local wasteWoodLoopThread = nil
local wasteLogTo = 50
local wasteLogLoopThread = nil
local wasteFoodTo = 50
local wasteFoodLoopThread = nil
local deleteEnabled = false
local WalkSpeedEnabled = false
local WalkSpeedValue = 16
local originalWalkSpeed
local maxSlopeEnabled = false
local autoJumpEnabled = false
local fishingEnabled = false
local TPGoldToChest = false
local coinPressTask = false
local pickupCoinTask = false
local pickupGoldTask = false
local pickupRawGoldTask = false
local pickupRawGold = false
local pickupAllItemsTask = false
local pickupAllItems = false
local replacePotEnabled = false
local trackingActive = false
local startAmounts, endAmounts = nil, nil
local rodBubbleConn
local autoFishLoop
local autoFishEnabled = false
local lastHarvestScan = 0
local TPDropToChest = false

local autoBrewEnabled = false
local selectedPotion = "Healing"
local cauldronRange = 100
local currentCauldron = nil

local autoBrewInFlight = {}
local autoBrewQueue = {}
local BASE_ICE_CUBES = 3
local ICE_MELT_WAIT = 10
local autoBrewGen = 0
local AUTO_BREW_QCAP = 200

local HUNGER_CAP = 100
local EAT_AT_OR_BELOW = 90
local LOOP_WAIT_SECONDS = 1
local POST_EAT_COOLDOWN = 2.0 

local LEVEL_TO_REBIRTH = 100
local autoRebirthEnabled = false
local autoBedSpawnEnabled = false
local autoBedSpawnThread = nil

local POTION_RECIPES = {
    ["Poison"] = { ["Prickly Pear"] = 3, ["Magnetite Bar"] = 1 },
    ["Swift"] = { ["Crystal Chunk"] = 1, ["Cloudberry"] = 3 },
    ["Slowness"] = { ["Crystal Chunk"] = 1, ["Ice Cube"] = 3 },
    ["Instant Damage"] = { ["Adurite Bar"] = 3, ["Prickly Pear"] = 3 },
    ["Fire Resistance"] = { ["Fire Hide"] = 2 },
    ["Strength"] = { ["Adurite"] = 2, ["Bloodfruit"] = 2 },
    ["Weakness"] = { ["Berries"] = 3, ["Coal"] = 2 },
    ["Healing"] = { ["Bloodfruit"] = 5, ["Strawberry"] = 2 },
    ["Haste"] = { ["Iron"] = 2, ["Lemon"] = 2 },
}

local Threads, Conns = {}, {}

local function kill(t)
    if type(t) == "thread" then pcall(task.cancel, t) end
end
local function stopAll(keys)
    for _,k in ipairs(keys) do
        if Threads[k] then kill(Threads[k]); Threads[k] = nil end
    end
    for _,k in ipairs(keys) do
        if Conns[k] and Conns[k].Disconnect then pcall(Conns[k].Disconnect, Conns[k]); Conns[k] = nil end
    end
end

local defaultConfigUrl = "https://raw.githubusercontent.com/Tion-D/booga-config-yes/refs/heads/main/MidasConfig.txt"
local defaultConfigFile = "MidasConfig.txt"

local configContent = game:HttpGet(defaultConfigUrl)
writefile(defaultConfigFile, configContent)

LocalPlayer:SetAttribute("hasSpawned", false)

LocalPlayer.CharacterAdded:Connect(function(char)
    LocalPlayer:SetAttribute("hasSpawned", false)
    local hum = char:WaitForChild("Humanoid")
    hum.Died:Connect(function()
        LocalPlayer:SetAttribute("hasSpawned", false)
    end)
end)

local function make_8x8()
    if not Character or not Character.Parent then
        Character = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
    end

    local start = Character:GetPivot() * CFrame.new(0, -3, 0)

    for i = -4, 4 do
        for n = -4, 4 do
            local pos = start * CFrame.new(6.3 * i, 0, 6.3 * n)
            Packets.PlaceStructure.send({
                buildingName = "Plant Box",
                vec = pos.Position,
                yrot = 90,
                isMobile = false
            })
            task.wait(0.45)
        end
    end
end

local function move_left()
    if moving then return end
    moving = true

    if not Character or not Character.Parent then
        Character = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
    end
    local hum = Character:FindFirstChildOfClass("Humanoid") or Character:WaitForChild("Humanoid")

    hum:MoveTo((Character:GetPivot() * CFrame.new(-(6.4 * 9), -3, 0)).Position)
    hum.MoveToFinished:Wait()

    moving = false
end

local function move_right()
    if moving then return end
    moving = true

    if not Character or not Character.Parent then
        Character = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
    end
    local hum = Character:FindFirstChildOfClass("Humanoid") or Character:WaitForChild("Humanoid")

    hum:MoveTo((Character:GetPivot() * CFrame.new((6.4 * 9), -3, 0)).Position)
    hum.MoveToFinished:Wait()

    moving = false
end

local function move_up()
    if moving then return end
    moving = true

    if not Character or not Character.Parent then
        Character = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
    end
    local hum = Character:FindFirstChildOfClass("Humanoid") or Character:WaitForChild("Humanoid")

    hum:MoveTo((Character:GetPivot() * CFrame.new(0, -3, -(6.4 * 9))).Position)
    hum.MoveToFinished:Wait()

    moving = false
end

local function move_down()
    if moving then return end
    moving = true

    if not Character or not Character.Parent then
        Character = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
    end
    local hum = Character:FindFirstChildOfClass("Humanoid") or Character:WaitForChild("Humanoid")

    hum:MoveTo((Character:GetPivot() * CFrame.new(0, -3, (6.4 * 9))).Position)
    hum.MoveToFinished:Wait()

    moving = false
end

if getgenv().japanese_connection ~= nil then
    getgenv().japanese_connection:Disconnect()
end

getgenv().japanese_connection = game.UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end

    if input.KeyCode == Enum.KeyCode.U then
        make_8x8()
    end

    if input.KeyCode == Enum.KeyCode.M then
        move_right()
    end

    if input.KeyCode == Enum.KeyCode.N then
        move_down()
    end

    if input.KeyCode == Enum.KeyCode.B then
        move_left()
    end

    if input.KeyCode == Enum.KeyCode.H then
        move_up()
    end
end)

for x, v in next, ItemData do
    if v.grows then
        table.insert(fruitOptions, x)
    end
end

local function Notify(title, content)
    if not Fluent or not Fluent.Notify then
        warn(("[Notify pending] %s: %s"):format(title, tostring(content)))
        return
    end
    Fluent:Notify({ Title = title, Content = content, Duration = 5 })
end


local function findFruitIndex(fruitName)
    for index, data in next, GameUtil.getData().inventory do
        if data.name == fruitName then
            return index
        end
    end
    return nil
end

local function getFruitRestoreAmount(nameOrId)
    local id = ItemIDS[nameOrId] or nameOrId
    local data = ItemData[id] or (ItemIDS[id] and ItemData[ItemIDS[id]])
    if not data then return nil end

    return data.food or data.hunger or data.restore or data.restoreValue or data.heal or nil
end

local function getHunger()
    local stats = GameUtil and GameUtil.Data and GameUtil.Data.stats
    return stats and stats.food or nil
end

local lastEatTime = 0
local function canEatNow()
    return (time() - lastEatTime) >= POST_EAT_COOLDOWN
end

local function eatFruitOnce(idx)
    Packets.UseBagItem.send(idx)
    lastEatTime = time()
end

local function willOvereat(currentHunger, restore)
    if not restore then return false end
    return (currentHunger + restore) > HUNGER_CAP
end

local function autoEatSelectedFruit()
    local function autoEatLoop()
        while autoEat do
            local current = getHunger()

            if not fruit then
                Notify("No fruit selected for auto-eat.")
            elseif not current then
                Notify("Hunger value unavailable right now.")
            else
                if current <= EAT_AT_OR_BELOW and canEatNow() then
                    local fruitIndex = findFruitIndex(fruit)
                    if fruitIndex then
                        local restore = getFruitRestoreAmount(fruit)

                        if restore and willOvereat(current, restore) then
                        else
                            eatFruitOnce(fruitIndex)
                        end
                    else
                        Notify("Selected fruit not found in inventory:", tostring(fruit))
                    end
                end
            end

            task.wait(LOOP_WAIT_SECONDS)
        end
    end
    task.spawn(autoEatLoop)
end

local Path = PathfindingService:CreatePath({
    WaypointSpacing = math.huge
})

local function setWalkSpeed(enabled)
    WalkSpeedEnabled = enabled
    if LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            if not originalWalkSpeed then
                originalWalkSpeed = humanoid.WalkSpeed
            end
            humanoid.WalkSpeed = enabled and WalkSpeedValue or originalWalkSpeed
        end
    end
end

local oldNewIndex
oldNewIndex = hookmetamethod(game, "__newindex", function(self, idx, val)
    if not checkcaller() then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if WalkSpeedEnabled and hum and self == hum and idx == "WalkSpeed" then
            val = WalkSpeedValue
        end
    end
    return oldNewIndex(self, idx, val)
end)


local function setMaxSlope(enabled)
    maxSlopeEnabled = enabled
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        if maxSlopeEnabled then
            LocalPlayer.Character.Humanoid.MaxSlopeAngle = 89
        else
            LocalPlayer.Character.Humanoid.MaxSlopeAngle = 45
        end
    end
end

local function HasItem(item)
    for x, v in next, GameUtil.getData().inventory do
        if v.name == item then
            return true
        end
    end
end

local function GetQuantity(name)
    for x,v in next, GameUtil.getData().inventory do
        if v.name == name then
            return v.quantity, x
        end
    end
end

local function GetFuel()
    for x, v in next, GameUtil.getData().inventory do
        if ItemData[v.name]["fuels"] then
            return ItemIDS[v.name]
        end
    end
end

local function wasteLeavesLoop()
    while autoleaves do
        local amt = GetQuantity("Leaves")
        
        if amt == nil then
            print("GetQuantity('Leaves') returned nil")
        end
        if wasteLeavesTo == nil then
            print("wasteLeavesTo is nil")
        end
        
        amt = tonumber(amt)

        if amt and wasteLeavesTo and amt >= tonumber(wasteLeavesTo) then
            Packets.CraftItem.send(164)
        end

        task.wait()
    end
end

local function wastewoodLoop()
    while autowood do
        local amt = GetQuantity("Wood")
        
        if amt == nil then
            print("GetQuantity('Wood') returned nil")
        end
        if wasteWoodTo == nil then
            print("wasteWoodTo is nil")
        end
        
        amt = tonumber(amt)

        if amt and wasteWoodTo and amt >= tonumber(wasteWoodTo) then
            Packets.CraftItem.send(248)
        end

        task.wait()
    end
end

local function wastelogLoop()
    while autolog do
        local amt = GetQuantity("Log")
        
        if amt == nil then
            print("GetQuantity('Log') returned nil")
        end
        if wasteLogTo == nil then
            print("wasteLogTo is nil")
        end
        
        amt = tonumber(amt)

        if amt and wasteLogTo and amt >= tonumber(wasteLogTo) then
            Packets.CraftItem.send(123)
        end

        task.wait()
    end
end

local function wasteFoodLoop(fruit)
    while task.wait() do
        local amt, id = GetQuantity(fruit)
        amt = tonumber(amt)
        local wasteFoodToNumber = tonumber(wasteFoodTo)
        if amt and wasteFoodToNumber and amt > wasteFoodToNumber then
            for x = 1, amt - wasteFoodToNumber do
                Packets.UseBagItem.send(id)
            end
            task.wait()
        end
    end
end

local function deleteItems()
    local itemsFolder = Workspace:FindFirstChild("Items")
    if not itemsFolder then return end
    for _, item in ipairs(itemsFolder:GetChildren()) do
        if item.Name ~= "Raw Gold" and item.Name ~= "Gold" and item.Name ~= "Essence" and item.Name ~= "Coin2" then
            item:Destroy()
        end
    end
end

local function monitorItems()
    while deleteEnabled do
        deleteItems()
        task.wait(0.2)
    end
end

local function GetDeployable(name, range, multiple)
    local deployablesFolder = Workspace:FindFirstChild("Deployables")
    if not deployablesFolder or not Root then
        return multiple and {} or nil
    end

    range = tonumber(range) or math.huge

    if multiple then
        local results = {}
        for _, v in ipairs(deployablesFolder:GetChildren()) do
            if v.Name == name and v:IsA("Model") then
                local ok, pivot = pcall(function() return v:GetPivot() end)
                if ok and pivot then
                    local dist = (Root.Position - pivot.Position).Magnitude
                    if dist < range then
                        table.insert(results, { deployable = v, range = dist })
                    end
                end
            end
        end
        table.sort(results, function(a, b) return a.range < b.range end)
        return results
    else
        local closest, closestDist = nil, range
        for _, v in ipairs(deployablesFolder:GetChildren()) do
            if v.Name == name and v:IsA("Model") then
                local ok, pivot = pcall(function() return v:GetPivot() end)
                if ok and pivot then
                    local dist = (Root.Position - pivot.Position).Magnitude
                    if dist < closestDist then
                        closest, closestDist = v, dist
                    end
                end
            end
        end
        return closest
    end
end

local function findBloodfruitIndex()
    for index, data in next, GameUtil.getData().inventory do
        if data.name == "Bloodfruit" then
            return index
        end
    end
    return 0
end

local function autoHeal()
    while autoHealEnabled do
        if Character and Character:FindFirstChild("Humanoid") then
            local humanoid = Character.Humanoid
            if humanoid.Health <= 99 then
                local bloodfruit_index = findBloodfruitIndex()
                if bloodfruit_index > 0 then
                    Packets.UseBagItem.send(bloodfruit_index)
                end
            end
        end
        task.wait(1 / 50)
    end
end

local function GetIceChunks()
    local chunks = {}
    local function processChild(child)
        if child:IsA("Model") or child:IsA("BasePart") then
            local Pivot = child:GetPivot()
            if (child.Name == "Ice Chunk" or child.Name == "Gold Node") and (Root.Position - Pivot.Position).Magnitude < 100 then
                table.insert(chunks, child)
            end
        end
    end

    for _, v in next, Workspace:GetChildren() do
        processChild(v)
    end

    local resources = Workspace:FindFirstChild("Resources")
    if resources then
        for _, v in next, resources:GetChildren() do
            processChild(v)
        end
    end

    return chunks
end

local function GetCaveChunks()
    local chunks = {}
    for x, v in next, Workspace.Resources:GetChildren() do
        local Pivot = v:GetPivot()
        if v.Name == "Gold Node" and (Root.Position - Pivot.Position).Magnitude < 100 then
            table.insert(chunks, v)
        end
    end
    return chunks
end

local function GetCrewmates()
    local critters = Workspace:FindFirstChild("Critters")
    if not critters then return {} end
    local crewmates = {}
    for _, v in pairs(critters:GetChildren()) do
        if (v.Name == "Crewmate" or v.Name == "Captain") and v:IsA("Model") and v:FindFirstChild("HumanoidRootPart") then
            table.insert(crewmates, v)
        end
    end
    return crewmates
end

local SEND_DT = 0.02
local LOOKUP_DT = 2
local BURST_MAX = 5

local function pressCoins()
    local press, entityID, lastLookup, lastSend = nil, nil, 0, 0

    while CoinpressEnabled do
        local now = os.clock()

       if (not press or not press.Parent or (now - lastLookup) >= LOOKUP_DT) then
            press = GetDeployable("Coin Press", 25)
            entityID = (press and press:GetAttribute("EntityID")) or nil
            lastLookup = now
        end


        if entityID then
            local goldAmt = GetQuantity("Gold") or 0
            if goldAmt > 0 and (now - lastSend) >= SEND_DT then
                local n = math.min(goldAmt, BURST_MAX)
                for i = 1, n do
                    Packets.InteractStructure.send({ entityID = entityID, itemID = ItemIDS.Gold })
                end
                lastSend = now
            end
        end

        RunService.Heartbeat:Wait()
    end
end

local function pickupCoins()
    while pickUpPressedGold do
        local Items = Workspace:FindFirstChild("Items")
        if Items then
            for _, item in ipairs(Items:GetChildren()) do
                if item.Name == "Coin2" then
                    Packets.Pickup.send(item:GetAttribute("EntityID"))
                end
            end
        end
        task.wait()
    end
end

local function pickupAllItem()
    while pickupAllItems do
        local Items = Workspace:FindFirstChild("Items")
        if Items then
            for _, item in ipairs(Items:GetChildren()) do
                Packets.Pickup.send(item:GetAttribute("EntityID"))
                task.wait()
            end
        end
        task.wait(0.5)
    end
end

local function pickupGolds()
    while pickupGold do
        if chest and chest.Parent then
            if pickUpGoldEnabled then
                for _, v in next, chest.Contents:GetChildren() do
                    if v.Name == "Gold" then
                        local id = v:GetAttribute("EntityID")
                        if id then
                            Packets.Pickup.send(id)
                            task.wait(0.05)
                        end
                    end
                end
            end
        end

        local ItemsFolder = Workspace:FindFirstChild("Items")
        if ItemsFolder then
            for _, item in ipairs(ItemsFolder:GetChildren()) do
                if item.Name == "Gold" then
                    local t0 = os.clock()
                    local id = item:GetAttribute("EntityID")
                    while item.Parent == workspace.Items and not id and os.clock() - t0 < 3 do
                        task.wait()
                        id = item:GetAttribute("EntityID")
                    end
                    if id then
                        for i = 1, 8 do
                            if not item or item.Parent ~= workspace.Items then break end
                            Packets.Pickup.send(id)
                            task.wait(0.12)
                        end
                    end
                end
            end
        end

        task.wait(0.25)
    end
end

local function pickupRawGolds()
    while pickupRawGold do
        if chest and chest.Parent then
            for _, v in next, chest.Contents:GetChildren() do
                if v.Name == "Raw Gold" or v.Name == "Gold" then
                    local id = v:GetAttribute("EntityID")
                    if id then
                        Packets.Pickup.send(id)
                        task.wait(0.05)
                    end
                end
            end

        end

        local ItemsFolder = Workspace:FindFirstChild("Items")
        if ItemsFolder then
            for _, item in ipairs(ItemsFolder:GetChildren()) do
                if item.Name == "Raw Gold" then
                    local t0 = os.clock()
                    local id = item:GetAttribute("EntityID")
                    while item.Parent == workspace.Items and not id and os.clock() - t0 < 3 do
                        task.wait()
                        id = item:GetAttribute("EntityID")
                    end
                    if id then
                        for i = 1, 8 do
                            if not item or item.Parent ~= workspace.Items then break end
                            Packets.Pickup.send(id)
                            task.wait(0.12)
                        end
                    end
                end
            end
        end

        task.wait(0.25)
    end
end


local function sendEntitiesBuffer(entities)
    local bufferSize = #entities * 4 + 2
    local entityBuffer = buffer.create(bufferSize)
    local offset = 0

    for _, entity in pairs(entities) do
        local entityID = entity:GetAttribute("EntityID")
        buffer.writeu32(entityBuffer, offset, entityID)
        offset = offset + 4
    end

    local finalBuffer = buffer.create(offset)
    buffer.copy(finalBuffer, 0, entityBuffer, 0, offset)
    
    Packets.SwingTool.send(finalBuffer)
end
local function campfireRefuelLoop()
    while campEnabled do
        local list = GetDeployable("Campfire", 30, true) or {}
        for _, rec in ipairs(list) do
            local d = rec.deployable
            local board = d:FindFirstChild("Board")
            local bb = board and board:FindFirstChild("Billboard")
            local back = bb and bb:FindFirstChild("Backdrop")
            local tl = back and back:FindFirstChild("TextLabel")
            local secondsLeft = tonumber(tl and tl.Text) or 999

            if secondsLeft <= 10 then
                local fuel = GetFuel()
                if fuel then
                    Packets.InteractStructure.send({
                        entityID = d:GetAttribute("EntityID"),
                        itemID = fuel
                    })
                    task.wait(0.05)
                end
            end
        end
        task.wait(0.25)
    end
end

local function IcenodeFarm()
    while task.wait(0.1) do
        local chunks = GetIceChunks()
        for x, v in next, chunks do
            if v.Parent then
                Path:ComputeAsync(Root.Position, v:GetPivot().Position)
                Root.Anchored = false
                for m, n in next, Path:GetWaypoints() do
                    tweenInfo = {MaxSpeed = Humanoid.WalkSpeed, CFrame = CFrame.new(n.Position)}
                    tween = TweenService:Create(
                        Root, 
                        TweenInfo.new((Root.Position - n.Position).Magnitude / (tweenInfo.MaxSpeed * (tweenSpeed/10)), Enum.EasingStyle.Linear),
                        {CFrame = tweenInfo.CFrame * CFrame.new(0, Root.Size.Y, 0)}
                    )
                    tween:Play()
                    repeat
                        tween.Completed:Wait()
                    until not v or not v.Parent or tween.PlaybackState == Enum.PlaybackState.Completed
                end

                if v then
                    Root.Anchored = true
                    local node = v:FindFirstChild("Breakaway") and v.Breakaway:FindFirstChild("Gold Node")
                    local s = os.clock()
                    local entity
                    repeat
                        local swingEntities = {}
                        if v and v.Parent and v:GetAttribute("EntityID") then
                            table.insert(swingEntities, v:GetAttribute("EntityID"))
                        end
                        if node and node.Parent and node:GetAttribute("EntityID") then
                            table.insert(swingEntities, node:GetAttribute("EntityID"))
                        end
                        entity = (#swingEntities > 0)
                        if entity then
                            Packets.SwingTool.send(swingEntities)
                            task.wait(1 / 4)
                        end
                        task.wait()
                    until not entity or os.clock() - s > 25
                    Root.Anchored = false
                end
            end
        end

        if #chunks == 0 and chest then
            if not Root.Anchored then
                Path:ComputeAsync(Root.Position, chest:GetPivot().Position)
                for m, n in next, Path:GetWaypoints() do
                    tweenInfo = {MaxSpeed = Humanoid.WalkSpeed, CFrame = CFrame.new(n.Position)}
                    tween = TweenService:Create(
                        Root, 
                        TweenInfo.new((Root.Position - n.Position).Magnitude / (tweenInfo.MaxSpeed * (tweenSpeed/10)), Enum.EasingStyle.Linear),
                        {CFrame = tweenInfo.CFrame * CFrame.new(0, Root.Size.Y, 0)}
                    )
                    tween:Play()
                    repeat
                        tween.Completed:Wait()
                    until not chest or tween.PlaybackState == Enum.PlaybackState.Completed
                end
                Root.Anchored = true
            end
            
            if pickUpGoldEnabled then
                for x, v in next, chest.Contents:GetChildren() do
                    if v.Name == "Gold" then
                        Packets.Pickup.send(v:GetAttribute("EntityID"))
                    end
                end
            end

            if pressEnabled then
                local deployable = GetDeployable("Coin Press", 25)
                if deployable then
                    for x, v in next, chest.Contents:GetChildren() do
                        if v.Name == "Gold" then
                            Packets.Pickup.send(v:GetAttribute("EntityID"))
                            Packets.InteractStructure.send({
                                entityID = deployable:GetAttribute("EntityID"),
                                itemID = ItemIDS[v.Name]
                            })
                            task.wait(0.2)
                        end
                    end
                end
            end
        end
    end
end

local function CavenodeFarm()
    while task.wait(0.5) do
        local chunks = GetCaveChunks()
        for x, v in next, chunks do
            if v.Parent then
                Path:ComputeAsync(Root.Position, v:GetPivot().Position)
                Root.Anchored = false
                for m, n in next, Path:GetWaypoints() do
                    tweenInfo = {MaxSpeed = Humanoid.WalkSpeed, CFrame = CFrame.new(n.Position)}
                    tween = TweenService:Create(Root, TweenInfo.new((Root.Position - n.Position).Magnitude / (tweenInfo.MaxSpeed * (tweenSpeed/10)), Enum.EasingStyle.Linear), {CFrame = tweenInfo.CFrame * CFrame.new(0, Root.Size.Y, 0)})
                    tween:Play()
                    repeat
                        tween.Completed:Wait()
                    until not v or not v.Parent or tween.PlaybackState == Enum.PlaybackState.Completed
                end

                if v then
                    Root.Anchored = true
                    local node = v:FindFirstChild("Gold Node")
                    local s = os.clock()
                    repeat
                        local entity = (v and v.Parent) and v or (node and node.Parent and node)
                        if entity then
                            Packets.SwingTool.send({ entity:GetAttribute("EntityID") })
                        end
                        task.wait()
                    until not entity or os.clock() - s > 25
                    Root.Anchored = false
                end
            end
        end

        if #chunks == 0 and chest then
            if not Root.Anchored then
                Path:ComputeAsync(Root.Position, chest:GetPivot().Position)
                for m, n in next, Path:GetWaypoints() do
                    tweenInfo = {MaxSpeed = Humanoid.WalkSpeed, CFrame = CFrame.new(n.Position)}
                    tween = TweenService:Create(Root, TweenInfo.new((Root.Position - n.Position).Magnitude / (tweenInfo.MaxSpeed * (tweenSpeed/10)), Enum.EasingStyle.Linear), {CFrame = tweenInfo.CFrame * CFrame.new(0, Root.Size.Y, 0)})
                    tween:Play()
                    repeat
                        tween.Completed:Wait()
                    until not chest or tween.PlaybackState == Enum.PlaybackState.Completed
                end
                Root.Anchored = true
            end      

            if pressEnabled then
                local deployable = GetDeployable("Coin Press", 25)
                if deployable then
                    for x, v in next, chest.Contents:GetChildren() do
                        if v.Name == "Gold" then
                            Packets.Pickup.send(v:GetAttribute("EntityID"))
                            Packets.InteractStructure.send({entityID = deployable:GetAttribute("EntityID"), itemID = ItemIDS[v.Name]})
                            task.wait(0.2)
                        end
                    end
                end
            end
        end
    end
end

local function antFarm()
    while task.wait(1 / 3) do
        local entities = {}
        for _, v in next, Workspace:GetPartBoundsInRadius(Root.Position, 25) do
            if v.Name == "HumanoidRootPart" and v.Parent.Name == "Queen Ant's Servant" then
                local id = v.Parent:GetAttribute("EntityID")
                if id then
                    table.insert(entities, id)
                end
            end
        end
        if #entities > 0 then
            Packets.SwingTool.send(entities)
        end

        if chest then

            if pressEnabled then
                if chest.Contents:FindFirstChild("Gold") then
                    for _, v in next, chest.Contents:GetChildren() do
                        if v.Name == "Gold" then
                            Packets.Pickup.send(v:GetAttribute("EntityID"))
                        end
                    end
                end

                local deployable = GetDeployable("Coin Press", 25)
                if deployable then
                    local quantity = GetQuantity("Gold")
                    if quantity then
                        local entityID = deployable:GetAttribute("EntityID")
                        local itemID = ItemIDS.Gold
                        for i = 1, quantity do
                            Packets.InteractStructure.send({ entityID = entityID, itemID = itemID })
                            task.wait(0.2)
                        end
                    end
                end
            end
        end
    end
end


local function autoFarmPumpkin()
    while task.wait() do
        if Root then
            local hugePumpkin = Workspace:FindFirstChild("Huge Pumpkin")
            if hugePumpkin and hugePumpkin.PrimaryPart then
                local playerCharacter = Players.LocalPlayer.Character
                if not playerCharacter then
                    playerCharacter = Players.LocalPlayer.CharacterAdded:Wait()
                end
                local humanoidRootPart = playerCharacter:FindFirstChild("HumanoidRootPart")
                local humanoid = playerCharacter:FindFirstChildOfClass("Humanoid")

                if humanoidRootPart and humanoid then
                    local path = PathfindingService:CreatePath({
                        AgentRadius = 2,
                        AgentHeight = 5,
                        AgentCanJump = true,
                        AgentJumpHeight = humanoid.JumpHeight,
                        AgentMaxSlope = humanoid.MaxSlopeAngle,
                    })

                    path:ComputeAsync(humanoidRootPart.Position, hugePumpkin.PrimaryPart.Position)
                    humanoidRootPart.Anchored = false

                    for _, waypoint in ipairs(path:GetWaypoints()) do
                        local tweenInfo = TweenInfo.new(
                            (humanoidRootPart.Position - waypoint.Position).Magnitude / humanoid.WalkSpeed,
                            Enum.EasingStyle.Linear
                        )
                        local goal = {
                            CFrame = CFrame.new(waypoint.Position)
                        }
                        local tween = TweenService:Create(humanoidRootPart, tweenInfo, goal)
                        tween:Play()
                        tween.Completed:Wait()
                    end

                    humanoidRootPart.Anchored = true
                    local s = os.clock()
                    repeat
                        local entity = hugePumpkin.Parent and hugePumpkin
                        if entity then
                            --sendEntitiesBuffer({entity})
                            Packets.SwingTool.send({entity:GetAttribute("EntityID")})
                            task.wait(1 / 3)
                        end
                        task.wait()
                    until not entity or os.clock() - s > 25
                    humanoidRootPart.Anchored = false
                else
                    warn("Unable to find Huge Pumpkin or character components.")
                end
            else
                local deployable = GetDeployable("Plant Box", 100, true)
                table.sort(deployable, function(a, b)
                    return a.range < b.range
                end)

                for x, v in next, deployable do
                    if not v.deployable:FindFirstChild("Seed") then
                        tween2 = TweenService:Create(Root, TweenInfo.new(v.range / 20, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {CFrame = v.deployable:GetPivot() * CFrame.new(0, 5, 0)})
                        tween2:Play()
                        break
                    end
                end

                for m, n in next, Workspace:GetChildren() do
                    local item = ItemData[n.Name]
                    if item and item.itemType == "crop" and (Root.Position - n:GetPivot().Position).Magnitude < 25 then
                        Packets.Pickup.send(n:GetAttribute("EntityID"))
                    end
                end

                for x, v in next, deployable do
                    if v.range < 25 then
                        if not v.deployable:FindFirstChild("Seed") and HasItem(fruit) then
                            Packets.InteractStructure.send({entityID = v.deployable:GetAttribute("EntityID"), itemID = ItemIDS[fruit]})
                            task.wait(0.023333333)
                        end
                    end
                end
            end
        else
            fruitRun:Set(false)
            warn("Couldn't find the root")
        end
    end
end

local function crewFarm()
    local lastPosition = nil
    local stuckCounter = 0
    local stuckThreshold = 5

    while task.wait(1 / 3) do
        local crewmates = GetCrewmates()
        for _, crewmate in pairs(crewmates) do
            if crewmate.Parent then
                Path:ComputeAsync(Root.Position, crewmate.HumanoidRootPart.Position)
                Root.Anchored = false
                local success = true
                for _, waypoint in pairs(Path:GetWaypoints()) do
                    if not success then break end
                    tweenInfo = {MaxSpeed = Humanoid.WalkSpeed, CFrame = CFrame.new(waypoint.Position)}
                    tween = TweenService:Create(Root, TweenInfo.new((Root.Position - waypoint.Position).Magnitude / (tweenInfo.MaxSpeed * (tweenSpeed/10)), Enum.EasingStyle.Linear), {CFrame = tweenInfo.CFrame * CFrame.new(0, Root.Size.Y, 0)})
                    tween:Play()
                    local connection
                    connection = tween.Completed:Connect(function()
                        if (Root.Position - waypoint.Position).Magnitude > 5 then
                            success = false
                            connection:Disconnect()
                        end
                    end)
                    repeat
                        task.wait()
                    until not crewmate or not crewmate.Parent or tween.PlaybackState == Enum.PlaybackState.Completed
                end

                if success and crewmate then
                    Root.Anchored = true
                    local s = os.clock()
                    repeat
                        Packets.SwingTool.send({crewmate:GetAttribute("EntityID")})
                        task.wait(1 / 3)
                    until not crewmate.Parent or os.clock() - s > 25
                    Root.Anchored = false
                else
                    task.wait(1)
                end
            end

            if lastPosition then
                if (Root.Position - lastPosition).Magnitude < 1 then
                    stuckCounter = stuckCounter + 1
                else
                    stuckCounter = 0
                end

                if stuckCounter >= stuckThreshold then
                    stuckCounter = 0
                    break
                end
            end

            lastPosition = Root.Position
        end
    end
end

local function fruitJump(on)
    fruitJumpEnabled = on
    if on then
        if fruitJumpThread then return end
        fruitJumpThread = task.spawn(function()
            while fruitJumpEnabled do
                if Humanoid and Humanoid.Parent and Humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
                    Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
                task.wait(1)
            end
        end)
    else
        if fruitJumpThread then pcall(task.cancel, fruitJumpThread); fruitJumpThread = nil end
    end
end

local function fruitFarm()
    while task.wait() do
        if not Root then
            fruitRun = false
            warn("Couldn't find root")
            return
        end

        local deployable = GetDeployable("Plant Box", 100, true) or {}
        table.sort(deployable, function(a, b) return a.range < b.range end)

        if tweenEnabled then
            for _, v in ipairs(deployable) do
                if v.deployable and not v.deployable:FindFirstChild("Seed") then
                    tween2 = TweenService:Create(
                        Root,
                        TweenInfo.new(v.range / 20, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut),
                        { CFrame = v.deployable:GetPivot() * CFrame.new(0, 5, 0) }
                    )
                    tween2:Play()
                    break
                end
            end
        end

        if harEnabled and (os.clock() - lastHarvestScan > 0.5) then
            lastHarvestScan = os.clock()
            local resources = Workspace:FindFirstChild("Resources")
            if resources then
                for _, n in ipairs(resources:GetChildren()) do
                    local item = ItemData[n.Name]
                    if item and item.itemType == "crop" and (Root.Position - n:GetPivot().Position).Magnitude < 25 then
                        Packets.Pickup.send(n:GetAttribute("EntityID"))
                    end
                end
            end
        end

        if plantEnabled then
            for _, v in ipairs(deployable) do
                if v.range < 25 and v.deployable and not v.deployable:FindFirstChild("Seed") and HasItem(fruit) then
                    Packets.InteractStructure.send({ entityID = v.deployable:GetAttribute("EntityID"), itemID = ItemIDS[fruit] })
                end
            end
        end
    end
end

function getFruitAmounts()
    local amounts = {}
    for _, fruitName in pairs(fruitOptions) do
        amounts[fruitName] = GetQuantity(fruitName) or 0
    end
    return amounts
end

function sendFruitAmount(startAmounts, endAmounts, duration)
    pcall(function()
        local description = "Fruits tracked in " .. duration .. ":\n"
        for fruitName, startAmount in pairs(startAmounts) do
            local endAmount = endAmounts[fruitName] or 0
            local change = endAmount - startAmount
            description = description .. fruitName .. " made: " .. tostring(change) .. "\n"
        end
        local data = {
            ["content"] = "",
            ["embeds"] = {{
                ["title"] = "Midas Hub's Fruit Tracker",
                ["description"] = description,
                ["color"] = 65280,
                ["footer"] = {
                    ["text"] = "discord.gg/FDAhrbbT7F"
                }
            }}
        }

        local response = request({
            Url = getgenv().webhook,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode(data)
        })

        if response.StatusCode ~= 200 then
            print("Webhook failed with status code: " .. response.StatusCode)
        end
    end)
end

local function addCurrentPosition()
    local root = game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if root then
        local pos = root.Position
        table.insert(positionList, {Y = pos.Y, X = pos.X, Z = pos.Z})
        Notify("Position added: " .. tostring(pos))
    end
end

local function interactWithNearbyResources(radius)
    local Character = Players.LocalPlayer.Character
    if not Character then return end

    local nearbyEntities = {}
    for _, resource in ipairs(Workspace.Resources:GetChildren()) do
        local distance = (Character:GetPivot().Position - resource:GetPivot().Position).Magnitude
        if distance <= radius then
            --table.insert(nearbyEntities, resource)
            table.insert(nearbyEntities, resource:GetAttribute("EntityID"))
        end
    end

    if #nearbyEntities > 0 then
        Packets.SwingTool.send(nearbyEntities)
    end
end

local function startWalking()
    if not Humanoid or not Humanoid.Parent then
        Notify("Humanoid not found, reinitializing.")
        Character = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
        Humanoid = Character:WaitForChild("Humanoid")
        Root = Character:WaitForChild("HumanoidRootPart")
    end
    if #positionList == 0 then
        Notify("Unable to start walking. No positions available.")
        return
    end

    local REACH_RADIUS = 4
    local MAX_TRAVEL_SECS = 15 
    local NO_PROGRESS_SECS = 2.5
    local MIN_IMPROVE_studs = 0.75

    while walkingEnabled do
        local rp = Root.Position
        local i, bestD = 1, math.huge
        for j = 1, #positionList do
            local p = positionList[j]
            if p and p.X and p.Y and p.Z then
                local d = (rp - Vector3.new(p.X, p.Y, p.Z)).Magnitude
                if d < bestD then i, bestD = j, d end
            end
        end

        for step = 1, #positionList do
            if not walkingEnabled then break end
            local pos = positionList[i]
            if not (pos and pos.X and pos.Y and pos.Z) then
                Notify("Invalid position data."); break
            end

            local targetPos = Vector3.new(pos.X, pos.Y, pos.Z)
            Humanoid:MoveTo(targetPos)

            local moveFinished, restartToNearest = false, false
            local conn; conn = Humanoid.MoveToFinished:Connect(function() moveFinished = true; if conn then conn:Disconnect() end end)

            local t0 = tick()
            local lastCheck = t0
            local lastDist = (Root.Position - targetPos).Magnitude

            while walkingEnabled and not moveFinished do
                task.wait(0.2)
                local curDist = (Root.Position - targetPos).Magnitude
                if curDist <= REACH_RADIUS then
                    moveFinished = true
                    break
                end
                if (tick() - t0) > MAX_TRAVEL_SECS or ((tick() - lastCheck) > NO_PROGRESS_SECS and (lastDist - curDist) < MIN_IMPROVE_studs) then
                    restartToNearest = true
                    break
                end
                lastCheck = tick()
                lastDist = curDist
            end

            if conn then conn:Disconnect() end

            if restartToNearest then
                break
            end

            i = (i % #positionList) + 1
            task.wait(0.1)
        end
    end

end

local function startTweening()
    if not Humanoid or not Humanoid.Parent then
        Notify("Humanoid not found, reinitializing.")
        Character = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
        Humanoid = Character:WaitForChild("Humanoid")
        Root = Character:WaitForChild("HumanoidRootPart")
    end
    if #positionList == 0 then
        Notify("Unable to start Tweening. No positions available.")
        return
    end

    local REACH_RADIUS = 4
    local MIN_IMPROVE_STUDS = 0.75
    local NO_PROGRESS_SECS = 2.5
    local TELEPORT_BACK_DINC = 8
    local TELEPORT_STEP_JUMP = 15

    local RUBBER_DEV_STUDS = 6
    local SETTLE_SECS = 0.40
    local MAX_RB_PER_NODE = 3
    local JUMP_SAMPLE_SECS = 0.20

    local function nearestIndex(fromPos)
        local bestI, bestD = 1, math.huge
        for j = 1, #positionList do
            local p = positionList[j]
            if p and p.X and p.Y and p.Z then
                local d = (fromPos - Vector3.new(p.X, p.Y, p.Z)).Magnitude
                if d < bestD then bestI, bestD = j, d end
            end
        end
        return bestI
    end

    local curIndex = nearestIndex(Root.Position)
    local fails = table.create(#positionList, 0)
    local rbCount = table.create(#positionList, 0)

    while tweeningEnabled do
        if curIndex < 1 or curIndex > #positionList then
            curIndex = 1
        end

        local pos = positionList[curIndex]
        if not (pos and pos.X and pos.Y and pos.Z) then
            Notify(("Invalid pos @ %d, skipping."):format(curIndex))
            curIndex = (curIndex % #positionList) + 1
            task.wait(0.05)
            continue
        end

        local targetPos = Vector3.new(pos.X, pos.Y, pos.Z)
        local startPos  = Root.Position
        local dist = (startPos - targetPos).Magnitude
        local speed = walkSpeed
        local MAX_TRAVEL_SECS = math.max(15, dist / (speed * 0.6))
        local duration = math.max(0.02, dist / speed)

        if tweenConn then tweenConn:Disconnect(); tweenConn = nil end
        if tween then tween:Cancel(); tween = nil end

        local ti = TweenInfo.new(duration, Enum.EasingStyle.Linear)
        tween = TweenService:Create(Root, ti, { CFrame = CFrame.new(targetPos) })

        local completed, restartToNext, rubberbanded = false, false, false
        local jumpOuter = false

        local t0 = tick()
        local lastPoll = t0
        local lastPos  = startPos
        local lastDist = (lastPos - targetPos).Magnitude

        tweenConn = tween.Completed:Connect(function()
            completed = true
            if tweenConn then tweenConn:Disconnect(); tweenConn = nil end
        end)

        tween:Play()

        while tweeningEnabled and not completed do
            task.wait(JUMP_SAMPLE_SECS)

            local now = tick()
            local elapsed = now - t0
            local alpha = math.clamp(elapsed / duration, 0, 1)

            local curPos  = Root.Position
            local curDist = (curPos - targetPos).Magnitude

            if curDist <= REACH_RADIUS then
                completed = true
                break
            end

            local stepJump = (curPos - lastPos).Magnitude
            if (curDist - lastDist) >= TELEPORT_BACK_DINC or stepJump >= TELEPORT_STEP_JUMP then
                rubberbanded = true
            end

            do
                local expectPos = startPos:Lerp(targetPos, alpha)
                local dev = (curPos - expectPos).Magnitude
                if dev >= RUBBER_DEV_STUDS then
                    local vmag = Root.AssemblyLinearVelocity.Magnitude
                    if vmag < 1 or dev > (RUBBER_DEV_STUDS * 1.5) then
                        rubberbanded = true
                    end
                end
            end

            if (now - t0) > MAX_TRAVEL_SECS
               or ((now - lastPoll) > NO_PROGRESS_SECS and (lastDist - curDist) < MIN_IMPROVE_STUDS) then
                restartToNext = true
                break
            end

            if rubberbanded then
                if tweenConn then tweenConn:Disconnect(); tweenConn = nil end
                if tween then tween:Cancel(); tween = nil end

                task.wait(SETTLE_SECS)
                local serverPos = Root.Position
                local newIndex  = nearestIndex(serverPos)

                rbCount[curIndex] = (rbCount[curIndex] or 0) + 1
                if rbCount[curIndex] >= MAX_RB_PER_NODE then
                    Notify(("Rubberband @ %d x%d -> skip node."):format(curIndex, rbCount[curIndex]))
                    rbCount[curIndex] = 0
                    curIndex = (curIndex % #positionList) + 1
                else
                    curIndex = newIndex
                end

                Root.Anchored = false
                task.wait(0.1)
                jumpOuter = true
                break
            end

            lastPoll = now
            lastDist = curDist
            lastPos = curPos
        end

        if tweenConn then tweenConn:Disconnect(); tweenConn = nil end
        if tween then tween:Cancel(); tween = nil end

        if jumpOuter then
            continue
        end

        if restartToNext then
            fails[curIndex] = (fails[curIndex] or 0) + 1
            if fails[curIndex] >= 3 then
                Notify(("Skipping idx %d after repeated fails."):format(curIndex))
                fails[curIndex] = 0
            end
            curIndex = (curIndex % #positionList) + 1
            Root.Anchored = false
            task.wait(0.15)
            continue
        end

        fails[curIndex] = 0
        rbCount[curIndex] = 0
        curIndex = (curIndex % #positionList) + 1
        task.wait(0.1)
    end

    if tweenConn then tweenConn:Disconnect(); tweenConn = nil end
    if tween then tween:Cancel(); tween = nil end
end

local function autoJump()
    while autoJumpEnabled do
        if Humanoid and Humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
            Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
        task.wait(0.2)
    end
end

local function savePositionsTab()
    if #positionList == 0 then
        Notify("No positions to save.")
        return
    end

    local serializedPositionsTab = {}

    for _, pos in ipairs(positionList) do
        local positionString = string.format('{"Y":%f,"X":%f,"Z":%f}', pos.Y, pos.X, pos.Z)
        table.insert(serializedPositionsTab, positionString)
    end

    local fileContent = table.concat(serializedPositionsTab, ",")
    writefile(selectedFileName, fileContent)
    Notify("Positions saved to " .. selectedFileName)
end

local function createRedBlobAtPosition(position)
    local blob = Instance.new("Part")
    blob.Shape = Enum.PartType.Ball
    blob.Color = Color3.new(1, 0, 0)
    blob.Size = Vector3.new(2, 2, 2)
    blob.Anchored, blob.CanCollide, blob.Position = true, false, position
    blob.Parent = workspace

    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Size = UDim2.new(0, 100, 0, 50)
    billboardGui.StudsOffset = Vector3.new(0, -3, 0)
    billboardGui.Adornee = blob
    billboardGui.Parent = blob

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = string.format("X: %.2f\nY: %.2f\nZ: %.2f", position.X, position.Y, position.Z)
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.TextScaled = true
    textLabel.Parent = billboardGui

    table.insert(posBlobs, blob)
end

local function clearPosBlobs()
    for _,b in ipairs(posBlobs) do pcall(function() b:Destroy() end) end
    table.clear(posBlobs)
end

local function loadPositionsTab()
    if not isfile(selectedFileName) then
        Notify("Could not find the file: " .. selectedFileName)
        return
    end
    clearPosBlobs()
    local contents = readfile(selectedFileName)
    setclipboard(contents)
    positionList = {}

    local entries = contents:gsub("%[", ""):gsub("%]", ""):split("},")

    for _, entry in ipairs(entries) do
        local y, x, z = entry:match('"Y":([%d%.%-]+),"X":([%d%.%-]+),"Z":([%d%.%-]+)')

        local xVal = tonumber(x)
        local yVal = tonumber(y)
        local zVal = tonumber(z)

        if xVal and yVal and zVal then
            local pos = Vector3.new(xVal, yVal, zVal)
            table.insert(positionList, pos)
            createRedBlobAtPosition(pos)
        else
            Notify("Invalid position data detected and skipped.")
        end
    end

    Notify("PositionsTab loaded from " .. selectedFileName)
end


local function clearPositionSet()
    positionList = {}
    clearPosBlobs()
    Notify("Position set cleared.")
end

local function noclipDoors(enabled)
    noclip = enabled
    for _, v in workspace.Deployables:GetChildren() do
        if v:FindFirstChild("Door") then
            v.Door.Transparency = enabled and 0.5 or 0
            v.Door.CanCollide = not enabled
        end
    end
    for _, v in workspace.Resources:GetChildren() do
        if v.Name == "Old Boards" then
            v:Destroy()
        end
    end
end

local function updateHugePumpkinESP()
    local hugePumpkinsFound = false

    for _, v in pairs(Workspace:GetChildren()) do
        if v.Name == "Huge Pumpkin" and v:IsA("Model") and v.PrimaryPart then
            hugePumpkinsFound = true
            if not v:FindFirstChildOfClass("Highlight") then
                local highlight = Instance.new("Highlight")
                highlight.Adornee = v
                highlight.FillColor = Color3.fromRGB(255, 165, 0)
                highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                highlight.Parent = v
            end
        end
    end

    if not hugePumpkinsFound then
        Notify("ESP Notification", "No Huge Pumpkins found!", "", 4)
    end
end

local function toggleHugePumpkinESP()
    if espEnabled then
        espConnection = RunService.Heartbeat:Connect(function()
            updateHugePumpkinESP()
        end)
    else
        if espConnection then
            espConnection:Disconnect()
            espConnection = nil
        end
        for _, v in pairs(Workspace:GetChildren()) do
            if v.Name == "Huge Pumpkin" and v:IsA("Model") then
                local highlight = v:FindFirstChildOfClass("Highlight")
                if highlight then
                    highlight:Destroy()
                end
            end
        end
    end
end

local function applySkins()
    for i = 1, 999 do
        pcall(function()
            SkinHandler.SkinAdded(tostring(math.random(100000, 999999)), i)
        end)
    end
end

local function startAutoFishing()
    if rodBubbleConn then rodBubbleConn:Disconnect(); rodBubbleConn = nil end
    rodBubbleConn = Packets.RodBubble.listen(function(data)
        if data.should_bubble then
            Packets.RodEnd.send()
        end
    end)
    if autoFishLoop then pcall(task.cancel, autoFishLoop) end
    autoFishLoop = task.spawn(function()
        while autoFishEnabled do
            if not Players.LocalPlayer:GetAttribute("Fishing") then
                local ray = workspace.CurrentCamera:ScreenPointToRay(LocalPlayerMouse.X, LocalPlayerMouse.Y)
                Packets.RodSwing.send({ origin = ray.Origin, direction = ray.Direction * 2000 })
            end
            task.wait(1)
        end
    end)
end

local function autoFarmGoldPot()
    while task.wait() do
        if Root then
            local goldPot = GetDeployable("Gold Pot", math.huge, false)
            local megaGoldPot = GetDeployable("Mega Gold Pot", math.huge, false)
            
            local pots = {}
            if goldPot then
                table.insert(pots, goldPot)
            end
            if megaGoldPot then
                table.insert(pots, megaGoldPot)
            end
            
            if #pots > 0 then
                local playerCharacter = Players.LocalPlayer.Character
                if not playerCharacter then
                    playerCharacter = Players.LocalPlayer.CharacterAdded:Wait()
                end
                local humanoidRootPart = playerCharacter:FindFirstChild("HumanoidRootPart")
                local humanoid = playerCharacter:FindFirstChildOfClass("Humanoid")
                
                if humanoidRootPart and humanoid then
                    for _, pot in ipairs(pots) do
                        local path = PathfindingService:CreatePath({
                            AgentRadius = 2,
                            AgentHeight = 5,
                            AgentCanJump = true,
                            AgentJumpHeight = humanoid.JumpHeight,
                            AgentMaxSlope = humanoid.MaxSlopeAngle,
                        })
                        
                        local potPosition = pot:GetPivot().Position
                        path:ComputeAsync(humanoidRootPart.Position, potPosition)
                        humanoidRootPart.Anchored = false
                        
                        for _, waypoint in ipairs(path:GetWaypoints()) do
                            local tweenInfo = TweenInfo.new(
                                (humanoidRootPart.Position - waypoint.Position).Magnitude / humanoid.WalkSpeed,
                                Enum.EasingStyle.Linear
                            )
                            local goal = { CFrame = CFrame.new(waypoint.Position) }
                            local tween = TweenService:Create(humanoidRootPart, tweenInfo, goal)
                            tween:Play()
                            tween.Completed:Wait()
                        end
                        
                        humanoidRootPart.Anchored = true
                        local startTime = os.clock()
                        repeat
                            local entity = pot.Parent and pot
                            if entity then
                                Packets.SwingTool.send({ entity:GetAttribute("EntityID") })
                                task.wait(1 / 3)
                            end
                        until not entity or os.clock() - startTime > 25
                        humanoidRootPart.Anchored = false
                        
                        if replacePotEnabled then
                            task.wait(0.01)
                            Packets.PlaceStructure.send({["buildingName"] = "Empty Pot", ["vec"] = potPosition, ["yrot"] = 90, ["isMobile"] = false})
                        end
                    end
                else
                    warn("Unable to find Gold/Mega Gold Pot or character components.")
                end
            end
        end
    end
end

local function getInventoryNameList()
    local seen, list = {}, {}
    for _, data in next, GameUtil.getData().inventory do
        local n = data and data.name
        if n and not seen[n] then
            seen[n] = true
            table.insert(list, n)
        end
    end
    table.sort(list)
    return list
end

local function findItemIndexByName(itemName)
    for index, data in next, GameUtil.getData().inventory do
        if data.name == itemName then
            return index
        end
    end
    return 0
end

local function ensureHasQuantity(name, want)
    local have = tonumber((GetQuantity(name) or 0)) or 0
    return have >= want, have
end

local function dropItemN(name, count)
    for i = 1, count do
        local idx = findItemIndexByName(name)
        if idx == 0 then
            return false, i - 1
        end
        Packets.DropBagItem.send(idx)
        task.wait(0.3)
    end
    return true, count
end
local function getNearbyCauldrons()
    local list = GetDeployable("Cauldron", cauldronRange, true) or {}
    local out = {}
    for _, rec in ipairs(list) do
        table.insert(out, rec.deployable)
    end
    return out
end


local function queueForItem(itemName, cauldrons, countPerCauldron)
    autoBrewQueue[itemName] = autoBrewQueue[itemName] or {}
    for _, c in ipairs(cauldrons) do
        for _ = 1, countPerCauldron do
            if #autoBrewQueue[itemName] >= AUTO_BREW_QCAP then return end
            table.insert(autoBrewQueue[itemName], c)
        end
    end
end

local function planDropsForCauldrons(recipeTable, cauldrons)
    autoBrewInFlight = {}
    autoBrewQueue = {}

    autoBrewInFlight["Ice Cube"] = BASE_ICE_CUBES * #cauldrons
    queueForItem("Ice Cube", cauldrons, BASE_ICE_CUBES)

    for name, qty in pairs(recipeTable) do
        autoBrewInFlight[name] = qty * #cauldrons
        queueForItem(name, cauldrons, qty)
    end
end

local function markInFlightItemsForTP(recipeTable)
    autoBrewInFlight = {}
    autoBrewInFlight["Ice Cube"] = (autoBrewInFlight["Ice Cube"] or 0) + BASE_ICE_CUBES
    for name, qty in pairs(recipeTable) do
        autoBrewInFlight[name] = (autoBrewInFlight[name] or 0) + qty
    end
end

local function brewPotionOnce(potionName)
    local cauldrons = getNearbyCauldrons()
    if not cauldrons or #cauldrons == 0 then
        Notify("Auto Brew", "No Cauldron within range (" .. tostring(cauldronRange) .. ").")
        return false
    end

    local recipe = POTION_RECIPES[potionName]
    if not recipe then
        Notify("Auto Brew", "Unknown potion: " .. tostring(potionName))
        return false
    end

    local maxSets = math.huge

    local okIce, haveIce = ensureHasQuantity("Ice Cube", BASE_ICE_CUBES)
    if not okIce then
        Notify("Auto Brew", "Need 3× Ice Cube (have " .. tostring(haveIce) .. ").")
        return false
    end
    maxSets = math.min(maxSets, math.floor((haveIce or 0) / BASE_ICE_CUBES))

    for name, need in pairs(recipe) do
        local haveOK, have = ensureHasQuantity(name, need)
        if not haveOK then
            Notify("Auto Brew", ("Missing %dx %s (have %d)."):format(need, name, have))
            return false
        end
        maxSets = math.min(maxSets, math.floor((have or 0) / need))
    end

    if maxSets <= 0 then
        Notify("Auto Brew", "Not enough ingredients for any set.")
        return false
    end

    local setsToRun = math.min(#cauldrons, maxSets)
    local activeCauldrons = {}
    for i = 1, setsToRun do
        table.insert(activeCauldrons, cauldrons[i])
    end
    currentCauldron = nil
    local currentCauldrons = activeCauldrons

    planDropsForCauldrons(recipe, activeCauldrons)

    local function dropTotal(name, perSet)
        return dropItemN(name, perSet * setsToRun)
    end

    local ok1 = dropTotal("Ice Cube", BASE_ICE_CUBES)
    if not ok1 then
        Notify("Auto Brew", "Failed to drop base Ice Cubes.")
        return false
    end

    task.wait(ICE_MELT_WAIT)

    for name, qty in pairs(recipe) do
        local ok2 = dropTotal(name, qty)
        if not ok2 then
            Notify("Auto Brew", "Failed to drop recipe item: " .. name)
            return false
        end
        task.wait()
    end

    --Notify("Auto Brew", ("Dropped ingredients for %s x%d cauldron(s)."):format(potionName, setsToRun))
    return true
end

local function autoDropLoop()
    while autoDropEnabled do
        if not selectedDropItem then
            Notify("Dropper", "Select an item first.")
            break
        end

        local qty, idx = GetQuantity(selectedDropItem)
        qty = tonumber(qty or 0)

        if not idx or qty <= 0 then
            Notify("Dropper", "No more " .. tostring(selectedDropItem) .. " to drop.")
            break
        end

        Packets.DropBagItem.send(idx)
        task.wait()
    end

    autoDropEnabled = false
end

local function setBushVisibility(visible)
    bushesVisible = visible
    currentBushName = (fruit or "Bloodfruit") .. " Bush"
    for _, bush in ipairs(Workspace:GetChildren()) do
        if bush:IsA("Model") and bush.Name == currentBushName then
            for _, part in bush:GetDescendants() do
                if part:IsA("BasePart") then
                    part.Transparency = visible and 0 or 1
                    part.CanCollide = true
                end
            end
        end
    end
end

local function getMyLevel()
    local lvl = tonumber(GameUtil.Data and GameUtil.Data.level or 0) or 0
    return lvl
end

function doRebirthIfReady()
    local lvl = getMyLevel()
    if lvl >= LEVEL_TO_REBIRTH then
        Packets.Rebirth.send()
    end
    return false
end

local function showGameplayUI()
    local SpawnGui = PG:FindFirstChild("SpawnGui")
    local MainGui = PG:FindFirstChild("MainGui")
    local Topbar = PG:FindFirstChild("Topbar")
    if SpawnGui then SpawnGui.Enabled = false end
    if MainGui then MainGui.Enabled  = true  end
    if Topbar then Topbar.Enabled   = true  end
    for _, ui in ipairs(PG:GetChildren()) do
        if ui:IsA("ScreenGui") and ui.Enabled and ui.Name:lower():find("spawn") then
            ui.Enabled = false
        end
    end
end

local function bedCooldown()
    local now = math.floor(Clock.getServerTime())
    local last = tonumber(GameUtil.Data and GameUtil.Data.lastSpawnFromBed or 0) or 0
    return math.max(120 - (now - last), 0)
end

local function spawnAtBed()
    local cd = bedCooldown()
    if cd > 0 then
        warn(("[AutoSpawn] Bed cooldown: %ds left"):format(cd))
        return false
    end
    local ok, serverStamp = pcall(function()
        return SpawnFirst:InvokeServer(true)
    end)
    if ok and serverStamp then
        LocalPlayer:SetAttribute("hasSpawned", true)
        if GameUtil and GameUtil.Data then GameUtil.Data.lastSpawnFromBed = serverStamp end
        local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local Humanoid = Character:WaitForChild("Humanoid")
        CurrentCamera.CameraType = Enum.CameraType.Custom
        CurrentCamera.CameraSubject = Humanoid
        showGameplayUI()
        warn("[AutoSpawn] Spawned at Bed ✔")
        return true
    else
        warn("[AutoSpawn] Bed spawn rejected.")
        showGameplayUI()
        return false
    end
end



local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "JordanHub",
    SubTitle = "discord.gg/FDAhrbbT7F",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Fruit Farm", Icon = "" }),
    GoldEXP = Window:AddTab({ Title = "Gold/EXP Farm", Icon = "" }),
    PositionsTab = Window:AddTab({ Title = "Set Positions" }),
    Extra = Window:AddTab({ Title = "Extra", Icon = "" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

if (require == nil or hookmetamethod == nil or request == nil or Packets == nil or ItemData == nil or ItemIDS == nil or GameUtil == nil) then
    Fluent:Notify({
        Title = "JordanHub",
        Content = "Your executor is not supported lmao",
        Duration = 8
    })
    return
end

Tabs.Main:AddSection("Fruit Farm")

Tabs.Main:AddDropdown("Fruit", {
    Title = "Fruit",
    Values = fruitOptions,
    Default = fruit,
    Callback = function(value)
        fruit = value
        currentBushName = fruit .. " Bush"
        setBushVisibility(bushesVisible)
    end
})

Tabs.Main:AddToggle("AutoPlant", {
    Title = "Auto Plant",
    Default = false,
    Callback = function(value)
        plantEnabled = value
    end
})

Tabs.Main:AddToggle("AutoHarvest", {
    Title = "Auto Harvest",
    Default = false,
    Callback = function(value)
        harEnabled = value
    end
})

Tabs.Main:AddToggle("Tween", {
    Title = "Tween",
    Default = false,
    Callback = function(value)
        tweenEnabled = value
        if value and farm.node then
            tweenEnabled = false
            Notify("Fruit Farm", "Tween already enabled on a different farm")
        elseif tween2 then
            tween2:Cancel()
            tween2 = nil
        end
    end
})

Tabs.Main:AddToggle("AutoEat", {
    Title = "Auto Eat",
    Default = false,
    Callback = function(value)
        autoEat = value
        if value then
            autoEatSelectedFruit()
        end
    end
})

Tabs.Main:AddToggle("FruitJump", {
    Title = "Jump",
    Default = false,
    Callback = function(v)
        fruitJump(v)
    end
})

Tabs.Main:AddToggle("BushVisibility", {
    Title = "Hide the Selected Fruit Bushes",
    Default = true,
    Callback = function(v)
        setBushVisibility(v)
    end
})

Tabs.Main:AddToggle("Run", {
    Title = "Start",
    Default = false,
    Callback = function(value)
        fruitRun = value
        if value then
            if not tweenEnabled or not farm.node then
                farm.fruit = task.spawn(fruitFarm)
            else
                fruitRun = false
                Notify("Fruit Farm", "Tween already enabled on a different farm")
            end
        elseif farm.fruit and pcall(task.cancel, farm.fruit) then
            farm.fruit = nil
            if tween2 then
                tween2:Cancel()
                tween2 = nil
            end
        end
    end
})

Tabs.Main:AddSection("Fruit Tracker")

Tabs.Main:AddButton({
    Title = "Start Tracking",
    Callback = function()
        if not trackingActive then
            startAmounts = getFruitAmounts()
            trackingActive = true
            trackingStartTime = os.time()
            Notify("Started tracking.")
        else
            Notify("Tracking is already active!")
        end
    end
})

Tabs.Main:AddButton({
    Title = "Stop Tracking",
    Callback = function()
        if trackingActive then
            endAmounts = getFruitAmounts()
            trackingActive = false
            local endTime = os.time()
            local duration = os.difftime(endTime, trackingStartTime)
            local hours = math.floor(duration / 3600)
            local minutes = math.floor((duration % 3600) / 60)
            local durationStr = string.format("%d hours and %d minutes", hours, minutes)
            sendFruitAmount(startAmounts, endAmounts, durationStr)
            Notify("Stopped tracking. Results sent.")
        else
            Notify("Tracking is not active.")
        end
    end
})

Tabs.GoldEXP:AddSection("Farm Options")

Tabs.GoldEXP:AddSlider("Speed", {
    Title = "Speed",
    Min = 1,
    Max = 10,
    Default = tweenSpeed,
    Rounding = 1,
    Callback = function(value)
        tweenSpeed = value
        if tween and tween.PlaybackState == Enum.PlaybackState.Playing then
            tween = TweenService:Create(Root, TweenInfo.new((Root.Position - tweenInfo.CFrame.Position).Magnitude / (tweenInfo.MaxSpeed * value), Enum.EasingStyle.Linear), {CFrame = tweenInfo.CFrame})
            tween:Play()
        end
    end
})

Tabs.GoldEXP:AddToggle("CoinPress", {
    Title = "Coin Press",
    Default = false,
    Callback = function(value)
        pressEnabled = value
    end
})

Tabs.GoldEXP:AddToggle("FuelCampfires", {
    Title = "Fuel Campfires",
    Default = false,
    Callback = function(value)
        campEnabled = value
    end
})

Tabs.GoldEXP:AddToggle("PickupCoins", {
    Title = "Pickup Coins",
    Default = false,
    Callback = function(value)
        coinEnabled = value
    end
})

Tabs.GoldEXP:AddToggle("PickupGoldFromChest", {
    Title = "Pickup Gold from Chest",
    Default = false,
    Callback = function(value)
        pickUpGoldEnabled = value
    end
})

Tabs.GoldEXP:AddToggle("PickupEssences", {
    Title = "Pickup Essences",
    Default = false,
    Callback = function(value)
        essenceEnabled = value
    end
})

Tabs.GoldEXP:AddToggle("RemoveLag", {
    Title = "Remove lag",
    Default = false,
    Callback = function(value)
        deleteEnabled = value
        if value then
            stopAll({"monitorItems"})
            Threads.monitorItems = task.spawn(monitorItems)
        else
            stopAll({"monitorItems"})
        end
    end
})

Tabs.GoldEXP:AddSection("Gold/EXP Farm")

Tabs.GoldEXP:AddToggle("IceNodeFarm", {
    Title = "Ice Node Farm",
    Default = false,
    Callback = function(value)
        icenodeRun = value
        if value then
            if not farm.fruit or not tweenEnabled then
                local chunks = GetIceChunks()
                if #chunks ~= 0 then
                    chest = GetDeployable("Chest", 100)
                    if chest then
                        farm.node = task.spawn(IcenodeFarm)
                    else
                        icenodeRun = false
                        Notify("Gold Farm", "Couldn't find your chest")
                    end
                else
                    icenodeRun = false
                    Notify("Gold Farm", "You're far away from the farm area")
                end
            else
                icenodeRun = false
                Notify("Gold Farm", "Tween already enabled on a different farm")
            end
        elseif farm.node and pcall(task.cancel, farm.node) then
            farm.node = nil
            if tween then
                tween:Cancel()
                tween = nil
            end
            chest = nil
            Root.Anchored = false
        end
    end
})

Tabs.GoldEXP:AddToggle("CaveNodeFarm", {
    Title = "Cave Node Farm",
    Default = false,
    Callback = function(value)
        cavenodeRun = value
        if value then
            if not farm.fruit or not tweenEnabled then
                local chunks = GetCaveChunks()
                if #chunks ~= 0 then
                    chest = GetDeployable("Chest", 100)
                    if chest then
                        farm.node = task.spawn(CavenodeFarm)
                    else
                        cavenodeRun = false
                        Notify("Gold Farm", "Couldn't find your chest")
                    end
                else
                    cavenodeRun = false
                    Notify("Gold Farm", "You're far away from the farm area")
                end
            else
                cavenodeRun = false
                Notify("Gold Farm", "Tween already enabled on a different farm")
            end
        elseif farm.node and pcall(task.cancel, farm.node) then
            farm.node = nil
            if tween then
                tween:Cancel()
                tween = nil
            end
            chest = nil
            Root.Anchored = false
        end
    end
})

-- Tabs.GoldEXP:AddToggle("AutoFarmPumpkin", {
--     Title = "Auto Farm Huge Pumpkin (Will autofarm pumpkin and autohit huge pumpkin)",
--     Default = false,
--     Callback = function(value)
--         if value then
--             farm.pumpkin = task.spawn(autoFarmPumpkin)
--         elseif farm.pumpkin and pcall(task.cancel, farm.pumpkin) then
--             farm.pumpkin = nil
--         end
--     end
-- })

Tabs.GoldEXP:AddToggle("AntFarm", {
    Title = "Ant Farm",
    Default = false,
    Callback = function(value)
        antRun = value
        if value then
            chest = GetDeployable("Chest", 100)
            if chest then
                farm.ant = task.spawn(antFarm)
            else
                antRun = false
                Notify("Ant Farm", "Couldn't find your chest")
            end
        elseif pcall(task.cancel, farm.ant) then
            farm.ant = nil
            chest = nil
        end
    end
})

-- Tabs.GoldEXP:AddToggle("AutoFarmGoldPot", {
--     Title = "Auto Farm Gold Pot",
--     Default = false,
--     Callback = function(value)
--         if value then
--             farm.goldPot = task.spawn(autoFarmGoldPot)
--         else
--             if farm.goldPot then
--                 pcall(task.cancel, farm.goldPot)
--                 farm.goldPot = nil
--             end
--         end
--     end
-- })

-- Tabs.GoldEXP:AddToggle("ReplaceGoldPot", {
--     Title = "Replace pot that u broke",
--     Default = false,
--     Callback = function(value)
--         replacePotEnabled = value
--     end
-- })

-- Tabs.GoldEXP:AddToggle("PumpkinESP", {
--     Title = "ESP for Huge Pumpkin",
--     Default = false,
--     Callback = function(value)
--         espEnabled = value
--         toggleHugePumpkinESP()
--     end
-- })
-- Tabs.GoldEXP:AddToggle("CrewFarm", {
--     Title = "Crew Farm",
--     Default = false,
--     Callback = function(value)
--         crewRun = value
--         if value then
--             if not farm.crew or not tweenEnabled then
--                 farm.crew = task.spawn(crewFarm)
--             else
--                 crewRun = false
--                 Notify("Crewmate Farm", "Tween already enabled on a different farm")
--             end
--         elseif farm.crew and pcall(task.cancel, farm.crew) then
--             farm.crew = nil
--             if tween then
--                 tween:Cancel()
--                 tween = nil
--             end
--             Root.Anchored = false
--         end
--     end
-- })

Tabs.GoldEXP:AddSection("Waste Options")

Tabs.GoldEXP:AddSlider("WasteLeavesThreshold", {
    Title = "Waste Leaves Threshold",
    Min = 1,
    Max = 50,
    Default = wasteLeavesTo,
    Rounding = 1,
    Callback = function(value)
        wasteLeavesTo = value
    end
})

Tabs.GoldEXP:AddSlider("WasteWoodThreshold", {
    Title = "Waste Wood Threshold",
    Min = 1,
    Max = 60,
    Default = wasteWoodTo,
    Rounding = 1,
    Callback = function(value)
        wasteWoodTo = value
    end
})

Tabs.GoldEXP:AddSlider("WasteLogThreshold", {
    Title = "Waste Log Threshold",
    Min = 1,
    Max = 100,
    Default = wasteLogTo,
    Rounding = 1,
    Callback = function(value)
        wasteLogTo = value
    end
})

Tabs.GoldEXP:AddSlider("WasteFoodThreshold", {
    Title = "Waste Food Threshold",
    Min = 1,
    Max = 100,
    Default = wasteFoodTo,
    Rounding = 1,
    Callback = function(value)
        wasteFoodTo = value
    end
})

Tabs.GoldEXP:AddDropdown("SelectWasteFruit", {
    Title = "Select Waste Fruit",
    Values = fruitOptions,
    Default = fruit,
    Callback = function(value)
        selectedFruit = value
    end
})

Tabs.GoldEXP:AddSection("Waste")

Tabs.GoldEXP:AddToggle("AutoWasteLeaves", {
    Title = "Auto Waste Leaves",
    Default = autoleaves,
    Callback = function(value)
        autoleaves = value
        if autoleaves and not wasteLeavesLoopThread then
            wasteLeavesLoopThread = task.spawn(wasteLeavesLoop)
        elseif not autoleaves and wasteLeavesLoopThread then
            task.cancel(wasteLeavesLoopThread)
            wasteLeavesLoopThread = nil
        end
    end
})

Tabs.GoldEXP:AddToggle("AutoWasteWood", {
    Title = "Auto Waste Wood",
    Default = autowood,
    Callback = function(value)
        autowood = value
        if autowood and not wasteWoodLoopThread then
            wasteWoodLoopThread = task.spawn(wastewoodLoop)
        elseif not autowood and wasteWoodLoopThread then
            task.cancel(wasteWoodLoopThread)
            wasteWoodLoopThread = nil
        end
    end
})

Tabs.GoldEXP:AddToggle("AutoWasteLog", {
    Title = "Auto Waste Log",
    Default = autolog,
    Callback = function(value)
        autolog = value
        if autolog and not wasteLogLoopThread then
            wasteLogLoopThread = task.spawn(wastelogLoop)
        elseif not autolog and wasteLogLoopThread then
            task.cancel(wasteLogLoopThread)
            wasteLogLoopThread = nil
        end
    end
})

Tabs.GoldEXP:AddToggle("AutoWasteFood", {
    Title = "Auto Waste Food",
    Default = false,
    Callback = function(value)
        if value then
            wasteFoodLoopThread = task.spawn(wasteFoodLoop, selectedFruit)
        else
            if wasteFoodLoopThread then
                task.cancel(wasteFoodLoopThread)
                wasteFoodLoopThread = nil
            end
        end
    end
})

Tabs.PositionsTab:AddSection("PositionsTab")

Tabs.PositionsTab:AddButton({
    Title = "Add Current Position",
    Callback = function(value)
        addCurrentPosition()
    end
})

Tabs.PositionsTab:AddToggle("StartTweenToggle", {
    Title = "Start Tween",
    Default = false,
    Callback = function(value)
        tweeningEnabled = value
        if autoJumpEnabled or walkingEnabled then
            tweeningEnabled = false
            Notify("Auto Jump or Auto Walk enabled, turn them off to start tweening.")
        elseif value then
            tweeningEnabled = true
            task.spawn(startTweening)
        else
            if tweeningEnabled then
                Notify("Tweening stopped.")
            end
            tweeningEnabled = false
            if tweenConn then tweenConn:Disconnect(); tweenConn = nil end
            if tween then tween:Cancel(); tween = nil end
        end
    end
})

Tabs.PositionsTab:AddToggle("StartWalkingToggle", {
    Title = "Start Walk (Turn off camera lock)",
    Default = false,
    Callback = function(value)
        walkingEnabled = value
        if tweeningEnabled then
            walkingEnabled = false
            Notify("Tweening is enabled, disable it to use Start Walk.")
        elseif value then
            task.spawn(startWalking)
        else
            if walkingEnabled then
                Notify("Walking stopped.")
            end
            walkingEnabled = false
        end
    end
})

Tabs.PositionsTab:AddToggle("AutoJumpToggle", {
    Title = "Auto Jump",
    Default = false,
    Callback = function(value)
        autoJumpEnabled = value
        if tweeningEnabled then
            autoJumpEnabled = false
            Notify("Tweening is enabled, disable it to use Auto Jump.")
        elseif value then
            task.spawn(autoJump)
        end
    end
})

Tabs.PositionsTab:AddToggle("TPGoldToChest", {
    Title = "TP Gold to chest (stand near a chest and turn it on)",
    Default = false,
    Callback = function(value)
        TPGoldToChest = value
        if value then
            chest = GetDeployable("Chest", 100, false)
            if not chest then
                Notify("No chest found within 100 studs.")
                TPGoldToChest = false
            end
        end
    end
})

Tabs.PositionsTab:AddSection("Settings")

Tabs.PositionsTab:AddInput("FileNameInput", {
    Title = "Save/Load Filename",
    Placeholder = selectedFileName,
    Callback = function(value)
        selectedFileName = value
    end
})

Tabs.PositionsTab:AddButton({
    Title = "Save Positions to File",
    Callback = function(value)
        savePositionsTab()
    end
})

Tabs.PositionsTab:AddButton({
    Title = "Load Positions to Script",
    Callback = function(value)
        loadPositionsTab()
    end
})

Tabs.PositionsTab:AddButton({
    Title = "Load Default Config",
    Callback = function()
        selectedFileName = "MidasConfig.txt"
        loadPositionsTab()
    end
})

Tabs.PositionsTab:AddButton({
    Title = "Clear Position Set",
    Callback = function(value)
        clearPositionSet()
    end
})

Tabs.PositionsTab:AddSlider("SetSpeedSlider", {
    Title = "Set Speed",
    Min = 1,
    Max = 24,
    Default = walkSpeed,
    Rounding = 1,
    Callback = function(value)
        walkSpeed = value
    end
})

Tabs.Extra:AddSection("Auto Brew Potions")

Tabs.Extra:AddDropdown("PotionSelect", {
    Title = "Select Potion",
    Values = (function()
        local names = {}
        for k,_ in pairs(POTION_RECIPES) do table.insert(names, k) end
        table.sort(names)
        return names
    end)(),
    Default = selectedPotion,
    Callback = function(value)
        selectedPotion = value
        Notify("Auto Brew", "Selected: " .. value)
    end
})

Tabs.Extra:AddButton({
    Title = "Brew Potion Once",
    Callback = function()
        local success = brewPotionOnce(selectedPotion)
        if success then
            Notify("Auto Brew", "Brewed " .. selectedPotion .. " once.")
        else
            Notify("Auto Brew", "Failed to brew potion.")
        end
    end
})

Tabs.Extra:AddSection("Extras")


Tabs.Extra:AddToggle("AutoRebirth", {
    Title = "Auto Rebirth",
    Default = false,
    Callback = function(v)
        autoRebirthEnabled = v
    end
})

local function isOnSpawnScreen()
    local sg = PG:FindFirstChild("SpawnGui")
    return sg and sg.Enabled == true
end


Tabs.Extra:AddToggle("AutoBedSpawn", {
    Title = "Auto Bed Spawn",
    Default = false,
    Callback = function(v)
        autoBedSpawnEnabled = v
        if v then
            autoBedSpawnThread = task.spawn(function()
                local lastTry = 0
                while autoBedSpawnEnabled do
                    if isOnSpawnScreen() then
                        LocalPlayer:SetAttribute("hasSpawned", false)
                    end

                    local now = os.clock()
                    if (now - lastTry) >= 1 then
                        lastTry = now
                        local shouldTry = (not LocalPlayer:GetAttribute("hasSpawned")) and (bedCooldown() <= 0)

                        if shouldTry then
                            pcall(spawnAtBed)
                        end
                    end

                    task.wait(0.2)
                end
            end)
        else
            if autoBedSpawnThread then
                task.cancel(autoBedSpawnThread)
                autoBedSpawnThread = nil
            end
        end
    end
})


Tabs.Extra:AddToggle("PickupItems", {
    Title = "Pickup everything",
    Default = false,
    Callback = function(value)
        pickupAllItems = value
        if value then
            pickupAllItemsTask = task.spawn(pickupAllItem)
        else
            pcall(task.cancel, pickupAllItemsTask)
        end
    end
})

Tabs.Extra:AddToggle("PickupCoins", {
    Title = "Pickup Coins (stand next to coinpress)",
    Default = false,
    Callback = function(value)
        pickUpPressedGold = value
        if value then
            pickupCoinTask = task.spawn(pickupCoins)
        else
            pcall(task.cancel, pickupCoinTask)
        end
    end
})

Tabs.Extra:AddToggle("PressCoins", {
    Title = "Press Coins (stand next to coinpress)",
    Default = false,
    Callback = function(value)
        CoinpressEnabled = value
        if value then
            coinPressTask = task.spawn(pressCoins)
        else
            pcall(task.cancel, coinPressTask)
        end
    end
})

Tabs.Extra:AddToggle("PickupGold", {
    Title = "Pickup Gold (from floor)",
    Default = false,
    Callback = function(value)
        pickupGold = value
        if value then
            pickupGoldTask = task.spawn(pickupGolds)
        else
            pcall(task.cancel, pickupGoldTask)
        end
    end
})

Tabs.Extra:AddToggle("PickupRawGold", {
    Title = "Pickup Raw Gold (from floor)",
    Default = false,
    Callback = function(value)
        pickupRawGold = value
        if value then
            pickupRawGoldTask = task.spawn(pickupRawGolds)
        else
            pcall(task.cancel, pickupRawGoldTask)
        end
    end
})

Tabs.Extra:AddToggle("AutohittWithResources", {
    Title = "Autohit Closest Resource",
    Default = false,
    Callback = function(value)
        interactingWithResources = value
        if value then
            task.spawn(function()
                while interactingWithResources do
                    interactWithNearbyResources(100)
                    task.wait()
                end
            end)
        end
    end
})

Tabs.Extra:AddToggle("AutoFish", {
    Title = "Auto Fish",
    Default = false,
    Callback = function(v)
        autoFishEnabled = v
        if v then
            startAutoFishing()
        else
            if rodBubbleConn then rodBubbleConn:Disconnect(); rodBubbleConn = nil end
            if autoFishLoop then pcall(task.cancel, autoFishLoop); autoFishLoop = nil end
        end
    end
})

Tabs.Extra:AddInput("SetMaxFPS", {
    Title = "Set Max FPS",
    Placeholder = "Enter FPS",
    Default = "",
    Numeric = false,
    Callback = function(Text)
        local fps = tonumber(Text)
        if fps then
            setfpscap(fps)
        else
            Notify("Invalid fps value")
        end
    end
})

Tabs.Extra:AddToggle("AutoHeal", {
    Title = "Auto Heal",
    Default = false,
    Callback = function(value)
        autoHealEnabled = value
        if value then
            task.spawn(autoHeal)
        end
    end
})

Tabs.Extra:AddToggle("SpeedToggle", {
    Title = "Water Walker",
    Default = false,
    Callback = function(value)
        setWalkSpeed(value)
    end
})

Tabs.Extra:AddToggle("SlopeToggle", {
    Title = "Mountain Climber",
    Default = false,
    Callback = function(value)
        setMaxSlope(value)
    end
})

Tabs.Extra:AddToggle("NoClip", {
    Title = "NoClip Doors and old Board",
    Default = false,
    Callback = function(value)
        noclipDoors(value)
    end
})

-- Tabs.Extra:AddButton({
--     Title = "Get every skin in the game (cant equip)",
--     Callback = function(value)
--         applySkins(value)
--     end
-- })

Tabs.Extra:AddSection("Inventory Dropper")

local DropInvDD = Tabs.Extra:AddDropdown("InvDropSelect", {
    Title = "Select Item to Drop",
    Values = getInventoryNameList(),
    Default = nil,
    Callback = function(v)
        selectedDropItem = v
    end
})

Tabs.Extra:AddButton({
    Title = "Refresh Inventory List",
    Callback = function()
        local values = getInventoryNameList()
        if DropInvDD and DropInvDD.SetValues then
            DropInvDD:SetValues(values)
        else
            Notify("Dropper", "Could not refresh dropdown (SetValues missing).")
        end
    end
})

Tabs.Extra:AddToggle("AutoDropSelected", {
    Title = "Auto Drop Selected",
    Default = false,
    Callback = function(v)
        autoDropEnabled = v
        if v then
            if not selectedDropItem then
                autoDropEnabled = false
                Notify("Dropper", "Select an item first.")
                return
            end
            autoDropTask = task.spawn(autoDropLoop)
        else
            if autoDropTask then
                pcall(task.cancel, autoDropTask)
                autoDropTask = nil
            end
        end
    end
})

-- Tabs.Extra:AddToggle("TPDropToChestToggle", {
--     Title = "TP Dropped Item to Chest",
--     Default = false,
--     Callback = function(v)
--         TPDropToChest = v

--         if v then
--             chest = chest or GetDeployable("Chest", 100, false)
--             if not chest then
--                 TPDropToChest = false
--                 Notify("Dropper", "No chest found within 100 studs.")
--                 return
--             end
--         end
--     end
-- })

Tabs.Extra:AddSection("Make Farm (turn off cam lock, made by Zam)")

Tabs.Extra:AddButton({
    Title = "Create 8x8 Plant Boxes",
    Callback = function()
        make_8x8()
    end
})

Tabs.Extra:AddButton({
    Title = "Move Left",
    Callback = function()
        move_left()
    end
})

Tabs.Extra:AddButton({
    Title = "Move Right",
    Callback = function()
        move_right()
    end
})

Tabs.Extra:AddButton({
    Title = "Move Up",
    Callback = function()
        move_up()
    end
})

Tabs.Extra:AddButton({
    Title = "Move Down",
    Callback = function()
        move_down()
    end
})

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})

InterfaceManager:SetFolder("FluentScriptHub")
SaveManager:SetFolder("FluentScriptHub/specific-game")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)

Fluent:Notify({
    Title = "Fluent",
    Content = "The script has been loaded.",
    Duration = 8
})

SaveManager:LoadAutoloadConfig()

if Conns.itemsChildAdded then Conns.itemsChildAdded:Disconnect() end
Conns.itemsChildAdded = Workspace.Items.ChildAdded:Connect(function(item)
    if (icenodeRun or cavenodeRun or antRun or crewRun or TPGoldToChest) and item.Name == "Raw Gold" and chest then
        task.spawn(function()
            while item and item.Parent == workspace.Items do
                local id = item:GetAttribute("EntityID")
                if id then
                    Packets.ForceInteract.send(id)
                    pcall(function() item:PivotTo(chest:GetPivot()) end)
                    Packets.ForceInteract.send()
                end
                task.wait()
            end
        end)
        return
    end
    -- if TPDropToChest and autoDropEnabled and chest and selectedDropItem and item.Name == selectedDropItem then
    --     task.spawn(function()
    --         local t0 = os.clock()
    --         local id = item:GetAttribute("EntityID")
    --         while item.Parent == workspace.Items and not id and (os.clock() - t0) < 3 do
    --             task.wait()
    --             id = item:GetAttribute("EntityID")
    --         end
    --         if not id then return end

    --         while TPDropToChest and autoDropEnabled and chest and item and item.Parent == workspace.Items do
    --             Packets.ForceInteract.send(id)
    --             pcall(function() item:PivotTo(chest:GetPivot()) end)
    --             Packets.ForceInteract.send()
    --             task.wait()
    --         end
    --     end)
    --     return
    -- end

    if item.Name == "Coin2" and coinEnabled then
        task.spawn(function()
            local t0 = os.clock()
            local id = item:GetAttribute("EntityID")
            while item.Parent == workspace.Items and not id and os.clock() - t0 < 3 do
                task.wait()
                id = item:GetAttribute("EntityID")
            end
            if id then
                for i = 1, 8 do
                    if not item or item.Parent ~= workspace.Items then break end
                    Packets.Pickup.send(id)
                    task.wait(0.12)
                end
            end
        end)
        return
    end

    if item.Name == "Essence" and essenceEnabled then
        task.spawn(function()
            local t0 = os.clock()
            local id = item:GetAttribute("EntityID")
            while item.Parent == workspace.Items and not id and os.clock() - t0 < 3 do
                task.wait()
                id = item:GetAttribute("EntityID")
            end
            if id then
                for i = 1, 8 do
                    if not item or item.Parent ~= workspace.Items then break end
                    Packets.Pickup.send(id)
                    task.wait(0.12)
                end
            end
        end)
        return
    end

    if pickupAllItems then
        task.spawn(function()
            local t0 = os.clock()
            local id = item:GetAttribute("EntityID")
            while item.Parent == workspace.Items and not id and os.clock() - t0 < 3 do
                task.wait()
                id = item:GetAttribute("EntityID")
            end
            if id then
                for i = 1, 8 do
                    if not item or item.Parent ~= workspace.Items then break end
                    Packets.Pickup.send(id)
                    task.wait(0.12)
                end
            end
        end)
        return
    end

    if item.Name == "Gold" and pickupGold then
        task.spawn(function()
            local t0 = os.clock()
            local id = item:GetAttribute("EntityID")
            while item.Parent == workspace.Items and not id and os.clock() - t0 < 3 do
                task.wait()
                id = item:GetAttribute("EntityID")
            end
            if id then
                for i = 1, 8 do
                    if not item or item.Parent ~= workspace.Items then break end
                    Packets.Pickup.send(id)
                    task.wait(0.12)
                end
            end
        end)
        return
    end

    if item.Name == "Raw Gold" and pickupRawGold then
        task.spawn(function()
            local t0 = os.clock()
            local id = item:GetAttribute("EntityID")
            while item.Parent == workspace.Items and not id and os.clock() - t0 < 3 do
                task.wait()
                id = item:GetAttribute("EntityID")
            end
            if id then
                for i = 1, 8 do
                    if not item or item.Parent ~= workspace.Items then break end
                    Packets.Pickup.send(id)
                    task.wait(0.12)
                end
            end
        end)
        return
    end

    local myGen = autoBrewGen
    local name = item.Name
    if not autoBrewQueue or not autoBrewQueue[name] or #autoBrewQueue[name] == 0 then return end
    if myGen ~= autoBrewGen then return end

    local target = table.remove(autoBrewQueue[name], 1)
    if not target or not target.Parent then return end

    local id = item:GetAttribute("EntityID")
    if not id then return end

    if myGen == autoBrewGen and item and item.Parent == workspace.Items and target and target.Parent then
        for tries = 1, 6 do
            if myGen ~= autoBrewGen then return end
            if not item or item.Parent ~= workspace.Items then break end
            if not target or not target.Parent then break end

            Packets.ForceInteract.send(id)
            local ok = pcall(function()
                local dropPos = target:GetPivot().Position + Vector3.new(0, 5, 0)
                item:PivotTo(CFrame.new(dropPos))
            end)
            Packets.ForceInteract.send()

            if not ok then break end
            task.wait()
        end
    end

    if autoBrewInFlight and autoBrewInFlight[name] then
        autoBrewInFlight[name] = math.max(0, autoBrewInFlight[name] - 1)
    end
end)

Workspace.ChildAdded:Connect(function(child)
    if child:IsA("Model") and child.Name == currentBushName then
        for _, part in child:GetDescendants() do
            if part:IsA("BasePart") then
                part.Transparency = bushesVisible and 0 or 1
                part.CanCollide = true
            end
        end
        child.DescendantAdded:Connect(function(part)
            if part:IsA("BasePart") then
                part.Transparency = bushesVisible and 0 or 1
                part.CanCollide = true
            end
        end)
    end
end)

Workspace.Deployables.ChildRemoved:Connect(function(deployable)
    if deployable == chest then
        icenodeRun = false
        cavenodeRun = false
    end
end)

local GC = getconnections or get_signal_cons
if GC then
    for i,v in pairs(GC(Players.LocalPlayer.Idled)) do
        if v["Disable"] then
            v["Disable"](v)
        elseif v["Disconnect"] then
            v["Disconnect"](v)
        end
    end
else
    local VirtualUser = cloneref(game:GetService("VirtualUser"))
    Players.LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end
