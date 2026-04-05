local Attribute = require("./Attribute")
local Level = require("./Level")
local LevelState = require("./LevelState")
local Life = require("@libs/memory/Life")
local Mechanic = require("./Mechanic")
local activation = require("./activation")
local gt = require("./gt")
local sounds = require("./sounds")
local tweens = require("./tweens")

export type Mechanic<Self = any, Mixin = {}> = Mechanic.Mechanic<Self, Mixin>
export type MechanicImplementation = Mechanic.MechanicImplementation
export type MechanicImplementationLike = Mechanic.MechanicImplementationLike
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

	The standard library is kept as small as possible to focus on things
	that are most frequently used for tower scripting.
]=]
return table.freeze {
	Mechanic = Mechanic.new,
	Attribute = Attribute.new,
	Life = Life.new,
	LevelState = LevelState.new,

	useActivation = activation.useAttributes,
	useSound = sounds.useAttributes,
	useTween = tweens.useAttributes,

	gt = gt,
	isA = gt.isA,
}
