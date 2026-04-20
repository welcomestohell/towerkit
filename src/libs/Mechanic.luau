local HttpService = game:GetService("HttpService")

local Attribute = require("@libs/Attribute")
local AttributeMap = require("@libs/AttributeMap")
local Life = require("@libs/memory/Life")
local Log = require("./Log")
local Result = require("@libs/Result")
local functions = require("@libs/functions")
local gt = require("@libs/gt")

--[=[
	@interface MechanicImplementationMetadata

	Additional metadata attached to a `MechanicImplementation`. 

	This is primarially used for Welcome To Hell's Debugger, the Hyperborea
	plugin, and the Kitnomicon documentation.
]=]
export type MechanicImplementationMetadata = {
	currentAttributeSection: string?,
	attributeSections: { string },
	attributes: { Attribute.Attribute<any> },
	sectionByAttribute: { [Attribute.Attribute<any>]: string? },
}

--[=[
	@interface Mechanic<Self>

	An instance loaded in a `Level` with user-implemented behavior as defined by a
	`MechanicImplementation`.
]=]
export type Mechanic<Self, Mixin = {}> = Self & Mixin & {
	life: Life.Life,
	log: Log.Log,
	id: string,
	implementation: Self,
	instance: index<Self, "instanceType">,
	instanceConfiguration: Instance,
}

--[=[
	@interface MechanicImplementation

	Represents the implementation of a `Mechanic` used in a `Level`.
]=]
export type MechanicImplementation = {
	[unknown]: unknown,

	basename: string,
	instanceType: gt.Type,

	debuggerEmoji: string,

	onPreRender: (self: any, deltaTime: number, level: any) -> ()?,
	onPreAnimation: (self: any, deltaTime: number, level: any) -> ()?,
	onPreSimulation: (self: any, deltaTime: number, level: any) -> ()?,
	onPostSimulation: (self: any, deltaTime: number, level: any) -> ()?,

	onInit: (self: any, level: any) -> ()?,
	onStart: (self: any, mechanic: Mechanic<any>, level: any) -> ()?,
	onActivate: (self: any, mechanic: Mechanic<any>, level: any) -> ()?,
	onDeactivate: (self: any, mechanic: Mechanic<any>, level: any) -> ()?,
}

--[=[
	@class Mechanic
	@tag Library
]=]
local Mechanic = {}
Mechanic.__index = Mechanic
Mechanic._metadata = {} :: { [{}]: MechanicImplementationMetadata }
Mechanic._proxies = {} :: { [{}]: {} }
Mechanic.Enabled = Attribute.new("Enabled", gt.boolean(), false)

export type MechanicImplementationLike<Self = {}> = setmetatable<Self, typeof(Mechanic)>

local function initializeProxy(implementation: {})
	local proxy = {}
	proxy.__index = implementation
	proxy.__newindex = implementation

	function proxy.__tostring(self: Mechanic<MechanicImplementation>)
		return `{self.implementation.basename}({(self.instance :: any):GetFullName()})`
	end

	Mechanic._proxies[implementation] = proxy
	return proxy
end

function Mechanic.new<T>(implementation: T): setmetatable<T, typeof(Mechanic)>
	local metadata: MechanicImplementationMetadata = {
		attributeSections = {},
		attributes = {},
		sectionByAttribute = {},
	}

	local implementation: any = setmetatable(implementation, Mechanic)
	Mechanic._metadata[implementation] = metadata
	implementation:attributeSection("Configuration")
	initializeProxy(implementation)
	return implementation
end

function Mechanic.tryMechanize<Self>(
	implementation: Self,
	outerLife: Life.Life,
	instance: Instance
): Result.Result<Mechanic<Self>, { id: "invalidInstance", cause: gt.Cause }>
	local implementation = Mechanic.downcast(implementation)

	local instanceConfiguration = instance
	if instance.ClassName == "Configuration" and instance.Parent then
		instanceConfiguration, instance = instance, instance.Parent
	end

	if implementation.instanceType then
		local instanceType = gt.build(implementation.instanceType)
		local isValid, reason = instanceType:matches(instance)
		if not isValid then
			return Result.Err({ id = functions.literal("invalidInstance"), cause = reason })
		end
	end

	local mechanicLife = outerLife:extend()
	mechanicLife:add(instance)
	mechanicLife:destroyOn(instance.Destroying)

	local mechanic = setmetatable({
		life = mechanicLife,
		id = HttpService:GenerateGUID(false),
		implementation = implementation,
		instance = instance,
		instanceConfiguration = instanceConfiguration,
	}, Mechanic._proxies[implementation])
	mechanic.log = Log.new(mechanic)

	return Result.Ok(mechanic :: any)
end

function Mechanic.isMechanicImplementation(x: any)
	return typeof(x) == "table" and getmetatable(x) == Mechanic
end

function Mechanic.downcast(self: {}): setmetatable<MechanicImplementation, typeof(Mechanic)>
	return self :: any
end

function Mechanic.getMetadata(self: {}): MechanicImplementationMetadata
	return Mechanic._metadata[self]
end

function Mechanic.attributeSection(self: {}, section: string)
	Mechanic._metadata[self].currentAttributeSection = section
end

function Mechanic.attribute<T>(self: {}, name: string, type: T, default: T): Attribute.Attribute<T>
	local attribute = Attribute.new(name, type, default)
	table.insert(Mechanic._metadata[self].attributes, attribute)
	Mechanic._metadata[self].sectionByAttribute[attribute] = Mechanic._metadata[self].currentAttributeSection
	return attribute
end

function Mechanic.withAttribute<T>(self: {}, attribute: Attribute.Attribute<T>): Attribute.Attribute<T>
	table.insert(Mechanic._metadata[self].attributes, attribute)
	Mechanic._metadata[self].sectionByAttribute[attribute] = Mechanic._metadata[self].currentAttributeSection
	return attribute
end

function Mechanic.withEnabled(self: {}): Attribute.Attribute<boolean>
	return Mechanic.withAttribute(self :: any, Mechanic.Enabled)
end

function Mechanic.withActive(self: {}): Attribute.Attribute<boolean>
	return Mechanic.attribute(self :: any, "Active", gt.boolean(), false)
end
function Mechanic.prefixedAttributeMap<T>(self: {}, prefix: string, type: T): AttributeMap.AttributeMap<T>
	local map = AttributeMap.fromPrefix(prefix, type)
	return map
end

function Mechanic.__tostring(self: MechanicImplementation)
	return self.basename
end

return table.freeze(Mechanic)
