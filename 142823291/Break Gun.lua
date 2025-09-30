local function getGunInstance()
    for i, v in next, game.Players:GetPlayers() do
        if v.Character and v.Character:FindFirstChild("Gun") then
            return v.Character.Gun
        end
    end
end

local gun = getGunInstance()
if gun then
    local shootGun = gun:FindFirstChild("ShootGun", true)
    if shootGun then
        repeat
            shootGun:InvokeServer(1, 0, "AH2")
            task.wait()
        until (not shootGun or not shootGun.Parent) or not shootGun:IsDescendantOf(workspace)
    end
end
