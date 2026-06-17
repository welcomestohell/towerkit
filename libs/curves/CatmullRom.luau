const Base = require "@roblox_packages/CatRom"

const CatmullRom = {}
CatmullRom.__index = CatmullRom

export type CatRom = setmetatable<{ points: { Vector3 }, solver: typeof(Base.new(...)) }, typeof(CatmullRom)>

function CatmullRom.new(props: { points: { Vector3 } }): CatRom
	return setmetatable({ points = props.points, solver = Base.new(props.points :: { any }, 0.5, 0) }, CatmullRom)
end

function CatmullRom.solvePosition(self: CatRom, alpha: number): Vector3
	return self.solver:SolvePosition(alpha) :: Vector3
end

return table.freeze(CatmullRom)
