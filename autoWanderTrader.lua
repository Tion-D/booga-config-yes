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

local RARE_ALERT = {["Twin Scythe"]=true,["Spirit Key"]=true,["Secret Class"]=true}

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Http = game:GetService("HttpService")
local PathfindingService = game:GetService("PathfindingService")
local LP = Players.LocalPlayer

local Events = RS:WaitForChild("Events")
local RefreshServers = Events:WaitForChild("RefreshServers")
local TeleportEvent = Events:WaitForChild("Teleport")
local PG = LP:WaitForChild("PlayerGui")

local Packets = require(RS.Modules.Packets)
local traderData = require(RS.Modules.traderData)

local ServerRegionValue = RS:FindFirstChild("BOOLET") and RS.BOOLET:FindFirstChild("ServerRegion")

local MainGui = LP:WaitForChild("PlayerGui"):WaitForChild("MainGui", 5)
local traderPanel = MainGui and MainGui:FindFirstChild("Panels")
traderPanel = traderPanel and traderPanel:FindFirstChild("wanderingTrader")

local WalkSpeedEnabled, WalkSpeedValue, originalWalkSpeed = false, 22, nil
local maxSlopeEnabled = true
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
local function setMaxSlope(enabled)
	maxSlopeEnabled = enabled
	if LP.Character and LP.Character:FindFirstChild("Humanoid") then
		LP.Character.Humanoid.MaxSlopeAngle = enabled and 89 or 45
	end
end

local function showGameplayUI()
    local SpawnGui = PG:FindFirstChild("SpawnGui")
    local MainGui = PG:FindFirstChild("MainGui")
    local Topbar  = PG:FindFirstChild("Topbar")
    if SpawnGui then SpawnGui.Enabled = false end
    if MainGui then MainGui.Enabled = true end
    if Topbar then Topbar.Enabled = true  end
    for _, ui in ipairs(PG:GetChildren()) do
        if ui:IsA("ScreenGui") and ui.Enabled and ui.Name:lower():find("spawn") then
            ui.Enabled = false
        end
    end
end

local function sendTraderWebhook(stock, locationStr, serverInfo)
	if not stock or #stock == 0 then return end
	local rareFound = false
	local lines = {}
	for _, it in ipairs(stock) do
		table.insert(lines, string.format("- %s x%d (G$%s)", it.name, it.amount or 0, tostring(it.cost or "?")))
		if RARE_ALERT[it.name] then rareFound = true end
	end
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
				{ name = "Trader Location", value = locationStr or "Unknown", inline = false },
				{ name = "copy paste this to ur browser", value = "roblox://placeID="..placeId.."&gameInstanceId="..jobId, inline = false },
			}
		}}
	}
	if not request then return end
	local ok, res = pcall(request, {Url=WEBHOOK_URL, Method="POST", Headers={["Content-Type"]="application/json"}, Body=Http:JSONEncode(payload)})
	if not ok or not res then return end
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
		if s.jobId ~= currentJob and not cache.visited[s.jobId] then table.insert(choices, s) end
	end
	if #choices==0 then return nil end
	return choices[math.random(1,#choices)]
end
local function hopTo(jobId)
	if not jobId or jobId=="" then return end
	markVisited(game.JobId)
	TeleportEvent:FireServer(jobId)
end

local function dist(a,b) if not a or not b then return math.huge end return (a-b).Magnitude end
local function findTraderNPCStrict()
	local root = workspace:FindFirstChild("DialogNPCs"); if not root then return nil end
	local normal = root:FindFirstChild("Normal"); if normal then local npc = normal:FindFirstChild("Wandering Trader"); if npc then return npc end end
	for _, d in ipairs(root:GetDescendants()) do if d.Name=="Wandering Trader" then return d end end
	return nil
end
local function tryFirePrompt(npc)
	local prompt
	for _, d in ipairs(npc:GetDescendants()) do if d:IsA("ProximityPrompt") then prompt=d break end end
	if prompt and typeof(fireproximityprompt)=="function" then pcall(fireproximityprompt,prompt) end
end

local function ensureSpawned(fromBed)
    if LP:GetAttribute("hasSpawned") then
        showGameplayUI()
        return true
    end
    local ok, res = pcall(function()
        return Events.SpawnFirst:InvokeServer(fromBed or false)
    end)
    if not ok or res == nil then return false end
    local char = LP.Character or LP.CharacterAdded:Wait()
    if not char then return false end
    char:WaitForChild("Humanoid", 10)
    showGameplayUI()
    return true
end

local function forceRespawn()
    local c = LP.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    if h and h.Health > 0 then
        h.Health = 0
    end
    LP.CharacterAdded:Wait()
    task.wait(0.25)
    showGameplayUI()
end

local function getHRP(char) return char and char:FindFirstChild("HumanoidRootPart") end
local function segmentSlopeDegrees(a,b)
	local d = b-a
	local horiz = Vector3.new(d.X,0,d.Z).Magnitude
	if horiz<=1e-3 then return 0 end
	return math.abs(math.deg(math.atan2(d.Y,horiz)))
end
local MAX_ALLOWED_SLOPE = 40
local function computePath(fromPos,toPos)
	local agent={AgentRadius=2,AgentHeight=5,AgentCanJump=true,AgentCanClimb=true}
	local p=PathfindingService:CreatePath(agent); p:ComputeAsync(fromPos,toPos); if p.Status~=Enum.PathStatus.Success then return nil end
	local pts=p:GetWaypoints()
	for i=1,#pts-1 do if segmentSlopeDegrees(pts[i].Position,pts[i+1].Position)>MAX_ALLOWED_SLOPE then
		local a,b=pts[i].Position,pts[i+1].Position
		local lateral=(b-a).Unit:Cross(Vector3.yAxis)*10
		local mid=(a+b)*0.5 + lateral
		local p1=PathfindingService:CreatePath(agent); p1:ComputeAsync(fromPos,mid)
		local p2=PathfindingService:CreatePath(agent); p2:ComputeAsync(mid,toPos)
		if p1.Status==Enum.PathStatus.Success and p2.Status==Enum.PathStatus.Success then
			local w1,w2=p1:GetWaypoints(),p2:GetWaypoints()
			for j=#w1,2,-1 do table.remove(w1,j) end
			for _,w in ipairs(w2) do table.insert(w1,w) end
			return w1
		end
		break
	end end
	return pts
end
local function followPathTo(npc)
	local char=LP.Character or LP.CharacterAdded:Wait()
	local hum=char:WaitForChild("Humanoid")
	local hrp=getHRP(char)
	if not (hum and hrp) then return "failed" end
	setWalkSpeed(true); setMaxSlope(false)
	local t0=os.clock()
	local function alive() return hum and hum.Health>0 end
	while npc and npc.Parent and alive() do
		if os.clock()-t0>300 then return "timeout" end
		local tPos=npc:GetPivot().Position
		if dist(hrp.Position,tPos)<=8 then hum:Move(Vector3.new(),true); tryFirePrompt(npc); return "arrived" end
		local wps=computePath(hrp.Position,tPos)
		if not wps or #wps==0 then task.wait(0.25) continue end
		for _,w in ipairs(wps) do
			if not alive() then break end
			if segmentSlopeDegrees(hrp.Position,w.Position)>MAX_ALLOWED_SLOPE then break end
			hum:MoveTo(w.Position)
			if not hum.MoveToFinished:Wait() then break end
			if os.clock()-t0>300 then return "timeout" end
		end
		task.wait(0.05)
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
	if ENFORCE_PROXIMITY and d > REQUIRED_DIST then end
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
	return {jobId=game.JobId,region=(ServerRegionValue and ServerRegionValue.Value) or "Unknown",name="Unknown",players=#Players:GetPlayers()}
end

markVisited(game.JobId)
showGameplayUI()
local function navigateThenFetch()
	if not ensureSpawned(false) then return false,{}, "Unknown" end
	local char=LP.Character or LP.CharacterAdded:Wait()
	local hum=char:WaitForChild("Humanoid")
	hum.Died:Once(function() task.spawn(function() LP.CharacterAdded:Wait(); task.wait(0.5); navigateThenFetch() end) end)
	local npc=findTraderNPCStrict()
	if not npc then return false,{}, "None" end
	local res=followPathTo(npc)
	if res=="timeout" then forceRespawn(); return false,{}, "Timeout" end
	local hadTrader,stock,loc=fetchStock(12)
	return hadTrader,stock,loc
end

local function scanCurrentServer()
	local hadTrader, stock, location = navigateThenFetch()
	if hadTrader and stock and #stock>0 then
		sendTraderWebhook(stock, location, getCurrentServerInfo())
	else
		print("[TraderHopper] No trader/stock -> skip webhook.")
	end
end

scanCurrentServer()

if AUTO_HOP then
	while task.wait(HOP_INTERVAL) do
		local target = pickRandomUnvisited()
		if not target then
			cache = { visited = {}, started = os.clock() }
			saveCache(cache)
			target = pickRandomUnvisited()
			if not target then task.wait(1) continue end
		end
		local prev = game.JobId
		hopTo(target.jobId)
		local t0 = os.clock()
		while game.JobId == prev and (os.clock() - t0) < 15 do task.wait() end
		if game.JobId == prev then continue end
		markVisited(game.JobId)
		task.wait(1)
		scanCurrentServer()
	end
end
