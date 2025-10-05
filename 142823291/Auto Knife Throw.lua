local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local MARKER_NAME = "_cr1m50n__kv_ok__7F2B1D"
if not CoreGui:FindFirstChild(MARKER_NAME) then return end

local me = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local env = (getgenv and getgenv()) or _G
env.CRIMSON_AUTO_KNIFE = env.CRIMSON_AUTO_KNIFE or { enabled = true }

local allowedAnimIds = {
    "rbxassetid://1957618848",
}
local animGateSec = 0.75

local ignoreThinTransparency = 0.4
local ignoreMinThickness = 0.4

local groundProbeRadius = 2.5
local maxGroundSnap = 24
local sameGroundTolerance = 1.75

local groundedMemorySec = 0.35
local groundedTorsoYOffset = 1.0

local maxHorizontalSlide = 2.5
local cornerPeekDist = 2.5

local exposureCheckRadius = 0.8
local minExposureRatio = 0.4

local knifeSpeed = 63/0.85

local myChar = me.Character or me.CharacterAdded:Wait()
local myHum = myChar:WaitForChild("Humanoid")
local myRoot = myChar:WaitForChild("HumanoidRootPart")
local myKnife, knifeRemote
local loopConn

local trackStart = setmetatable({}, { __mode = "k" })
local lastGroundY = {}
local lastGroundedTorso = {}
local lastGroundedTime = {}

local function unit(v) local m=v.Magnitude if m==0 or m~=m then return Vector3.zero,0 end return v/m,m end
local function clamp(v,a,b) if b<a then a,b=b,a end if v~=v then return a end return math.clamp(v,a,b) end
local function finite3(v) return v and v.X==v.X and v.Y==v.Y and v.Z==v.Z end

local function resolveKnife()
    local k = (me.Backpack and me.Backpack:FindFirstChild("Knife")) or (myChar and myChar:FindFirstChild("Knife"))
    if k ~= myKnife then
        myKnife = k
        knifeRemote = myKnife and myKnife:FindFirstChild("Throw") or nil
    end
end
resolveKnife()
me.CharacterAdded:Connect(function(c)
    myChar=c; myHum=c:WaitForChild("Humanoid"); myRoot=c:WaitForChild("HumanoidRootPart")
    trackStart=setmetatable({}, { __mode = "k" }); task.defer(resolveKnife)
end)
if me:FindFirstChild("Backpack") then
    me.Backpack.ChildAdded:Connect(function(it) if it.Name=="Knife" then resolveKnife() end end)
    me.Backpack.ChildRemoved:Connect(function(it) if it==myKnife then resolveKnife() end end)
end
myChar.ChildAdded:Connect(function(it) if it.Name=="Knife" then resolveKnife() end end)
myChar.ChildRemoved:Connect(function(it) if it==myKnife then resolveKnife() end end)

local function throwIsAllowedNow()
    if not myHum then return false end
    local now=os.clock(); local ok=false
    for _, tr in ipairs(myHum:GetPlayingAnimationTracks()) do
        local id = tr.Animation and tr.Animation.AnimationId or ""
        for _, allow in ipairs(allowedAnimIds) do
            if id:find(allow,1,true) then
                if not trackStart[tr] then trackStart[tr]=now end
                if (now - trackStart[tr]) >= animGateSec then ok=true end
            end
        end
    end
    for tr in pairs(trackStart) do
        if typeof(tr)~="Instance" or not tr.IsPlaying then trackStart[tr]=nil end
    end
    return ok
end

local function aimPart(char)
    return char and (char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head"))
end
local function worldVel(char)
    local p=aimPart(char); return p and p.AssemblyLinearVelocity or Vector3.zero
end

local function ignoreHit(hit)
    local inst=hit.Instance
    if inst and inst:IsA("BasePart") then
        if inst.Transparency>=ignoreThinTransparency then return true end
        local s=inst.Size
        if s.X<ignoreMinThickness or s.Y<ignoreMinThickness or s.Z<ignoreMinThickness then return true end
        local mat=inst.Material
        if mat==Enum.Material.Glass or mat==Enum.Material.ForceField then return true end
    end
    return false
end
local function raycastVec(origin, dir, len, ignore)
    local p=RaycastParams.new(); p.FilterType=Enum.RaycastFilterType.Exclude; p.FilterDescendantsInstances=ignore
    return Workspace:Raycast(origin, dir*len, p)
end
local function rayTowards(origin, target, ignore)
    local u,mag=unit(target-origin); local hit=raycastVec(origin,u,clamp(mag,0,12288),ignore); return hit,u,mag
end

local limbOrder = {
    "LeftFoot","RightFoot","LeftLowerLeg","RightLowerLeg","LeftLeg","RightLeg",
    "LeftHand","RightHand","LeftLowerArm","RightLowerArm","LeftArm","RightArm",
    "Head","UpperTorso","LowerTorso","HumanoidRootPart"
}
local function isPartExposed(part, origin, ignore)
    if not part or not part:IsA("BasePart") then return false end
    local c=part.Position; local s=part.Size
    local pts = {
        c, c+Vector3.new(s.X*0.3,0,0), c+Vector3.new(-s.X*0.3,0,0),
        c+Vector3.new(0,s.Y*0.3,0), c+Vector3.new(0,-s.Y*0.3,0),
        c+Vector3.new(0,0,s.Z*0.3), c+Vector3.new(0,0,-s.Z*0.3),
    }
    if part.Name:find("Foot") or part.Name:find("Hand") or part.Name:find("Leg") or part.Name:find("Arm") then
        table.insert(pts, c+Vector3.new(s.X*0.4, s.Y*0.4, 0))
        table.insert(pts, c+Vector3.new(-s.X*0.4, s.Y*0.4, 0))
        table.insert(pts, c+Vector3.new(s.X*0.4, -s.Y*0.4, 0))
        table.insert(pts, c+Vector3.new(-s.X*0.4, -s.Y*0.4, 0))
    end
    local clear=0
    local fullIgnore={myChar, part.Parent}
    for _,i in ipairs(ignore) do table.insert(fullIgnore, i) end
    for _,p in ipairs(pts) do
        local hit=rayTowards(origin,p,fullIgnore)
        if not hit or hit.Instance:IsDescendantOf(part.Parent) or ignoreHit(hit) then
            clear=clear+1
        end
    end
    return (clear/#pts) >= minExposureRatio
end
local function getExposedLimbs(char, origin, ignore)
    local exposed={}
    if not char then return exposed end
    for _,name in ipairs(limbOrder) do
        local part=char:FindFirstChild(name)
        if part and isPartExposed(part, origin, ignore) then
            table.insert(exposed, part)
        end
    end
    return exposed
end
local function pickExposedTarget(origin)
    local mouse=me:GetMouse(); local bestPlr,bestPart,bestScore=nil,nil,math.huge
    for
