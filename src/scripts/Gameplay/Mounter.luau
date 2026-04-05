local Attribute = require("@libs/Attribute")
local activation = require("@libs/activation")
local character = require("@libs/character")
local constraints = require("@libs/constraints")
local destroy = require("@libs/destroy")
local std = require("@libs/std")

local LIMB_MAP: { [Enum.Limb]: string } = {
	[Enum.Limb.Torso] = "HumanoidRootPart",
	[Enum.Limb.LeftArm] = "Left Arm",
	[Enum.Limb.RightArm] = "Right Arm",
	[Enum.Limb.LeftLeg] = "Left Leg",
	[Enum.Limb.RightLeg] = "Right Leg",
	[Enum.Limb.Head] = "Head",
}

--[=[
    @class Mounter
    @tag Mechanic

    Welds the mounter's model onto the player's HumanoidRootPart. Unlike
    Followers, mounted models are physically attached to the player. Therefore, 
    collisions on the mounted model also affects the player.
]=]
local Mounter = std.Mechanic({})
export type MounterMechanic = std.Mechanic<typeof(Mounter)> & { model: BasePart | Model }
Mounter.instanceTag = "Attacher"
Mounter.instanceType = std.gt.instanceTree({
	MounterActivator = std.isA.Instance(),
	MounterModel = std.gt.union2(std.isA.BasePart(), std.isA.Model()),
})
Mounter.debuggerEmoji = "🔌"

Mounter.Enabled = Mounter:withEnabled()
Mounter.Cooldown = Mounter:attribute("Cooldown", std.gt.positiveNumber, 0)
Mounter.CleanupDelay = Mounter:attribute("CleanupDelay", std.gt.positiveNumber, 1)
Mounter.Debounced = Mounter:attribute("Debounced", std.gt.boolean(), false)
Mounter.Offset = Mounter:attribute("Offset", std.gt.CFrame(), CFrame.identity)
Mounter.Limb = Mounter:attribute("Target", std.gt.enumOf(Enum.Limb) :: Enum.Limb, Enum.Limb.Torso)

Mounter:attributeSection("Activation")
Mounter.Activation = activation.useAttributes(Mounter)

Mounter:attributeSection("Dismount")
Mounter.Dismount = activation.useAttributes(Mounter, "Dismount")

function Mounter:onStart(mounter: MounterMechanic)
	mounter.model = mounter.instance.MounterModel
	mounter.model.Parent = nil
end

function Mounter:onActivate(mounter: MounterMechanic)
	if not mounter:Enabled() then
		return
	end

	mounter.Activation.Enabled(mounter, false)

	local mountLife = mounter.life:extend()

	local cleanupLife = mountLife:extend()
	cleanupLife:add(function()
		task.delay(mounter:CleanupDelay(), destroy, mountLife)
	end)

	local model = mountLife:add(mounter.model:Clone())
	mountLife:destroyOn(model.Destroying)
	model.Parent = mounter.instance

	local weldTarget = if model:IsA("BasePart") then model else model.PrimaryPart
	if weldTarget then
		local limbName = LIMB_MAP[Mounter:Limb()]
		local weldLimb = limbName and character.getCharacter():FindFirstChild(limbName) :: BasePart?
			or mounter.log:error("Invalid Limb to weld.")

		if weldLimb then
			weldTarget:PivotTo(weldLimb.CFrame * mounter:Offset())
			constraints.weld(mountLife, weldTarget, weldLimb)

			cleanupLife:destroyOn(weldLimb.Destroying)
		end
	else
		mounter.log:error("MounterModel will not be welded as it's PrimaryPart is unset.")
	end

	activation.bindActivation({
		instance = mounter.instance,
		instanceConfiguration = mounter.instanceConfiguration or mounter.instance,
		instanceLife = mountLife,
		attributes = mounter.Dismount,

		onActivate = function(context: activation.ActivationContext)
			mountLife:destroy()
			task.delay(mounter:Cooldown(), Attribute.set :: any, mounter.Activation.Enabled, mounter, true)
		end,
	})

	cleanupLife:add(mounter.Enabled:onChange(mounter, function(isEnabled)
		if not isEnabled then
			cleanupLife:destroy()
		end
	end))

	cleanupLife:add(model.AncestryChanged:Connect(function(_, parent)
		if not parent then
			cleanupLife:destroy()
		end
	end))

	local humanoid = character.getHumanoid()
	cleanupLife:destroyOn(humanoid.Died)
	cleanupLife:add(humanoid.StateChanged:Connect(function(_, new: Enum.HumanoidStateType)
		if new == Enum.HumanoidStateType.Dead then
			cleanupLife:destroy()
		end
	end))
end

return Mounter
