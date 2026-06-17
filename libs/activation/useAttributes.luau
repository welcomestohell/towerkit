const Attribute = require "@libs/attributes/Attribute"
local gt = require "@libs/vendor/gt"
local touch = require "@libs/touch"
local types = require "./types"

local function useAttributes(basename: string?): types.ActivationAttributes
	basename = basename or "Activation"
	return {
		Enabled = Attribute.new(basename .. "Enabled", gt.boolean(), false),
		Mode = Attribute.new(basename .. "Mode", gt.optional(gt.string()), nil),
		BaseName = Attribute.new(basename .. "BaseName", gt.string(), basename),
		HumanoidStateType = Attribute.new(
			basename .. "HumanoidStateType",
			gt.optional(gt.enumOf(Enum.HumanoidStateType)),
			nil
		),
		Interval = Attribute.new(basename .. "Interval", gt.optional(gt.positiveNumber), nil),
		KeyCode = Attribute.new(basename .. "KeyCode", gt.optional(gt.enumOf(Enum.KeyCode) :: Enum.KeyCode), nil),
		MaxDistance = Attribute.new(basename .. "MaxDistance", gt.positiveNumber, math.huge),
		Id = Attribute.new(basename .. "Id", gt.optional(gt.string()), nil),
		Touch = touch.useAttributes(basename),
	}
end

return useAttributes
