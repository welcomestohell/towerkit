local PlayerInstanceLoader = {}
PlayerInstanceLoader.__index = PlayerInstanceLoader

export type PlayerInstanceLoader = setmetatable<{
	timeout: number,
	onTimeout: (Instance) -> (),
	_threads: { [Player]: thread },
	_instances: { [Player]: Instance },
}, typeof(PlayerInstanceLoader)>

function PlayerInstanceLoader.new(timeout: number, onTimeout: (Instance) -> ()?): PlayerInstanceLoader
	return setmetatable({
		timeout = timeout,
		onTimeout = onTimeout or game.Destroy :: any,
		_threads = {},
		_instances = {},
	}, PlayerInstanceLoader)
end

function PlayerInstanceLoader.sendToPlayer(self: PlayerInstanceLoader, player: Player, instance: Instance)
	if self._threads[player] then
		return self._instances[player]
	end

	instance.Parent = player.PlayerGui
	self._instances[player] = instance

	self._threads[player] = task.delay(self.timeout, function(self: PlayerInstanceLoader, player, instance)
		self.onTimeout(instance)
		self._instances[player] = nil
		self._threads[player] = nil
	end, self, player, instance)

	return instance
end

function PlayerInstanceLoader.cloneToPlayer(self: PlayerInstanceLoader, player: Player, instance: Instance)
	return self:sendToPlayer(player, instance:Clone())
end

function PlayerInstanceLoader.cancelPlayer(self: PlayerInstanceLoader, player: Player)
	local thread = self._threads[player]
	if thread then
		pcall(task.cancel, thread)
		self.onTimeout(self._instances[player])
		self._instances[player] = nil
		self._threads[player] = nil
	end
end

return table.freeze(PlayerInstanceLoader)
