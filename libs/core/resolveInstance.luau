-- LUAU FIXME: Waiting on cyclic requires RFC to be merged, this depends on
-- Mechanic type </3
export type InstanceLike = any

local function resolveInstance(resolvable: InstanceLike): Instance
	local type = typeof(resolvable)
	if type == "Instance" then
		return resolvable
	elseif type == "table" then
		return resolvable.instanceConfiguration or resolvable.instance
	else
		error(`Expected an instance or a mechanic, got {resolvable}`)
	end
end

return resolveInstance
