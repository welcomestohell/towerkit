local activation = require("@libs/activation")
local std = require("@libs/std")

local Wings = std.Mechanic({})
export type WingsMechanic = std.Mechanic<typeof(Wings)>
Wings.instanceTag = "Wings"
Wings.instanceType = std.isA.Instance()
Wings.debuggerEmoji = "🪽"

Wings.Enabled = Wings:withEnabled()
Wings.Cooldown = Wings:attribute("Cooldown", std.gt.positiveNumber, 0)
Wings.Duration = Wings:attribute("Duration", std.gt.positiveNumber, 1)

Wings:attributeSection("Activation")
Wings.Activation = activation.useAttributes(Wings)

return Wings
