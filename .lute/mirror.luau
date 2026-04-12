local _ = require("@lute/time")
local cli = require("@batteries/cli")
local config = require("@config/mirror")
local copy = require("@scripts/lib/copy")
local exec = require("@scripts/lib/exec")
local fs = require("@std/fs")
local path = require("@std/path")
local process = require("@std/process")

local args = cli.parser()
args:add("script", "positional", { required = true })
args:add("subcommand", "positional", { default = "sync" })
args:parse({ ... })

local function pull()
	if fs.exists(config.directory) then
		fs.removedirectory(config.directory, { recursive = true })
	end

	local gitVersionString = process.run({ "git", "--version" }).stdout
	local gitVersion = string.split(gitVersionString, " ")[3]
	local components = string.split(gitVersion, ".")

	local major = tonumber(components[1]) or 0
	local minor = tonumber(components[2]) or 0

	return if major >= 3 or (major == 2 and minor >= 49)
		then exec("git", "clone", "--depth=1", "--revision", config.branch, config.remote, config.directory)
		else exec("git", "clone", "--depth=1", "--branch", config.branch, config.remote, config.directory)
end

local function applyTargets()
	for _, destination in config.targets do
		local source = path.join(config.directory, destination)
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
	print("Configure in `.config/mirror.luau`")
	print("")
	print("Usage:")
	print("  lute mirror <command>")
	print()
	print("Commands:")
	print("  sync (default)        Fetch and mirror code")
	print("  commit                Fetch and mirror code, then pushes a git commit")
	print("  fetch                 Fetch mirror from current revision")
	print("  apply                 Mirrors code onto targets")
	print("  help                  Prints this message")

	process.exit(0)
elseif subcommand == "sync" then
	pull()
	applyTargets()
elseif subcommand == "commit" then
	pull()
	applyTargets()
	exec("git", "add", ".")
	exec("git", 'commit -m "chore: mirror codebase"')
	exec("git", "push", "origin", "main")
elseif subcommand == "pull" then
	process.exit(pull().exitcode)
elseif subcommand == "apply" then
	if not fs.exists(config.directory) then
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
