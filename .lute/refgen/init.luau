local docs = require("@config/docs")
local project = require("@config/project")
local clearDirectory = require("@scripts/lib/clearDirectory")
local text = require("@scripts/lib/text")
local filepaths = require("@self/filepaths")
local modelMoonwave = require("@self/modelMoonwave")
local process = require("@std/process")
local json = require("@std/json")
local moonwave = require("@self/moonwave")
local templates = require("@self/templates")
local fs = require("@std/fs")
local path = require("@std/path")

local raw = process.run({
	"moonwave-extractor",
	"extract",
	project.source,
}).stdout

local model = modelMoonwave(json.deserialize(raw) :: moonwave.Extracted)

clearDirectory(filepaths.api)

local libraryNav: { { [string]: { string } } } = {}

local function linkNames(content: string, hyperlinks: { [string]: string })
	for name, url in hyperlinks do
		content = string.gsub(content, "%f[%w]" .. name .. "%f[%W]", url)
	end
	return content
end

for _, class in model.classes do
	local contents = text.replaceBraced(templates.Class, class)

	local nameToHyperlinks = table.clone(model.nameToHyperlinks)
	nameToHyperlinks[class.name] = nil
	contents = linkNames(contents, nameToHyperlinks)

	local index = path.join(class.directory, "index.md")
	print("Writing api class", class.name)
	fs.createdirectory(class.directory, { makeparents = true })
	fs.writestringtofile(index, contents)

	table.insert(libraryNav, { [class.name] = { path.format(path.join(class.url, "index.md")) } })
end

local zensical = fs.readfiletostring(docs.zensical)
zensical = text.replaceSectionedBlock(
	zensical,
	-- json is close enough lmao
	-- + toml breaks anyway
	'{ "API" = '
		.. json.serialize(libraryNav :: any):gsub(":", "=")
		.. " }",
	"# refgen: api start",
	"# refgen: api end"
)
fs.writestringtofile(docs.zensical, zensical)
