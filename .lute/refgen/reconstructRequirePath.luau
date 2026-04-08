local path = require("@std/path")

local function reconstructRequirePath(sourcemapPaths: { [string]: { string } }, inputPath: string): { string }?
	local bestSource, bestLen = "", 0
	for sourcePath in sourcemapPaths do
		if string.find(inputPath, "^" .. sourcePath) then
			local len = string.len(sourcePath)
			if bestLen < len then
				bestSource, bestLen = sourcePath, len
			end
		end
	end

	if bestLen == 0 then
		return nil
	end

	local requirePath = table.clone(sourcemapPaths[bestSource])
	if requirePath[1] == "game" then
		requirePath[1] = "@game"
	end

	local sourceParts = path.parse(bestSource).parts
	local parts = path.parse(inputPath).parts
	local lenParts = #parts
	parts[lenParts] = string.match(parts[lenParts], "(.+)%..+$")
	table.move(parts, #sourceParts + 1, #parts, #requirePath + 1, requirePath)
	return requirePath
end

return reconstructRequirePath
