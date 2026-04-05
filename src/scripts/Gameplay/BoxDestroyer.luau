local std = require("@libs/std")

local BoxDestroyer = std.Mechanic({})
export type BoxDestroyerMechanic = std.Mechanic<typeof(BoxDestroyer)>
BoxDestroyer.instanceTag = "BoxDestroyer"
BoxDestroyer.instanceType = std.isA.Instance()
BoxDestroyer.debuggerEmoji = "💥"

return BoxDestroyer
