-- Source: https://pomax.github.io/bezierinfo/#bsplines

const BSpline = {}
BSpline.__index = BSpline

export type BSpline = setmetatable<{
	points: { Vector3 },
	knots: { number },

	degree: number,
	minimum: number,
	maximum: number,
}, typeof(BSpline)>

function BSpline.new(props: { points: { Vector3 } }): BSpline
	const n = #props.points
	const degree = n < 4 and math.max(1, n - 1) or 3

	const knotCount = n + degree + 1
	const knots = table.create(knotCount) :: { number }
	for index = 1, knotCount do
		knots[index] = if index <= degree + 1
			then 0
			elseif index > knotCount - (degree + 1) then 1
			else (index - (degree + 1)) / (n - degree)
	end

	return setmetatable({
		points = props.points,
		knots = knots,

		degree = degree,
		minimum = degree + 1,
		maximum = knotCount - degree,
	}, BSpline)
end

function BSpline.solvePosition(self: BSpline, alpha: number): Vector3
	const points = self.points
	const knots = self.knots
	const degree = self.degree

	const tMin = knots[self.minimum]
	const tMax = knots[self.maximum]
	const t = math.map(math.clamp(alpha, 0, 1), 0, 1, tMin, tMax)

	local k = self.minimum
	for index = self.minimum, self.maximum - 1 do
		if t >= knots[index] and t <= knots[index + 1] then
			k = index
			break
		end
	end

	local v = table.create(degree + 1) :: { Vector3 }
	for i = 0, degree do
		v[i + 1] = points[k - degree + i]
	end

	for j = 1, degree do
		for i = degree, j, -1 do
			const knotIndex = k - degree + i
			const knotStart = knots[knotIndex]
			const knotEnd = knots[knotIndex + degree + 1 - j]

			const a = if knotEnd == knotStart then 0 else (t - knotStart) / (knotEnd - knotStart)

			v[i + 1] = v[i]:Lerp(v[i + 1], a)
		end
	end

	return v[degree + 1]
end

return table.freeze(BSpline)
