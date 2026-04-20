return {
	remote = "https://github.com/welcomestohell/game.git",
	branch = "main",

	directory = "mirror",
	targets = {
		"src/core",
		"src/libs",

		".github/workflows/ci.yml",

		".darklua.json",
		".gitattributes",
		".styluaignore",
		"pesde.toml",
		"rokit.toml",
		"selene.toml",
		"stylua.toml",

		".lute/ci.luau",
		".lute/mirror.luau",

		"patches",
		".zed",
		".vscode",
	},
}
