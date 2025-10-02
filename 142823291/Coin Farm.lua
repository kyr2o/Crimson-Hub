local CoreGui = game:GetService("CoreGui")
local Players  = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local MARKER_NAME = "_cr1m50n__kv_ok__7F2B1D"
if not CoreGui:FindFirstChild(MARKER_NAME) then
    return
end

local Shared = (getgenv and getgenv()) or _G

local function destroySafe(x)
    if x and x.Destroy then pcall(function() x:Destroy() end) end
end

local function getHRP(character)
    if not character then return nil end
    return character:FindFirstChild("HumanoidRootPart")
end

local function isAlivePlayer(plr)
    if not plr then return false end
    local ch = plr.Character
    if not ch then return false end
    local hum = ch:FindFirstChild("Humanoid")
    if not hum then return false end
    if ch:GetAttribute("Alive") == false then return false end
    return hum.Health > 0
end

local function hasItem(character, itemName)
    local plr = Players:GetPlayerFromCharacter(character)
    if not plr then return false end
    local backpack = plr:FindFirstChild("Backpack")
    if character:FindFirstChild(itemName) then return true end
    if backpack and backpack:FindFirstChild(itemName) then return true end
    return false
end

local function getMurderer()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and isAlivePlayer(plr) then
            local ch = plr.Character
            if ch and hasItem(ch, "Knife") then
                return plr
            end
        end
    end
    return nil
end

local function findMapCoinContainer()

    for _, mdl in ipairs(Workspace:GetChildren()) do
        if mdl:IsA("Model") then
            local cc = mdl:FindFirstChild("CoinContainer")
            if cc and cc:IsA("Folder") or (typeof(cc) == "Instance") then
                return mdl, cc
            end
        end
    end

    local coinContainer = Workspace:FindFirstChild("CoinContainer", true)
    if coinContainer then
        return coinContainer.Parent, coinContainer
    end
    return nil, nil
end

local function waitForCoinServer(timeout)
    local t0 = time()
    while true do
        local found = Workspace:FindFirstChild("Coin_Server", true)
        if found then return found end
        if timeout and (time() - t0) > timeout then return nil end
        RunService.Heartbeat:Wait()
    end
end

local function getCoins(coinContainer)
    local coins = {}
    if not coinContainer then return coins end
    for _, child in ipairs(coinContainer:GetChildren()) do
        if child:IsA("BasePart") then
            table.insert(coins, child)
        elseif child:IsA("Model") then
            local part = child.PrimaryPart
            if not part then
                for _, d in ipairs(child:GetChildren()) do
                    if d:IsA("BasePart") then part = d; break end
                end
            end
            if part then table.insert(coins, part) end
        end
    end
    return coins
end

local function chooseTargetCoin(coins)
    if #coins == 0 then return nil end

    local murderer = getMurderer()
    if murderer and murderer.Character then
        local mhrp = getHRP(murderer.Character)
        if mhrp then
            local best, bestDist = nil, -math.huge
            for _, coin in ipairs(coins) do
                if coin and coin.Parent then
                    local d = (coin.Position - mhrp.Position).Magnitude
                    if d > bestDist then
                        bestDist = d
                        best = coin
                    end
                end
            end
            if best then return best end
        end
    end

    if coins[64] and coins[64].Parent then
        return coins[64]
    end

    local ch = LocalPlayer and LocalPlayer.Character
    local hrp = getHRP(ch)
    if hrp then
        local best, bestDist = nil, -math.huge
        for _, coin in ipairs(coins) do
            if coin and coin.Parent then
                local d = (coin.Position - hrp.Position).Magnitude
                if d > bestDist then
                    bestDist = d
                    best = coin
                end
            end
        end
        return best
    end

    for _, coin in ipairs(coins) do
        if coin and coin.Parent then return coin end
    end
    return nil
end

local function tpTo(cframe)
    local ch = LocalPlayer and LocalPlayer.Character
    local hrp = getHRP(ch)
    if not hrp then return false end

    hrp.CFrame = cframe
    return true
end

local function visitCoinAndReturn(coin)
    local ch = LocalPlayer and LocalPlayer.Character
    local hrp = getHRP(ch)
    if not (coin and coin.Parent and hrp) then return end

    local beforeCFrame = hrp.CFrame
    local targetCF = CFrame.new(coin.Position + Vector3.new(0, 3, 0))
    tpTo(targetCF)

    local t0 = time()
    while coin and coin.Parent and (time() - t0) < 5 do
        RunService.Heartbeat:Wait()
    end

    tpTo(beforeCFrame)
end

local State = { enabled = false, conns = {}, loopFlag = 0 }

local function track(conn)
    if conn then table.insert(State.conns, conn) end
    return conn
end

local function disconnectAll()
    for i, c in ipairs(State.conns) do
        if c and c.Disconnect then pcall(function() c:Disconnect() end) end
        State.conns[i] = nil
    end
end

local function loop()
    State.loopFlag += 1
    local myFlag = State.loopFlag
    task.spawn(function()
        while State.enabled and myFlag == State.loopFlag do

            local ch = LocalPlayer.Character
            if not ch then
                RunService.Heartbeat:Wait()
                continue
            end

            local coinServer = waitForCoinServer(10)
            if not coinServer then
                RunService.Heartbeat:Wait()
                continue
            end

            local mapModel, coinContainer = findMapCoinContainer()
            if not coinContainer then
                RunService.Heartbeat:Wait()
                continue
            end

            local coins = getCoins(coinContainer)
            local target = chooseTargetCoin(coins)
            if target then
                visitCoinAndReturn(target)
            else

                task.wait(0.25)
            end
        end
    end)
end

Shared.CRIMSON_COIN_FARM = {
    enable = function()
        if State.enabled then return end
        State.enabled = true
        loop()
    end,
    disable = function()
        if not State.enabled then return end
        State.enabled = false
        State.loopFlag += 1
        disconnectAll()
    end
}

Shared.CRIMSON_COIN_FARM.enable()
