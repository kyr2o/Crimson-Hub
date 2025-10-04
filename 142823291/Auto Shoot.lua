local function fallAimOffsets(rootPos, vel, hum, ignore, basePred)
    local state = hum and hum:GetState()
    local vy = vel.Y
    local falling = (state == Enum.HumanoidStateType.Freefall) or (vy < -1.0)
    local jumping = (state == Enum.HumanoidStateType.Jumping)

    local outY = 0
    local forwardScale = 1.0

    local downHit = raycastDown(rootPos + Vector3.new(0,1.5,0), 180, ignore)
    local floorY = downHit and downHit.Position.Y or nil
    local distToFloor = floorY and (rootPos.Y - floorY) or nil

    if falling then

        local deepDrop = distToFloor and distToFloor >= 10 or false
        local veryDeep = distToFloor and distToFloor >= 20 or false

        local baseDown = 1.0
        if distToFloor then
            baseDown = math.clamp(0.7 + distToFloor * 0.36, 1.0, 12.0)
        else
            baseDown = 1.4
        end

        local speedFactor = math.clamp(math.abs(vy)/35, 0.0, 1.4) 

        local snapBonus = 0
        if deepDrop then

            local depthK = math.clamp((distToFloor - 10)/20, 0, 1) 
            snapBonus = 0.25 + 0.30 * depthK
        end

        local downTotal = baseDown * (1.0 + 0.65*speedFactor + snapBonus)
        outY = -downTotal

        if floorY then
            local minAbove = 1.6
            local targetY = rootPos.Y + outY
            if targetY < (floorY + minAbove) then
                outY = (floorY + minAbove) - rootPos.Y
            end
        end

        local distScale = distToFloor and math.clamp(distToFloor/7, 0.9, 3.4) or 1.6
        local speedScale = math.clamp(math.abs(vy)/30, 0.0, 1.8)
        local pingBoost = math.clamp(basePred*2.2, 0.10, 0.38)

        forwardScale = (1.0 + pingBoost + 0.58*distScale + 0.5*speedScale)
        forwardScale = forwardScale * math.max(0.2, tonumber(G.CRIMSON_AUTO_SHOOT.FALL_LEAD_MULT) or 1.0)
        forwardScale = math.clamp(forwardScale, 1.2, 4.8) 

    elseif jumping then
        outY = math.clamp(vy * 0.03, 0, 1.2)
        forwardScale = 1.05
    else
        outY = math.clamp(vy * 0.02, -0.8, 0.8)
        forwardScale = 1.0
    end

    return outY, forwardScale
end
