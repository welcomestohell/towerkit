local std = require "@libs/std"

local BoxDestroyer = std.Mechanic {}
export type BoxDestroyerMechanic = std.Mechanic<typeof(BoxDestroyer)>
BoxDestroyer.name = "BoxDestroyer"
BoxDestroyer.instanceType = std.isA.Instance()
BoxDestroyer.emoji = "💥"

return BoxDestroyer
