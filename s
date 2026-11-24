--[[ Exist Scan with UI  (Steal A Niche)
   Run from F9 > Server:
     _G.EXIST = { Brainrot = "Cucutron", Viewer = "YourUsername", Webhook = true }
     loadstring(game:GetService("HttpService"):GetAsync("RAW_GITHUB_URL"))()
   Needs: ServerScriptService.LoadStringEnabled = true, and Allow HTTP Requests on.
]]

local CFG = _G.EXIST or {}
local BRAINROT = CFG.Brainrot or "Cucutron"
local VIEWER = CFG.Viewer -- username who sees the UI (nil = everyone in the server)
local USE_WEBHOOK = CFG.Webhook ~= false
local WEBHOOK = CFG.WebhookUrl or "https://discord.com/api/webhooks/1574744252070625384/5xEUszmyknv-rZMnc_pQ3jAPsWusO5PD2jBkmjymmQbngA0OT4QG92JrAwBp2J_eEhsz"
local STORE_NAME = "DataTest12345754247"

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local DSS = game:GetService("DataStoreService")
local store = DSS:GetDataStore(STORE_NAME)
local Sync = require(game:GetService("ReplicatedStorage").Packages.Synchronizer)

---------------------------------------------------------------- UI
local guis = {}

local function make(class, props, parent)
	local i = Instance.new(class)
	for k, v in pairs(props) do i[k] = v end
	i.Parent = parent
	return i
end

local function buildGui(player)
	local pg = player:FindFirstChildOfClass("PlayerGui")
	if not pg then return end
	local old = pg:FindFirstChild("ExistScanUI")
	if old then old:Destroy() end

	local sg = make("ScreenGui", { Name = "ExistScanUI", ResetOnSpawn = false, DisplayOrder = 999, IgnoreGuiInset = true }, nil)
	local main = make("Frame", {
		Size = UDim2.fromOffset(520, 420), Position = UDim2.new(0.5, -260, 0.5, -210),
		BackgroundColor3 = Color3.fromRGB(22, 24, 30), BorderSizePixel = 0, Active = true, Draggable = true,
	}, sg)
	make("UICorner", { CornerRadius = UDim.new(0, 10) }, main)
	make("UIStroke", { Color = Color3.fromRGB(70, 200, 120), Thickness = 2 }, main)

	local title = make("TextLabel", {
		Size = UDim2.new(1, -50, 0, 36), Position = UDim2.fromOffset(12, 4), BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold, TextSize = 20, TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Color3.new(1, 1, 1), Text = "EXIST SCAN // " .. BRAINROT,
	}, main)
	-- server-made buttons can't detect clicks, so close it with:  _G.ExistClose()

	local status = make("TextLabel", {
		Size = UDim2.new(1, -24, 0, 22), Position = UDim2.fromOffset(12, 40), BackgroundTransparency = 1,
		Font = Enum.Font.Gotham, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Color3.fromRGB(180, 180, 190), Text = "Starting...",
	}, main)

	local list = make("ScrollingFrame", {
		Size = UDim2.new(1, -24, 1, -190), Position = UDim2.fromOffset(12, 66),
		BackgroundColor3 = Color3.fromRGB(30, 33, 42), BorderSizePixel = 0, ScrollBarThickness = 6,
		AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
	}, main)
	make("UICorner", { CornerRadius = UDim.new(0, 8) }, list)
	make("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, list)
	make("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }, list)

	local summary = make("TextLabel", {
		Size = UDim2.new(1, -24, 0, 110), Position = UDim2.new(0, 12, 1, -118),
		BackgroundColor3 = Color3.fromRGB(30, 33, 42), BorderSizePixel = 0,
		Font = Enum.Font.Gotham, TextSize = 14, TextWrapped = true, RichText = true,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
		TextColor3 = Color3.new(1, 1, 1), Text = "Summary appears when the scan finishes.",
	}, main)
	make("UICorner", { CornerRadius = UDim.new(0, 8) }, summary)
	make("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, summary)

	sg.Parent = pg
	guis[player] = { gui = sg, status = status, list = list, summary = summary }
end

local function viewers()
	local out = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if not VIEWER or p.Name:lower() == tostring(VIEWER):lower() then table.insert(out, p) end
	end
	return out
end

for _, p in ipairs(viewers()) do buildGui(p) end
_G.ExistClose = function()
	for _, g in pairs(guis) do if g.gui then g.gui:Destroy() end end
	table.clear(guis)
end

local rowCount = 0
local function uiRow(text, color)
	rowCount += 1
	for _, g in pairs(guis) do
		if g.gui.Parent then
			make("TextLabel", {
				Size = UDim2.new(1, -6, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
				Font = Enum.Font.Gotham, TextSize = 14, TextWrapped = true, RichText = true,
				TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = color or Color3.new(1, 1, 1),
				Text = text, LayoutOrder = rowCount,
			}, g.list)
			g.list.CanvasPosition = Vector2.new(0, 1e6)
		end
	end
end
local function uiStatus(text)
	for _, g in pairs(guis) do if g.gui.Parent then g.status.Text = text end end
end
local function uiSummary(text)
	for _, g in pairs(guis) do if g.gui.Parent then g.summary.Text = text end end
end

---------------------------------------------------------------- Webhook
local URLS = { WEBHOOK, (WEBHOOK:gsub("^https://discord%.com", "https://webhook.lewisakura.moe")) }
local function postNow(payload)
	local body = HttpService:JSONEncode(payload)
	for _ = 1, 4 do
		for _, url in URLS do
			local ok, res = pcall(function()
				return HttpService:RequestAsync({ Url = url, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = body })
			end)
			if ok and res.Success then return true
			elseif ok and res.StatusCode == 429 then
				local w = 2
				pcall(function() w = math.max(1, tonumber(HttpService:JSONDecode(res.Body).retry_after) or 2) end)
				task.wait(w)
			elseif ok then
				print(("[exist] webhook refused: %d %s"):format(res.StatusCode, tostring(res.Body):sub(1, 150)))
			end
		end
		task.wait(2)
	end
	return false
end

local queue, scanDone, sent, failed = {}, false, 0, 0
local function send(p) if USE_WEBHOOK then table.insert(queue, p) end end
if USE_WEBHOOK then
	if not HttpService.HttpEnabled then warn("[exist] HTTP REQUESTS ARE OFF") end
	task.spawn(function()
		while not scanDone or #queue > 0 do
			local p = table.remove(queue, 1)
			if p then
				if postNow(p) then sent += 1 else failed += 1 end
				task.wait(2.2)
			else task.wait(0.5) end
		end
		print(("[exist] webhook finished: %d sent, %d failed"):format(sent, failed))
		uiRow(("<i>Webhook finished: %d sent, %d failed</i>"):format(sent, failed), Color3.fromRGB(150, 150, 160))
	end)
end

---------------------------------------------------------------- Scan
local function waitBudget(kind, keep)
	while DSS:GetRequestBudgetForRequestType(kind) <= keep do task.wait(0.5) end
end

local names = {}
local function nameOf(id)
	if names[id] then return names[id] end
	local p = typeof(id) == "number" and Players:GetPlayerByUserId(id)
	local n = p and p.Name
	if not n and typeof(id) == "number" then
		local ok, r = pcall(Players.GetNameFromUserIdAsync, Players, id)
		n = ok and r or nil
	end
	n = n or ("ID " .. tostring(id)); names[id] = n
	return n
end

local function esc(s) return (tostring(s):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")) end

task.spawn(function()
	local total, muts, traits, online, scanned, unreadable = 0, {}, {}, {}, 0, 0

	local function record(pod, ownerId, where)
		total += 1
		local mut = pod.Mutation or "Normal"
		muts[mut] = (muts[mut] or 0) + 1
		local list = {}
		if type(pod.Traits) == "table" then
			for _, t in ipairs(pod.Traits) do traits[t] = (traits[t] or 0) + 1; table.insert(list, t) end
		end
		local owner = nameOf(ownerId)
		local tr = #list > 0 and table.concat(list, ", ") or "none"
		uiRow(("<b>#%d</b>  %s <font color='#8a8a99'>(%s)</font>  -  <font color='#ffd34d'>%s</font>  -  %s")
			:format(total, esc(owner), where, esc(mut), esc(tr)), where == "online" and Color3.fromRGB(120, 230, 150) or Color3.new(1, 1, 1))
		send({ content = ("**#%d %s** - Owner: **%s** (%s) - Mutation: **%s** - Traits: %s"):format(total, BRAINROT, owner, where, mut, tr) })
		print(("[exist] found #%d %s (%s)"):format(total, owner, where))
	end

	uiStatus("Scanning online players...")
	send({ content = "Starting exist scan for **" .. BRAINROT .. "** (online + offline)..." })
	for _, p in ipairs(Players:GetPlayers()) do
		online[p.UserId] = true
		local ch = Sync:Get(p)
		for _, pod in pairs(ch and ch:Get("AnimalPodiums") or {}) do
			if type(pod) == "table" and pod.Index == BRAINROT then record(pod, p.UserId, "online") end
		end
	end

	waitBudget(Enum.DataStoreRequestType.ListAsync, 2)
	local ok, pages = pcall(function() return store:ListKeysAsync(nil, 100) end)
	if not ok then uiRow("Couldn't list saves: " .. esc(pages), Color3.fromRGB(255, 90, 90)) end
	while ok do
		local okPage, items = pcall(function() return pages:GetCurrentPage() end)
		if not okPage then break end
		for _, item in ipairs(items) do
			local uid = tonumber(item.KeyName)
			if not (uid and online[uid]) then
				local data, read = nil, false
				for _ = 1, 5 do
					waitBudget(Enum.DataStoreRequestType.GetAsync, 5)
					local okGet, res = pcall(function() return store:GetAsync(item.KeyName) end)
					if okGet then data, read = res, true break end
					task.wait(2)
				end
				if not read then unreadable += 1 end
				scanned += 1
				if type(data) == "table" and type(data.AnimalPodiums) == "table" then
					for _, pod in pairs(data.AnimalPodiums) do
						if type(pod) == "table" and pod.Index == BRAINROT then record(pod, uid or item.KeyName, "offline") end
					end
				end
				if scanned % 25 == 0 then uiStatus(("Checking saves... %d checked, %d found"):format(scanned, total)) end
			end
		end
		if pages.IsFinished then break end
		waitBudget(Enum.DataStoreRequestType.ListAsync, 2)
		if not pcall(function() pages:AdvanceToNextPageAsync() end) then break end
	end

	local function lines(map, sep)
		local t = {}
		for k, v in pairs(map) do table.insert(t, { k = k, v = v }) end
		table.sort(t, function(a, b) return a.v > b.v end)
		local out = {}
		for _, e in ipairs(t) do table.insert(out, e.k .. ": " .. e.v) end
		local s = #out > 0 and table.concat(out, sep) or "none"
		return #s > 1000 and (s:sub(1, 990) .. "...") or s
	end

	uiStatus(("Done - %d saves checked%s"):format(scanned, unreadable > 0 and (", " .. unreadable .. " unreadable") or ""))
	uiSummary(("<b>TOTAL: %d</b>\n<b>Mutations:</b> %s\n<b>Traits:</b> %s")
		:format(total, esc(lines(muts, ", ")), esc(lines(traits, ", "))))

	send({ embeds = { {
		title = "EXIST COUNT // " .. BRAINROT, color = 0x00FF00,
		fields = {
			{ name = "Total", value = "**" .. total .. "**", inline = false },
			{ name = "Mutations", value = lines(muts, "\n"), inline = true },
			{ name = "Traits", value = lines(traits, "\n"), inline = true },
			{ name = "Saves checked", value = tostring(scanned) .. (unreadable > 0 and (" (" .. unreadable .. " couldn't be read)") or ""), inline = false },
		},
		footer = { text = os.date("%Y-%m-%d %H:%M:%S") },
	} } })
	print(("[exist] scan done: %d %s found in %d saves (+ online)"):format(total, BRAINROT, scanned))
	scanDone = true
end)
