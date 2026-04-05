local Workspace = game:GetService("Workspace")

local Iris = require("@pkgs/Iris")
local Life = require("@libs/memory/Life")
local net = require("@client/generated/net")

local Actions = {}
Actions.__index = Actions
Actions.title = "Actions"

export type Actions = setmetatable<{ life: Life.Life }, typeof(Actions)>

function Actions.new(life: Life.Life)
	return setmetatable({ life = life }, Actions)
end

function Actions.renderViewport() end

function Actions.renderWindow(self: Actions)
	if Iris.Button({ "Rejoin" }).clicked() then
		net.rejoin.fire()
	end

	if Iris.Button({ "Load Decorations" }).clicked() then
		net.loadDecorations.invoke():andThenCall(function(decorations: Instance?)
			if not decorations then
				return
			end

			local oldDecorations = Workspace:FindFirstChild(decorations.Name)
			if oldDecorations then
				oldDecorations:Destroy()
			end
			decorations.Parent = Workspace
		end)
	end
end

return Actions
