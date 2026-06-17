local LogService = game:GetService "LogService"

local Log = require "@roblox_packages/Log"
local repr = require "@libs/vendor/repr"

export type LogEvent = typeof(Log.LogEvent.new(...))

const LOG_LEVEL_TO_MESSAGE_TYPES = {
	[Log.LogLevel.Verbose] = Enum.MessageType.MessageOutput,
	[Log.LogLevel.Trace] = Enum.MessageType.MessageOutput,
	[Log.LogLevel.Debugging] = Enum.MessageType.MessageOutput,
	[Log.LogLevel.Information] = Enum.MessageType.MessageInfo,
	[Log.LogLevel.Warning] = Enum.MessageType.MessageWarning,
	[Log.LogLevel.Error] = Enum.MessageType.MessageError,
	[Log.LogLevel.Fatal] = Enum.MessageType.MessageError,
}

local logger = Log.Logger.new({
	Log.Common.Enrichers.LogLevelEnricher(),
	Log.Common.Enrichers.DynSourceEnricher(true),
}, {
	Log.LogSink.new(function(event: LogEvent): ()
		local prefix: string?
		if #event.Prefixes > 0 then prefix = `[{table.concat(event.Prefixes, " ")}]` end

		local fullRender: string = prefix and prefix .. " " or ""
		for index, arg: unknown in event.Args do
			if index ~= 1 then
				fullRender ..= " "
			end
			fullRender ..= if typeof(arg) == "string" then arg else repr(arg)
		end

		if #event.Postfixes > 0 then
			fullRender ..= table.concat(event.Postfixes, "\n")
		end

		local context = table.clone(event) :: { [string]: any }
		context.LogLevel = event.LogLevel
		context.Timestamp = event.Timestamp

		LogService:Log(LOG_LEVEL_TO_MESSAGE_TYPES[event.LogLevel], fullRender, context)
	end),
})

return logger
