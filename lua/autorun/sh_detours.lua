-- detours so stuff go through portals
AddCSLuaFile()

-- bullet detour
hook.Add("EntityFireBullets", "seamless_portal_detour_bullet", function(entity, data)
    if !SeamlessPortals or SeamlessPortals.PortalIndex < 1 then return end
	local tr = util.TraceLine({start = data.Src, endpos = data.Src + data.Dir * data.Distance, filter = entity})
	local hitPortal = tr.Entity
	if !hitPortal:IsValid() then return end
	if hitPortal:GetClass() == "seamless_portal" and hitPortal:ExitPortal() then
		if (tr.HitPos - hitPortal:GetPos()):Dot(hitPortal:GetUp()) > 0 then
			local newPos, newAng = SeamlessPortals.TransformPortal(hitPortal, hitPortal:ExitPortal(), tr.HitPos, data.Dir:Angle())

			--ignoreentity doesnt seem to work for some reason
			data.IgnoreEntity = hitPortal:ExitPortal()
			data.Src = newPos
			data.Dir = newAng:Forward()

			return true
		end
	end
end)

-- effect detour (Thanks to WasabiThumb)
local oldUtilEffect = util.Effect
local function effect(name, b, c, d)
     if SeamlessPortals.PortalIndex > 0 and (name == "phys_freeze" or name == "phys_unfreeze") then return end
     oldUtilEffect(name, b, c, d)
end
util.Effect = effect


if SERVER then return end

-- sound detour
hook.Add("EntityEmitSound", "seamless_portals_detour_sound", function(t)
    if !SeamlessPortals or SeamlessPortals.PortalIndex < 1 then return end
	for k, v in ipairs(ents.FindByClass("seamless_portal")) do
        if !v.ExitPortal or !v:ExitPortal() or !v:ExitPortal():IsValid() then continue end
        if !t.Pos or !t.Entity or t.Entity == NULL then continue end
        if t.Pos:DistToSqr(v:GetPos()) < 50000 and (t.Pos - v:GetPos()):Dot(v:GetUp()) > 0 then
            local newPos, _ = SeamlessPortals.TransformPortal(v, v:ExitPortal(), t.Pos, Angle())
            local oldPos = t.Entity:GetPos() or Vector()
            t.Entity:SetPos(newPos)
            EmitSound(t.SoundName, newPos, t.Entity:EntIndex(), t.Channel, t.Volume, t.SoundLevel, t.Flags, t.Pitch, t.DSP)
            t.Entity:SetPos(oldPos)
        end
	end
end)
