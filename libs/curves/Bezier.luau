const Bezier = {}
Bezier.__index = Bezier

export type Bezier = setmetatable<{ points: { Vector3 } }, typeof(Bezier)>

function Bezier.new(props: { points: { Vector3 } }): Bezier
	return setmetatable({ points = props.points }, Bezier)
end

function Bezier.solvePosition(self: Bezier, alpha: number): Vector3
	const points = table.clone(self.points)
	while #points > 1 do
		for i = 1, #points - 1 do
			points[i] = points[i]:Lerp(points[i + 1], alpha)
		end
		points[#points] = nil
	end
	return points[1]
end

return table.freeze(Bezier)
