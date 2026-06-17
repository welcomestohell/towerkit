local std = require "@libs/std"

local Carryable = std.Mechanic {}
export type CarryableMechanic = std.Mechanic<typeof(Carryable)>
Carryable.name = "Carryable"
Carryable.instanceType = std.isA.Instance()
Carryable.emoji = "💠"

-- TODO: implement

return Carryable
