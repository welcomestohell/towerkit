local Attribute = require "@libs/attributes/Attribute"
local gt = require "@libs/vendor/gt"
local threadpool = require "./threadpool"

const Delay = Attribute.new("Delay", gt.positiveNumber, 0)

const function emit(instance: Instance)
	if instance:IsA "ParticleEmitter" then instance:Emit(instance.Rate) end

	if instance:IsA "Sound" then instance:Play() end
end

const function emitTaggedDescendants(parent: Instance, tag: string)
	for _, descendant in parent:GetDescendants() do
		if descendant:HasTag(tag) then threadpool.spawn(emit, descendant) end
	end
end

return table.freeze {
	Delay = Delay,

	emit = emit,
	emitTaggedDescendants = emitTaggedDescendants,
}
