local sys_config = require("lib.sys_config")
local url_utils = require("lib.url_utils")

return function ()
	if webview then
		local html_data = sys.load_resource("/resources/custom/licenses.html")
		local update_timer, close_request = nil
		local shown = false

		local function show_webview(webview_id)
			if shown then
				return
			end

			shown = true

			webview.set_visible(webview_id, 1)

			update_timer = timer.delay(0, true, function ()
				if not close_request then
					close_request = webview.eval(webview_id, "window.shouldClose")
				end
			end)
		end

		local webview_id = webview.create(function (_, webview_id, request_id, type, data)
			if type == webview.CALLBACK_RESULT_URL_OK then
				show_webview(webview_id)
			elseif type == webview.CALLBACK_RESULT_URL_ERROR then
				print("ERROR in webview: " .. data.result)
			elseif type == webview.CALLBACK_RESULT_EVAL_OK and request_id == close_request then
				close_request = nil
				local result = data.result

				if result and (result == "true" or tonumber(result) and tonumber(result) ~= 0) then
					timer.cancel(update_timer)

					update_timer = nil

					webview.destroy(webview_id)
				end
			end
		end)

		webview.open_raw(webview_id, html_data, {
			hidden = true
		})

		return
	end

	local path = sys_config.bundle_root_path .. sys_config.path_sep .. "licenses.html"

	if sys_config.system_name == "Darwin" then
		path = sys_config.bundle_root_path .. "/Contents/Resources/licenses.html"
	end

	if sys_config.path_sep == "\\" then
		path = "/" .. path:gsub("\\", "/")
	else
		path = url_utils.url_encode(path)
	end

	local url = "file://" .. path

	print("Opening " .. url)
	sys.open_url(url)
end
