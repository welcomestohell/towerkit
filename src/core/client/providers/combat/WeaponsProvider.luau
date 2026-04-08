local Log = require("@libs/Log")
local input = require("@core/shared/combat/input")
local prvd = require("@core/shared/prvdmwrong/prvdmwrong")

local WeaponsProvider = {}

export type WeaponsProvider = typeof(WeaponsProvider)

WeaponsProvider.log = Log.new(WeaponsProvider)
WeaponsProvider.inputManager = input.new()

-- is it worth using prvd lifecycles here??
-- are they even a thing with this version of prvd
function WeaponsProvider.onClick(self: WeaponsProvider) end

function WeaponsProvider.onStart(self: WeaponsProvider)
	local context = self.inputManager:createContext({
		identifier = "combat",
	})

	if not context then
		return
	end

	local action = self.inputManager:attachAction({
		identifier = "action",
		actionType = Enum.InputActionType.Bool,

		pressed = function()
			self:onClick()
		end,
	}, {
		context = context,
	})

	if not action then
		return
	end

	-- this gives me rust ptsd
	local _ = self.inputManager:attachBinding({
		identifier = "binding",
		keybind = Enum.KeyCode.F,
	}, {
		context = context,
		action = action,
	})
end

return prvd(WeaponsProvider)
