export type function NonNilable(ty: type): type
	if not ty:is "union" then return ty end
	local union = nil
	for _, member in ty:components() do
		if not member:is "nil" then union = if union then types.unionof(union, member) else member end
	end
	return union or ty
end

export type function Partial(ty: type): type
	local result = types.copy(ty)
	for key, property in ty:properties() do
		if property.read then result:setreadproperty(key, types.unionof(property.read, types.singleton(nil))) end
		if property.write then result:setwriteproperty(key, types.unionof(property.write, types.singleton(nil))) end
	end
	return result
end

local function nilAs<T>(): T
	return nil :: T
end

return table.freeze {
	any = nil :: any,
	nilAs = nilAs,
}
