local docs = require("@config/docs")
local project = require("@config/project")
local tables = require("@libs/collections/tables")
local text = require("@scripts/lib/text")
local templates = require("./templates")
local reconstructRequirePath = require("./reconstructRequirePath")
local sourcemap = require("./sourcemap")
local path = require("@std/path")
local tableext = require("@std/tableext")
local filepaths = require("./filepaths")
local moonwave = require("./moonwave")

export type Base = {
	name: string,
	slug: string,
	summary: string,
	description: string,

	sourcePath: string,
	sourceLine: number,
	importPath: string,

	url: path.path,
}

export type Class = Base & {
	directory: path.path,
	methods: { Method },
	apiSignature: string,
	sectionMethods: string,
}

export type Method = Base & {
	filepath: path.path,
	parameters: { moonwave.FunctionParameter },
	returns: { moonwave.LuaType },
	signature: string,
	definition: string,
}

export type Model = {
	classes: { Class },
	sourcemapPaths: { [string]: { string } },
	nameToUrls: { [string]: string },
	nameToHyperlinks: { [string]: string },
}

local function modelLink(model: Model, name: string, url: path.path)
	model.nameToUrls[name] = path.format(url)
	model.nameToHyperlinks[name] = `<a href={text.quote("/" .. path.format(url))}>{name}</a>`
end

local function modelBase(model: Model, base: moonwave.Class | moonwave.Function)
	local sourcePath = project.source .. "/" .. base.source.path
	local slug = string.lower(base.name)
	local url = path.join(docs.documentationPaths.api, slug)

	return {
		name = base.name,
		slug = slug,
		summary = string.match(base.desc, "^[^\n]+") or "",
		description = base.desc,

		sourcePath = sourcePath,
		sourceLine = base.source.line,
		importPath = table.concat(
			reconstructRequirePath(model.sourcemapPaths, sourcePath)
				or error(`{base.source.path} cannot be imported; is it included under rojo?`),
			"/"
		),

		url = url,
	}
end

local function modelMethod(model: Model, class: Class, method: moonwave.Function)
	local base = modelBase(model, method) :: Method
	base.filepath = path.join(class.directory, base.slug)
	base.url = path.join(class.url, base.slug)
	base.parameters = method.params
	base.returns = method.returns

	local parameterSignature = tableext.map(base.parameters, function(p: moonwave.FunctionParameter)
		return `{p.name}: {p.lua_type}`
	end)

	local returnTypes = tableext.map(base.returns, function(t: moonwave.LuaType)
		return t.lua_type
	end)

	local returnBraces = if #returnTypes == 1 then "%s" else "(%s)"
	local returnSignature = string.format(returnBraces :: any, table.concat(returnTypes, ", "))

	base.signature = `({table.concat(parameterSignature, ", ")}) -> {returnSignature}`
	base.definition = `function {base.name}({table.concat(parameterSignature, ", ")}): {returnSignature}`

	return base
end

local function modelClass(model: Model, class: moonwave.Class): Class
	local base = modelBase(model, class) :: Class
	modelLink(model, base.name, base.url)
	base.directory = path.join(filepaths.api, base.slug)

	local apiSignature = {}
	local methods = {}

	base.methods = tables.create(#class.functions)
	for index, method in class.functions do
		local methodModel = modelMethod(model, base, method)
		base.methods[index] = methodModel
		table.insert(apiSignature, text.replaceBraced(templates.ApiSignatureField, methodModel))
		methods[index] = text.replaceBraced(templates.Function, methodModel)
	end

	base.apiSignature = if #apiSignature > 1 then `\{\n{table.concat(apiSignature, "\n")}\n\}` else "{}"
	base.sectionMethods = if #methods > 0 then `## Methods\n{table.concat(methods, "\n")}` else ""

	return base
end

local function modelMoonwave(classes: { moonwave.Class })
	local model: Model = {
		classes = {},
		sourcemapPaths = sourcemap.process(),
		nameToUrls = {},
		nameToHyperlinks = {},
	}

	for _, class in ipairs(classes) do
		local tags: { string } = class.tags or {}

		for _, tag in tags do
			if tag == "Class" then
				table.insert(model.classes, modelClass(model, class))
				break
			end
		end
	end

	return model
end

return modelMoonwave
