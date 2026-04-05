local Charm = require("@pkgs/Charm")
local Life = require("@libs/memory/Life")

export type DebuggerTool = {
	title: string,
	life: Life.Life,
	new: (life: Life.Life) -> DebuggerTool,
	renderViewport: (self: any) -> (),
	renderWindow: (self: any) -> (),
}

export type DebuggerProps = {
	isOpen: Charm.Atom<boolean>,
}

return nil
