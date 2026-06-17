const Attribute = require "@libs/attributes/Attribute"
local gt = require "@libs/vendor/gt"

local SeamlessMeasurement = gt.build(gt.literals("Relative", "World"))
export type SeamlessMeasurement = typeof(SeamlessMeasurement:type())

local function useSeamlessAttributes(basename: string?)
	basename = basename or "Seamless"
	return {
		Enabled = Attribute.new(basename .. "Enabled", gt.boolean(), false),
		Scaled = Attribute.new(basename .. "Scaled", gt.boolean(), true),
		Clamped = Attribute.new(basename .. "Clamped", gt.boolean(), true),
	}
end

return useSeamlessAttributes
