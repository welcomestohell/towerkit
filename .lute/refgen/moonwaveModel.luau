local docs = require("@config/docs")
local project = require("@config/project")
local text = require("@scripts/lib/text")
local reconstructRequirePath = require("./reconstructRequirePath")
local sourcemap = require("./sourcemap")
local path = require("@std/path")
local filepaths = require("./filepaths")
local moonwave = require("./moonwave")

export type Library = {
	name: string,
	slug: string,
	summary: string,
	description: string,

	sourcePath: string,
	sourceLine: number,
	importPath: string,

	outputDirectory: path.path,
	outputUrl: path.path,
}

export type Mechanic = {}

export type Model = {
	libraries: { Library },
	mechanics: { Mechanic },
	sourcemapPaths: { [string]: { string } },
	nameToUrls: { [string]: string },
	nameToHyperlinks: { [string]: string },
}

local function modelLibrary(model: Model, library: moonwave.Class): Library
	local sourcePath = project.source .. "/" .. library.source.path
	local slug = string.lower(library.name)
	local url = path.join(docs.documentationPaths.libraries, slug)
	model.nameToUrls[library.name] = path.format(url)
	model.nameToHyperlinks[library.name] = `<a href={text.quote("/" .. path.format(url))}>{library.name}</a>`

	return {
		name = library.name,
		slug = slug,
		summary = string.match(library.desc, "^[^\n]+") or "",
		description = library.desc,

		sourcePath = sourcePath,
		sourceLine = library.source.line,
		importPath = table.concat(
			reconstructRequirePath(model.sourcemapPaths, sourcePath)
				or error(`library {library.source.path} cannot be imported`),
			"/"
		),

		outputDirectory = path.join(filepaths.libraries, slug),
		outputUrl = url,
	}
end

local function moonwaveModel(classes: { moonwave.Class })
	local model: Model = {
		libraries = {},
		mechanics = {},
		sourcemapPaths = sourcemap.process(),
		nameToUrls = {},
		nameToHyperlinks = {},
	}

	for _, class in ipairs(classes) do
		local tags: { string } = class.tags or {}

		for _, tag in tags do
			if tag == "Library" then
				table.insert(model.libraries, modelLibrary(model, class))
				break
			end
		end
	end

	return model
end

return moonwaveModel
