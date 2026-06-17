const Fluid = require "@roblox_packages/Fluid"

export type PropsWithChildren = { [number]: Fluid.UsedAs<Instance> | PropsWithChildren }

export type LayoutProps = {
	position: Fluid.UsedAs<UDim2>?,
	size: Fluid.UsedAs<UDim2>?,
	automaticSize: Fluid.UsedAs<Enum.AutomaticSize>?,
	layoutOrder: Fluid.UsedAs<number>?,
	zIndex: Fluid.UsedAs<number>?,
}

export type FontProps = {
	family: Fluid.UsedAs<Font>?,
	weight: Fluid.UsedAs<Enum.FontWeight>?,
	style: Fluid.UsedAs<Enum.FontStyle>?,
}

return nil
