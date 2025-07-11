setthreadidentity(5)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local events = ReplicatedStorage:FindFirstChild("Events")
if events then
    local sendEmbed = events:FindFirstChild("SendEmbed")
    if sendEmbed and sendEmbed:IsA("RemoteEvent") then
    local originalFireServer = sendEmbed.FireServer
    hookfunction(originalFireServer, function(...) end)
    end
end

local PathfindingService = game:GetService("PathfindingService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Items = Workspace:FindFirstChild("Items")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CurrentCamera = workspace.CurrentCamera
local LocalPlayerMouse = Players.LocalPlayer:GetMouse()

local GameUtil = require(ReplicatedStorage.Modules.GameUtil)
local ItemData = require(ReplicatedStorage.Modules.ItemData)
local ItemIDS = require(ReplicatedStorage.Modules.ItemIDS)
local Packets = require(ReplicatedStorage.Modules.Packets)
local SkinHandler = require(game:GetService("Players").LocalPlayer.PlayerScripts.src.Game.SkinHandler)

local Character = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
local LocalPlayer = game.Players.LocalPlayer
local Humanoid = Character:WaitForChild("Humanoid")
local Root = Character:WaitForChild("HumanoidRootPart")

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

local tween2
local autoHealEnabled
local pressEnabled
local campEnabled
local coinEnabled
local essenceEnabled
local pickUpGoldEnabled

local pickUpPressedGold
local CoinpressEnabled
local pickupGold

local plantEnabled
local harEnabled
local tweenEnabled

local tween
local tweenInfo
local chest

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
local replacePotEnabled = false

local defaultConfigUrl = "https://raw.githubusercontent.com/Tion-D/booga-config-yes/refs/heads/main/MidasConfig.txt"
local defaultConfigFile = "MidasConfig.txt"
if not isfile(defaultConfigFile) then
    local configContent = game:HttpGet(defaultConfigUrl)
    writefile(defaultConfigFile, configContent)
end

local make_8x8 = function()
    if not character then
        character = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
    end

    local start = character:GetPivot() * CFrame.new(0, -3, 0)

    for i = -4, 4 do
        for n = -4, 4 do
            local pos = start * CFrame.new(6.3 * i, 0, 6.3 * n)

            Packets.PlaceStructure.send({["buildingName"] = "Plant Box", ["vec"] = pos.Position, ["yrot"] = 90, ["isMobile"] = false})
            task.wait(0.45)
        end
    end
end

local move_left = function()
    if moving then return end
    moving = true

    if not character then
        character = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
    end

    local hum = character:FindFirstChildOfClass("Humanoid")
    hum:MoveTo((character:GetPivot() * CFrame.new(-(6.4 * 9), -3, 0)).Position)
    hum.MoveToFinished:Wait()

    moving = false
end

local move_right = function()
    if moving then return end
    moving = true

    if not character then
        character = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
    end

    local hum = character:FindFirstChildOfClass("Humanoid")
    hum:MoveTo((character:GetPivot() * CFrame.new((6.4 * 9), -3, 0)).Position)
    hum.MoveToFinished:Wait()

    moving = false
end

local move_up = function()
    if moving then return end
    moving = true

    if not character then
        character = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
    end

    local hum = character:FindFirstChildOfClass("Humanoid")
    hum:MoveTo((character:GetPivot() * CFrame.new(0, -3, -(6.4 * 9))).Position)
    hum.MoveToFinished:Wait()

    moving = false
end

local move_down = function()
    if moving then return end
    moving = true

    if not character then
        character = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
    end

    local hum = character:FindFirstChildOfClass("Humanoid")
    hum:MoveTo((character:GetPivot() * CFrame.new(0, -3, (6.4 * 9))).Position)
    hum:MoveTo(character:GetPivot().Position + Vector3.new(0, -3, 6.4 * 9))
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
    Fluent:Notify({
        Title = title,
        Content = content,
        Duration = 5
    })
end

local function findFruitIndex(fruitName)
    for index, data in next, GameUtil.GetData().inventory do
        if data.name == fruitName then
            return index
        end
    end
    return nil
end

local function autoEatSelectedFruit()
    local function autoEatLoop()
        while true do
            if fruit then
                local fruitIndex = findFruitIndex(fruit)
                if fruitIndex then
                    Packets.UseBagItem.send(fruitIndex)
                else
                    Notify("Selected fruit not found in inventory:", fruit)
                end
            else
                Notify("No fruit selected for auto-eat.")
            end
            task.wait(10)
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

local __newindex
__newindex = hookmetamethod(game, '__newindex', function(self, index, value)
    local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if not checkcaller() then
        if WalkSpeedEnabled and humanoid and self == humanoid and index == 'WalkSpeed' then
            value = WalkSpeedValue
        end
    end
    return __newindex(self, index, value)
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
    for x, v in next, GameUtil.Data.inventory do
        if v.name == item then
            return true
        end
    end
end

local function GetQuantity(name)
    for x,v in next, GameUtil.Data.inventory do
        if v.name == name then
            return v.quantity, x
        end
    end
end

local function GetFuel()
    for x, v in next, GameUtil.Data.inventory do
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
    if Items then
        for _, item in ipairs(Items:GetChildren()) do
            if item.Name ~= "Raw Gold" and item.Name ~= "Gold" and item.Name ~= "Essence" and item.Name ~= "Coin2" then
                item:Destroy() 
            end
        end
    end
end

local function monitorItems()
    while true do
        if deleteEnabled then
            deleteItems()
        end
        task.wait(0.2)
    end
end

local function GetDeployable(name, range, multiple)
    local deployable = multiple and {}
    local range = range or math.huge
    for x, v in next, Workspace.Deployables:GetChildren() do
        if v.Name == name then
            local Magnitude = (Root.Position - v:GetPivot().Position).Magnitude
            if Magnitude < range then
                if multiple then
                    table.insert(deployable, {deployable = v, range = Magnitude})
                else
                    deployable = v
                    range = Magnitude
                end
            end
        end
    end
    return deployable
end

local function findBloodfruitIndex()
    for index, data in next, GameUtil.GetData().inventory do
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
    if not critters then
        return {}
    end

    local crewmates = {}
    for _, v in pairs(critters:GetChildren()) do
        if v.Name == "Crewmate" or v.Name == "Captain" and v:IsA("Model") and v:FindFirstChild("HumanoidRootPart") then
            table.insert(crewmates, v)
        end
    end
    return crewmates
end

local function pressCoins()
    if CoinpressEnabled then
        local goldAmt = GetQuantity("Gold")
        if goldAmt > 0 then
            local deployable = GetDeployable("Coin Press", 25)
            if deployable then
                for x = 1, goldAmt do
                    Packets.InteractStructure.send({entityID = deployable:GetAttribute("EntityID"), itemID = ItemIDS["Gold"]})
                    task.wait(0.0005)
                end
            end
        end
    end
end

local function pickupCoins()
    if pickUpPressedGold then
        local Items = Workspace:FindFirstChild("Items")
        if Items then
            for _, item in ipairs(Items:GetChildren()) do
                if item.Name == "Coin2" then
                    Packets.Pickup.send(item:GetAttribute("EntityID"))
                end
            end
        end
    end
end

local function pickupGolds()
    while pickupGold do
        local Items = Workspace:FindFirstChild("Items")
        if Items then
            for _, item in ipairs(Items:GetChildren()) do
                if item.Name == "Gold" then
                    Packets.Pickup.send(item:GetAttribute("EntityID"))
                end
            end
        end
        task.wait(0.5)
    end
end

local function pickupRawGolds()
    while pickupRawGold do
        local Items = Workspace:FindFirstChild("Items")
        if Items then
            for _, item in ipairs(Items:GetChildren()) do
                if item.Name == "Raw Gold" then
                    Packets.Pickup.send(item:GetAttribute("EntityID"))
                end
            end
        end
        task.wait(0.5)
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

            if campEnabled then
                for x, v in next, GetDeployable("Campfire", 25, true) do
                    if v.deployable.Board.Billboard.Backdrop.TextLabel.Text <= "10" then
                        local itemID = GetFuel()
                        if itemID then
                            Packets.InteractStructure.send({
                                entityID = v.deployable:GetAttribute("EntityID"),
                                itemID = itemID
                            })
                        end
                    end
                end
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
                        local entity = v.Parent and v or node and node.Parent and node
                        if entity then
                            --sendEntitiesBuffer({entity})
                            Packets.SwingTool.send({node:GetAttribute("EntityID")})
                            task.wait(1 / 3)
                        end
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

            if campEnabled then
                for x, v in next, GetDeployable("Campfire", 25, true) do
                    if v.deployable.Board.Billboard.Backdrop.TextLabel.Text <= "10" then
                        local itemID = GetFuel()
                        if itemID then
                            Packets.InteractStructure.send({entityID = v.deployable:GetAttribute("EntityID"), itemID = itemID})
                        end
                    end
                end
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
        for x,v in next, Workspace:GetPartBoundsInRadius(Root.Position, 25) do
            if v.Name == "HumanoidRootPart" and v.Parent.Name == "Queen Ant's Servant" then
                Packets.SwingTool.send({v.Parent:GetAttribute("EntityID")})
            end
        end
        if chest then
            if campEnabled then
                for x, v in next, GetDeployable("Campfire", 25, true) do
                    if v.deployable.Board.Billboard.Backdrop.TextLabel.Text <= "10" then
                        local itemID = GetFuel()
                        if itemID then
                            Packets.InteractStructure.send({entityID = v.deployable:GetAttribute("EntityID"), itemID = itemID})
                        end
                    end
                end
            end

            if pressEnabled then
                if chest.Contents:FindFirstChild("Gold") then
                    for x,v in next, chest.Contents:GetChildren() do
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
                        for x = 1, quantity do
                            Packets.InteractStructure.send({entityID = entityID, itemID = itemID})
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

local function fruitFarm()
    while task.wait() do
        if Root then
            local deployable = GetDeployable("Plant Box", 100, true)
            table.sort(deployable, function(a, b)
                return a.range < b.range
            end)

            if tweenEnabled and tweenEnabled then
                for x, v in next, deployable do
                    if not v.deployable:FindFirstChild("Seed") then
                        tween2 = TweenService:Create(Root, TweenInfo.new(v.range / 20, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {CFrame = v.deployable:GetPivot() * CFrame.new(0, 5, 0)})
                        tween2:Play()
                        break
                    end
                end
            end

            if harEnabled and harEnabled then
                for m, n in next, Workspace:GetChildren() do
                    local item = ItemData[n.Name]
                    if item and item.itemType == "crop" and (Root.Position - n:GetPivot().Position).Magnitude < 25 then
                        Packets.Pickup.send(n:GetAttribute("EntityID"))
                    end
                end
            end

            if plantEnabled and plantEnabled then
                for x, v in next, deployable do
                    if v.range < 25 then
                        if not v.deployable:FindFirstChild("Seed") and HasItem(fruit) then
                            Packets.InteractStructure.send({entityID = v.deployable:GetAttribute("EntityID"), itemID = ItemIDS[fruit]})
                            --task.wait(0.023333333)
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

    while walkingEnabled do
        for _, pos in ipairs(positionList) do
            if not walkingEnabled then break end

            if pos and pos.X and pos.Y and pos.Z then
                local targetPos = Vector3.new(pos.X, pos.Y, pos.Z)
                Humanoid:MoveTo(targetPos)

                local moveFinished = false
                local conn
                conn = Humanoid.MoveToFinished:Connect(function(reached)
                    moveFinished = true
                    conn:Disconnect()
                end)

                local startTime = tick()
                -- Poll until the movement is finished or 15 seconds elapse.
                while not moveFinished and tick() - startTime < 15 do
                    task.wait(0.1)
                end

                if not moveFinished then
                    Notify("Walking to position taking too long; restarting move for this transition.")
                    -- Restart the movement for the current target.
                    Humanoid:MoveTo(targetPos)
                    Humanoid.MoveToFinished:Wait()  -- Wait until this restarted movement finishes.
                end

                if not walkingEnabled then break end
                task.wait(0.1)
            else
                Notify("Invalid position data.")
            end
        end

        -- Additional logic for camp, pickup, press remains as needed...
        if campEnabled and chest.Contents:FindFirstChild("Gold") then
            for x, v in next, GetDeployable("Campfire", 25, true) do
                if v.deployable.Board.Billboard.Backdrop.TextLabel.Text <= "10" then
                    local itemID = GetFuel()
                    if itemID then
                        Packets.InteractStructure.send({
                            entityID = v.deployable:GetAttribute("EntityID"),
                            itemID = itemID
                        })
                    end
                end
            end
        end

        if pickUpGoldEnabled and chest.Contents:FindFirstChild("Gold") then
            for x, v in next, chest.Contents:GetChildren() do
                if v.Name == "Gold" then
                    Packets.Pickup.send(v:GetAttribute("EntityID"))
                end
            end
        end

        if pressEnabled and chest.Contents:FindFirstChild("Gold") then
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

    while tweeningEnabled do
        for _, pos in ipairs(positionList) do
            if not tweeningEnabled then break end

            if pos and pos.X and pos.Y and pos.Z then
                local targetPos = Vector3.new(pos.X, pos.Y, pos.Z)
                local duration = (Root.Position - targetPos).Magnitude / walkSpeed
                local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
                local tween = TweenService:Create(Root, tweenInfo, {CFrame = CFrame.new(targetPos)})

                local tweenFinished = false
                local tweenConn = tween.Completed:Connect(function()
                    tweenFinished = true
                    tweenConn:Disconnect()
                end)

                tween:Play()
                local startTime = tick()

                while not tweenFinished and tick() - startTime < 15 do
                    task.wait(0.1)
                end

                if not tweenFinished then
                    Notify("Tween from current position to target taking too long; restarting tween for this transition.")
                    tween:Cancel()
                    
                    tween = TweenService:Create(Root, tweenInfo, {CFrame = CFrame.new(targetPos)})
                    tween:Play()
                    tween.Completed:Wait()
                end

                if not tweeningEnabled then break end
                task.wait(0.1)
            else
                Notify("Invalid position data.")
            end
        end

        if campEnabled and chest.Contents:FindFirstChild("Gold") then
            for x, v in next, GetDeployable("Campfire", 25, true) do
                if v.deployable.Board.Billboard.Backdrop.TextLabel.Text <= "10" then
                    local itemID = GetFuel()
                    if itemID then
                        Packets.InteractStructure.send({
                            entityID = v.deployable:GetAttribute("EntityID"),
                            itemID = itemID
                        })
                    end
                end
            end
        end

        if pickUpGoldEnabled and chest.Contents:FindFirstChild("Gold") then
            for x, v in next, chest.Contents:GetChildren() do
                if v.Name == "Gold" then
                    Packets.Pickup.send(v:GetAttribute("EntityID"))
                end
            end
        end

        if pressEnabled and chest.Contents:FindFirstChild("Gold") then
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
    blob.Anchored = true
    blob.CanCollide = false
    blob.Position = position
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
end

local function loadPositionsTab()
    if not isfile(selectedFileName) then
        Notify("Could not find the file: " .. selectedFileName)
        return
    end

    local contents = readfile(selectedFileName)
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
    Packets.RodBubble.listen(function(data)
        if data.should_bubble then
            Packets.RodEnd.send()
        end
    end)

    task.spawn(function()
        while autoFishEnabled do
            if not Players.LocalPlayer:GetAttribute("Fishing") then
                local calculated = Workspace.CurrentCamera:ScreenPointToRay(LocalPlayerMouse.X, LocalPlayerMouse.Y)
                Packets.RodSwing.send({
                    origin = calculated.Origin,
                    direction = calculated.Direction * 2000
                })
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


local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "MidasHub",
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
        Title = "MidasHub",
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
            task.spawn(monitorItems)
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

Tabs.GoldEXP:AddToggle("AutoFarmGoldPot", {
    Title = "Auto Farm Gold Pot",
    Default = false,
    Callback = function(value)
        if value then
            farm.goldPot = task.spawn(autoFarmGoldPot)
        else
            if farm.goldPot then
                pcall(task.cancel, farm.goldPot)
                farm.goldPot = nil
            end
        end
    end
})

Tabs.GoldEXP:AddToggle("ReplaceGoldPot", {
    Title = "Replace pot that u broke",
    Default = false,
    Callback = function(value)
        replacePotEnabled = value
    end
})

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

Tabs.GoldEXP:AddToggle("AutoWasteWood", {
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

Tabs.PositionsTab.AddSection("PositionsTab")

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

        if TPGoldToChest then
            chest = GetDeployable("Chest", 100, false)
            if not nearestChest then
                Library:Notify("No chest found within 100 studs.", 3, Color3.fromRGB(0, 255, 0))
                TPGoldToChest = false
            end
        else
            nearestChest = nil
        end
    end
})

Tabs.PositionsTab.AddSection("Settings")

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

Tabs.PositionsTab:AddSlider("TweenSpeedSlider", {
    Title = "Tween Speed",
    Min = 1,
    Max = 24,
    Default = walkSpeed,
    Rounding = 1,
    Callback = function(value)
        walkSpeed = value
    end
})

Tabs.Extra:AddSection("Extra")

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
                    interactWithNearbyResources(25)
                    task.wait()
                end
            end)
        end
    end
})


Tabs.Extra:AddToggle("AutoFish", { 
    Title = "Auto Fish", 
    Default = false,
    Callback = function(value)
        autoFishEnabled = value
        if autoFishEnabled then
            task.spawn(startAutoFishing)
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
    Title = "NoClip Doors",
    Default = false,
    Callback = function(value)
        noclipDoors(value)
    end
})

Tabs.Extra:AddButton({
    Title = "Get every skin in the game (cant equip)",
    Callback = function(value)
        applySkins(value)
    end
})

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

Workspace.Items.ChildAdded:Connect(function(item)
    if icenodeRun or cavenodeRun or antRun or crewRun or TPGoldToChest then
        if item.Name == "Raw Gold" and chest then
            repeat
                Packets.ForceInteract.send(item:GetAttribute("EntityID"))
                item:PivotTo(chest:GetPivot())
                Packets.ForceInteract.send()
                task.wait()
            until not item or item.Parent ~= workspace.Items
        end
    end
    if item.Name == "Coin2" and coinEnabled then
        repeat
            Packets.Pickup.send(item:GetAttribute("EntityID"))
        until not item or item.Parent ~= workspace.Items
    elseif item.Name == "Essence" and essenceEnabled then
        repeat
            Packets.Pickup.send(item:GetAttribute("EntityID"))
        until not item or item.Parent ~= workspace.Items
    end
end)

Workspace.Deployables.ChildRemoved:Connect(function(deployable)
    if deployable == chest then
        icenodeRun = false
        cavenodeRun = false
    end
end)
