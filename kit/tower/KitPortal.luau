-- local activation = require "@libs/activation"
-- local character = require "@libs/character"
-- local logger = require "@core/shared/logger"
-- local std = require "@libs/std"

-- local KitPortal = std.Mechanic {}
-- export type KitPortalMechanic = std.Mechanic<typeof(KitPortal)>
-- KitPortal.basename = "KitPortal"
-- KitPortal.instanceType = std.isA.Instance()
-- KitPortal.emoji = "💠"

-- KitPortal:attributeSection "Activation"
-- KitPortal.Activation = activation.useAttributes(KitPortal)

-- KitPortal.debounce = false

-- function KitPortal:onActivate(portal: KitPortalMechanic, level: std.Level)
-- 	if self.debounce then return end

-- 	self.debounce = true
-- 	local spawnPortal = level.instance:FindFirstChild "SpawnPortal"

-- 	if not spawnPortal then
-- 		logger:Warn 'KitPortal is missing "SpawnPortal" in tower.'
-- 	elseif not spawnPortal:IsA "BasePart" then
-- 		logger:Error('Expected "SpawnPortal" to be a BasePart, got', spawnPortal.ClassName)
-- 	else
-- 		character.getHumanoidRootPart().CFrame = spawnPortal.CFrame
-- 	end

-- 	task.wait(1)
-- 	self.debounce = false
-- end

-- return KitPortal

return nil
