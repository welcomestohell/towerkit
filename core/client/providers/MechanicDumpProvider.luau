const HttpService = game:GetService "HttpService"
const ReplicatedStorage = game:GetService "ReplicatedStorage"

const tables = require "@libs/collections/tables"
const Level = require "@libs/core/Level"
const Mechanic = require "@libs/core/Mechanic"
const gt = require "@libs/vendor/gt"
const prvd = require "@roblox_packages/prvd"

--[=[
	@class MechanicDumpProvider

	Provides a JSON dump of all Welcome To Hell mechanics. It's useful for
	implementing your own plugins that extend Welcome To Hell's kits.

	TODO: this class is temporary so we can get the plugin up and running
]=]
const MechanicDumpProvider = {}
export type MechanicDumpProvider = typeof(MechanicDumpProvider)

function MechanicDumpProvider.onStart()
	const dump = {}
	for _, implementation in Level.baseScripts.mechanicImplementationByName do
		const implementation = Mechanic.downcast(implementation)
		dump[implementation.name] = {
			name = implementation.name,
			emoji = implementation.emoji,

			attributeSections = tables.map(
				implementation._metadata.attributeSections,
				function(index, section: Mechanic.AttributeSection)
					section.attributes = table.clone(section.attributes)
					for index, attribute in section.attributes do
						section.attributes[index] = {
							name = attribute.attribute,
							type = gt.serialize(attribute.check),
						} :: any
					end
					return index, section
				end
			),
		}
	end

	const encodedDump = HttpService:JSONEncode(dump)

	const bind = Instance.new "BindableFunction"
	bind.Name = "GetMechanicDump"
	function bind.OnInvoke()
		return encodedDump
	end
	bind.Parent = ReplicatedStorage
end

return prvd(MechanicDumpProvider)
