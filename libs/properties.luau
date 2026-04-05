local knownClassProperties: { [string]: { [string]: boolean } } = {}

local function isInInstance(instance: Instance, property: string): boolean
	local knownProperties = knownClassProperties[instance.ClassName]
	if knownProperties then
		local propertyExists = knownProperties[property]
		if propertyExists ~= nil then
			return propertyExists
		end
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

local function setUnsafe(instance: Instance, property: string, value: any)
	(instance :: any)[property] = value
end

local function getUnsafe(instance: Instance, property: string): any
	return (instance :: any)[property]
end

return table.freeze {
	knownClassProperties = knownClassProperties,

	isInInstance = isInInstance,
	setUnsafe = setUnsafe,
	getUnsafe = getUnsafe,
}
