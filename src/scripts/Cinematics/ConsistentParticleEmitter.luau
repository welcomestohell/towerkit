local std = require("@libs/std")

local ConsistentParticleEmitter = std.Mechanic({})
export type ConsistentParticleEmitterMechanic = std.Mechanic<typeof(ConsistentParticleEmitter)>
ConsistentParticleEmitter.instanceTag = "ConsistentParticleEmitter"
ConsistentParticleEmitter.instanceType = std.isA.ParticleEmitter()
ConsistentParticleEmitter.debuggerEmoji = "✨"

ConsistentParticleEmitter.Rate = ConsistentParticleEmitter:attribute("Rate", std.gt.positiveNumber, 0)

ConsistentParticleEmitter.oldGraphicsLevel = -1
ConsistentParticleEmitter.fixed = {} :: { [ConsistentParticleEmitterMechanic]: true }

function ConsistentParticleEmitter.onInit(self: typeof(ConsistentParticleEmitter))
	self.oldGraphicsLevel = -1
	table.clear(self.fixed)
	self.fixed = {}
end

function ConsistentParticleEmitter.onPreRender(
	self: typeof(ConsistentParticleEmitter),
	deltaTime: number,
	level: std.Level
)
	local graphicsLevel = UserSettings().GameSettings.SavedQualityLevel.Value
	local isGraphicsLevelChanged = graphicsLevel == self.oldGraphicsLevel

	for _, emitter in level:getMechanics(self) do
		if isGraphicsLevelChanged or not emitter.fixed[emitter] then
			local rate = emitter.Rate:getOrSet(emitter, emitter.instance.Rate)
			emitter.instance.Rate = rate * 10 / graphicsLevel
			self.fixed[emitter] = true
		end
	end

	self.oldGraphicsLevel = graphicsLevel
end

return ConsistentParticleEmitter
