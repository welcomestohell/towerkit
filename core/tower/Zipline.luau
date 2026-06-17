const activation = require "@libs/activation"
const constraints = require "@libs/constraints"
const curves = require "@libs/curves"
const functions = require "@libs/functions"
const std = require "@libs/std"
const toggle = require "@libs/toggle"
const Oklab = require "@libs/vendor/Oklab"

const Zipline = std.Mechanic {
	emoji = "🚠",
	name = "Zipline",
	description = "When activated, carries the activator across it's curve.",
	instanceType = std.gt.instanceTree {
		-- Handle = std.isA.BasePart(),
		Points = std.isA.Instance(),
	},

	std.AttributeSection "Curve",
	CurveType = std.Attribute("CurveType", std.gt.keysOf(curves.CURVES), "CatmullRom"),
	CatenarySlack = std.Attribute("CatenarySlack", std.gt.constrainNumberExclusive(1), 1.05),

	std.AttributeSection "Segments",
	SegmentType = std.Attribute("SegmentType", std.gt.literals("Part", "Beam"), "Part"),
	SegmentCount = std.Attribute("SegmentCount", std.gt.positiveNumber, 20),
	SegmentThickness = std.Attribute("SegmentThickness", std.gt.positiveNumber, 0.25),
	SegmentColor = std.Attribute(
		"SegmentColor",
		std.gt.literals("Startpoint", "Endpoint", "BothEndpoints", "AllPoints"),
		"AllPoints"
	),
	SegmentTransparency = std.Attribute(
		"SegmentTransparency",
		std.gt.literals("Startpoint", "Endpoint", "BothEndpoints"),
		"BothEndpoints"
	),

	std.AttributeSection "Activation",
	StartpointActivation = activation.useAttributes "StartpointActivation",
	EndpointActivation = activation.useAttributes "EndpointActivation",
	SegmentActivation = activation.useAttributes "SegmentActivation",
}

export type ZiplineMechanic = std.Mechanic<typeof(Zipline), {
	curve: curves.Curve,

	segmentsLife: std.Life?,
	segmentsPartContainer: Instance,
	segments: { BasePart | Beam },

	pointsLife: std.Life?,
	pointInstances: { BasePart },
	points: { Vector3 },
}>

-- we bind activation ourselves
Zipline.bindActivation = functions.noop

function Zipline.calculateSegmentCount(zipline: ZiplineMechanic): number
	const numPoints = #zipline.points
	return if numPoints <= 2 then 1 elseif zipline:CurveType() == "Linear" then numPoints - 1 else zipline:SegmentCount()
end

function Zipline.calculateCurveType(zipline: ZiplineMechanic)
	return if zipline:calculateSegmentCount() == 1 then "Linear" else zipline:CurveType()
end

function Zipline.calculateSegmentTransparency(zipline: ZiplineMechanic, index: number, count: number): number
	const segmentTransparency = zipline:SegmentTransparency()
	return if segmentTransparency == "Startpoint"
		then zipline.pointInstances[1].Transparency
		elseif segmentTransparency == "Endpoint" then zipline.pointInstances[#zipline.pointInstances].Transparency
		elseif segmentTransparency == "BothEndpoints" then math.lerp(
			zipline.pointInstances[1].Transparency,
			zipline.pointInstances[#zipline.pointInstances].Transparency,
			index / count
		)
		else 1
end

function Zipline.calculateSegmentPartColor(zipline: ZiplineMechanic, index: number, count: number): Color3
	const segmentColor = zipline:SegmentColor()
	if segmentColor == "Startpoint" then
		return zipline.pointInstances[1].Color
	elseif segmentColor == "Endpoint" then
		return zipline.pointInstances[#zipline.pointInstances].Color
	elseif segmentColor == "BothEndpoints" then
		return Oklab.lerpColor3s(
			zipline.pointInstances[1].Color,
			zipline.pointInstances[#zipline.pointInstances].Color,
			index / count
		)
	elseif segmentColor == "AllPoints" then
		const alpha = index / count

		const totalGaps = #zipline.points - 1
		const scaledAlpha = alpha * totalGaps

		const pointIndex = math.clamp(math.floor(scaledAlpha) + 1, 1, totalGaps)
		const nextPointIndex = pointIndex + 1

		const localAlpha = scaledAlpha - (pointIndex - 1)

		const startColor = zipline.pointInstances[pointIndex].Color
		const endColor = zipline.pointInstances[nextPointIndex].Color
		return Oklab.lerpColor3s(startColor, endColor, localAlpha)
	else
		return Color3.new()
	end
end

function Zipline.createSegments(zipline: ZiplineMechanic)
	if zipline.segmentsLife and zipline.segmentsLife.alive then zipline.segmentsLife:destroy() end
	const segmentsLife = zipline.life:extend()
	zipline.segmentsLife = segmentsLife
	table.clear(zipline.segments)

	const segmentType = zipline:SegmentType()
	const segmentCount = zipline:calculateSegmentCount()

	const startPoint = zipline.pointInstances[1]
	const startPointPosition = zipline.points[1]
	local previousPosition = zipline.curve:solvePosition(0)

	for index = 1, segmentCount do
		const alpha = index / segmentCount
		const nextPosition = zipline.curve:solvePosition(alpha)

		if previousPosition == nextPosition then
			previousPosition = nextPosition
			continue
		end

		const segmentLength = (nextPosition - previousPosition).Magnitude
		const centerPosition = previousPosition:Lerp(nextPosition, 0.5)
		const segmentCFrame = CFrame.lookAt(centerPosition, nextPosition) * CFrame.Angles(0, math.pi * 0.5, 0)

		local segment
		if segmentType == "Part" then
			segment = segmentsLife:add(Instance.new "Part")
			segment.Name = tostring(index)
			segment.Anchored = false
			segment.CanCollide = false
			segment.CFrame = segmentCFrame
			segment.Material = Enum.Material.SmoothPlastic
			segment.Shape = Enum.PartType.Cylinder
			segment.Size = Vector3.new(segmentLength, 0, 0)

			constraints.weld(segmentsLife, startPoint, segment)
			segment.Parent = zipline.segmentsPartContainer

			activation.bindActivation {
				attributes = zipline.SegmentActivation,
				instanceLife = segmentsLife,
				instance = segment,
				instanceConfiguration = zipline.instanceConfiguration,
				onActivate = zipline.onActivateCallback,
			}
		else
			segment = segmentsLife:add(Instance.new "Beam")
			segment.Name = tostring(index)
			segment.FaceCamera = true
			segment.LightInfluence = 1
			segment.Segments = 1
			segment.Transparency = NumberSequence.new(0)

			segment.Parent = startPoint

			const attachment0, attachment1 = constraints.populateAttachments(segmentsLife, segment)
			attachment0.Position = previousPosition - startPointPosition
			attachment1.Position = nextPosition - startPointPosition
			attachment0.Parent = startPoint
			attachment1.Parent = startPoint
		end

		table.insert(zipline.segments :: { BasePart | Beam }, segment)

		previousPosition = nextPosition
	end

	zipline:updateSegments()
	return zipline.segments
end

function Zipline.updateSegments(zipline: ZiplineMechanic)
	const segmentCount = zipline:calculateSegmentCount()
	const thickness = zipline:SegmentThickness()

	if zipline:SegmentType() == "Part" then
		for _, part in zipline.segments :: { BasePart } do
			const index = tonumber(part.Name) :: number
			part.Color = zipline:calculateSegmentPartColor(index, segmentCount)
			part.Transparency = zipline:calculateSegmentTransparency(index, segmentCount)
			part.Size = Vector3.new(part.Size.X, thickness, thickness)
		end
	else
		for _, beam in zipline.segments :: { Beam } do
			const index = tonumber(beam.Name) :: number
			beam.Color = ColorSequence.new(
				zipline:calculateSegmentPartColor(index - 1, segmentCount),
				zipline:calculateSegmentPartColor(index, segmentCount)
			)
			beam.Transparency = NumberSequence.new(
				zipline:calculateSegmentTransparency(index - 1, segmentCount),
				zipline:calculateSegmentTransparency(index, segmentCount)
			)
			beam.Width0 = thickness
			beam.Width1 = thickness
		end
	end
end

function Zipline.createCurve(zipline: ZiplineMechanic)
	zipline.curve = curves.CURVES[zipline:calculateCurveType()].new {
		points = zipline.points,
		slack = zipline:CatenarySlack(),
	}

	zipline:createSegments()
end

-- FIXME: there are bugs when removing points at runtime, fix tmr morning
function Zipline.solvePoints(zipline: ZiplineMechanic): { Vector3 }
	if zipline.pointsLife and zipline.pointsLife.alive then zipline.pointsLife:destroy() end

	const pointsLife = zipline.life:extend()
	zipline.pointsLife = pointsLife
	pointsLife:add(function()
		zipline:solvePoints()
	end)

	table.clear(zipline.points)
	table.clear(zipline.pointInstances)

	const container = zipline.instance.Points
	for index = 1, #container:GetChildren() do
		const point = container:FindFirstChild(tostring(index))
		if point and point:IsA "BasePart" then
			table.insert(zipline.points, point.Position)
			table.insert(zipline.pointInstances, point)
			toggle.SetCollision(point, false)
			-- FIXME: Name property doesn't fire??
			pointsLife:destroyOn(point:GetPropertyChangedSignal "Name")
			pointsLife:destroyOn(point:GetPropertyChangedSignal "Position")
			pointsLife:add(point:GetPropertyChangedSignal("Color"):Connect(zipline.updateSegmentsCallback))
			pointsLife:add(point:GetPropertyChangedSignal("Transparency"):Connect(zipline.updateSegmentsCallback))
		end
	end

	zipline:createCurve()

	const pointCount = #zipline.pointInstances
	for index, point in zipline.pointInstances do
		toggle.toggleInstance(index % pointCount <= 1, point)

		if index == 1 then
			activation.bindActivation {
				attributes = zipline.StartpointActivation,
				instanceLife = pointsLife,
				instance = zipline.pointInstances[1],
				instanceConfiguration = zipline.instanceConfiguration,
				onActivate = zipline.onActivateCallback,
			}
		end

		if index == #zipline.pointInstances then
			activation.bindActivation {
				attributes = zipline.EndpointActivation,
				instanceLife = pointsLife,
				instance = zipline.pointInstances[#zipline.pointInstances],
				instanceConfiguration = zipline.instanceConfiguration,
				onActivate = zipline.onActivateCallback,
			}
		end
	end

	return zipline.points
end

function Zipline.onStart(self: typeof(Zipline), zipline: ZiplineMechanic, level: std.Level)
	function zipline.onActivateCallback(_, event: activation.ActivationEvent)
		self:onActivate(zipline, level, event)
	end

	function zipline.solvePointsCallback()
		zipline:solvePoints()
	end

	function zipline.createCurveCallback()
		zipline:createCurve()
	end

	function zipline.updateSegmentsCallback()
		zipline:updateSegments()
	end

	zipline.segmentsPartContainer = Instance.new "Folder"
	zipline.segmentsPartContainer.Name = "SegmentParts"
	zipline.segmentsPartContainer.Parent = zipline.instance

	zipline.segments = {}
	zipline.points = {}
	zipline.pointInstances = {}
	zipline:solvePoints()

	zipline.life:addMany(
		zipline.instance.Points.ChildAdded:Connect(zipline.solvePointsCallback),
		zipline.instance.Points.ChildRemoved:Connect(zipline.solvePointsCallback),
		self.CurveType:onChange(zipline, zipline.createCurveCallback),
		self.CatenarySlack:onChange(zipline, zipline.createCurveCallback),
		self.SegmentType:onChange(zipline, zipline.createCurveCallback),
		self.SegmentCount:onChange(zipline, zipline.createCurveCallback),
		self.SegmentColor:onChange(zipline, zipline.updateSegmentsCallback),
		self.SegmentThickness:onChange(zipline, zipline.updateSegmentsCallback),
		self.SegmentTransparency:onChange(zipline, zipline.updateSegmentsCallback)
	)
end

function Zipline.onActivate(
	self: typeof(Zipline),
	zipline: ZiplineMechanic,
	level: std.Level,
	event: activation.ActivationEvent
)
	print("im so activated:", event)
end

return Zipline
