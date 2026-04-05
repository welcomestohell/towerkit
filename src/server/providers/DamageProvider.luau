local net = require("@server/generated/net")
local prvd = require("@shared/prvdmwrong/prvdmwrong")

local damage = require("@libs/damage")

local DamageProvider = {}
export type DamageProvider = typeof(DamageProvider)
DamageProvider.priority = 5

function DamageProvider.onStart(self: DamageProvider)
	net.damage.on(function(player: Player, value: number)
		damage.damagePlayer(player, value)
	end)
end

return prvd(DamageProvider)
