local Workspace = game:GetService "Workspace"

local flattenAssetPaths = require "@core/shared/assets/flattenAssetPaths"
local instances = require "@libs/instances"
local logger = require "@core/shared/logger"
local net = require "@core/server/generated/net"
local prvd = require "@roblox_packages/prvd"
local requireAssetModules = require "@core/shared/assets/requireAssetModules"

local PreloadProvider = {}
export type PreloadProvider = typeof(PreloadProvider)
PreloadProvider.priority = -1
PreloadProvider.knownAssetIds = {}

function PreloadProvider.castMeshId(self: PreloadProvider, instance: Instance)
	return if instance:IsA "MeshPart"
			or (instance:IsA "SpecialMesh" and instance.MeshType == Enum.MeshType.FileMesh)
		then instance.MeshId
		else nil
end

function PreloadProvider.onInit(self: PreloadProvider)
	const assetPaths = flattenAssetPaths(requireAssetModules())

	local assetIds = {}
	for _, descendant in Workspace:GetDescendants() do
		local meshId = self:castMeshId(descendant)
		if meshId and not self.knownAssetIds[meshId] then
			self.knownAssetIds[meshId] = true
			table.insert(assetIds, meshId)
		end

		if descendant:HasTag "Preload: Sound From Assets" and descendant:IsA "StringValue" then
			const soundId = assetPaths[descendant.Value]
			if not soundId then
				logger:Warn("Unknown asset", descendant.Value, "from", descendant:GetFullName())
				continue
			end

			const sound = Instance.new "Sound"
			sound.Name = descendant.Name
			sound.SoundId = soundId
			instances.copyCAT(descendant, sound)
			sound.Parent = descendant.Parent
			descendant:Destroy()
		end
	end

	net.fetchAssetIds.on(function(player: Player)
		return assetIds
	end)
end

return prvd(PreloadProvider)
