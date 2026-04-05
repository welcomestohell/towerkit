local Attribute = require("./Attribute")
local gt = require("./gt")
local threadpool = require("./threadpool")

local Delay = Attribute.new("Delay", gt.positiveNumber, 0)

local function emit(instance: Instance)
	task.wait(Delay:get(instance))

	if instance:IsA("ParticleEmitter") then
		instance:Emit(instance.Rate)
	end
end

local function emitTaggedDescendants(parent: Instance, tag: string)
	for _, descendant in parent:GetDescendants() do
		if descendant:HasTag(tag) then
			threadpool.spawn(emit, descendant)
		end
	end
end

return table.freeze {
	Delay = Delay,

	emit = emit,
	emitTaggedDescendants = emitTaggedDescendants,
}
