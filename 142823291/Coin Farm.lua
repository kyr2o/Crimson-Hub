local CoreGui   = game:GetService("CoreGui")
local Players   = game:GetService("Players")
local RunService= game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local MARKER_NAME = "_cr1m50n__kv_ok__7F2B1D"
if not CoreGui:FindFirstChild(MARKER_NAME) then return end

local Shared = (getgenv and getgenv()) or _G

local function getHRP(ch) return ch and ch:FindFirstChild("HumanoidRootPart") end
local function isAlive(plr)
    local ch = plr and plr.Character
    local hum = ch and ch:FindFirstChild("Humanoid")
    if not hum then return false end
    if ch:GetAttribute("Alive") == false then return false end
    return hum.Health > 0
end
local function hasItem(ch, item)
    local plr = Players:GetPlayerFromCharacter(ch)
    local bp  = plr and plr:FindFirstChild("Backpack")
    return (ch and ch:FindFirstChild(item)) or (bp and bp:FindFirstChild(item)) or false
end
local function murderer()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and isAlive(plr) then
            local ch = plr.Character
            if ch and hasItem(ch, "Knife") then return plr end
        end
    end
end

local CoinContainer, MapModel
local function findCoinContainer()
    for _, m in ipairs(Workspace:GetChildren()) do
        if m:IsA("Model") then
            local cc = m:FindFirstChild("CoinContainer")
            if cc then return m, cc end
        end
    end
    local cc2 = Workspace:FindFirstChild("CoinContainer", true)
    return cc2 and cc2.Parent or nil, cc2
end

local Coins = {}
local function addCoin(inst)
    if not inst then return end
    local part = inst:IsA("BasePart") and inst or (inst:IsA("Model") and (inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart")))
    if part then Coins[part] = true end
end
local function removeCoin(inst)
    if not inst then return end
    if inst:IsA("BasePart") and Coins[inst] then Coins[inst] = nil end
    if inst:IsA("Model") then
        if inst.PrimaryPart and Coins[inst.PrimaryPart] then Coins[inst.PrimaryPart] = nil end
        for p in pairs(Coins) do
            if p:IsDescendantOf(inst) then Coins[p] = nil end
        end
    end
end

local CoinConns = {}
local function hookCoins(cc)
    for _, c in ipairs(cc:GetChildren()) do addCoin(c) end
    table.insert(CoinConns, cc.ChildAdded:Connect(addCoin))
    table.insert(CoinConns, cc.ChildRemoved:Connect(removeCoin))
end
local function clearCoinHooks()
    for _, c in ipairs(CoinConns) do if c.Disconnect then pcall(function() c:Disconnect() end) end end
    CoinConns = {}
    for k in pairs(Coins) do Coins[k] = nil end
end

local function bestCoin()
    local mur = murderer()
    local mhrp = mur and mur.Character and getHRP(mur.Character)
    local ch = LocalPlayer.Character
    local lhrp = getHRP(ch)
    local best, bestDist = nil, -math.huge
    for coin in pairs(Coins) do
        if coin and coin.Parent then
            local ref = mhrp or lhrp
            if ref then
                local d = (coin.Position - ref.Position).Magnitude
                if d > bestDist then bestDist, best = d, coin end
            else
                best = coin; break
            end
        end
    end
    return best
end

local State = { enabled = false, gen = 0, busy = false, returnCF = nil }
local function tp(cf)
    local hrp = getHRP(LocalPlayer.Character)
    if hrp then hrp.CFrame = cf return true end
    return false
end

local function visit(gen, coin)
    local hrp = getHRP(LocalPlayer.Character)
    if not (hrp and coin and coin.Parent) then return end
    State.busy = true
    State.returnCF = hrp.CFrame

    tp(CFrame.new(coin.Position + Vector3.new(0, 3, 0)))

    local t0 = os.clock()
    while State.enabled and gen == State.gen and coin and coin.Parent and (os.clock() - t0) < 1.25 do
        RunService.Heartbeat:Wait()
    end

    if State.returnCF then tp(State.returnCF) end
    State.returnCF, State.busy = nil, false
end

local function loop()
    State.gen += 1
    local gen = State.gen

    MapModel, CoinContainer = findCoinContainer()
    if CoinContainer then
        clearCoinHooks()
        hookCoins(CoinContainer)
    end

    task.spawn(function()
        while State.enabled and gen == State.gen do
            if not LocalPlayer.Character then RunService.Heartbeat:Wait(); continue end
            if not CoinContainer or not CoinContainer.Parent then
                MapModel, CoinContainer = findCoinContainer()
                if CoinContainer then clearCoinHooks(); hookCoins(CoinContainer) end
            end

            local target = bestCoin()
            if target and not State.busy then
                visit(gen, target)
            else
                task.wait(0.03)
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
        State.gen += 1 
        if State.busy and State.returnCF then tp(State.returnCF) end
        clearCoinHooks()
    end,
}
