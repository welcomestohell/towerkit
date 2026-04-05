local std = require("@libs/std")

local Anchor = std.Mechanic({})
export type AnchorMechanic = std.Mechanic<typeof(Anchor)>
Anchor.instanceTag = "Anchor"
Anchor.instanceType = std.isA.BasePart()
Anchor.debuggerEmoji = "🔱"

Anchor.JumpOnDismount = Anchor:attribute("JumpOnDismount", std.gt.boolean(), true)

Anchor:attributeSection("Activation")
Anchor.Activation = std.useActivation(Anchor)

Anchor:attributeSection("Deactivation")
Anchor.Deactivation = std.useActivation(Anchor, "Deactivation")

Anchor:attributeSection("Transition")
Anchor.Transition = std.useTween(Anchor)

function Anchor.onActivate(self: typeof(Anchor), mechanic: AnchorMechanic, level: std.Level) end

return Anchor
