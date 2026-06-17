const Linear = {}
Linear.__index = Linear

export type Linear = setmetatable<{ points: { Vector3 } }, typeof(Linear)>

function Linear.new(props: { points: { Vector3 } }): Linear
	return setmetatable({ points = props.points }, Linear)
end

function Linear.solvePosition(self: Linear, alpha: number): Vector3
	return self.points[math.floor(alpha * (#self.points - 1) + 1)]
end

return table.freeze(Linear)
