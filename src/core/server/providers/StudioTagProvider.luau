local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local prvd = require("@core/shared/prvdmwrong/prvdmwrong")

local StudioTagProvider = {}
export type StudioTagProvider = typeof(StudioTagProvider)
StudioTagProvider.priority = -1

local function destroyTagged(tag: string)
	for _, tagged in CollectionService:GetTagged(tag) do
		tagged:Destroy()
	end
	CollectionService:GetInstanceAddedSignal(tag):Connect(game.Destroy :: (Instance) -> ())
end

function StudioTagProvider.onStart(self: StudioTagProvider)
	if RunService:IsRunning() then
		destroyTagged("EditOnly")
	end

	destroyTagged(if RunService:IsStudio() then "ProductionOnly" else "StudioOnly")
end

return prvd(StudioTagProvider)
