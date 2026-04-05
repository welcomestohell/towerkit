local LocalizationService = game:GetService("LocalizationService")

local Charm = require("@pkgs/Charm")
local repr = require("@libs/repr")
local threadpool = require("@libs/threadpool")

export type LogMessage = {
	timestamp: DateTime,
	from: Log,
	level: number,
	args: { [number]: any, n: number },
}

local LOG_LEVELS = {
	ERROR = 1,
	WARN = 2,
	INFO = 3,
	DEBUG = 4,
	TRACE = 5,
}

local LOG_LEVEL_TAGS = {
	[LOG_LEVELS.ERROR] = "❌",
	[LOG_LEVELS.WARN] = "⚠️",
	[LOG_LEVELS.INFO] = "💬",
	[LOG_LEVELS.DEBUG] = "🐛",
	[LOG_LEVELS.TRACE] = "🔍",
}

local Log = {}
Log.__index = Log
Log._maxLevel = Charm.atom(LOG_LEVELS.TRACE)
Log._messages = Charm.atom({} :: { LogMessage })
Log.LOG_LEVELS = LOG_LEVELS

export type Log = setmetatable<{ read source: unknown, read maxLevel: number? }, typeof(Log)>

local function outputMessage(event: LogMessage)
	local timestamp = event.timestamp:FormatLocalTime("LTS", LocalizationService.RobloxLocaleId)
	local source: string = if typeof(event.from.source) == "Instance"
		then event.from.source.Name
		else tostring(event.from.source)
	local prefix = `{LOG_LEVEL_TAGS[event.level]} {source}: `

	local formatted = {}
	for i = 1, event.args.n do
		local value = event.args[i]
		formatted[i] = if typeof(value) == "string" then value else repr(value)
	end

	local formattedString = prefix .. string.gsub(table.concat(formatted, " "), "\n", `\n{prefix}`)
	formattedString ..= ` - {timestamp}`

	if event.level <= LOG_LEVELS.ERROR then
		threadpool.spawn(error :: any, formattedString :: any, 0)
	elseif event.level <= LOG_LEVELS.WARN then
		warn(formattedString)
	else
		print(formattedString)
	end

	return formattedString
end

function Log.new(source: unknown, maxLevel: number?): Log
	return table.freeze(setmetatable({ source = source, maxLevel = maxLevel }, Log))
end

function Log.log(self: Log, level: number, ...: any)
	local timestamp = DateTime.now()

	local event: LogMessage = {
		timestamp = timestamp,
		from = self,
		level = level,
		args = table.pack(...),
	}

	local newEvents = table.clone(Log._messages())
	table.insert(newEvents, event)
	Log._messages(newEvents)

	if level <= (self.maxLevel or Log._maxLevel()) then
		outputMessage(event)
	end
end

function Log.error(self: Log, ...: any)
	self:log(LOG_LEVELS.ERROR, ...)
end

function Log.warn(self: Log, ...: any)
	self:log(LOG_LEVELS.WARN, ...)
end

function Log.info(self: Log, ...: any)
	self:log(LOG_LEVELS.INFO, ...)
end

function Log.debug(self: Log, ...: any)
	self:log(LOG_LEVELS.DEBUG, ...)
end

function Log.trace(self: Log, ...: any)
	self:log(LOG_LEVELS.TRACE, ...)
end

return table.freeze(Log)
