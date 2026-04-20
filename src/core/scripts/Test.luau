local functions = require("@libs/functions")
local std = require("@libs/std")
local tables = require("@libs/collections/tables")

--[=[
    @class Test
    @tag Mechanic

    Test stand for attributes and mechanic loading.
]=]
local Test = std.Mechanic({})
export type TestMechanic = std.Mechanic<typeof(Test)>
Test.basename = "Test"
Test.instanceType = std.isA.Instance()
Test.debuggerEmoji = "🧪"

local DATA_TYPES: { [string]: any } = {
	string = "Hello World",
	boolean = true,
	number = 67,
	UDim = UDim.new(0.6, 0.7),
	UDim2 = UDim2.fromScale(0.6, 0.7),
	BrickColor = BrickColor.Red(),
	Color3 = Color3.fromHex("#b00b69"),
	Vector2 = Vector2.new(6, 7),
	Vector3 = Vector3.new(0, 6, 7),
	CFrame = CFrame.new(1, 2, 3) * CFrame.Angles(0, math.rad(45), 0),
	NumberSequence = NumberSequence.new(6, 7),
	ColorSequence = ColorSequence.new(Color3.fromHex("#b00b69")),
	NumberRange = NumberRange.new(6, 7),
	Rect = Rect.new(Vector2.new(6, 6), Vector2.new(7, 7)),
	Font = Font.fromEnum(Enum.Font.Merriweather),
}

local DATA_TYPE_KEYS = tables.keys(DATA_TYPES)
table.sort(DATA_TYPE_KEYS)

Test:attributeSection("Required Data Types")
for _, key in DATA_TYPE_KEYS do
	Test:attribute("Required" .. key, std.gt.isTypeof(key), DATA_TYPES[key])
end

Test:attributeSection("Empty Data Types")
for _, key in DATA_TYPE_KEYS do
	Test:attribute(key, std.gt.optional(std.gt.isTypeof(key)), nil)
end

Test:attributeSection("Optional Data Types")
for _, key in DATA_TYPE_KEYS do
	Test:attribute("Optional" .. key, std.gt.optional(std.gt.isTypeof(key)), DATA_TYPES[key])
end

Test:attributeSection("Custom Types")
Test:attribute("Unions", std.gt.union3(std.gt.number(), std.gt.Vector3(), std.gt.CFrame()), 67)
Test:attribute(
	"NestedUnions",
	std.gt.union3(std.gt.number(), std.gt.union2(std.gt.Vector2(), std.gt.Vector3()), std.gt.CFrame()),
	67
)
Test:attribute(
	"Literals",
	std.gt.union3(functions.literal("Foo"), functions.literal("Bar"), functions.literal("Qux")),
	"Foo"
)

function Test:onActivate(test: TestMechanic)
	test.log:info("Activated!")
end

return Test
