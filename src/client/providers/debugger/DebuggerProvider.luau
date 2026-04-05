local Debugger = require("./Debugger")
local Iris = require("@libs/Iris")
local Life = require("@libs/memory/Life")
local prvd = require("@shared/prvdmwrong/prvdmwrong")

local DebuggerProvider = {}
export type DebugProvider = typeof(DebuggerProvider)
DebuggerProvider.renderDebuggerTab = prvd.lifecycle("renderDebuggerTab", prvd.fireSequential)
DebuggerProvider.priority = math.huge

function DebuggerProvider.constructor(self: DebugProvider)
	self.life = Life.new()
end

function DebuggerProvider.onStart(self: DebugProvider)
	Iris.Init()
	Iris:Connect(Debugger(self.life))
end

function DebuggerProvider.onFinish(self: DebugProvider)
	Iris.Shutdown()
	self.life:destroy()
end

return prvd(DebuggerProvider)
