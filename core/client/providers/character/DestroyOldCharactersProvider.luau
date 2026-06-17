local Charm = require "@roblox_packages/Charm"
local character = require "@libs/character"
local prvd = require "@roblox_packages/prvd"

local DestroyOldCharactersProvider = {}
export type DestroyOldCharactersProvider = typeof(DestroyOldCharactersProvider)
DestroyOldCharactersProvider.currentCharacter = Charm.atom<<character.Character?>>()

function DestroyOldCharactersProvider.onLocalCharacterAdded(
	self: DestroyOldCharactersProvider,
	character: character.Character
)
	local currentCharacter = self.currentCharacter()
	if currentCharacter ~= nil then task.defer(game.Destroy, currentCharacter) end
	self.currentCharacter(character)
end

return prvd(DestroyOldCharactersProvider)
