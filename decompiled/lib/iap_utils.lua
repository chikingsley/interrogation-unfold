local env = require("lib.environment")
local dispatcher = require("crit.dispatcher")
local h_iap_buy = hash("iap_buy")
local h_iap_restore = hash("iap_restore")

if env.mock_iap then
	iap = {
		TRANS_STATE_RESTORED = "TRANS_STATE_RESTORED",
		PROVIDER_ID_FACEBOOK = "PROVIDER_ID_FACEBOOK",
		TRANS_STATE_PURCHASED = "TRANS_STATE_PURCHASED",
		TRANS_STATE_FAILED = "TRANS_STATE_FAILED",
		PROVIDER_ID_GOOGLE = "PROVIDER_ID_GOOGLE",
		TRANS_STATE_UNVERIFIED = "TRANS_STATE_UNVERIFIED",
		REASON_USER_CANCELED = "REASON_USER_CANCELED",
		REASON_UNSPECIFIED = "REASON_UNSPECIFIED",
		PROVIDER_ID_APPLE = "PROVIDER_ID_APPLE",
		TRANS_STATE_PURCHASING = "TRANS_STATE_PURCHASING",
		PROVIDER_ID_AMAZON = "PROVIDER_ID_AMAZON"
	}
end

local M = {
	FAKE_FULL_GAME = "_____fake",
	FULL_GAME = "com.mixtvision.interrogation.full_game"
}

function M.is_demo()
	return env.demo or iap and env.iap_demo and not M.verified_purchase_full_game
end

function M.has_iap_demo()
	return iap and env.iap_demo
end

function M.buy_full_game()
	dispatcher.dispatch(h_iap_buy, {
		id = M.FULL_GAME
	})
end

function M.restore()
	dispatcher.dispatch(h_iap_restore)
end

local function get_store_url()
	if env.steam then
		local app_id = sys.get_config("steam.app_id")

		if app_id then
			return "http://store.steampowered.com/app/" .. tostring(app_id)
		end
	end

	if env.gog then
		local gog_url = sys.get_config("gog.store_url")

		if gog_url then
			return gog_url
		end
	end

	return sys.get_config("demo.store_url")
end

function M.buy_full_game_or_direct_to_store()
	if not M.is_demo() then
		return false
	end

	if M.has_iap_demo() then
		M.buy_full_game()

		return true
	end

	sys.open_url(get_store_url() .. "?utm_source=demo")

	return false
end

if env.mock_iap then
	local function listener()
		return
	end

	function iap.set_listener(cb)
		listener = cb
	end

	function iap.buy(product_id)
		print("IAP: Buy", product_id)
		timer.delay(0, false, function ()
			listener(nil, {
				ident = M.FULL_GAME,
				state = iap.TRANS_STATE_PURCHASING
			})
		end)
		timer.delay(3, false, function ()
			listener(nil, {
				ident = M.FULL_GAME,
				state = math.random(2) == 1 and iap.TRANS_STATE_PURCHASED or iap.TRANS_STATE_FAILED
			})
		end)
	end

	function iap.restore()
		print("IAP: restore")
		timer.delay(0, false, function ()
			listener(nil, {
				ident = M.FULL_GAME,
				state = iap.TRANS_STATE_RESTORED
			})
		end)

		return true
	end

	function iap.finish(transaction)
		pprint("IAP: Finished transaction", transaction)
	end

	function iap.get_provider_id()
		return iap.PROVIDER_ID_APPLE
	end

	function iap.list(callback)
		return
	end
end

return M
