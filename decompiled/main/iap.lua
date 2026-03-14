local iap_utils = require("lib.iap_utils")
local dispatcher = require("crit.dispatcher")
local save_file = require("lib.save_file")
local h_iap_transaction_update = hash("iap_transaction_update")
local h_iap_bought_full_game = hash("iap_bought_full_game")
local h_iap_buy = hash("iap_buy")
local h_iap_restore = hash("iap_restore")

local function is_consumable(product_id)
	return false
end

local function verify_full_game()
	return not not save_file.config.owns_full_game
end

local function store_full_game(transaction)
	save_file.config_set("owns_full_game", true)
end

local function unlock_full_game(transaction)
	store_full_game(transaction)

	iap_utils.verified_purchase_full_game = true

	dispatcher.dispatch(h_iap_bought_full_game)
end

local function iap_listener(self, transaction, error)
	if error then
		print(error.error)

		return
	end

	if transaction.state == iap.TRANS_STATE_PURCHASING then
		dispatcher.dispatch(h_iap_transaction_update, {
			state = "purchasing",
			id = transaction.ident
		})
	elseif transaction.state == iap.TRANS_STATE_PURCHASED then
		dispatcher.dispatch(h_iap_transaction_update, {
			state = "purchased",
			id = transaction.ident
		})

		if is_consumable(transaction.ident) or iap.get_provider_id() ~= iap.PROVIDER_ID_GOOGLE then
			iap.finish(transaction)
		end
	elseif transaction.state == iap.TRANS_STATE_UNVERIFIED then
		dispatcher.dispatch(h_iap_transaction_update, {
			state = "unverified",
			id = transaction.ident
		})
	elseif transaction.state == iap.TRANS_STATE_FAILED then
		dispatcher.dispatch(h_iap_transaction_update, {
			state = "failed",
			id = transaction.ident
		})
	elseif transaction.state == iap.TRANS_STATE_RESTORED then
		dispatcher.dispatch(h_iap_transaction_update, {
			state = "restored",
			id = transaction.ident
		})
	end

	if transaction.ident == iap_utils.FULL_GAME and (transaction.state == iap.TRANS_STATE_PURCHASED or transaction.state == iap.TRANS_STATE_RESTORED) then
		unlock_full_game(transaction)
	end
end

function _env:init()
	if not iap_utils.has_iap_demo() then
		return
	end

	iap.set_listener(iap_listener)

	if verify_full_game() then
		iap_utils.verified_purchase_full_game = true
	end

	self.sub_id = dispatcher.subscribe({
		h_iap_buy,
		h_iap_restore
	})
end

function _env:final()
	if self.sub_id then
		dispatcher.unsubscribe(self.sub_id)
	end
end

function _env:on_message(message_id, message)
	if message_id == h_iap_buy then
		if message.id == iap_utils.FAKE_FULL_GAME then
			unlock_full_game({
				ident = iap_utils.FAKE_FULL_GAME
			})
		else
			iap.buy(message.id)
		end
	elseif message_id == h_iap_restore then
		iap.restore()
	end
end
