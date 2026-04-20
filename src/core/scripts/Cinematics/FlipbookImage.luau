local std = require("@libs/std")

local FlipbookImage = std.Mechanic({})
export type FlipbookImageMechanic = std.Mechanic<typeof(FlipbookImage)>
FlipbookImage.basename = "FlipbookImage"
FlipbookImage.instanceType = std.isA.Instance()
FlipbookImage.debuggerEmoji = "🎞️"

FlipbookImage.Enabled = FlipbookImage:withEnabled()

return FlipbookImage
