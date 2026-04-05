local Signal = require("@pkgs/Signal")
local activation = require("@libs/activation")
local std = require("@libs/std")

local Dismounter = std.Mechanic({})
export type DismounterMechanic = std.Mechanic<typeof(Dismounter)>

Dismounter.instanceTag = "Dismounter"
Dismounter.instanceType = std.isA.Instance()
Dismounter.debuggerEmoji = "⏏️"

Dismounter.Dismounts = Dismounter:prefixedAttributeMap("Dismounts", std.gt.boolean())

Dismounter:attributeSection("Activation")
Dismounter.Activation = activation.useAttributes(Dismounter)

Dismounter.onDismount = Signal.new() :: Signal.Signal<{ [string]: boolean }>

function Dismounter.onActivate(self: typeof(Dismounter), dismounter: DismounterMechanic)
	self.onDismount:Fire(self:Dismounts())
end

return Dismounter
