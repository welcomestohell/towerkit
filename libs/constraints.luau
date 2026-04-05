local Life = require("@libs/memory/Life")

local function weld(life: Life.Life, from: BasePart, to: BasePart)
	local weldConstraint = Instance.new("WeldConstraint")
	weldConstraint.Part0 = from
	weldConstraint.Part1 = to
	weldConstraint.Parent = to
	return life:add(weldConstraint)
end

local function populateAttachments(life: Life.Life, constraint: Constraint): (Attachment, Attachment)
	local attachment0 = life:add(Instance.new("Attachment"))
	local attachment1 = life:add(Instance.new("Attachment"))

	constraint.Attachment0 = attachment0
	constraint.Attachment1 = attachment1

	attachment0.Name = constraint.Name .. "Attachment0"
	attachment1.Name = constraint.Name .. "Attachment1"

	return attachment0, attachment1
end

return table.freeze {
	weld = weld,
	populateAttachments = populateAttachments,
}
