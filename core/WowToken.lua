local _, AUR = ...

if AUR.State and AUR.State.libraryIncompatible then return end

local AWL = ArcaneWizardLibrary
local WowToken = AUR.Modules.WowToken
local Utils = AUR.Modules.Utils
local TokenData = AUR.WOW_TOKEN_DATA

local EventFrame = nil
local ticker = nil
local pollSeconds = nil
local lastRequest = nil
local supported = false

local function HasAPI()
	return C_WowTokenPublic
		and type(C_WowTokenPublic.GetCommerceSystemStatus) == "function"
		and type(C_WowTokenPublic.UpdateMarketPrice) == "function"
		and type(C_WowTokenPublic.GetCurrentMarketPrice) == "function"
end

local function NotifyViews()
	AUR.Modules.Overview:RefreshToken()
	AUR.Modules.Chart:OnTokenUpdated()
end

local function StorePrice(result)
	if result == nil or result ~= LE_TOKEN_RESULT_SUCCESS or not C_WowTokenPublic.GetCommerceSystemStatus() then return end

	local price = C_WowTokenPublic.GetCurrentMarketPrice()
	-- Der Selbstvergleich erkennt NaN und verhindert ungültige Preise in der Historie.
	if type(price) ~= "number" or price <= 0 or price == math.huge or price ~= price then return end

	Aurarium_DataTokenPrices = Aurarium_DataTokenPrices or {}
	AUR.Data.tokenPrices = Aurarium_DataTokenPrices
	local records = AUR.Data.tokenPrices
	local today = Utils:GetToday()
	local changed = records[today] ~= price or not supported
	records[today] = price
	supported = true

	if changed then
		NotifyViews()
	end
end

function WowToken:IsSupported()
	return AWL.GAME_TYPE_RETAIL and supported
end

function WowToken:GetRegionName()
	local region = type(GetCurrentRegion) == "function" and GetCurrentRegion()

	return TokenData.regions[region] or "-"
end

function WowToken:GetHistory()
	local history = {}
	local today = Utils:GetToday()

	for day, price in pairs(AUR.Data.tokenPrices or {}) do
		if day <= today then
			history[#history + 1] = {date = day, value = price}
		end
	end

	table.sort(history, function(a, b) return a.date < b.date end)

	return history
end

function WowToken:RequestPrice()
	if not EventFrame or not C_WowTokenPublic.GetCommerceSystemStatus() then return end

	local now = GetTime()
	if lastRequest and now - lastRequest < pollSeconds then return end

	lastRequest = now
	C_WowTokenPublic.UpdateMarketPrice()
end

function WowToken:RefreshStatus()
	if not EventFrame then return end

	local enabled, interval = C_WowTokenPublic.GetCommerceSystemStatus()
	local nextInterval = type(interval) == "number" and interval > 0 and interval < math.huge
		and interval or TokenData.defaultPollSeconds

	if ticker and (not enabled or nextInterval ~= pollSeconds) then
		ticker:Cancel()
		ticker = nil
	end

	pollSeconds = nextInterval

	if not enabled then return end

	if not supported then
		supported = true
		NotifyViews()
	end

	self:RequestPrice()

	if not ticker then
		ticker = C_Timer.NewTicker(pollSeconds, function()
			WowToken:RefreshStatus()
		end)
	end
end

function WowToken:Initialize()
	if not AWL.GAME_TYPE_RETAIL or EventFrame or not HasAPI() then return end

	if C_EventUtils and C_EventUtils.IsEventValid then
		if not C_EventUtils.IsEventValid("TOKEN_STATUS_CHANGED")
			or not C_EventUtils.IsEventValid("TOKEN_MARKET_PRICE_UPDATED")
		then
			return
		end
	end

	AUR.Data.tokenPrices = Aurarium_DataTokenPrices
	supported = next(AUR.Data.tokenPrices or {}) ~= nil
	EventFrame = CreateFrame("Frame")
	EventFrame:RegisterEvent("TOKEN_STATUS_CHANGED")
	EventFrame:RegisterEvent("TOKEN_MARKET_PRICE_UPDATED")
	EventFrame:SetScript("OnEvent", function(_, event, result)
		if event == "TOKEN_MARKET_PRICE_UPDATED" then
			StorePrice(result)
		else
			WowToken:RefreshStatus()
		end
	end)

	if supported then
		NotifyViews()
	end

	self:RefreshStatus()
end
