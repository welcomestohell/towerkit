const std = require "@libs/std"

const Template = std.Mechanic {
	emoji = "❔",
	name = "Template",
	description = "Hello, Welcome To Hell!",
	instanceType = std.isA.Instance(),
}

export type TemplateMechanic = std.Mechanic<typeof(Template)>

function Template.onStart(self: typeof(Template), mechanic: TemplateMechanic, level: std.Level) end

return Template
