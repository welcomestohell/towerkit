-- https://github.com/prvdmwrong/prvdmwrong/blob/b4fd0eb527d09824692b67c7838f8c51ed7a9e9a/lune/docs/moonwave.luau

export type Interface = {
	desc: string,
	name: string,
	fields: { LuaType & { name: string } }?,
	source: Source,
}

export type LuaType = {
	desc: string,
	lua_type: string,
}

export type FunctionParameter = LuaType & {
	name: string,
}

export type Source = {
	line: number,
	path: string,
}

export type Function = {
	name: string,
	desc: string,
	function_type: "static",
	since: string?,
	params: { FunctionParameter },
	returns: { LuaType },
	tags: { string }?,
	source: Source,
}

export type Property = {
	name: string,
	desc: string,
	lua_type: string,
	tags: { string }?,
	source: Source,
}

export type Type = {
	name: string,
	desc: string,
	lua_type: string,
	tags: { string }?,
	source: Source,
}

export type Class = {
	name: string,
	desc: string,
	since: string?,
	source: Source,
	functions: { Function },
	types: { Type },
	properties: { Property },
	tags: { string }?,
}

export type Extracted = { Class }

return nil
