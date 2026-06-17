const AttributeOrder = require "@libs/attributes/AttributeOrder"

const AttributeSection = {}
AttributeSection.__index = AttributeSection
AttributeSection.type = "AttributeSection"

export type AttributeSection = setmetatable<{ title: string }, typeof(AttributeSection)>

function AttributeSection.new(title: string): AttributeSection
	return AttributeOrder.track(setmetatable({ title = title }, AttributeSection))
end

function AttributeSection.isAttributeSection(x: unknown)
	return type(x) == "table" and getmetatable(x) == AttributeSection
end

return table.freeze(AttributeSection)
