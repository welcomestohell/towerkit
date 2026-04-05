local Workspace = game:GetService("Workspace")

local DebuggerStore = require("./DebuggerStore")
local Iris = require("@libs/Iris")
local tools = require("./tools")

local WINDOW_HEIGHT = 26

local WINDOW_ARGS = {
	"Welcome To Hell Debugger Toolbar",
	[Iris.Args.Window.NoTitleBar] = true,
	[Iris.Args.Window.NoMove] = true,
	[Iris.Args.Window.NoClose] = true,
	[Iris.Args.Window.NoResize] = true,
	[Iris.Args.Window.NoScrollbar] = true,
}

local function DebuggerToolbar()
	local windowPadding = Iris._config.WindowPadding

	Iris.SetNextWidgetID("WTHDebuggerToolbar")
	local window = Iris.Window(WINDOW_ARGS)

	Iris.SameLine({
		windowPadding.X,
		[Iris.Args.SameLine.VerticalAlignment] = Enum.VerticalAlignment.Top,
		[Iris.Args.SameLine.HorizontalAlignment] = Enum.HorizontalAlignment.Center,
	})
	for _, tool in tools do
		if Iris.Button({ tool.title }).clicked() then
			if DebuggerStore.enabledTools()[tool] then
				DebuggerStore.toolToDisable(tool)
			else
				DebuggerStore.toolToEnable(tool)
			end
		end
	end
	Iris.End()

	Iris.End()

	-- Fuck off
	local windowContent = window.Instance:FindFirstChildWhichIsA("GuiObject") :: GuiObject
	windowContent.Size = UDim2.new(1, 0, 0, WINDOW_HEIGHT)
	windowContent.Position = UDim2.fromScale(0, 1)
	windowContent.AnchorPoint = Vector2.new(0, 1)
end

return DebuggerToolbar
