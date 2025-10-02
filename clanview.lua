local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Events = RS:WaitForChild("Events")

local WEBHOOK_URL = "https://discord.com/api/webhooks/1423118239235575888/Y2Ck-Lx5PAn-B2JTp967hQH1X-s8YLc9V762BGviBBwV3DPC8qPOGnxlSmDr1sqdA5lh"
local RANK = { "Member", "Officer", "Admin", "Owner" }

local function UName(id)
    local ok, name = pcall(Players.GetNameFromUserIdAsync, Players, id)
    return ok and name or ("User_"..tostring(id))
end

local function Request(url, body)
    local req = (http_request or request or (syn and syn.request))
    if req then
        return req({
            Url = url,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = body
        })
    else
        if http and http.request then
            return http.request({
                url = url,
                method = "POST",
                headers = { ["Content-Type"] = "application/json" },
                body = body
            })
        end
    end
end

local function sendEmbeds(embeds)
    local payload = HttpService:JSONEncode({ embeds = embeds })
    return Request(WEBHOOK_URL, payload)
end

local function run()
    local info = Events.RequestClanInfo:InvokeServer()
    if info == "no_clan" or type(info) ~= "table" or type(info.members) ~= "table" then
        return
    end

    local rows = {}
    local total = 0
    for _, m in ipairs(info.members) do
        local c = m.contribution or 0
        total += c
        rows[#rows+1] = {
            userId = m.playerId,
            username = UName(m.playerId),
            role = RANK[m.rank] or tostring(m.rank),
            contribution = c
        }
    end
    table.sort(rows, function(a,b) return a.contribution > b.contribution end)

    local header = {
        title = string.format("Clan Contributions — %s [%s]", info.clan_name or "?", info.clan_tag or "?"),
        description = string.format("Level **%s** • Members **%d/%d** • Clan Coins **%s**",
            tostring(info.clan_level or "?"), #rows, tonumber(info.clan_cap) or 0, tostring(info.clan_coins or 0)),
        footer = { text = os.date("Generated %Y-%m-%d %H:%M:%S") },
        color = 0xEFA234
    }

    local embeds = { header }
    local fields = {}
    local count = 0

    for i, r in ipairs(rows) do
        fields[#fields+1] = {
            name = string.format("#%d  @%s  (%s)", i, r.username, r.role),
            value = string.format("Contributed: **%d**", r.contribution),
            inline = true
        }
        count += 1
        if (#fields == 25) then
            embeds[#embeds+1] = { title = "Members", fields = fields, color = 0xFFFFFF }
            fields = {}
        end
        if (#embeds == 10) then break end
    end
    if #fields > 0 and #embeds < 10 then
        embeds[#embeds+1] = { title = "Members", fields = fields, color = 0xFFFFFF }
    end

    if #embeds < 10 then
        local top = rows[1]
        if top then
            embeds[#embeds+1] = {
                title = "Top Contributor",
                description = string.format("@%s — **%d** (Role: %s)", top.username, top.contribution, top.role),
                color = 0x33CC66
            }
        end
    end

    if #embeds < 10 then
        embeds[#embeds+1] = {
            title = "Totals",
            fields = {
                { name = "Total Contribution", value = string.format("**%d**", total), inline = true },
                { name = "Member Count", value = string.format("**%d**", #rows), inline = true }
            },
            color = 0x7289DA
        }
    end

    sendEmbeds(embeds)
end

run()
