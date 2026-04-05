local Mechanic = require("./Mechanic")
local character = require("./character")
local gt = require("./gt")

local function useAttributes(implementation: Mechanic.MechanicImplementationLike, basename: string?)
	basename = basename or "Touch"

	return {
		CollisionGroup = implementation:attribute(basename .. "CollisionGroup", gt.optional(gt.string()), nil),
		SupportsCharacter = implementation:attribute(basename .. "SupportsCharacter", gt.boolean(), false),
		SupportsBullets = implementation:attribute(basename .. "SupportsBullets", gt.boolean(), false),
	}
end

export type TouchAttributes = typeof(useAttributes(nil :: any))

local function isToucherValid(
	attributes: TouchAttributes,
	instance: Instance,
	instanceConfiguration: Instance,
	toucher: BasePart
)
	-- local collisionGroup = attributes.CollisionGroup(instanceConfiguration)
	-- local isCollisionGroupEmpty = collisionGroup == nil or collisionGroup == ""
	-- local isCollisionGroupValid = (
	-- 	collisionGroup == nil
	-- 	or collisionGroup == ""
	-- 	or PhysicsService:CollisionGroupsAreCollidable(toucher.CollisionGroup, collisionGroup :: string)
	-- )

	-- if not isCollisionGroupValid then
	-- 	return false
	-- end

    -- stylua: ignore
	return (attributes.SupportsCharacter(instanceConfiguration) and character.isFromMaybeCharacter(toucher))
		or (attributes.SupportsBullets(instanceConfiguration) and (toucher:HasTag("Bullet") or toucher:FindFirstAncestor("Bullet") ~= nil))
end

return table.freeze {
	useAttributes = useAttributes,
	isToucherValid = isToucherValid,
}
