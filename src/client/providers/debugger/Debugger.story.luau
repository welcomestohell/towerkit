local Debugger = require("./Debugger")
local DebuggerStore = require("./DebuggerStore")
local Iris = require("@libs/Iris")
local Life = require("@libs/memory/Life")
local UILabs = require("@pkgs/UILabs")

return UILabs.CreateIrisStory({ iris = Iris }, function(props: UILabs.IrisProps)
	local life = Life.new()
	DebuggerStore.isOpen(true)
	Iris:Connect(Debugger(life))
	return function()
		life:destroy()
	end
end)
