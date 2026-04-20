local Attribute = require("@libs/Attribute")
local Life = require("@libs/memory/Life")
local Log = require("@libs/Log")
local types = require("@libs/types")

export type AttributeSection = {
	title: string?,
	attributes: { Attribute.Attribute<any> },
}

export type MechanicImplementationMetadata = {
	currentAttributeSection: AttributeSection,
	attributeSections: { AttributeSection },
}

export type Mechanic<Implementation = any, Mixin = {}> = Implementation & Mixin & {
	life: Life.Life,
	log: Log.Log,
	id: string,
	implementation: Implementation,
	instance: index<Implementation, "instanceType">,
	instanceConfiguration: Instance,
}

export type AnyMechanicImplementation = {
	basename: string,
	instanceType: Instance,

	debuggerEmoji: string,

	onPreRender: (self: any, deltaTime: number, level: any) -> ()?,
	onPreAnimation: (self: any, deltaTime: number, level: any) -> ()?,
	onPreSimulation: (self: any, deltaTime: number, level: any) -> ()?,
	onPostSimulation: (self: any, deltaTime: number, level: any) -> ()?,

	onInit: (self: any, level: any) -> ()?,
	onStart: (self: any, mechanic: Mechanic<any>, level: any) -> ()?,
	onActivate: (self: any, mechanic: Mechanic<any>, level: any, activationEvent: any) -> ()?,
}

local MechanicImplementation = {}
MechanicImplementation.__index = MechanicImplementation

-- Instance properties can't be defined on MechanicImplementation because it
-- breaks metatable typing...
MechanicImplementation._proxy = types.any :: {}
MechanicImplementation._metadata = types.any :: MechanicImplementationMetadata

export type MechanicImplementation<Self = {}> = setmetatable<Self, typeof(MechanicImplementation)>

function MechanicImplementation.new<Self>(self: Self): MechanicImplementation<Self>
	local implementation: any = setmetatable(self, MechanicImplementation)

	local firstSection: AttributeSection = { attributes = {} }

	local metadata: MechanicImplementationMetadata = {
		currentAttributeSection = firstSection,
		attributeSections = { firstSection },
	}

	implementation._metadata = metadata

	local proxy = {
		__newindex = rawset,
	}

	-- Investigate: we could get rid of the closure by storing implementation
	-- on the proxy and then using getmetatable
	function proxy.__index(self: any, key: any)
		local value = rawget(self, key)
		return if value == nil then implementation[key] else value
	end

	function proxy.__tostring(self: Mechanic<AnyMechanicImplementation>)
		return `{self.implementation.basename}({self.instance:GetFullName()})`
	end

	implementation._proxy = proxy

	return implementation
end

function MechanicImplementation.isMechanicImplementation(x: any)
	return typeof(x) == "table" and getmetatable(x) == MechanicImplementation
end

function MechanicImplementation.downcast(self: {}): MechanicImplementation<AnyMechanicImplementation>
	return self :: any
end

function MechanicImplementation.attributeSection(self: {}, title: string)
	self = MechanicImplementation.downcast(self)

	local section: AttributeSection = { title = title, attributes = {} }
	self._metadata.currentAttributeSection = section
	table.insert(self._metadata.attributeSections, section)
end

function MechanicImplementation.attribute<T>(self: {}, name: string, type: T, default: T): Attribute.Attribute<T>
	self = MechanicImplementation.downcast(self)

	local attribute = Attribute.new(name, type, default)
	table.insert(self._metadata.currentAttributeSection.attributes, attribute)
	return attribute
end

function MechanicImplementation.basename(self: {})
	self = MechanicImplementation.downcast(self)
	return `Mechanic: {self.basename}`
end

function MechanicImplementation.__tostring(self: AnyMechanicImplementation)
	return self.basename
end

return table.freeze(MechanicImplementation)
