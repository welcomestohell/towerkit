local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UILabs = require("@pkgs/UILabs")

return {
	name = "Welcome To Hell",
	storyRoots = { ReplicatedStorage.Internal },
} :: UILabs.Storybook
