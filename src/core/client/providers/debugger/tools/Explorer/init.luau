local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local MaterialService = game:GetService("MaterialService")
local Players = game:GetService("Players")
local ReflectionService = game:GetService("ReflectionService")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local StarterGui = game:GetService("StarterGui")
local StarterPack = game:GetService("StarterPack")
local StarterPlayer = game:GetService("StarterPlayer")
local Teams = game:GetService("Teams")
local TextChatService = game:GetService("TextChatService")
local Workspace = game:GetService("Workspace")

type ReflectedProperty = {
	-- The name of the property.
	Name: string,
	-- Whether the property is serialized (able to be saved to disk or sent over the network).
	Serialized: boolean,
	-- The type of the property.
	Type: {
		EngineType: string,
		ScriptType: string,
	},
	-- The content type of the property, if applicable.
	ContentType: Enum.AssetType?,
	-- Studio display information.
	Display: {
		-- The category under which the property is listed in Studio.
		Category: string,
		-- A message indicating that the property is deprecated, if applicable.
		DeprecationMessage: string?,
		-- The order in which the property appears in Studio.
		LayoutOrder: number,
	},
	-- The security permissions required to access this property.
	Permits: {
		-- The security context required to read this property.
		Read: SecurityCapabilities?,
		-- The security context required to read this property while thread-safe.
		ReadParallel: SecurityCapabilities?,
		-- The security context required to write to this property.
		Write: SecurityCapabilities?,
		-- The security context required to write to this property while thread-safe.
		WriteParallel: SecurityCapabilities?,
	},
}

local DebuggerStore = require("@core/client/providers/debugger/DebuggerStore")
local Iris = require("@libs/Iris")
local Life = require("@libs/memory/Life")
local icons = require("@self/icons")

local CARET_COLLAPSED = "▶"
local CARET_EXPANDED = "▼"
local SPACE = " "

local CARET_SIZE = UDim2.fromOffset(20, 16)

local EMPTY = table.freeze({})

local SERVICES = {
	Workspace,
	Players,
	CoreGui,
	Lighting,
	MaterialService,
	ReplicatedFirst,
	ReplicatedStorage,
	StarterGui,
	StarterPack,
	StarterPlayer,
	Teams,
	SoundService,
	TextChatService,
}

local Explorer = {}
Explorer.__index = Explorer
Explorer.title = "Explorer"

export type Explorer = setmetatable<{
	life: Life.Life,
	selectedInstance: Instance?,
	expandedInstances: { [Instance]: true? },
	instanceIds: { [Instance]: string },
	classProperties: { [string]: { ReflectedProperty } },
}, typeof(Explorer)>

local function formatInstanceLabel(instance: Instance)
	return `{icons[instance.ClassName] or icons.DEFAULT} {instance.Name}`
end

local function compareInstances(left: Instance, right: Instance): boolean
	local leftClass, rightClass = left.ClassName, right.ClassName
	return if leftClass == rightClass then left.Name < right.Name else leftClass < rightClass
end

local function compareReflectedProperties(left: ReflectedProperty, right: ReflectedProperty): boolean
	return (left.Name or "") < (right.Name or "")
end

function Explorer.new(life: Life.Life): Explorer
	return setmetatable({
		life = life,
		expandedInstances = {},
		selectedInstance = nil :: Instance?,
		instanceIds = {},
		classProperties = {},
	}, Explorer)
end

function Explorer.getInstanceId(self: Explorer, instance: Instance)
	local id = self.instanceIds[instance]
	if not id then
		id = HttpService:GenerateGUID()
		self.instanceIds[instance] = id
	end
	return id
end

function Explorer.getClassProperties(self: Explorer, className: string): { ReflectedProperty }
	local properties: { ReflectedProperty } = self.classProperties[className]
	if not properties then
		properties = table.clone(ReflectionService:GetPropertiesOfClass(className) or EMPTY) :: { ReflectedProperty }
		table.sort(properties, compareReflectedProperties)
		self.classProperties[className] = properties :: any
	end
	return properties
end

function Explorer.renderInstance(self: Explorer, instance: Instance)
	Iris.SetNextWidgetID(self:getInstanceId(instance))
	Iris.SameLine({ 0 })
	local children = instance:GetChildren()
	local isOrphan = #children == 0

	local hasExpanded = false
	if isOrphan then
		Iris.Image({ "rbxassetid://0", [Iris.Args.Image.Size] = CARET_SIZE })
	else
		local expandButton = Iris.Button({
			if isOrphan then SPACE else if self.expandedInstances[instance] then CARET_EXPANDED else CARET_COLLAPSED,
			[Iris.Args.Button.Size] = CARET_SIZE,
		})

		hasExpanded = expandButton.clicked()
	end

	local selectButton = Iris.Button({ formatInstanceLabel(instance), [Iris.Args.Button.Size] = UDim2.fromScale(1, 0) });
	(selectButton.Instance :: TextLabel).TextXAlignment = Enum.TextXAlignment.Left
	if hasExpanded or selectButton.doubleClicked() then
		self.expandedInstances[instance] = if self.expandedInstances[instance] then nil else true
	elseif selectButton.clicked() then
		self.selectedInstance = instance
	end
	Iris.End()

	if self.expandedInstances[instance] then
		if isOrphan then
			self.expandedInstances[instance] = nil
		else
			table.sort(children, compareInstances)
			Iris.SetNextWidgetID("Children" .. self:getInstanceId(instance))
			Iris.Indent()
			for _, child in children do
				self:renderInstance(child)
			end
			Iris.End()
		end
	end
end

function Explorer.renderInspector(self: Explorer, old: Instance?, instance: Instance)
	local window = Iris.Window({ "Inspector" })
	if window.closed() then
		Iris.End()
		window.state.isOpened:set(true)
		self.selectedInstance = nil
		return
	end

	if old ~= instance then
		Iris.SetFocusedWindow(window)
	end

	Iris.SameLine()
	Iris.Text({ formatInstanceLabel(instance) })
	if instance.Name ~= instance.ClassName then
		Iris.Text({ `<font transparency="0.5">{instance.ClassName}</font>` })
	end
	if Iris.Button({ "Destroy" }).clicked() then
		Iris.End()
		Iris.End()
		pcall(game.Destroy, instance)
		self.selectedInstance = nil
		self.expandedInstances[instance] = nil
		return
	end
	Iris.End()

	Iris.Table({ 2 })
	for _, property in self:getClassProperties(instance.ClassName) do
		Iris.Text({ property.Name })
		Iris.NextColumn()
		Iris.Text({ "???" })
		Iris.NextColumn()
	end
	Iris.End()

	Iris.End()
end

function Explorer.renderWindow(self: Explorer)
	self.expandedInstances = table.clone(DebuggerStore.explorerExpandedInstances())
	self.selectedInstance = DebuggerStore.explorerSelectedInstance()
	local oldSelectedInstance = self.selectedInstance

	Iris.PushConfig({ ButtonTransparency = 1, ItemSpacing = Vector2.zero } :: Iris.Config)
	Iris.Group()
	for _, service in SERVICES do
		self:renderInstance(service)
	end
	Iris.End()
	Iris.PopConfig()

	if self.selectedInstance then
		self:renderInspector(oldSelectedInstance, self.selectedInstance)
	end

	DebuggerStore.explorerExpandedInstances(self.expandedInstances)
	DebuggerStore.explorerSelectedInstance(self.selectedInstance)
end

return Explorer
