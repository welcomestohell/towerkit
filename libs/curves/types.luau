export type Curve = {
	read new: (props: { points: { Vector3 }, [unknown]: unknown }) -> Curve,
	read solvePosition: (self: Curve, alpha: number) -> Vector3,
}

return nil
