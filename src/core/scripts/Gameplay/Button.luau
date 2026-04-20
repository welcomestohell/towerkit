local Attribute = require("@libs/Attribute")
local ButtonEnabled = require("./ButtonEnabled")
local Life = require("@libs/memory/Life")
local Signal = require("@pkgs/Signal")
local activation = require("@libs/activation")
local emission = require("@libs/emission")
local msets = require("@libs/collections/msets")
local properties = require("@libs/properties")
local sounds = require("@libs/sounds")
local std = require("@libs/std")
local threadpool = require("@libs/threadpool")
local tweens = require("@libs/tweens")

local GLOW_PADDING = Vector3.new(0.05, 0.05, 0.05)

local Button = std.Mechanic({})
export type ButtonMechanic = std.Mechanic<typeof(Button)>
Button.basename = "Button"
Button.instanceType = std.isA.BasePart()
Button.debuggerEmoji = "🖲️"

function Button.useAttributes(implementation: std.MechanicImplementationLike)
	local attributes = {}

	attributes.Enabled = implementation:withEnabled()
	attributes.Active = implementation:withActive()
	attributes.Id = implementation:attribute("Id", std.gt.optional(std.gt.string()), nil)
	attributes.PressedOffset = implementation:attribute("PressedOffset", std.gt.CFrame(), CFrame.new(0, -0.5, 0))
	attributes.Cooldown = implementation:attribute("Cooldown", std.gt.positiveNumber, 0)
	attributes.Duration = implementation:attribute("Duration", std.gt.positiveNumber, 0)

	return attributes
end

export type ButtonAttributes = typeof(Button:useAttributes())

local attributes = Button:useAttributes()
Button.Enabled = attributes.Enabled
Button.Active = attributes.Active
Button.Id = attributes.Id
Button.PressedOffset = attributes.PressedOffset
Button.Cooldown = attributes.Cooldown
Button.Duration = attributes.Duration
Button.ActivatedEmissionTag = Button:attribute("ActivatedEmissionTag", std.gt.string(), "EmitOnButtonActivated")
Button.DeactivatedEmissionTag = Button:attribute("DeactivatedEmissionTag", std.gt.string(), "EmitOnButtonDeactivated")

Button:attributeSection("Activation")
Button.Activation = activation.useAttributes(Button)

Button:attributeSection("Sound Effects")
Button.Sound = sounds.useAttributes(Button)

Button:attributeSection("Transition")
Button.Transition = tweens.useAttributes(Button)

Button.enabledButtonsById = std.LevelState({} :: { [string]: { [ButtonMechanic]: true } })
Button.onPressed = Signal.new() :: Signal.Signal<string>

activation
	.registerMode("ButtonActivated", {
		implement = function(context: activation.ActivationContext) end,
	})
	:expect("Failed to register ButtonActivated activation mode")

function Button.glowButton(props: {
	life: Life.Life,
	instance: BasePart,
	instanceConfiguration: Instance,
	tweenAttributes: tweens.TweenAttributes,
	flash: boolean?,
})
	local life = props.life:extend()

	local adornment = Instance.new("BoxHandleAdornment")
	adornment.Adornee = props.instance
	adornment.Color3 = props.instance.Color
	adornment.Name = props.instance.Name .. "Glow"
	adornment.Size = props.instance.Size + GLOW_PADDING
	adornment.Transparency = 1
	adornment.Parent = props.instance

	local tweenConfiguration = tweens.configurationFromAttributes(props.tweenAttributes, props.instanceConfiguration)
	tweenConfiguration.duration = tweenConfiguration.duration or 0.25
	if props.flash then
		tweenConfiguration.isReversed = true
		tweens.play(adornment, { Transparency = 0 }, tweenConfiguration)
		task.delay(tweenConfiguration.duration * 2 :: any, function(adornment)
			adornment:Destroy()
		end, adornment)
	else
		tweens.play(adornment, { Transparency = 0 }, tweenConfiguration)
		life:add(function()
			tweens.play(adornment, { Transparency = 1 }, tweenConfiguration)
			task.delay(tweenConfiguration.duration, function(adornment)
				adornment:Destroy()
			end, adornment)
		end)
	end
end

function Button.toggleId(self: typeof(Button), level: std.Level, id: string)
	local bes = ButtonEnabled.besById:get(level)[id]
	if bes then
		for _, be in bes do
			threadpool.spawn(ButtonEnabled.toggle, be)
		end
	end
end

function Button.onActivate(self: typeof(Button), button: ButtonMechanic, level: std.Level)
	if not button:Enabled() or button:Active() then
		return
	end

	local id = button:Id()
	if id == nil then
		return
	end

	local enabledButtonsById = msets.get(self.enabledButtonsById:get(level), id)

	self.Activation.Enabled(button, false)
	button:Active(true)
	enabledButtonsById[button] = true

	local deactivationLife = button.life:extend()
	deactivationLife:add(function()
		button:Active(false)
		enabledButtonsById[button] = nil
		emission.emitTaggedDescendants(button.instance, button:DeactivatedEmissionTag())
		task.delay(button:Cooldown(), Attribute.set :: any, self.Activation.Enabled, button, true)
	end)

	self.glowButton({
		life = deactivationLife,
		instance = button.instance,
		instanceConfiguration = button.instanceConfiguration,
		tweenAttributes = self.Transition,
	})

	emission.emitTaggedDescendants(button.instance, button:ActivatedEmissionTag())

	if self.Sound.Play(button) then
		sounds.playMechanic(self.Sound, button :: any, sounds.sfx.button)
	end

	if button.instance.Anchored then
		local originalTransform = button.instance.CFrame
		local pressedOffset = button:PressedOffset()

		tweens.playFromAttributes(button.instance, { CFrame = originalTransform * pressedOffset }, self.Transition)

		deactivationLife:add(function()
			if button.life.destroyed == false then
				local configuration = tweens.configurationFromAttributes(self.Transition, button)
				tweens.play(button.instance, { CFrame = originalTransform }, configuration)
				task.delay(configuration.duration, properties.setUnsafe, button.instance, "CFrame", originalTransform)
			end
		end)
	end

	local duration = button:Duration()
	if duration > 0 then
		deactivationLife:delay(duration, Life.destroy, deactivationLife)
	end

	local function onDisabled(isEnabled: boolean)
		if not isEnabled then
			deactivationLife:destroy()
		end
	end

	deactivationLife:add(self.Enabled:onChange(button, onDisabled))
	deactivationLife:add(self.Active:onChange(button, onDisabled))
end

function Button.onStart(self: typeof(Button), button: ButtonMechanic, level: std.Level)
	button.life:add(self.Active:onChange(button, function(active)
		local id = button:Id()
		if id then
			self:toggleId(level, id)
		end
	end))

	button.life:add(self.Id:onChange(button, function(_id)
		-- TODO
	end))
end

return Button
