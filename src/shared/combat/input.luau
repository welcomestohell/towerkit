local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

local Life = require("@libs/memory/Life")

local inputManager = {}
inputManager.__index = inputManager

export type Keybind = Enum.KeyCode | Enum.UserInputType

export type Binding = {
	identifier: string,
	keybind: Keybind,
	life: life.Life,

	_instance: InputBinding?,
}

export type Action = {
	identifier: string,
	actionType: Enum.InputActionType,
	life: life.Life,
	bindings: { [string]: Binding },

	data: ActionData,

	_instance: InputAction,
}

export type Context = {
	identifier: string,
	life: life.Life,
	actions: { [string]: Action },

	_instance: InputContext,
}

export type Manager = setmetatable<{
	folder: Folder,
	contexts: { [string]: Context },
}, typeof(inputManager)>

function inputManager.new(): Manager
	print(1)

	local self = setmetatable({}, inputManager) :: Manager
	local playerGui = LocalPlayer:WaitForChild("PlayerGui")

	local contextsFolder = (function()
		local folder = playerGui:FindFirstChild("Contexts") or Instance.new("Folder")

		folder.Name = "KeyContexts"
		folder.Parent = playerGui

		return folder
	end)()

	self.folder = contextsFolder :: Folder
	self.contexts = {}

	return self
end

export type ContextData = {
	identifier: string,
}

function inputManager.createContext(self: Manager, data: ContextData): Context?
	if not self or not data.identifier then
		return nil
	end

	self.contexts = self.contexts or {}

	if self.contexts[data.identifier] then
		return nil
	end

	local contextLife = Life.new()
	local contextInstance = Instance.new("InputContext")

	contextInstance.Name = data.identifier
	contextInstance.Parent = self.folder

	local inputContext: Context = {
		identifier = data.identifier,
		life = contextLife,
		actions = {},

		_instance = contextInstance,
	}

	self.contexts[data.identifier] = inputContext

	return inputContext
end

export type ActionData = {
	identifier: string,
	actionType: Enum.InputActionType,

	pressed: (...any) -> ()?,
	released: (...any) -> ()?,
	changed: (...any) -> ()?,
}

export type ActionAttachments = {
	context: Context,
}

function inputManager.attachAction(self: Manager, data: ActionData, attachments: ActionAttachments): Action?
	if not self or not attachments then
		return nil
	end

	self.contexts = self.contexts or {}

	local actionInstance = Instance.new("InputAction")

	actionInstance.Name = data.identifier
	actionInstance.Parent = attachments.context._instance

	local actionLife = attachments.context.life:extend()
	local inputAction: Action = {
		identifier = data.identifier,
		actionType = data.actionType,
		life = actionLife,
		bindings = {},

		data = data,

		_instance = actionInstance,
	}

	actionLife:add(actionInstance)

	actionLife:add(function()
		actionInstance.Pressed:Connect(function(...)
			print("aaaaaaaaaa")
			if data.pressed then
				data.pressed(...)
			end
		end)

		actionInstance.Released:Connect(function(...)
			if data.released then
				data.released(...)
			end
		end)

		actionInstance.StateChanged:Connect(function(...)
			if data.changed then
				data.changed(...)
			end
		end)
	end)

	attachments.context.actions[data.identifier] = inputAction

	self.contexts[attachments.context.identifier] = attachments.context

	return inputAction
end

export type BindingData = {
	identifier: string,
	keybind: Keybind,
}

export type BindingAttachments = {
	context: Context,
	action: Action,
}

function inputManager.attachBinding(self: Manager, data: BindingData, attachments: BindingAttachments): Binding?
	if not self or not data or not attachments then
		return nil
	end

	self.contexts = self.contexts or {}

	local actions = attachments.context.actions or {}

	if actions[data.identifier] then
		return nil
	end

	local bindingLife = attachments.action.life:extend()

	local bindingInstance: InputBinding? = nil

	if Enum.KeyCode:FromName(data.keybind.Name) then
		bindingInstance = Instance.new("InputBinding")

		bindingInstance.Name = data.identifier
		bindingInstance.KeyCode = data.keybind :: any

		bindingInstance.Parent = attachments.action._instance

		bindingLife:add(bindingInstance)
	end

	local inputBinding: Binding = {
		identifier = data.identifier,
		keybind = data.keybind,
		life = bindingLife,

		_instance = bindingInstance,
	}

	attachments.action.bindings[data.identifier] = inputBinding
	attachments.context.actions[attachments.action.identifier] = attachments.action

	self.contexts[attachments.context.identifier] = attachments.context

	return inputBinding
end

return inputManager
