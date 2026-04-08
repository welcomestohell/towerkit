local pp = require("@batteries/pp")
local docs = require("@config/docs")
local project = require("@config/project")
local clearDirectory = require("@scripts/lib/clearDirectory")
local text = require("@scripts/lib/text")
local filepaths = require("@self/filepaths")
local moonwaveModel = require("@self/moonwaveModel")
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

local model = moonwaveModel(json.deserialize(raw) :: moonwave.Extracted)

clearDirectory(filepaths.libraries)

local libraryNav: { { [string]: { string } } } = {}

for _, library in model.libraries do
	local libraryContents = templates.Library:gsub("{(.-)}", library :: { [string]: string })

	local hyperlink = model.nameToHyperlinks[library.name]
	model.nameToHyperlinks[library.name] = nil
	libraryContents = libraryContents:gsub("%w*", model.nameToHyperlinks)
	model.nameToHyperlinks[library.name] = hyperlink

	local index = path.join(library.outputDirectory, "index.md")
	print("Writing library", library.name)
	fs.createdirectory(library.outputDirectory, { makeparents = true })
	fs.writestringtofile(index, libraryContents)

	table.insert(libraryNav, { [library.name] = { path.format(index) } })
end

local zensical = fs.readfiletostring(docs.zensical)
zensical = text.replaceSectionedBlock(
	zensical,
	-- json is close enough lmao
	-- + toml breaks anyway
	json.serialize(libraryNav :: any):gsub(":", "="),
	"# refgen: libraries start",
	"# refgen: libraries end"
)
fs.writestringtofile(docs.zensical, zensical)
