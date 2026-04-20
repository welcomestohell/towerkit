local std = require("@libs/std")

local Template = std.Mechanic({})
export type TemplateMechanic = std.Mechanic<typeof(Template)>
Template.basename = "Template"
Template.instanceType = std.isA.BasePart()
Template.debuggerEmoji = "💠"

return Template
