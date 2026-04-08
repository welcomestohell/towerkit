local docs = require("@config/docs")
local path = require("@std/path")

return {
	libraries = path.join(docs.directory, docs.documentationPaths.libraries),
	mechanics = path.join(docs.directory, docs.documentationPaths.mechanics),
}
