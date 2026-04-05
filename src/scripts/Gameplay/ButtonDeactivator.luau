local Button = require("./Button")
local ids = require("@libs/ids")
local std = require("@libs/std")

local ButtonDeactivator = std.Mechanic({})
export type ButtonDeactivatorMechanic = std.Mechanic<typeof(ButtonDeactivator)>
ButtonDeactivator.instanceTag = "ButtonDeactivator"
ButtonDeactivator.instanceType = std.isA.Instance()
ButtonDeactivator.debuggerEmoji = "💠"

ButtonDeactivator.Id = ids.withAttribute(ButtonDeactivator)

ButtonDeactivator:attributeSection("Activation")
ButtonDeactivator.Activation = std.useActivation(ButtonDeactivator)

function ButtonDeactivator:onActivate(deactivator: ButtonDeactivatorMechanic, level: std.Level)
	local id = deactivator:Id()
	if not id then
		return
	end

	local enabledButtons = Button.enabledButtonsById:get(level)[id]
	if not enabledButtons then
		return
	end

	for button in enabledButtons do
		button:Active(false)
	end

	table.clear(enabledButtons)
end

return ButtonDeactivator
