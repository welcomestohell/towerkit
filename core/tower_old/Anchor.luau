local std = require "@libs/std"

local Anchor = std.Mechanic {}
export type AnchorMechanic = std.Mechanic<typeof(Anchor)>
Anchor.name = "Anchor"
Anchor.instanceType = std.isA.BasePart()
Anchor.emoji = "🔱"

Anchor.JumpOnDismount = Anchor:attribute("JumpOnDismount", std.gt.boolean(), true)

Anchor:attributeSection "Activation"
Anchor.Activation = std.useActivation(Anchor)

Anchor:attributeSection "Deactivation"
Anchor.Deactivation = std.useActivation(Anchor, "Deactivation")

Anchor:attributeSection "Transition"
Anchor.Transition = std.useTween(Anchor)

function Anchor.onActivate(self: typeof(Anchor), mechanic: AnchorMechanic, level: std.Level) end

return Anchor
