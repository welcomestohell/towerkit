local std = require "@libs/std"

local Template = std.Mechanic {}
export type TemplateMechanic = std.Mechanic<typeof(Template)>
Template.name = "Template"
Template.instanceType = std.isA.BasePart()
Template.emoji = "💠"

return Template
