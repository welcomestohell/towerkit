const types = require "@self/types"

export type Curve = types.Curve

const curves = {
	Bezier = require "@self/Bezier",
	BSpline = require "@self/BSpline",
	Catenary = require "@self/Catenary",
	CatmullRom = require "@self/CatmullRom",
	Linear = require "@self/Linear",
}

curves.CURVES = table.clone(curves) :: { [string]: Curve }
return table.freeze(curves)
