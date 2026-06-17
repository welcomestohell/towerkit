const knownClassProperties: { [string]: { [string]: boolean } } = {}

const function setUnsafe(instance: Instance, property: string, value: any)
	(instance :: any)[property] = value
end
const function getUnsafe(instance: Instance, property: string): any
	return (instance :: any)[property]
end

const function hasProperty(instance: Instance, property: string): boolean
	local knownProperties = knownClassProperties[instance.ClassName]
	if knownProperties then
		local propertyExists = knownProperties[property]
		if propertyExists ~= nil then return propertyExists end
	else
		knownProperties = {}
		knownClassProperties[instance.ClassName] = knownProperties
	end

	local propertyExists = pcall(function(instance: any, property)
		return (instance)[property]
	end, instance, property)
	knownProperties[property] = propertyExists
	return propertyExists
end

const function copyCAT(from: Instance, to: Instance)
	for _, child in from:GetChildren() do
		child:Clone().Parent = to
	end

	for attribute, value in from:GetAttributes() do
		to:SetAttribute(attribute, value)
	end

	for _, tag in from:GetTags() do
		to:AddTag(tag)
	end
end

return table.freeze {
	knownClassProperties = knownClassProperties,

	hasProperty = hasProperty,
	setUnsafe = setUnsafe,
	getUnsafe = getUnsafe,

	copyCAT = copyCAT,
}
