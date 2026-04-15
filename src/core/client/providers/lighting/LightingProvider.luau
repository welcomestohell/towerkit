local prvd = require("@core/shared/prvdmwrong/prvdmwrong")

local LightingProvider = {}
export type LightingProvider = typeof(LightingProvider)

--[[


Lighting = {
    instance = {},
    attributes = {
        Brightness = property("Brightness", gt.number(), 1),
    }
},
LensFlare = {
    attributes = {
        ExposureCompensation = {}
    }
}

]]

function LightingProvider.onStart(self: LightingProvider) end

return prvd(LightingProvider)
