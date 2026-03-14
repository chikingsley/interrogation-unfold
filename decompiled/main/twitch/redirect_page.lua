return function (state_token)
	return [[
<!doctype html>
<html>
  <body>
    <style>
      html {
        background-color: #333;
        color: #fff;
        font-family: Helvetica, Arial, sans-serif;
      }

      #root {
        margin: 16px auto;
        width: 100%;
        max-width: 600px;
        text-align: center;
      }

      .error {
        color: #f33;
      }

      #form {
        margin-bottom: 16px;
      }

      .channel {
        width: 100%;
        max-width: 300px;
        display: flex;
        flex-direction: row;
        padding: 16px;
        border-radius: 16px;
        border: 1px solid rgba(255, 255, 255, 0.5);
        margin-left: auto;
        margin-right: auto;
        cursor: pointer;
      }

      .channel:hover {
        background: rgba(255, 255, 255, 0.1);
      }

      .avatar {
        width: 64px;
        height: 64px;
        content-fit: cover;
        border-radius: 50%;
        margin-right: 16px;
      }

      .channel-info {
        flex: 1;
        display: flex;
        flex-direction: column;
        align-items: stretch;
        justify-content: center;
      }

      .name {
        font-weight: bold;
      }
    </style>
    <div id="root"></div>
    <script>
    (function () {
      function parseQuery(queryString) {
        const query = {}
        const pairs = ((queryString[0] === '?' || queryString[0] === '#')
          ? queryString.substr(1)
          : queryString
        ).split('&')

        for (let i = 0; i < pairs.length; i++) {
          const pair = pairs[i].split('=')
          query[decodeURIComponent(pair[0])] = decodeURIComponent(pair[1] || '')
        }
        return query
      }

      const rootEl = document.getElementById('root')

      function renderError(error) {
        const s = error.toString()
        rootEl.innerHTML = `<div class="error">${s}</div>`
      }

      const query = parseQuery(document.location.hash || '')
      const accessToken = query.access_token

      const state = ']] .. state_token .. [[
'
      if (query.state !== state) { return renderError('Invalid state token') }
      if (!accessToken) { return renderError('No access token') }

      const apiCall = (url, options) => {
        return fetch(url, options).then(res => {
          if (!res.ok) {
            throw new Error(`Request failed with HTTP status ${res.status}: ${res.statusText}`)
          }
          return res.json()
        })
      }

      apiCall('https://id.twitch.tv/oauth2/validate', { headers: {
        Authorization: `OAuth ${accessToken}`
      }}).then(({ login: userLogin }) => {
        if (!userLogin) {
          throw new Error('You must be logged in as a user')
        }

        rootEl.innerHTML = `
          <h3 id="label">Select channel where to connect vote chat bot</h3>
          <p>During interrogations and story choices, a button with a Twitch logo will appear in the bottom-right corner of the screen. Press it, then invite your viewers to vote in chat by sending a message containing only the letter associated with their desired option.</p>
          <form id="form">
            <label for="input">Channel ID: </label>
            <input id="input" type="text" placeholder="Type channel ID" value="${userLogin}"></input>
          </form>
          <div id="result"></div>
        `

        const inputEl = document.getElementById('input')
        const resultEl = document.getElementById('result')
        let displayedChannel = null

        function renderChannelError(error) {
          const s = error.toString()
          resultEl.innerHTML = `<div class="error">${s}</div>`
        }

        function renderUser(user) {
          displayedChannel = user.login
          resultEl.innerHTML = `<div class="channel">
            <img class="avatar" src="${user.profile_image_url}" />
            <div class="channel-info">
              <div class="name">${user.display_name || user.login}</div>
              <div class="description">${user.description}</div>
            </div>
          </div>`

          resultEl.getElementsByClassName('channel')[0].onclick = () => {
            rootEl.innerHTML = '<h3>Loading...</h3>'
            apiCall('/twitch/login/' +
              `access_token=${encodeURIComponent(accessToken)}` +
              `&state=${encodeURIComponent(state)}` +
              `&channel=${encodeURIComponent(displayedChannel)}` +
              `&login=${encodeURIComponent(userLogin)}`
            ).then(() => {
              rootEl.innerHTML = '<h3>You can close this browser tab now</h3>'
              window.close()
            }, renderError)
          }
        }

        function fetchChannel(login) {
          displayedChannel = null

          if (!login) {
            resultEl.innerHTML = ''
            return
          }

          apiCall(
            `https://api.twitch.tv/helix/users?login=${encodeURIComponent(login)}`,
             { headers: { Authorization: `Bearer ${accessToken}` } }
          ).then(({ data }) => {
            if (login !== inputEl.value) { return }
            const user = data[0]
            if (!user) { throw new Error("Channel not found") }
            renderUser(user)
          }).catch(renderChannelError)

          console.log(login)
        }

        let timer = null
        const onChange = () => {
          timer = null
          fetchChannel(inputEl.value)
        }

        inputEl.oninput = (evt) => {
          if (timer) { clearTimeout(timer) }
          timer = setTimeout(onChange, 500)
        }

        fetchChannel(userLogin)
      }, renderError)
    })()
    </script>
  </body>
</html>
]]
end
