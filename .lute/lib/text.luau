local function heading(count: number, str: string)
	return `{string.rep("#", count)} {str}`
end

local function replaceSectionedBlock(oldContent: string, replacement: string, sectionStart: string, sectionEnd: string)
	local newBlock = `{sectionStart}\n{replacement}\n{sectionEnd}`
	local updated = string.gsub(oldContent, `{sectionStart}(.-){sectionEnd}`, newBlock)
	return updated
end

local function quote(str: string)
	return string.format("%q", str)
end

local function replaceBraced(content: string, replacements: any)
	return (string.gsub(content, "{([^{}]-)}", replacements))
end

return table.freeze({
	heading = heading,
	quote = quote,
	replaceSectionedBlock = replaceSectionedBlock,
	replaceBraced = replaceBraced,
})
