local UserInputService = game:GetService("UserInputService")

local activation = require("@libs/activation")
local character = require("@libs/character")
local constraints = require("@libs/constraints")
local std = require("@libs/std")

local DISTANCE_FROM_ROOT_TO_GROUND_STUDS = 4
local DEFAULT_OFFSET = CFrame.new(0, DISTANCE_FROM_ROOT_TO_GROUND_STUDS / 2, 0)

local Seat = std.Mechanic({})
export type SeatMechanic = std.Mechanic<typeof(Seat)>

Seat.basename = "Seat"
Seat.instanceType = std.isA.BasePart()
Seat.debuggerEmoji = "🪑"

Seat.Offset = Seat:attribute("Offset", std.gt.CFrame(), DEFAULT_OFFSET)
Seat.JumpOnDismount = Seat:attribute("JumpOnDismount", std.gt.boolean(), true)
Seat.Cooldown = Seat:attribute("Cooldown", std.gt.positiveNumber, 0)

Seat.seated = false
Seat.debounced = {} :: { [SeatMechanic]: true }
Seat.activation = activation.useAttributes(Seat)

function Seat.onActivate(self: typeof(Seat), seat: SeatMechanic)
	local isSeatable = seat:Enabled() and not self.seated and not self.debounced[seat] and character.isCharacterAlive()

	if not isSeatable then
		return
	end

	self.debounced[seat] = true
	self.seated = true

	local root = character.getMaybeHumanoidRootPart() :: BasePart
	local humanoid = character.getMaybeHumanoid() :: Humanoid

	seat.activation.Enabled(seat, false)

	root.CFrame = seat.instance.CFrame * seat:Offset()
	humanoid.Sit = true

	local weldLife = seat.life:extend()
	weldLife:destroyOn(root.Destroying)
	constraints.weld(weldLife, seat.instance, root)

	local destroyWeld = weldLife:wrapDestroy()
	weldLife:add(UserInputService.JumpRequest:Connect(destroyWeld))
	weldLife:add(humanoid.Died:Connect(destroyWeld))

	-- weldLife:add(Dismounter.onDismount :: any, function(targets)
	-- 	if targets.Seat then
	-- 		weldLife:clean()
	-- 	end
	-- end)

	local function dismount()
		self.seated = false
		local humanoid = character.getMaybeHumanoid()
		if seat:JumpOnDismount() and humanoid then
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end
		seat.activation.Enabled(seat, true)
	end

	weldLife:add(dismount)
	task.delay(seat:Cooldown(), function()
		self.debounced[seat] = nil
	end)
end

return Seat
