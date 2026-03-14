local dispatcher = require("crit.dispatcher")
local Button = require("crit.button")
local button_sound = require("sound.button")
local KeyPrompt = require("lib.key_prompt")
local intl = require("crit.intl")
local iap_utils = require("lib.iap_utils")
local h_switch_input_method = hash("switch_input_method")
local h_gamepad_rpad_down = hash("gamepad_rpad_down")
local h_key_space = hash("key_space")
local h_key_enter = hash("key_enter")
local h_iap_transaction_update = hash("iap_transaction_update")

function _env:init()
	local buy_label = msg.url("buy_button#label")

	intl.translate_label(buy_label, "demo_cta.buy")
	intl.translate_label("title#label", "demo_cta.title")
	intl.translate_label("body#label", "demo_cta.body")

	local transaction_state_label = msg.url("transaction_state#label")

	label.set_text(transaction_state_label, "")

	self.transaction_state_label = transaction_state_label
	local prompt_url = msg.url("prompt_a")
	local prompt_component = msg.url(prompt_url.socket, prompt_url.path, "prompt")
	self.key_prompt = KeyPrompt.new(prompt_component, {
		is_sprite = true,
		halo = msg.url(prompt_url.socket, prompt_url.path, "prompt_halo"),
		action_id = self.gamepad_shortcut
	})
	self.buy_button = Button.new(msg.url("buy_button#sprite"), {
		is_sprite = true,
		faded_labels = {
			buy_label
		},
		shortcut_actions = {
			h_gamepad_rpad_down,
			h_key_space,
			h_key_enter
		},
		on_state_change = button_sound.with_sound(Button.darken_on_state_change),
		action = function ()
			if iap_utils.buy_full_game_or_direct_to_store() then
				self.buy_button:set_enabled(false)
			end
		end
	})
	self.sub_id = dispatcher.subscribe({
		h_switch_input_method,
		h_iap_transaction_update
	})

	msg.post(".", "acquire_input_focus")
end

function _env:final()
	dispatcher.unsubscribe(self.sub_id)
end

local function on_input_handler(self, action_id, action)
	self.key_prompt:on_input(action_id, action)

	if self.buy_button:on_input(action_id, action) then
		return true
	end
end

on_input = on_input_handler

function _env:on_message(message_id, message, sender)
	if message_id == h_switch_input_method then
		self.key_prompt:switch_input_method()
	elseif message_id == h_iap_transaction_update and message.id == iap_utils.FULL_GAME then
		self.buy_button:set_enabled(message.state ~= "purchasing")
		intl.translate_label(self.transaction_state_label, "demo_cta.transaction." .. message.state)
	end
end
