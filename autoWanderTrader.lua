local WEBHOOK_URL   = "https://discord.com/api/webhooks/1427511460744925246/fV-N6lLwFgkveffOUI7hIcMN8Wk1Yahh0T_aGhnI9HTBGWNbwbWLfC8aGKXSjsTh87jC"
local AUTO_HOP      = true
local HOP_INTERVAL  = 5             -- seconds between hops after reporting
local MAX_TRIES_PER_SERVER = 1
local CACHE_FILE    = "server_cache.json"
local CACHE_TTL     = 20 * 60       -- 20 minutes

-- Ping list: if any of these show up, we @everyone
local RARE_ALERT = {
	["Twin Scythe"] = true,
	["Spirit Key"]  = true,
	["Secret Class"]= true,
}
-- =========================================================

local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local Http    = game:GetService("HttpService")
local LP      = Players.LocalPlayer

-- Remotes / modules from your decomp
local Events          = RS:WaitForChild("Events")
local RefreshServers  = Events:WaitForChild("RefreshServers")
local TeleportEvent   = Events:WaitForChild("Teleport")

local Packets         = require(RS.Modules.Packets)
local traderData      = require(RS.Modules.traderData)

local ServerRegionValue = RS:FindFirstChild("BOOLET") and RS.BOOLET:FindFirstChild("ServerRegion")

-- =============== HTTP helper ===============
local function httpRequest(opts)
	local req = (syn and syn.request) or (http and http.request) or request or http_request
	if not req then
		warn("[TraderHopper] No HTTP request function available.")
		return nil, "no_request_fn"
	end
	local ok, res = pcall(req, opts)
	if not ok then return nil, res end
	return res, nil
end

local function postWebhook(json, pingEveryone)
	if pingEveryone then
		json.content = "@everyone"
		json.allowed_mentions = { parse = {"everyone"} }
	end
	local res, err = httpRequest({
		Url = WEBHOOK_URL,
		Method = "POST",
		Headers = { ["Content-Type"] = "application/json" },
		Body = Http:JSONEncode(json)
	})
	if not res then
		warn("[TraderHopper] Webhook POST failed:", err)
		return false
	end
	return res.StatusCode >= 200 and res.StatusCode < 300
end

-- =============== Cache ===============
local function safefile(name)
	return pcall(function() return isfile(name) end) and isfile(name)
end

local function loadCache()
	if safefile(CACHE_FILE) then
		local ok, data = pcall(function() return Http:JSONDecode(readfile(CACHE_FILE)) end)
		if ok and typeof(data) == "table" and data.visited and data.started then
			return data
		end
	end
	return { visited = {}, started = os.clock() }
end

local function saveCache(cache)
	writefile(CACHE_FILE, Http:JSONEncode(cache))
end

local cache = loadCache()

local function clearCacheIfExpired()
	if os.clock() - (cache.started or 0) >= CACHE_TTL then
		cache = { visited = {}, started = os.clock() }
		saveCache(cache)
		print("[TraderHopper] Cache cleared (TTL reached).")
	end
end

local function markVisited(jobId)
	if jobId and jobId ~= "" then
		cache.visited[jobId] = true
		saveCache(cache)
	end
end

-- =============== Server parsing ===============
local function parseServers(buf)
	local list, offset = {}, 0
	local function ru16() local v=buffer.readu16(buf,offset); offset+=2; return v end
	local function ru8()  local v=buffer.readu8(buf,offset);  offset+=1; return v end
	local function rf64() local v=buffer.readf64(buf,offset); offset+=8; return v end
	local function rstr(n) local s=buffer.readstring(buf,offset,n); offset+=n; return s end

	local total = ru16()
	for _ = 1, total do
		local playerCount = ru8()
		for i=1, math.min(playerCount, 8) do rf64() end
		local nameLen  = ru8()
		local jobId    = rstr(36)
		local regionLen= ru8()
		local region   = rstr(regionLen)
		local serverName = rstr(nameLen)
		table.insert(list, {
			jobId   = jobId,
			players = playerCount,
			name    = serverName,
			region  = region
		})
	end
	return list
end

local function pickRandomUnvisited()
	clearCacheIfExpired()
	local currentJob = game.JobId
	local buf = RefreshServers:InvokeServer()
	local servers = parseServers(buf)
	local choices = {}
	for _, s in ipairs(servers) do
		if s.jobId ~= currentJob and not cache.visited[s.jobId] then
			table.insert(choices, s)
		end
	end
	if #choices == 0 then return nil end
	return choices[math.random(1, #choices)]
end

local function hopTo(jobId)
	if not jobId or jobId == "" then return end
	markVisited(game.JobId)
	print("[TraderHopper] Hopping to:", jobId)
	TeleportEvent:FireServer(jobId)
end

-- =============== Trader Detection ===============
local function findTraderNPCPath()
    local root = workspace:FindFirstChild("DialogNPCs")
    if not root then return nil end
    -- prefer exact path first
    local normal = root:FindFirstChild("Normal")
    if normal then
        local exact = normal:FindFirstChild("Wandering Trader")
        if exact then return exact end
    end
    -- fallback: any descendant with that name
    for _, inst in ipairs(root:GetDescendants()) do
        if typeof(inst.Name) == "string" and inst.Name == "Wandering Trader" then
            return inst
        end
    end
    return nil
end

-- Wait up to `timeoutSec` for the trader to appear (handles late replication)
local function waitForTraderNPC(timeoutSec)
    local npc = findTraderNPCPath()
    if npc then return npc end

    local root = workspace:WaitForChild("DialogNPCs", 5)
    if not root then return nil end

    timeoutSec = timeoutSec or 6
    local deadline = os.clock() + timeoutSec
    local found = nil

    local conn; conn = root.DescendantAdded:Connect(function(inst)
        if inst.Name == "Wandering Trader" then
            found = inst
        end
    end)

    -- also poll occasionally in case DescendantAdded fired before we connected
    while os.clock() < deadline and not found do
        task.wait(0.2)
        found = findTraderNPCPath()
    end

    if conn then conn:Disconnect() end
    return found
end

local function formatV3(v)
	if not v then return "Unknown" end
	return string.format("(%.1f, %.1f, %.1f)", v.X, v.Y, v.Z)
end

local function fallbackSpawnPoints()
	local out = {}
	local spawns = workspace:FindFirstChild("WanderingTraderSpawns")
	if spawns then
		for _, child in ipairs(spawns:GetDescendants()) do
			if child:IsA("BasePart") then
				table.insert(out, string.format("%s %s", child.Name, formatV3(child.Position)))
			end
		end
	end
	return out
end

local function fetchStock(timeoutSec)
    -- Only send webhook if we truly have the trader
    local npc = waitForTraderNPC(6)
    if not npc then
        print("[TraderHopper] No trader found after waiting.")
        return false, {}, "None", nil
    end

    local locationStr = (function()
        local cf = npc:GetPivot()
        local p = cf and cf.Position
        return p and string.format("(%.1f, %.1f, %.1f)", p.X, p.Y, p.Z) or "Unknown"
    end)()

    local stock, done = nil, false
    local conn
    conn = Packets.ReceiveStock.listen(function(payload)
        local out = {}
        for _, v in payload do
            local itemName = v.name
            local amount   = tonumber(v.amount) or 0
            local cost     = traderData.items[itemName] and traderData.items[itemName].cost or nil
            table.insert(out, { name = itemName, amount = amount, cost = cost })
        end
        stock, done = out, true
        if conn and conn.Disconnect then conn:Disconnect() end
    end)

    Packets.RequestStock.send()

    local t0 = os.clock()
    timeoutSec = timeoutSec or 5
    while not done and (os.clock() - t0) < timeoutSec do
        task.wait()
    end
    if conn and conn.Disconnect then conn:Disconnect() end

    if not stock then
        print("[TraderHopper] Trader present but no stock payload received (timeout).")
        stock = {}
    end

    return true, stock, locationStr, nil
end
-- =============== Webhook ===================
local function sendTraderWebhook(stock, locationStr, serverInfo)
	if not stock or #stock == 0 then return end

	local rareFound = false
	local lines = {}
	for _, it in ipairs(stock) do
		table.insert(lines, string.format("- %s x%d (G$%s)", it.name, it.amount or 0, tostring(it.cost or "?")))
		if RARE_ALERT[it.name] then rareFound = true end
	end

	local region = (ServerRegionValue and ServerRegionValue.Value) or (serverInfo and serverInfo.region) or "Unknown"
	local placeId = game.PlaceId
	local jobId = game.JobId

	local embed = {
		title = "Wandering Trader Found",
		color = 3066993,
		fields = {
			{ name = "Region", value = tostring(region), inline = true },
			{ name = "Players", value = tostring(serverInfo and serverInfo.players or "?"), inline = true },
			{ name = "Trader Location", value = locationStr, inline = false },
			{ name = "Stock", value = table.concat(lines, "\n"), inline = false },
			{ name = "copy paste this to ur browser", value = "roblox://placeID="..placeId.."&gameInstanceId="..jobId, inline = false },
		},
		timestamp = DateTime.now():ToIsoDate(),
	}

	local body = {
		username = "Trader Hopper",
		embeds = { embed },
	}
	postWebhook(body, rareFound)
end

-- =============== Main Flow ===============
local function getCurrentServerInfo()
	local info = {
		jobId = game.JobId,
		region = (ServerRegionValue and ServerRegionValue.Value) or "Unknown",
		name = "Unknown",
		players = #Players:GetPlayers(),
	}
	local ok, buf = pcall(function() return RefreshServers:InvokeServer() end)
	if ok and buf then
		for _, s in ipairs(parseServers(buf)) do
			if s.jobId == game.JobId then
				info.region, info.name, info.players = s.region, s.name, s.players
				break
			end
		end
	end
	return info
end

markVisited(game.JobId)

local function scanCurrentServer()
	local hadTrader, stock, location = fetchStock(5)
	if hadTrader and stock and #stock > 0 then
		sendTraderWebhook(stock, location, getCurrentServerInfo())
	else
		print("[TraderHopper] No trader in this server, skipping webhook.")
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
			if not target then
				task.wait(10)
				continue
			end
		end

		local prev = game.JobId
		--hopTo(target.jobId)

		local t0 = os.clock()
		while game.JobId == prev and (os.clock() - t0) < 15 do task.wait() end
		if game.JobId == prev then continue end

		markVisited(game.JobId)
		task.wait(1)
		scanCurrentServer()
	end
end
