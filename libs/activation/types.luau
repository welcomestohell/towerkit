local Attribute = require("@libs/Attribute")
local Life = require("@libs/memory/Life")
local Result = require("@libs/Result")
local gt = require("@libs/gt")
local touch = require("@libs/touch")

export type ActivationAttributes = {
	Enabled: Attribute.Attribute<boolean>,
	Mode: Attribute.Attribute<string?>,

	BaseName: Attribute.Attribute<string>,
	HumanoidStateType: Attribute.Attribute<Enum.HumanoidStateType?>,
	Interval: Attribute.Attribute<number?>,
	KeyCode: Attribute.Attribute<Enum.KeyCode?>,
	MaxDistance: Attribute.Attribute<number>,

	Touch: touch.TouchAttributes,
}

export type ActivationEvent =
	| { kind: "Click", detector: ClickDetector }
	| { kind: "Died" }
	| { kind: "Jumped" }
	| { kind: "HumanoidStateChanged", old: Enum.HumanoidStateType, new: Enum.HumanoidStateType }
	| { kind: "Prompt", prompt: ProximityPrompt }
	| { kind: "Touch", toucher: BasePart }
	| { kind: string, [unknown]: unknown }

export type PredicateContext = {
	instance: Instance,
	instanceConfiguration: Instance,
}

export type BindContext = PredicateContext & {
	instanceLife: Life.Life,
	onActivate: (context: ActivationContext, event: ActivationEvent) -> (),
	attributes: ActivationAttributes,
}

export type ActivationContext = BindContext & {
	activationLife: Life.Life,
}

local ActivationMode = gt.build(gt.table({
	predicate = gt.optional(gt.anyfn() :: (PredicateContext) -> Result.Result<nil, string>),
	implement = gt.anyfn() :: (ActivationContext) -> (),
}))

export type ActivationMode = typeof(ActivationMode:type())

return table.freeze {
	ActivationMode = ActivationMode,
}
