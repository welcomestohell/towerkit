local Log = require("./Log")

export type DestroyableClass = {
	[any]: any,
	read Destroy: (self: any) -> ()?,
	read destroy: (self: any) -> ()?,
	read Disconnect: (self: any) -> ()?,
	read disconnect: (self: any) -> ()?,
}

-- TODO: unioning to any because Luau sucks
export type Destroyable = any | Instance | RBXScriptConnection | thread | DestroyableClass | { any } | () -> ...any

local DESTRUCTORS = {
	"Destroy",
	"destroy",
	"Disconnect",
	"disconnect",
}

local log = Log.new(script)

local function destroy(x: any)
	if typeof(x) == "Instance" then
		x:Destroy()
	elseif typeof(x) == "RBXScriptConnection" and x.Connected then
		x:Disconnect()
	elseif type(x) == "thread" then
		pcall(task.cancel, x)
	elseif type(x) == "function" then
		local co = coroutine.create(x :: () -> ())
		coroutine.resume(co)
		if coroutine.status(co) ~= "dead" then
			local source, line, name = debug.info(x :: () -> (), "sln")
			name = name == "" or name == nil and "Anonymous function" or "Function " .. name :: string
			log:error(name, "from line", line, "of", source, "attempted to yield during cleanup")
		end
	elseif type(x) == "table" then
		for _, method in DESTRUCTORS do
			if type(x[method]) == "function" then
				x[method](x)
				return
			end
		end

		local len = #(x :: any)
		if len ~= 0 then
			for index = #(x :: any), 1, -1 do
				destroy(x[index])
			end
		end
	end
end

return destroy
