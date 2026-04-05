local std = require("@libs/std")

local character = require("@libs/character")
local damage = require("@libs/damage")

--[=[
	@class Damager
	@tag Mechanic

	Damager makes the instance hurt the player when touched by any limb.
]=]
local Damager = std.Mechanic({})
export type DamagerMechanic = std.Mechanic<typeof(Damager)>

Damager.instanceTag = "Damager"
Damager.instanceType = std.isA.Instance()
Damager.debuggerEmoji = "☠️"

Damager.Enabled = Damager:withEnabled()
Damager.Damage = damage.useAttributes(Damager)
Damager.Cooldown = Damager:attribute("Cooldown", std.gt.positiveNumber, 0.5)

Damager.cooldowns = {} :: { [Player]: number }

function Damager.onTouch(damager: DamagerMechanic, hit: Part): boolean
	if not hit or not hit.Parent or not character.isFromMaybeCharacter(hit) then
		return false
	end

	local player = character.getPlayerFromHit(hit)

	if not player then
		return false
	end

	local damagerDamage, damagerCooldown = damager:Damage(), damager:Cooldown()
	local cooldowns = damager.cooldowns or {}

	local now = os.clock()

	if cooldowns[player] and cooldowns[player] > now then
		return false
	end

	cooldowns[player] = now + damagerCooldown
	damage.damagePlayer(player, damagerDamage)

	return true
end

function Damager.onStart(self: typeof(Damager), damager: DamagerMechanic, level: std.Level)
	damager.cooldowns = {} :: { [Player]: true }

	local instance = damager.instance

	if not instance then
		damager.log:error("Damager", instance:GetFullName(), "is missing.")

		return
	end

	-- damager.life:add(instance.Touched, function(hit: Part)
	-- 	damager:onTouch(hit)
	-- end)
end

return Damager
