local project = require("@config/project")
local fs = require("@std/fs")
local json = require("@std/json")

type ProjectPath = string | { optional: string }
type ProjectNode = { [string]: ProjectNode, ["$path"]: ProjectPath? }
type Project = { tree: ProjectNode }

local BLACKLISTED_NAMES = {
	["$className"] = true,
	["$path"] = true,
	["$properties"] = true,
}

local function processNode(node: ProjectNode, paths: { [string]: { string } }, currentPath: { string })
	local nodePath = node["$path"]
	if nodePath then
		nodePath = type(nodePath) == "string" and nodePath or nodePath.optional
		paths[nodePath] = table.clone(currentPath)
	end

	for name, child in node do
		if not BLACKLISTED_NAMES[name] and type(child) == "table" then
			local newPath = table.clone(currentPath)
			table.insert(newPath, name)
			processNode(child, paths, newPath)
		end
	end
end

local function process()
	local sourcemapProject = json.deserialize(fs.readfiletostring(project.rojoProjects.sourcemap)) :: Project
	local sourcemapPaths = {}
	processNode(sourcemapProject.tree, sourcemapPaths, { "game" })
	return sourcemapPaths
end

return {
	processNode = processNode,
	process = process,
}
