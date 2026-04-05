local UserInputService = game:GetService("UserInputService")

local DebuggerStore = require("./DebuggerStore")
local DebuggerToolbar = require("./DebuggerToolbar")
local Iris = require("@libs/Iris")
local Life = require("@libs/memory/Life")
local tools = require("./tools")
local types = require("./types")

local function Debugger(life: Life.Life)
	local windowEnabled = Iris.State(true)

	Iris.UpdateGlobalConfig({ WindowPadding = Vector2.new(4, 4), RichText = true })

	life:add(UserInputService.InputBegan:Connect(function(input, isProcessed)
		if isProcessed or input.KeyCode ~= Enum.KeyCode.F3 then
			return
		end

		local isOpen = DebuggerStore.isOpen()
		if isOpen then
			for _, tool in DebuggerStore.enabledTools() do
				tool.life:destroy()
			end
			DebuggerStore.reset()
		else
			DebuggerStore.isOpen(true)
		end
	end))

	return function()
		if not DebuggerStore.isOpen() then
			return
		end

		local toolToEnable = DebuggerStore.toolToEnable()
		local toolToDisable: types.DebuggerTool? = DebuggerStore.toolToDisable()

		local enabledTools = DebuggerStore.enabledTools()
		for _, implementation in tools do
			local tool = enabledTools[implementation]
			if not tool then
				continue
			end

			if tool.renderViewport then
				tool:renderViewport()
			end

			if tool.renderWindow then
				Iris.SetNextWidgetID(`WTHDebuggerWindow{tool.title}`)
				if
					Iris.Window({ tool.title }, {
						isOpened = windowEnabled,
						-- position = Iris.State(Vector2.zero),
					}).closed()
				then
					toolToDisable = implementation
				else
					tool:renderWindow()
				end
				Iris.End()
			end
		end

		DebuggerToolbar()

		if toolToEnable then
			DebuggerStore.toolToEnable(nil)
			DebuggerStore.enabledTools(function(tools)
				tools = table.clone(tools)
				tools[toolToEnable] = toolToEnable.new(life:extend())
				return tools
			end)
		end

		if toolToDisable then
			DebuggerStore.toolToDisable(nil)
			DebuggerStore.enabledTools(function(tools: { [types.DebuggerTool]: types.DebuggerTool })
				tools = table.clone(tools)
				tools[toolToDisable :: any].life:destroy()
				tools[toolToDisable :: any] = nil
				return tools
			end)
		end

		windowEnabled:set(true)
	end
end

return Debugger
