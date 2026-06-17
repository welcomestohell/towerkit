local CollectionService = game:GetService "CollectionService"
local RunService = game:GetService "RunService"

local prvd = require "@roblox_packages/prvd"

local TagProvider = {}
export type TagProvider = typeof(TagProvider)
TagProvider.priority = -1

function TagProvider.observeAndDestroyTag(self: TagProvider, tag: string)
	CollectionService:GetInstanceAddedSignal(tag):Connect(game.Destroy :: (Instance) -> ())
	for _, tagged in CollectionService:GetTagged(tag) do
		pcall(game.Destroy, tagged)
	end
end

function TagProvider.onStart(self: TagProvider)
	if RunService:IsRunning() then
		self:observeAndDestroyTag "EditOnly"
		self:observeAndDestroyTag "OnlyInEdit"
	end

	if RunService:IsStudio() then
		self:observeAndDestroyTag "StudioOnly"
		self:observeAndDestroyTag "OnlyInStudio"
	else
		self:observeAndDestroyTag "ProductionOnly"
		self:observeAndDestroyTag "OnlyInProduction"
	end
end

return prvd(TagProvider)
