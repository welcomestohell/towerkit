local fs = require("@std/fs")
local path = require("@std/path")

local function clearDirectory(directory: path.pathlike)
	if fs.exists(directory) then
		fs.removedirectory(directory, { recursive = true })
	end
	fs.createdirectory(directory, { makeparents = true })
end

return clearDirectory
