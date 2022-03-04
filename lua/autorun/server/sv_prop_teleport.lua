-- this is the code that teleports entities like props
-- it only works for things with physics since I dont want to add support to other wacked entities that dont have physics

local seamless_check = function(e) return e:GetClass() == "seamless_portal" end    -- for traces
local function destroyPortalEnt(e)
    SafeRemoveEntity(e.PORTAL_ENTITY)
    e.PORTAL_ENTITY = nil
end

hook.Add("Think", "seamless_portal_teleport", function()
    if !SeamlessPortals or SeamlessPortals.PortalIndex < 1 then return end
    for _, prop in ipairs(ents.GetAll()) do
        if prop:GetClass() == "player" or prop:GetClass() == "seamless_portal" then continue end
        if prop.PORTAL_PARENT_ENTITY then 
            if !prop.PORTAL_PARENT_ENTITY:IsValid() then
                SafeRemoveEntity(prop)
            end
            continue 
        end
        if !prop:GetPhysicsObject():IsValid() then continue end
        if prop:GetVelocity() == Vector(0, 0, 0) then continue end

        -- puts fake prop in the other portal
        local realPos = prop:GetPos()
        local closestPortalDist = 0
        local closestPortal = nil
        for k, portal in ipairs(ents.FindByClass("seamless_portal")) do 
            local dist = realPos:DistToSqr(portal:GetPos())
            if (dist < closestPortalDist or k == 1) and portal:ExitPortal() and portal:ExitPortal():IsValid() then
                closestPortalDist = dist
                closestPortal = portal
            end
        end

        if !closestPortal or !closestPortal:ExitPortal() or !closestPortal:ExitPortal():IsValid() then continue end
        
        --[[
        if closestPortalDist > 10000 then 
            destroyPortalEnt(prop)
            continue 
        end

        -- create the fake ent on the other side of the portal
        if !prop.PORTAL_ENTITY or !prop.PORTAL_ENTITY:IsValid() then
            prop.PORTAL_ENTITY = ents.Create(prop:GetClass())
            prop.PORTAL_ENTITY:SetPos(Vector())
            prop.PORTAL_ENTITY:SetAngles(Angle())
            prop.PORTAL_ENTITY:SetModel(prop:GetModel())
            prop.PORTAL_ENTITY:Spawn()
            prop.PORTAL_ENTITY:Activate()
            prop.PORTAL_ENTITY:SetColor(prop:GetColor())
            prop.PORTAL_ENTITY:SetMaterial(prop:GetMaterial())
            prop.PORTAL_ENTITY:SetRenderMode(prop:GetRenderMode())
            prop.PORTAL_ENTITY:SetRenderFX(prop:GetRenderFX())
            prop.PORTAL_ENTITY:GetPhysicsObject():EnableMotion(false)
            --prop.PORTAL_ENTITY:SetNotSolid(true)
            prop.PORTAL_ENTITY.PORTAL_PARENT_ENTITY = prop
        else
            -- set its position and angle
            local editedPos, editedAng = SeamlessPortals.TransformPortal(closestPortal, closestPortal:ExitPortal(), realPos, prop:GetAngles())
            prop.PORTAL_ENTITY:SetPos(editedPos)
            prop.PORTAL_ENTITY:SetAngles(editedAng)
            prop.PORTAL_ENTITY:GetPhysicsObject():EnableMotion(false)
        end

        if (realPos - closestPortal:GetPos()):Dot(closestPortal:GetUp()) < 0 then continue end]]
        if prop:IsPlayerHolding() then continue end
        
        -- can it go through the portal?
        local tr = util.TraceLine({
            start = realPos - prop:GetVelocity() * 0.01, 
            endpos = realPos + prop:GetVelocity() * 0.01, 
            filter = seamless_check
        })

        if !tr.Hit then continue end
        local hitPortal = tr.Entity
        if hitPortal and hitPortal:GetClass() == "seamless_portal" and hitPortal:ExitPortal():IsValid() then
            if prop:GetVelocity():Dot(hitPortal:GetUp()) < 0 then
                --local propsToTeleport = prop.Constraints
                --table.insert(propsToTeleport, prop)

                --for _, constraintedProp in ipairs(propsToTeleport) do
                    -- rotate velocity, position, and angles
                    local editedPos, editedAng = SeamlessPortals.TransformPortal(hitPortal, hitPortal:ExitPortal(), tr.HitPos, prop:GetVelocity():Angle())

                    --extra angle rotate
                    local newPropAng = prop:GetAngles()
                    newPropAng:RotateAroundAxis(hitPortal:GetForward(), 180)
                    local editedPropAng = hitPortal:ExitPortal():LocalToWorldAngles(hitPortal:WorldToLocalAngles(newPropAng))

                    local max = math.Max(prop:GetVelocity():Length(), hitPortal:ExitPortal():GetUp():Dot(-physenv.GetGravity() / 3))
                    prop:GetPhysicsObject():SetVelocity(editedAng:Forward() * max)
                    prop:GetPhysicsObject():SetAngles(editedPropAng)
                    prop:GetPhysicsObject():SetPos(editedPos)
                --end
                destroyPortalEnt(prop)
            end
        end
    end
end)


hook.Add("PhysgunPickup", "seamless_portal_disable_pickup", function(ply, ent)
	if ent.PORTAL_PARENT_ENTITY then
		return false
	end
end)