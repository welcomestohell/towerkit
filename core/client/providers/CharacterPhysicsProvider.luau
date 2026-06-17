local RunService = game:GetService "RunService"

local Life = require "@libs/memory/Life"
local character = require "@libs/character"
local prvd = require "@roblox_packages/prvd"

const DEFAULT_FPS = 1 / 60
const TRIGGER_FPS = 1 / 75
const STATES = {
	[Enum.HumanoidStateType.Jumping] = true,
	[Enum.HumanoidStateType.Climbing] = true,
	[Enum.HumanoidStateType.Freefall] = true,
	[Enum.HumanoidStateType.Landed] = true,
	[Enum.HumanoidStateType.Seated] = true,
	[Enum.HumanoidStateType.Swimming] = true,
	[Enum.HumanoidStateType.GettingUp] = true,
	[Enum.HumanoidStateType.FallingDown] = true,
	[Enum.HumanoidStateType.Ragdoll] = true,
	[Enum.HumanoidStateType.Flying] = true,
	[Enum.HumanoidStateType.PlatformStanding] = true,

	[Enum.HumanoidStateType.Running] = false,
}

-- TODO: port EnhancedCharacterPhysics v1
local CharacterPhysicsProvider = {}
export type CharacterPhysicsProvider = typeof(CharacterPhysicsProvider)

function CharacterPhysicsProvider.onLocalCharacterAdded(self: CharacterPhysicsProvider, character: character.Character)
	local life = Life.new()
	life:add(character)
	life:destroyOn(character.Destroying)

	local humanoid = character:WaitForChild "Humanoid" :: Humanoid
	local head = character:WaitForChild "Head" :: BasePart
	local fps: number

	-- Head collisions
	head.CanCollide = true
	life:add(character.Head:GetPropertyChangedSignal("CanCollide"):Connect(function()
		head.CanCollide = true
	end))

	-- Trusses
	local function onStateChanged(oldState: Enum.HumanoidStateType, newState: Enum.HumanoidStateType)
		if newState ~= oldState and STATES[newState] then
			for state, allowed in STATES do
				if allowed and state ~= newState then humanoid:SetStateEnabled(state, false) end
			end
			task.wait(DEFAULT_FPS - fps)
			for state, allowed in STATES do
				if allowed and state ~= newState then humanoid:SetStateEnabled(state, true) end
			end
		end
	end

	local stateConnection: RBXScriptConnection?
	RunService.Heartbeat:Connect(function(delta: number)
		debug.profilebegin "CharacterPhysicsProvider: Trusses"

		if delta < TRIGGER_FPS then
			fps = delta
			if stateConnection == nil then stateConnection = life:add(humanoid.StateChanged:Connect(onStateChanged)) end
		elseif delta > TRIGGER_FPS and stateConnection ~= nil then
			stateConnection:Disconnect()
			life:remove(stateConnection)
			stateConnection = nil
		end

		debug.profileend()
	end)
end

return prvd(CharacterPhysicsProvider)
