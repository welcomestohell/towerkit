local CollectionService = game:GetService("CollectionService")

local Attribute = require("./Attribute")
local Level = require("./Level")
local activation = require("./activation")
local character = require("./character")
local functions = require("./functions")
local properties = require("./properties")
local roblox = require("@core/shared/generated/types/roblox")
local tables = require("@libs/collections/tables")
local tweens = require("@libs/tweens")

export type EvaluationContext = {
	level: Level.Level,
	transformerInstance: Instance,
	transformerConfiguration: Instance,
	activationEvent: activation.ActivationEvent,
}

export type StaticValue = { value: unknown }
export type Evaluator<Returns = unknown> = (context: EvaluationContext) -> Returns
export type Evaluation<Returns = unknown> = { evaluator: Evaluator<Returns> }
export type Transformation = StaticValue | Evaluation

-- molly im really sorry for this shit ass code im better than this
-- update april 8th i got friendzoned </3
local function createHierachyMethod(method)
	-- 𒅒𒈔𒅒𒇫𒄆̼͙̈́͆̈́ͯ̒̆̀̓ͧ͠𒀱҈  ҉ ҈  ҉ ҈  ҉FUCK THIS SHIT
	return function<I>(self: Transformer<I>, ...): Transformer<Instance>
		self = self:clone()

		local args = table.pack(... :: any)
		local resolver = self.resolver

		function self.resolver(context: EvaluationContext): Instance | { Instance } | nil
			local resolved = resolver(context)

			local type = typeof(resolved)
			if type == "Instance" then
				return method(resolved, table.unpack(args, 1, args.n))
			elseif type == "table" then
				local result: { any } = {}
				for index, instance in resolved do
					local instances: any = method(instance, table.unpack(args, 1, args.n))
					if typeof(instances) == "Instance" then
						table.insert(result, instances)
					elseif instances ~= nil then
						table.move(instances, 1, #instances, #result + 1, result)
					end
				end
				return result
			else
				return nil
			end
		end

		return self
	end
end

--[=[
	@class Transformer
	@tag Library

	TBA
]=]
local Transformer = {}
Transformer.__index = Transformer

export type Transformer<I = Instance> = setmetatable<{
	instanceType: (unknown) -> I,
	resolver: (context: EvaluationContext) -> any,
	tweenConfiguration: tweens.TweenConfiguration,
	properties: { [string]: Transformation },
	attributes: { [string]: Transformation },
}, typeof(Transformer)>

export type Transformers = {
	kind: "concurrent" | "sequential",
	transformers: { Transformer<any> },
}

local function setStaticValue<I>(transformer: Transformer<I>, map: { [string]: any }, property: string, value: unknown)
	map[property] = { value = value }
	return transformer
end

local function setEvaluation<I, E>(
	transformer: Transformer<I>,
	map: { [string]: any },
	property: string,
	evaluator: Evaluator<E>
)
	if type(evaluator) == "function" then
		map[property] = { evaluator = evaluator :: any }
		return transformer
	end

	error(`Expected function to evaluate {property}, got {typeof(evaluator)}`)
end

function Transformer.new(resolver: (context: EvaluationContext) -> Instance | { Instance } | nil): Transformer<any>
	return setmetatable({
		instanceType = functions.identity,
		resolver = resolver,
		tweenConfiguration = {} :: tweens.TweenConfiguration,
		properties = {},
		attributes = {},
	}, Transformer)
end

function Transformer.clone<I>(self: Transformer<I>): Transformer<I>
	return setmetatable({
		instanceType = functions.identity,
		resolver = self.resolver,
		tweenConfiguration = table.clone(self.tweenConfiguration),
		properties = table.clone(self.properties),
		attributes = table.clone(self.attributes),
	}, Transformer)
end

--[=[
	Constructs a transformer that affects itself.
]=]
function Transformer.fromSelf(): Transformer<Instance>
	return Transformer.new(function(context: EvaluationContext)
		return context.instance
	end)
end

--[=[
	Constructs a transformer that affects the specified instance.
]=]
function Transformer.fromInstance(instance: Instance): Transformer<Instance>
	return Transformer.new(function(context: EvaluationContext)
		return instance
	end)
end

--[=[
	Constructs a transformer that affects the topmost instance of the current
	level.
]=]
function Transformer.fromLevel(): Transformer<Instance>
	return Transformer.new(function(context: EvaluationContext)
		return context.level.instance
	end)
end

--[=[
	Constructs a transformer that affects a `Target` ObjectValue under the
	transformer.
]=]
function Transformer.fromTargetValue(tag: string)
	return Transformer.new(function(context: EvaluationContext)
		local targetValue = context.instanceConfiguration:FindFirstChild("Target")
			or context.instance:FindFirstChild("Target")

		return if targetValue and targetValue:IsA("ObjectValue") then targetValue.Value else nil
	end)
end

--[=[
	Constructs a transformer that affects applicable touched parts when
	activated.
]=]
function Transformer.fromTouchActivator(): Transformer<BasePart>
	return Transformer.new(function(context: EvaluationContext)
		local activationEvent: any = context.activationEvent
		return if activationEvent.kind == "Touch" then activationEvent.toucher else nil
	end)
end

--[=[
	Constructs a transformer that affects all instances with the given tag
	under the level.
]=]
function Transformer.fromTagged(tag: string): Transformer<Instance>
	return Transformer.new(function(context: EvaluationContext)
		local result = {}

		for _, tagged in CollectionService:GetTagged(tag) do
			if tagged:IsDescendantOf(context.level.instance) then
				table.insert(result, tagged)
			end
		end

		return result
	end)
end

--[=[
	Constructs a transformer that affects all specified limbs of the
	player's character.
]=]
function Transformer.fromCharacterLimbs(limb: Enum.Limb, ...: Enum.Limb): Transformer<BasePart>
	local limbs = table.pack(limb, ...)

	return Transformer.new(function(context: EvaluationContext)
		local c = character.getMaybeCharacter()
		if c == nil then
			return nil
		end

		local result = {}

		for _, limbEnum in limbs do
			local limbName = character.LIMB_MAP[limbEnum]
			if limbName == nil then
				continue
			end

			local realLimb = c:FindFirstChild(limbName)
			if realLimb and realLimb:IsA("BasePart") then
				table.insert(result, realLimb)
			end
		end

		return result
	end)
end

function Transformer.setTweenConfiguration<I>(
	self: Transformer<I>,
	partialConfiguration: tables.Partial<tweens.TweenConfiguration>
)
	type TweenConfiguration = { [keyof<tweens.TweenConfiguration>]: any }

	for key, value in partialConfiguration :: TweenConfiguration do
		(self.tweenConfiguration :: TweenConfiguration)[key] = value
	end

	return self
end

function Transformer.setTweenInfo<I>(self: Transformer<I>, tweenInfo: TweenInfo)
	self.tweenConfiguration.delayDuration = tweenInfo.DelayTime
	self.tweenConfiguration.direction = tweenInfo.EasingDirection
	self.tweenConfiguration.duration = tweenInfo.Time
	self.tweenConfiguration.isReversed = tweenInfo.Reverses
	self.tweenConfiguration.repeatCount = tweenInfo.RepeatCount
	self.tweenConfiguration.style = tweenInfo.EasingStyle

	return self
end

-- LUAU FIXME: indexing generics dont work rahh

function Transformer.setProperty<I, K>(self: Transformer<I>, property: K | keyof<I>, value: unknown)
	return setStaticValue(self, self.properties, property, value)
end

function Transformer.setEvaluatedProperty<I, K>(self: Transformer<I>, property: K | keyof<I>, evaluator: Evaluator)
	return setEvaluation(self, self.properties, property, evaluator)
end

function Transformer.setAttribute<I>(self: Transformer<I>, attribute: string, value: Attribute.AttributeValue?)
	return setStaticValue(self, self.attributes, attribute, value)
end

function Transformer.setEvaluatedAttribute<I>(
	self: Transformer<I>,
	attribute: string,
	evaluator: Evaluator<Attribute.AttributeValue?>
)
	return setEvaluation(self, self.attributes, attribute, evaluator)
end

function Transformer.useTransformation(self: Transformer, context: EvaluationContext, transformation: Transformation)
	local asStaticValue, asEvaluator = transformation :: StaticValue, transformation :: Evaluation
	return if asEvaluator.evaluator then asEvaluator.evaluator(context) else asStaticValue.value
end

-- TODO: tweening for attributes
function Transformer.applyContext(self: Transformer, context: EvaluationContext)
	local duration = self.tweenConfiguration.duration or 0

	if duration == 0 then
		for property, transformation in self.properties do
			properties.setUnsafe(context.instance, property, self:useTransformation(context, transformation))
		end
	else
		local propertyTable = {}
		for property, transformation in self.properties do
			propertyTable[property] = self:useTransformation(context, transformation)
		end

		tweens.playAlways(context.instance, propertyTable, self.tweenConfiguration)
	end

	for attribute, transformation in self.attributes do
		context.instance:SetAttribute(attribute, self:useTransformation(context, transformation))
	end
end

-- TODO: tweening for attributes
function Transformer.resolveAndApply(self: Transformer, context: EvaluationContext) end

-- LUAU FIXME: recursion limits, have to downcast self
type VoidBuilder = (self: unknown) -> Transformer<Instance>
type NameBuilder = (self: unknown, name: string) -> Transformer<Instance>
type ClassNameBuilder = <K>(
	self: unknown,
	className: K | keyof<roblox.Instances>
) -> Transformer<index<roblox.Instances, K>>

Transformer.withChildren = createHierachyMethod(game.GetChildren) :: VoidBuilder
Transformer.withNamedChild = createHierachyMethod(game.FindFirstChild) :: NameBuilder
Transformer.withChildOfClass = createHierachyMethod(game.FindFirstChildOfClass) :: ClassNameBuilder
Transformer.withChildWhichIsA = createHierachyMethod(game.FindFirstChildWhichIsA) :: ClassNameBuilder

Transformer.withNamedAncestor = createHierachyMethod(game.FindFirstAncestor) :: NameBuilder
Transformer.withAncestorOfClass = createHierachyMethod(game.FindFirstAncestorOfClass) :: ClassNameBuilder
Transformer.withAncestorWhichIsA = createHierachyMethod(game.FindFirstAncestorWhichIsA) :: ClassNameBuilder

Transformer.withDescendants = createHierachyMethod(game.GetDescendants) :: NameBuilder
Transformer.withNamedDescendant = createHierachyMethod(function(self, name)
	return game.FindFirstChild(self, name, true)
end) :: NameBuilder

return Transformer
