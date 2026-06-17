const Template = {}
Template.__index = Template

export type Template = setmetatable<{ points: { Vector3 } }, typeof(Template)>

function Template.new(props: { points: { Vector3 } }): Template
	return setmetatable({ points = props.points }, Template)
end

function Template.solvePosition(self: Template, alpha: number): Vector3
	return Vector3.zero
end

return table.freeze(Template)
