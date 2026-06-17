const Attribute = require "@libs/attributes/Attribute"
local gt = require "@libs/vendor/gt"

local function useAttributes(basename: string?)
	basename = basename or ""
	return {
		Transition = Attribute.new(basename .. "Transition", gt.string(), "Instant"),
		KeepVelocity = Attribute.new(basename .. "KeepVelocity", gt.boolean(), true),
		Offset = Attribute.new(basename .. "Offset", gt.CFrame(), CFrame.identity),
		ScreenFadeColor = Attribute.new(basename .. "ScreenFadeColor", gt.Color3(), Color3.new()),
	}
end

return useAttributes
