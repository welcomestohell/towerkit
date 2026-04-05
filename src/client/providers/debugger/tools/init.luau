local types = require("@client/providers/debugger/types")

return table.freeze {
	require("@self/Levels"),
	require("@self/Explorer"),
	require("@self/Console"),
	require("@self/Providers"),
	require("@self/Actions"),
	require("@self/About"),
} :: { types.DebuggerTool }
