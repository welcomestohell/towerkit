local Stats = game:GetService("Stats")
local Workspace = game:GetService("Workspace")

local Iris = require("@pkgs/Iris")

local WINDOW_ARGS = {
	"Welcome To Hell Debugger Overlay",
	[Iris.Args.Window.NoTitleBar] = true,
	[Iris.Args.Window.NoBackground] = true,
	[Iris.Args.Window.NoMove] = true,
	[Iris.Args.Window.NoClose] = true,
	[Iris.Args.Window.NoResize] = true,
	[Iris.Args.Window.NoScrollbar] = true,
}

local function DebuggerOverlay()
	local position = Iris.State(Vector2.zero)
	Iris.SetNextWidgetID("WTHDebuggerOverlay")
	Iris.Window(WINDOW_ARGS, { position = position })

	Iris.Text({ `FPS: {math.round(1 / Stats.FrameTime)}` })

	Iris.End()
end

return DebuggerOverlay
