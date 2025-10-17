local WEBHOOK_URL = "https://discord.com/api/webhooks/1427511460744925246/fV-N6lLwFgkveffOUI7hIcMN8Wk1Yahh0T_aGhnI9HTBGWNbwbWLfC8aGKXSjsTh87jC"
local AUTO_HOP = true
local HOP_INTERVAL = 5
local MAX_TRIES_PER_SERVER = 1
local CACHE_FILE = "server_cache.json"
local CACHE_TTL = 20 * 60
local ENFORCE_PROXIMITY = true
local REQUIRED_DIST = 20
local MAX_REQ_TRIES = 5
local BETWEEN_REQ_WAIT = 0.25
local STOCK_TIMEOUT = 12
local scanBusy = false
local lastFoundTrader = false
local MAX_SERVER_PLAYERS = 50
local webhookSentServers = {}

local Players2 = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Http = game:GetService("HttpService")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LP = Players2.LocalPlayer

local Events = RS:WaitForChild("Events")
local RefreshServers = Events:WaitForChild("RefreshServers")
local TeleportEvent = Events:WaitForChild("Teleport")
local PG = LP:WaitForChild("PlayerGui")
local SpawnFirst = Events:WaitForChild("SpawnFirst")

local Packets = require(RS.Modules.Packets)
local traderData = require(RS.Modules.traderData)
local Clock = require(RS.Modules.Clock)
local GameUtil = require(RS.Modules.GameUtil)

local ServerRegionValue = RS:FindFirstChild("BOOLET") and RS.BOOLET:FindFirstChild("ServerRegion")

local MainGui = LP:WaitForChild("PlayerGui"):WaitForChild("MainGui", 5)
local traderPanel = MainGui and MainGui:FindFirstChild("Panels")
traderPanel = traderPanel and traderPanel:FindFirstChild("wanderingTrader")
local CurrentCamera = workspace.CurrentCamera
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    CurrentCamera = workspace.CurrentCamera
end)

local TeleportService = game:GetService("TeleportService")
local failedJobIds, lastTeleportFailed = {}, false
TeleportService.TeleportInitFailed:Connect(function(_, result, msg)
    warn("[Hop] Teleport failed:", result, msg)
    lastTeleportFailed = true
end)


local AUTO_SPAWN_ENABLED = true
local SPAWN_FROM_BED = false
local SPAWN_DELAY = 0.5

local function waitForGameLoad()
    local PlayerGui = LP:WaitForChild("PlayerGui")
    local SpawnGui = PlayerGui:WaitForChild("SpawnGui", 10)
    if not SpawnGui then
        warn("SpawnGui not found!")
        return false
    end
    local Events = RS:WaitForChild("Events", 10)
    if not Events then
        warn("Events folder not found!")
        return false
    end
    local SpawnFirst = Events:WaitForChild("SpawnFirst", 10)
    if not SpawnFirst then
        warn("SpawnFirst event not found!")
        return false
    end
    return true, SpawnGui, SpawnFirst
end

local function autoSpawn()
    print("[Auto Spawn] Initializing...")
    if LP:GetAttribute("hasSpawned") then
        print("[Auto Spawn] Already spawned!")
        return
    end

    local success, SpawnGui, SpawnFirst = waitForGameLoad()
    if not success then
        warn("[Auto Spawn] Failed to load game elements!")
        return
    end

    task.wait(SPAWN_DELAY)

    if LP:GetAttribute("hasSpawned") then
        print("[Auto Spawn] Already spawned during delay!")
        return
    end

    print("[Auto Spawn] Attempting to spawn...")
    local spawnSuccess, spawnResult = pcall(function()
        return SpawnFirst:InvokeServer(SPAWN_FROM_BED)
    end)

    if spawnSuccess and spawnResult then
        print("[Auto Spawn] Successfully spawned!")
        LP:SetAttribute("hasSpawned", true)

        local PlayerGui = LP:WaitForChild("PlayerGui")
        local Camera = workspace.CurrentCamera

        if SpawnGui then SpawnGui.Enabled = false end

        local MainGui = PlayerGui:FindFirstChild("MainGui")
        if MainGui then MainGui.Enabled = true end

        local Topbar = PlayerGui:FindFirstChild("Topbar")
        if Topbar then Topbar.Enabled = true end

        local character = LP.Character
        if character then
            local humanoid = character:WaitForChild("Humanoid", 5)
            if humanoid then
                Camera.CameraType = Enum.CameraType.Custom
                Camera.CameraSubject = humanoid
                print("[Auto Spawn] Camera fixed!")
            end
        end

        print("[Auto Spawn] GUIs updated!")
    else
        warn("[Auto Spawn] Failed to spawn:", spawnResult)
    end
end

local function onCharacterAdded(character)
    task.wait(0.5)
    if AUTO_SPAWN_ENABLED and not LP:GetAttribute("hasSpawned") then
        autoSpawn()
    end
end

if AUTO_SPAWN_ENABLED then
    print("[Auto Spawn] Script loaded! Auto-spawn is ENABLED")
    LP.CharacterAdded:Connect(onCharacterAdded)
    if LP.Character then
        onCharacterAdded(LP.Character)
    else
        task.wait(1)
        autoSpawn()
    end
else
    print("[Auto Spawn] Script loaded but auto-spawn is DISABLED")
end


local function waitForGameLoaded2()
    local ok = RS:FindFirstChild("GameLoaded")
    if ok then
        if ok:IsA("BindableEvent") then
            ok.Event:Wait()
        else
            repeat task.wait() until ok.Parent
        end
    else
        ok = RS:WaitForChild("GameLoaded", 15)
        if ok and ok:IsA("BindableEvent") then
            ok.Event:Wait()
        end
    end
end
waitForGameLoaded2()

local function setCameraToHumanoid(hum)
    local deadline = os.clock() + 3
    while os.clock() < deadline do
        if CurrentCamera and hum then
            CurrentCamera.CameraType = Enum.CameraType.Custom
            CurrentCamera.CameraSubject = hum
            return true
        end
        RunService.Heartbeat:Wait()
    end
    return false
end

local WalkSpeedEnabled, WalkSpeedValue, originalWalkSpeed = true, 16, nil
local maxSlopeEnabled, SlopeValue = true, 89
local function setMaxSlope(enabled)
    maxSlopeEnabled = enabled
    if LP.Character and LP.Character:FindFirstChild("Humanoid") then
        if maxSlopeEnabled then
            LP.Character.Humanoid.MaxSlopeAngle = 89
        else
            LP.Character.Humanoid.MaxSlopeAngle = 45
        end
    end
end
local function setWalkSpeed(enabled)
    WalkSpeedEnabled = enabled
    if LP.Character then
        local humanoid = LP.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            if not originalWalkSpeed then originalWalkSpeed = humanoid.WalkSpeed end
            humanoid.WalkSpeed = enabled and WalkSpeedValue or originalWalkSpeed
        end
    end
end

local oldNewIndex
oldNewIndex = hookmetamethod(game, "__newindex", function(self, idx, val)
    if not checkcaller() then
        local char = LP.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if WalkSpeedEnabled and hum and self == hum and idx == "WalkSpeed" then
            val = WalkSpeedValue
        end
    end
    return oldNewIndex(self, idx, val)
end)

local function hardHideSpawnGuiFor(ms)
    local SpawnGui = PG:FindFirstChild("SpawnGui")
    local MainGui = PG:FindFirstChild("MainGui")
    local Topbar = PG:FindFirstChild("Topbar")
    if MainGui then MainGui.Enabled = true end
    if Topbar then Topbar.Enabled  = true end
    if SpawnGui then
        SpawnGui.Enabled = false
        SpawnGui:GetPropertyChangedSignal("Enabled"):Connect(function()
            if SpawnGui.Enabled then SpawnGui.Enabled = false end
        end)
    end
    local t0 = os.clock()
    while (os.clock() - t0) < (ms/1000) do
        if MainGui and not MainGui.Enabled then MainGui.Enabled = true end
        if Topbar  and not Topbar.Enabled  then Topbar.Enabled  = true end
        if SpawnGui and SpawnGui.Enabled then SpawnGui.Enabled = false end
        RunService.RenderStepped:Wait()
    end
end

local function safefile(name) return pcall(function() return isfile(name) end) and isfile(name) end
local function loadCache()
    if safefile(CACHE_FILE) then
        local ok, data = pcall(function() return Http:JSONDecode(readfile(CACHE_FILE)) end)
        if ok and typeof(data)=="table" and data.visited and data.started then return data end
    end
    return { visited = {}, started = os.clock() }
end
local function saveCache(cache) writefile(CACHE_FILE, Http:JSONEncode(cache)) end
local cache = loadCache()
local function clearCacheIfExpired()
    if os.clock() - (cache.started or 0) >= CACHE_TTL then
        cache = { visited = {}, started = os.clock() }
        saveCache(cache)
    end
end
local function markVisited(jobId)
    if jobId and jobId~="" then cache.visited[jobId]=true; saveCache(cache) end
end
local function isGuid36(s) return typeof(s)=="string" and #s==36 and s:match("^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$") end
local function parseServers(buf)
    local list, seen = {}, {}
    local totalLen = (buffer.len and buffer.len(buf)) or 0
    if totalLen <= 0 then
        local i=0
        while true do local ok = pcall(buffer.readu8, buf, i); if not ok then break end; i+=1 end
        totalLen = i
    end
    for i = 0, math.max(0, totalLen-36) do
        local ok, s = pcall(buffer.readstring, buf, i, 36)
        if ok and isGuid36(s) and not seen[s] then seen[s]=true; table.insert(list,{jobId=s}) end
    end
    return list
end
local function pickRandomUnvisited()
    clearCacheIfExpired()
    local currentJob = game.JobId
    local ok, buf = pcall(function() return RefreshServers:InvokeServer() end)
    if not ok or not buf then return nil end
    local servers = parseServers(buf)
    local choices = {}
    for _, s in ipairs(servers) do
        if s.jobId ~= currentJob and not cache.visited[s.jobId] and not failedJobIds[s.jobId] then table.insert(choices, s) end
    end
    if #choices==0 then return nil end
    return choices[math.random(1,#choices)]
end
local function hopTo(jobId)
    if not jobId or jobId == "" or failedJobIds[jobId] then return false, "bad" end
    lastTeleportFailed = false
    markVisited(game.JobId)
    TeleportEvent:FireServer(jobId)
    local prev, t0 = game.JobId, os.clock()
    while os.clock() - t0 < 8 do
        if lastTeleportFailed then failedJobIds[jobId] = true; return false, "failed" end
        if game.JobId ~= prev then return true, "ok" end
        task.wait()
    end
    failedJobIds[jobId] = true
    return false, "timeout"
end

local function setNoclip(char, on)
    if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") and p.CanCollide ~= (not on) then
            p.CanCollide = not on
        end
    end
end

local function waitForSpawned(timeout)
    timeout = timeout or 25
    local t0 = os.clock()
    while os.clock() - t0 < timeout do
        if LP:GetAttribute("hasSpawned") then return true end
        task.wait(0.2)
    end
    return false
end

local function hopToNonFullServer(maxAttempts)
    maxAttempts = maxAttempts or 6
    for _ = 1, maxAttempts do
        local target = pickRandomUnvisited()
        if not target then
            cache = { visited = {}, started = os.clock() }
            saveCache(cache)
            target = pickRandomUnvisited()
        end
        if not target then
            task.wait(1)
        else
            local prev = game.JobId
            hopTo(target.jobId)

            local t0 = os.clock()
            while game.JobId == prev and (os.clock() - t0) < 15 do task.wait() end
            if game.JobId == prev then
                task.wait(0.5)
            else
                markVisited(game.JobId)
                if #Players2:GetPlayers() >= MAX_SERVER_PLAYERS then
                    task.wait(0.25)
                else
                    waitForSpawned(25)
                    return true
                end
            end
        end
    end
    return false
end

local function dist(a,b) if not a or not b then return math.huge end return (a-b).Magnitude end

local function tryFirePrompt(npc)
    local prompt
    for _, d in ipairs(npc:GetDescendants()) do if d:IsA("ProximityPrompt") then prompt=d break end end
    if prompt and typeof(fireproximityprompt)=="function" then pcall(fireproximityprompt,prompt) end
end

local function findTraderNPCStrict()
    local root = workspace:FindFirstChild("DialogNPCs"); if not root then return nil end
    local normal = root:FindFirstChild("Normal"); if normal then local npc = normal:FindFirstChild("Wandering Trader"); if npc then return npc end end
    for _, d in ipairs(root:GetDescendants()) do if d.Name=="Wandering Trader" then return d end end
    return nil
end

local function getTraderTimeLeft()
    local npc = findTraderNPCStrict()
    if not npc then return nil end
    local spawnTime = npc:GetAttribute("spawnTime")
    if not spawnTime then return nil end
    local now = Clock.getServerTime and Clock.getServerTime() or os.time()
    local left = 1800 - (now - spawnTime)
    if left < 0 then left = 0 end
    return string.format("%dm %02ds", math.floor(left/60), left % 60), left
end

local RARE_ALERT = {["Twin Scythe"]=true,["Spirit Key"]=true,["Secret Class"]=true}
local function sendTraderWebhook(stock, locationStr, serverInfo)
    if not stock or #stock == 0 then return end
    local rareFound = false
    local lines = {}
    for _, it in ipairs(stock) do
        table.insert(lines, string.format("- %s x%d (G$%s)", it.name, it.amount or 0, tostring(it.cost or "?")))
        if RARE_ALERT[it.name] then rareFound = true end
    end
    local timeLeftStr = (function()
        local tl = getTraderTimeLeft()
        return tl and tl or "Unknown"
    end)()
    local region  = (ServerRegionValue and ServerRegionValue.Value) or (serverInfo and serverInfo.region) or "Unknown"
    local placeId, jobId = game.PlaceId, game.JobId
    local payload = {
        content = rareFound and "@everyone" or nil,
        embeds = {{
            title = "Wandering Trader Found",
            description = table.concat(lines, "\n"),
            color = 3066993,
            fields = {
                { name = "Region", value = tostring(region), inline = true },
                { name = "Players", value = tostring(serverInfo and serverInfo.players or "?"), inline = true },
                { name = "Time Left", value = timeLeftStr, inline = true },
                { name = "Trader Location", value = locationStr or "Unknown", inline = false },
                { name = "copy paste this to ur browser", value = "roblox://placeID="..placeId.."&gameInstanceId="..jobId, inline = false },
            }
        }}
    }
    if not request then return end
    pcall(request, {Url=WEBHOOK_URL, Method="POST", Headers={["Content-Type"]="application/json"}, Body=Http:JSONEncode(payload)})
end

local function getHRP(char) return char and char:FindFirstChild("HumanoidRootPart") end
local function segmentSlopeDegrees(a,b)
    local d = b-a
    local horiz = Vector3.new(d.X,0,d.Z).Magnitude
    if horiz<=1e-3 then return 0 end
    return math.abs(math.deg(math.atan2(d.Y,horiz)))
end
local MAX_ALLOWED_SLOPE = 40
local function computePath(fromPos, toPos)
    local agent = {AgentRadius=2, AgentHeight=5, AgentCanJump=true, AgentCanClimb=true}
    local p = PathfindingService:CreatePath(agent)
    p:ComputeAsync(fromPos, toPos)
    if p.Status ~= Enum.PathStatus.Success then
        return { {Position = toPos} }
    end
    local pts = p:GetWaypoints()
    for i = 1, #pts - 1 do
        if segmentSlopeDegrees(pts[i].Position, pts[i+1].Position) > MAX_ALLOWED_SLOPE then
            local a, b = pts[i].Position, pts[i+1].Position
            local lateral = (b - a).Unit:Cross(Vector3.yAxis) * 10
            local mid = (a + b) * 0.5 + lateral
            local p1 = PathfindingService:CreatePath(agent) p1:ComputeAsync(fromPos, mid)
            local p2 = PathfindingService:CreatePath(agent) p2:ComputeAsync(mid, toPos)
            if p1.Status == Enum.PathStatus.Success and p2.Status == Enum.PathStatus.Success then
                local w1, w2 = p1:GetWaypoints(), p2:GetWaypoints()
                for j = #w1, 2, -1 do table.remove(w1, j) end
                for _, w in ipairs(w2) do table.insert(w1, w) end
                return w1
            end
            break
        end
    end
    return pts
end

local RAY_STEP = 3
local MAX_STEP_HEIGHT = 3
local NUDGE = Vector3.new(0.5, 0, 0.5)
local function shortLedgeAhead(hrp)
    if not hrp then return false end
    local origin = hrp.Position + Vector3.new(0, 2, 0)
    local dir = hrp.CFrame.LookVector
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {hrp.Parent}
    local low = workspace:Raycast(origin, dir * RAY_STEP, params)
    local high = workspace:Raycast(origin + Vector3.new(0, MAX_STEP_HEIGHT, 0), dir * RAY_STEP, params)
    return low and not high
end
local function nearlyStopped(a, b) return (a - b).Magnitude < 0.15 end

local function tweenTo(hrp, targetPos, opts)
    if not hrp or not hrp.Parent then return false end

    local speed = (opts and opts.speed) 
        or (WalkSpeedEnabled and WalkSpeedValue) 
        or (LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") and LP.Character.Humanoid.WalkSpeed) 
        or 16

    local arriveRadius = (opts and opts.arriveRadius) or 2.5
    local maxDuration  = (opts and opts.maxDuration)  or 8.0

    local startPos = hrp.Position
    local delta = (targetPos - startPos)
    local dist = delta.Magnitude
    if dist <= arriveRadius then return true end

    local flatLook = Vector3.new(targetPos.X, startPos.Y, targetPos.Z)
    if (flatLook - startPos).Magnitude > 0.001 then
        hrp.CFrame = CFrame.new(startPos, flatLook)
    end

    local duration = math.clamp(dist / math.max(speed, 1), 0.05, maxDuration)

    local tween = TweenService:Create(
        hrp,
        TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
        { CFrame = CFrame.new(targetPos) }
    )
    tween:Play()

    local done = false
    local conn; conn = tween.Completed:Connect(function() done = true end)

    local deadline = os.clock() + duration + 2.0
    while not done and os.clock() < deadline do
        if not hrp or not hrp.Parent then
            if conn then conn:Disconnect() end
            return false
        end
        if (hrp.Position - targetPos).Magnitude <= arriveRadius then
            tween:Cancel()
            if conn then conn:Disconnect() end
            return true
        end
        RunService.Heartbeat:Wait()
    end

    if conn then conn:Disconnect() end
    return (hrp and hrp.Parent and (hrp.Position - targetPos).Magnitude <= arriveRadius) or false
end

local function followPathTo(npc)
    if not LP:GetAttribute("hasSpawned") then
        if not waitForSpawned(25) then return "failed" end
    end

    local char = LP.Character or LP.CharacterAdded:Wait()
    local hum = char:WaitForChild("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not (hum and hrp) then return "failed" end

    hum.AutoRotate = true
    hum:Move(Vector3.new(), true)

    setWalkSpeed(true)
    setMaxSlope(true)

    local t0 = os.clock()
    local STOP_DISTANCE = 10
    local function alive() return hum and hum.Health > 0 end

    while npc and npc.Parent and alive() do
        if os.clock() - t0 > 300 then return "timeout" end

        local traderPos = npc:GetPivot().Position
        local distToTrader = (hrp.Position - traderPos).Magnitude
        if distToTrader <= STOP_DISTANCE then
            hum:Move(Vector3.new(), true)
            print("[TraderHopper] Reached trader! Distance:", math.floor(distToTrader), "studs")
            return "arrived"
        end

        local wps = computePath(hrp.Position, traderPos)
        if not wps or #wps == 0 then
            task.wait(0.2)
        else
            for _, w in ipairs(wps) do
                if not alive() then break end

                if segmentSlopeDegrees(hrp.Position, w.Position) > MAX_ALLOWED_SLOPE then
                    break
                end

                if (hrp.Position - traderPos).Magnitude <= STOP_DISTANCE then
                    hum:Move(Vector3.new(), true)
                    print("[TraderHopper] Reached trader! Distance:", math.floor((hrp.Position - traderPos).Magnitude), "studs")
                    return "arrived"
                end
                setNoclip(char, true)
                local ok = tweenTo(hrp, w.Position, { speed = WalkSpeedValue, arriveRadius = 2.5, maxDuration = 8 })
                setNoclip(char, false)
                if not ok then
                    if hrp and hrp.Parent then
                        hrp.CFrame = hrp.CFrame + Vector3.new(0, 2, 0)
                    end
                    break
                end

                if os.clock() - t0 > 300 then return "timeout" end
            end
        end

        task.wait(0.03)
    end
    return "failed"
end

function fetchStock(timeoutSec)
    timeoutSec = timeoutSec or STOCK_TIMEOUT
    local npc = findTraderNPCStrict()
    if not npc then return false, {}, "None", nil end
    local cf = npc:GetPivot()
    local npos = cf and cf.Position
    local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    local mpos = myRoot and myRoot.Position
    local d = dist(mpos, npos)
    
    print("[TraderHopper] Fetching stock from distance:", math.floor(d), "studs")
    
    local got=false
    local stock={}
    local tries=0
    local recvConn = Packets.ReceiveStock.listen(function(payload)
        stock={}
        for _,v in payload do
            local name=v.name
            local amt=tonumber(v.amount) or 0
            local cost=traderData.items[name] and traderData.items[name].cost or nil
            table.insert(stock,{name=name,amount=amt,cost=cost})
        end
        got=true
    end)
    local updConn
    if Packets.UpdateSlot and Packets.UpdateSlot.listen then
        updConn = Packets.UpdateSlot.listen(function(arg1)
            local idx=tonumber(arg1.slot)
            if idx and stock[idx] then stock[idx].amount=tonumber(arg1.amount) or stock[idx].amount end
        end)
    end
    local t0=os.clock()
    while not got and tries<MAX_REQ_TRIES and (os.clock()-t0)<timeoutSec do
        tries+=1
        Packets.RequestStock.send()
        local st=os.clock()
        while not got and (os.clock()-st)<BETWEEN_REQ_WAIT do task.wait(0.05) end
    end
    if not got then
        local uiStock
        if traderPanel then
            local contents=traderPanel:FindFirstChild("Contents")
            if contents then
                local out={}
                for _,slot in ipairs(contents:GetChildren()) do
                    if slot:IsA("Frame") then
                        local nameAttr=slot:GetAttribute("name")
                        local itemLabel=slot:FindFirstChild("ItemLabel")
                        local name=nameAttr or (itemLabel and itemLabel.Text) or nil
                        if name and name~="" then
                            local amt=0
                            if itemLabel and itemLabel.Text then local x=string.match(string.upper(itemLabel.Text),"X(%d+)"); if x then amt=tonumber(x) or 0 end end
                            local cost=traderData.items[name] and traderData.items[name].cost or nil
                            table.insert(out,{name=name,amount=amt,cost=cost})
                        end
                    end
                end
                if #out>0 then uiStock=out end
            end
        end
        if uiStock then stock=uiStock got=true end
    end
    if recvConn and recvConn.Disconnect then recvConn:Disconnect() end
    if updConn and updConn.Disconnect then updConn:Disconnect() end
    return true, stock, npos and string.format("(%.1f, %.1f, %.1f)", npos.X, npos.Y, npos.Z) or "Unknown", nil
end

local function getCurrentServerInfo()
    return {jobId=game.JobId,region=(ServerRegionValue and ServerRegionValue.Value) or "Unknown",name="Unknown",players=#Players2:GetPlayers()}
end

markVisited(game.JobId)

local function navigateThenFetch()
    if not LP:GetAttribute("hasSpawned") then
        if not waitForSpawned(25) then
            return false, {}, "None"
        end
    end

    local char = LP.Character or LP.CharacterAdded:Wait()
    local hum  = char:WaitForChild("Humanoid")
    hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
    local npc = findTraderNPCStrict()
    if not npc then return false, {}, "None" end

    local res = followPathTo(npc)
    if res == "timeout" then return false, {}, "Timeout" end

    local hadTrader, stock, loc = fetchStock(12)
    return hadTrader, stock, loc
end

local function scanCurrentServer()
    if scanBusy then return lastFoundTrader end
    
    local currentJobId = game.JobId
    
    if webhookSentServers[currentJobId] then
        print("[TraderHopper] Already sent webhook for this server, skipping...")
        lastFoundTrader = true
        return true
    end
    
    scanBusy = true
    local ok, hadTrader, stock, location = pcall(function()
        return navigateThenFetch()
    end)
    scanBusy = false

    if not ok then
        warn("[TraderHopper] scan error:", hadTrader)
        lastFoundTrader = false
        return false
    end

    if hadTrader and stock and #stock > 0 then
        lastFoundTrader = true
        print("[TraderHopper] Found trader with", #stock, "items! Sending webhook...")
        
        webhookSentServers[currentJobId] = true
        
        sendTraderWebhook(stock, location, getCurrentServerInfo())
        task.wait(2)
        print("[TraderHopper] Webhook sent! Hopping to next server...")
        return true
    else
        lastFoundTrader = false
    end

    return lastFoundTrader
end

scanCurrentServer()
if AUTO_HOP then
    while true do
        local found = scanCurrentServer()
        
        if found then
            print("[TraderHopper] Hopping to new server...")
            local prevJobId = game.JobId
            hopToNonFullServer()
            
            local timeout = os.clock() + 20
            while game.JobId == prevJobId and os.clock() < timeout do
                task.wait(0.5)
            end
            
            if game.JobId ~= prevJobId then
                print("[TraderHopper] Successfully hopped to new server!")
                markVisited(game.JobId)
            end
        else
            local target = pickRandomUnvisited()
            if not target then
                cache = { visited = {}, started = os.clock() }
                saveCache(cache)
                target = pickRandomUnvisited()
            end
            if target then
                print("[TraderHopper] No trader found, hopping to new server...")
                hopToNonFullServer()
            else
                task.wait(1)
            end
        end
        
        task.wait(HOP_INTERVAL)
    end
end
