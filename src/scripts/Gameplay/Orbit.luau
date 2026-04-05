local activation = require("@libs/activation")
local std = require("@libs/std")

local Orbit = std.Mechanic({})
export type OrbitMechanic = std.Mechanic<typeof(Orbit)>
Orbit.instanceTag = "Orbit"
Orbit.instanceType = std.gt.instanceTree {
	Pivot = std.isA.BasePart(),
	Handle = std.isA.BasePart(),
}
Orbit.debuggerEmoji = "🪐"

Orbit:attributeSection("Activation")
Orbit.Activation = activation.useAttributes(Orbit)

Orbit:attributeSection("Deactivation")
Orbit.Deactivation = activation.useAttributes(Orbit)

return Orbit
