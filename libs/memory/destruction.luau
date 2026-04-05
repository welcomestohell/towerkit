local Log = require("@libs/Log")
local functions = require("@libs/functions")

-- LUAU: Destroyable is set to any so types using Destroyable are readable
export type Destroyable = any

local log = Log.new(script)
local destructorMethods = {
	"Destroy",
	"destroy",
	"Disconnect",
	"disconnect",
}

local typeDestructors: { [string]: (any) -> () } = {}

local function destroy(x: Destroyable)
	local destructor = typeDestructors[typeof(x)]
	if destructor then
		destructor(x)
	end
end

typeDestructors.RBXScriptConnection = (function(): (RBXScriptConnection) -> nil
	local connection = game.Close:Connect(functions.noop)
	connection:Disconnect()
	return connection.Disconnect
end)()

typeDestructors["function"] = function(fn: () -> ())
	local co = coroutine.create(fn)
	coroutine.resume(co)
	if coroutine.status(co) ~= "dead" then
		local source, line, name = debug.info(fn, "sln")
		name = name == "" or name == nil and "Anonymous function" or "Function " .. name :: string
		log:error(name, "from line", line, "of", source, "attempted to yield during cleanup")
	end
end

function typeDestructors.thread(thread: thread)
	pcall(task.cancel, thread)
end

function typeDestructors.table(tbl: { [any]: any })
	for _, method in destructorMethods do
		if type(tbl[method]) == "function" then
			tbl[method](tbl)
			return
		end
	end

	local len = #tbl
	if len ~= 0 then
		for index = #tbl, 1, -1 do
			destroy(tbl[index])
		end
	end
end

return table.freeze {
	destroy = destroy,
	destructorMethods = destructorMethods,
	typeDestructors = typeDestructors,
}
