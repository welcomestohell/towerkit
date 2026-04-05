local std = require("@libs/std")

local Template = std.Mechanic({})
export type TemplateMechanic = std.Mechanic<typeof(Template)>
Template.instanceTag = "Template"
Template.instanceType = std.isA.BasePart()
Template.debuggerEmoji = "💠"

return Template
