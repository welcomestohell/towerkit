local Attribute = require "@libs/attributes/Attribute"
const AttributeMap = require "@libs/attributes/AttributeMap"
const AttributeSection = require "@libs/attributes/AttributeSection"
local Level = require "@libs/core/Level"
local LevelState = require "@libs/core/LevelState"
local Life = require "@libs/memory/Life"
local Mechanic = require "@libs/core/Mechanic"
local gt = require "@libs/vendor/gt"

export type AnyMechanicImplementation = Mechanic.AnyMechanicImplementation
export type Mechanic<Self = any, Mixin = {}> = Mechanic.Mechanic<Self, Mixin>
export type MechanicImplementation<Self = any> = Mechanic.MechanicImplementation<Self>
export type MechanicImplementationMetadata = Mechanic.MechanicImplementationMetadata

export type Level = Level.Level

export type LevelState<T> = LevelState.LevelState<T>
export type Attribute<T> = Attribute.Attribute<T>

export type Life = Life.Life

--[=[
	@class std
	@tag Library

	Welcome To Hell comes with a variety of things in it's libraries. However,
	if you had to manually import every single thing that you used, it would be
	very verbose. But importing a lot of things that a script never uses isn’t
	good either. A balance needs to be struck.

	The standard library is a minimal selection of APIs most frequently used in
	tower scripting.
]=]
return table.freeze {
	Mechanic = Mechanic.new,

	Life = Life.new,
	LevelState = LevelState.new,

	Attribute = Attribute.new,
	AttributeMap = AttributeMap.new,
	AttributeSection = AttributeSection.new,

	gt = gt,
	isA = gt.isA,
}
