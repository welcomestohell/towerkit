local cli = require("@batteries/cli")
local config = require("../wth.config")
local fs = require("@std/fs")
local _ = require("@lute/time")
local copy = require("@scripts/lib/copy")
local path = require("@std/path")
local process = require("@std/process")

local args = cli.parser()
args:add("script", "positional", { required = true })
args:add("subcommand", "positional", { default = "help" })
args:parse({ ... })

local function pull()
	local gitVersionString = process.run({ "git", "--version" }).stdout
	local gitVersion = string.split(gitVersionString, " ")[3]
	local components = string.split(gitVersion, ".")

	local major = tonumber(components[1]) or 0
	local minor = tonumber(components[2]) or 0

	return process.run(
		if major >= 3 or (major == 2 and minor >= 49)
			then {
				"git",
				"clone",
				"--depth=1",
				"--revision",
				config.mirror.branch,
				config.mirror.remote,
				config.mirror.directory,
			}
			else {
				"git",
				"clone",
				"--depth=1",
				"--branch",
				config.mirror.branch,
				config.mirror.remote,
				config.mirror.directory,
			},
		{ stdio = "inherit" }
	)
end

local function applyTargets()
	for _, destination in config.mirror.targets do
		local source = path.join(config.mirror.directory, destination)
		if not fs.exists(source) then
			print(`{destination} does not exist in mirrored repository, skipping...`)
			continue
		end

		if fs.exists(destination) and fs.type(destination) == "dir" then
			fs.removedirectory(destination, { recursive = true })
		end

		print(`copying {destination} from mirrored repository`)
		copy(source, destination)
	end

	print("finished applying code from mirrored repository")
end

local subcommand = args:get("subcommand")
if subcommand == "help" then
	print("Synchronize code between two repositories")
	print("See `mirror` table in `wth.config.luau`")
	print("")
	print("Usage:")
	print("  lute mirror <command>")
	print()
	print("Commands:")
	print("  sync          Fetch and mirror code")
	print("  fetch         Fetch mirror from current revision")
	print("  apply         Mirrors code onto targets")
	print("  help          Prints this message")

	process.exit(0)
elseif subcommand == "sync" then
	local pullResult = pull()
	if not pullResult.ok then
		print(`git failed with code {pullResult.code}, aborting...`)
		process.exit(pullResult.exitcode)
	end

	applyTargets()
elseif subcommand == "pull" then
	process.exit(pull().exitcode)
elseif subcommand == "apply" then
	if not fs.exists(config.mirror.directory) then
		print("missing mirror repository, fetch it first with `lute mirror fetch`")
		process.exit(1)
	else
		applyTargets()
		process.exit(0)
	end
else
	print(`unknown subcommand {string.format("%q", subcommand :: string)}`)
	process.exit(1)
end
