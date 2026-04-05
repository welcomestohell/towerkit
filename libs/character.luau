local Players = game:GetService("Players")

export type Character = {
	Humanoid: {
		HumanoidDescription: HumanoidDescription,
		Animator: Animator,
	} & Humanoid,
	HumanoidRootPart: BasePart,
	BodyColors: BodyColors,
	PrimaryPart: BasePart,
	Animate: LocalScript,
	Head: BasePart,
	["Left Arm"]: BasePart,
	["Right Arm"]: BasePart,
	["Left Leg"]: BasePart,
	["Right Leg"]: BasePart,
} & Model

local ROOT_OFFSET = CFrame.new(0, 1, 0)
local LIMB_MAP: { [Enum.Limb]: string? } = {
	[Enum.Limb.Torso] = "HumanoidRootPart",
	[Enum.Limb.LeftArm] = "Left Arm",
	[Enum.Limb.RightArm] = "Right Arm",
	[Enum.Limb.LeftLeg] = "Left Leg",
	[Enum.Limb.RightLeg] = "Right Leg",
	[Enum.Limb.Head] = "Head",
}

local function isCharacter(character: Instance): boolean
	return Players:GetPlayerFromCharacter(character :: Model) ~= nil
end

local function isLocalPlayerCharacter(character: Instance): boolean
	return Players:GetPlayerFromCharacter(character :: Model) == Players.LocalPlayer
end

local function getMaybePlayer(): Player?
	return Players.LocalPlayer
end

local function waitForPlayer(): Player
	return Players.PlayerAdded:Wait()
end

local function getPlayer(): Player
	return getMaybePlayer() or waitForPlayer()
end

local function getMaybeCharacter(player: Player?): Character?
	local plr = if player ~= nil then player else Players.LocalPlayer

	return plr.Character :: any
end

local function waitForCharacter(): Character
	return Players.LocalPlayer.CharacterAdded:Wait() :: Character
end

local function getCharacter(): Character
	return getMaybeCharacter() or waitForCharacter()
end

local function getCharacterFromHit(hit: Instance): Character?
	local character = getMaybeCharacter()
	return if character ~= nil and character:IsAncestorOf(hit) then character else nil
end

local function getPlayerFromHit(hit: Instance): Player?
	local player = getPlayer()
	local character = getMaybeCharacter(player)

	return if character ~= nil and character:IsAncestorOf(hit) then player else nil
end

local function isFromMaybeCharacter(instance: Instance): boolean
	local character = getMaybeCharacter()
	return if character ~= nil then character:IsAncestorOf(instance) else false
end

local function isFromCharacter(instance: Instance): boolean
	return getCharacter():IsAncestorOf(instance)
end

local function getMaybeHumanoidRootPart(): BasePart?
	local character = getMaybeCharacter()
	if character ~= nil then
		return character:FindFirstChild("HumanoidRootPart") :: BasePart
	end
	return nil
end

local function getHumanoidRootPart(): BasePart
	return getCharacter():WaitForChild("HumanoidRootPart") :: BasePart
end

local function getMaybeHumanoid(): Humanoid?
	local character = getMaybeCharacter()
	if character ~= nil then
		return character:FindFirstChild("Humanoid") :: Humanoid
	end
	return nil
end

local function getHumanoid(): Humanoid
	return getCharacter():WaitForChild("Humanoid") :: Humanoid
end

local function isCharacterAlive(): boolean
	local humanoid = getMaybeHumanoid()
	return humanoid ~= nil and humanoid.Health > 0
end

return {
	ROOT_OFFSET = ROOT_OFFSET,
	LIMB_MAP = LIMB_MAP,
	isCharacter = isCharacter,
	isLocalPlayerCharacter = isLocalPlayerCharacter,
	getMaybeCharacter = getMaybeCharacter,
	waitForCharacter = waitForCharacter,
	getCharacter = getCharacter,
	getCharacterFromHit = getCharacterFromHit,
	getPlayerFromHit = getPlayerFromHit,
	isFromMaybeCharacter = isFromMaybeCharacter,
	isFromCharacter = isFromCharacter,
	getMaybeHumanoidRootPart = getMaybeHumanoidRootPart,
	getHumanoidRootPart = getHumanoidRootPart,
	getMaybeHumanoid = getMaybeHumanoid,
	getHumanoid = getHumanoid,
	isCharacterAlive = isCharacterAlive,
}
