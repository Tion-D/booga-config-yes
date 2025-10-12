local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Packets = require(game.ReplicatedStorage.Modules.Packets)

local function isEnemy(p: Player): boolean
    if not p or p == LocalPlayer then return false end
    local myTeam = LocalPlayer.Team
    local theirTeam = p.Team
    if myTeam and theirTeam then
        return myTeam ~= theirTeam
    elseif myTeam == nil and theirTeam == nil then
        return true
    else
        return true
    end
end

local function getLowestHPEnemyUnder(thresholdHP: number, maxDist: number)
    local char = LocalPlayer.Character
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil, nil end

    local bestPlayer, bestHP = nil, math.huge
    local myPos = myRoot.Position

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and isEnemy(p) and p.Character then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hum and hrp and hum.Health > 0 then
                local d = (myPos - hrp.Position).Magnitude
                if d <= maxDist and hum.Health < thresholdHP and hum.Health < bestHP then
                    bestPlayer, bestHP = p, hum.Health
                end
            end
        end
    end

    if bestPlayer then
        local hrp = bestPlayer.Character and bestPlayer.Character:FindFirstChild("HumanoidRootPart")
        return bestPlayer, (hrp and hrp.Position or nil)
    end
    return nil, nil
end

local AutoVoidBolt = true
local VoidBoltDistance = 60

task.spawn(function()
    while task.wait(0.1) do
        if not AutoVoidBolt then continue end

        local enemy, pos = getLowestHPEnemyUnder(40, VoidBoltDistance)
        if enemy and pos then
            Packets.VoodooSpell.send(pos)
            --anims.playAnimation("VoidBolt")
            Packets.VoodooSpell.send(pos)
            --anims.playAnimation("VoidBolt")
            Packets.VoodooSpell.send(pos)
            --anims.playAnimation("VoidBolt")
        end
    end
end)
