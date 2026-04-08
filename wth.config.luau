return {
	mirror = {
		remote = "https://github.com/team-fireworks/wth.git",
		branch = "main",

		directory = "game",
		targets = {
			"src/core",
			"src/libs",
			"pesde.toml",
			"patches",
			"rokit.toml",
			".zed",
			".vscode",
		},
	},
}
