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

local MainGui = LP:WaitForChild("PlayerGui"):WaitForChild("MainGui", 5)
local traderPanel = MainGui and MainGui:FindFirstChild("Panels")
traderPanel = traderPanel and traderPanel:FindFirstChild("wanderingTrader")

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

-- precise finder with small wait
local function waitForTraderNPC(maxWait)
	maxWait = maxWait or 8
	local t0 = os.clock()

	local root = workspace:WaitForChild("DialogNPCs", 5)
	if not root then return nil end

	local function find()
		local normal = root:FindFirstChild("Normal")
		if normal then
			local npc = normal:FindFirstChild("Wandering Trader")
			if npc then return npc end
		end
		for _, d in ipairs(root:GetDescendants()) do
			if d.Name == "Wandering Trader" then return d end
		end
	end

	local npc = find()
	if npc then return npc end

	local found
	local conn; conn = root.DescendantAdded:Connect(function(inst)
		if inst.Name == "Wandering Trader" then found = inst end
	end)

	while not found and (os.clock() - t0) < maxWait do
		task.wait(0.2)
		found = find()
	end
	if conn then conn:Disconnect() end
	return found
end

-- scrape UI as a last resort (if some other script already filled it)
local function scrapeTraderUI()
	if not traderPanel then return nil end
	local contents = traderPanel:FindFirstChild("Contents")
	if not contents then return nil end
	local out = {}
	for _, slot in ipairs(contents:GetChildren()) do
		if slot:IsA("Frame") then
			local nameAttr = slot:GetAttribute("name")
			local itemLabel = slot:FindFirstChild("ItemLabel")
			local buyBtn = slot:FindFirstChild("Buy")
			local name = nameAttr or (itemLabel and itemLabel.Text) or nil
			if name and name ~= "" then
				-- try to parse amount from label "... X<amt>"
				local amt = 0
				if itemLabel and itemLabel.Text then
					local x = string.match(string.upper(itemLabel.Text), "X(%d+)")
					if x then amt = tonumber(x) or 0 end
				end
				local cost
				if _G and _G.traderData and _G.traderData.items and _G.traderData.items[name] then
					cost = _G.traderData.items[name].cost
				elseif traderData and traderData.items and traderData.items[name] then
					cost = traderData.items[name].cost
				end
				table.insert(out, { name = name, amount = amt, cost = cost })
			end
		end
	end
	if #out > 0 then return out end
	return nil
end

function fetchStock(timeoutSec)
	timeoutSec = timeoutSec or 10

	-- 1) Ensure NPC exists
	local npc = waitForTraderNPC(8)
	if not npc then
		print("[TraderHopper] No Wandering Trader found after waiting.")
		return false, {}, "None", nil
	end

	local cf = npc:GetPivot()
	local pos = cf and cf.Position
	local locationStr = pos and string.format("(%.1f, %.1f, %.1f)", pos.X, pos.Y, pos.Z) or "Unknown"

	-- 2) Hook listeners BEFORE sending any request
	local got = false
	local stock = {}

	local recvConn, updConn

	recvConn = Packets.ReceiveStock.listen(function(payload)
		stock = {}
		for _, v in payload do
			local name  = v.name
			local amt   = tonumber(v.amount) or 0
			local cost  = traderData.items[name] and traderData.items[name].cost or nil
			table.insert(stock, { name = name, amount = amt, cost = cost })
		end
		got = true
	end)

	-- optional: if the server updates amounts after initial payload
	if Packets.UpdateSlot and Packets.UpdateSlot.listen then
		updConn = Packets.UpdateSlot.listen(function(arg1)
			-- arg1.slot, arg1.amount; try to patch our local table
			local slotIndex = tonumber(arg1.slot)
			if slotIndex and stock[slotIndex] then
				stock[slotIndex].amount = tonumber(arg1.amount) or stock[slotIndex].amount
			end
		end)
	end

	-- 3) Retry RequestStock a few times until we get something
	local deadline = os.clock() + timeoutSec
	local tries = 0
	while not got and os.clock() < deadline do
		tries += 1
		Packets.RequestStock.send()
		for _ = 1, 20 do
			if got then break end
			task.wait(0.1)
		end
		if got then break end
		-- small backoff before next attempt
		task.wait(0.3)
	end

	-- 4) If still nothing, try scraping the UI as a last resort
	if not got then
		local uiStock = scrapeTraderUI()
		if uiStock then
			stock, got = uiStock, true
		end
	end

	-- cleanup
	if recvConn and recvConn.Disconnect then recvConn:Disconnect() end
	if updConn and updConn.Disconnect then updConn:Disconnect() end

	if not got then
		print("[TraderHopper] Trader present but no stock payload received (after retries).")
		return true, {}, locationStr, nil
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
