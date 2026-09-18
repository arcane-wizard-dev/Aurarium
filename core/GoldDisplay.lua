local addonName, AUR = ...

-- Library
local AWL = ArcaneWizardLibrary
local Addon = AWL:GetAddon(addonName)

-- Current module
local GoldDisplay = AUR.Modules.GoldDisplay

-- Module imports
local Overview = AUR.Modules.Overview
local Utils = AUR.Modules.Utils

-- Variables
local GoldDisplayFrame
local CurrentGoldText
local DailyChangeText

-----------------------
--- Local Functions ---
-----------------------

local function GetDisplayMode()
	local data = AUR.GOLD_DISPLAY_DATA
	local displayModeKey = AUR.Settings.goldDisplay["display-mode"] or data.defaultDisplayMode

	return data.displayModes[displayModeKey] or data.displayModes[data.defaultDisplayMode]
end

local function FormatGold(copper)
	local value = copper or 0
	local coinIcons = AUR.GOLD_DISPLAY_DATA.coinIcons
	local displayMode = GetDisplayMode()
	local gold = floor(value / (100 * 100))
	local silver = floor((value / 100) % 100)
	local copperValue = value % 100
	local parts = {
		string.format("%s |T%d:0|t", BreakUpLargeNumbers(gold), coinIcons.gold)
	}

	if displayMode.showSilver then
		parts[#parts + 1] = string.format("%02d |T%d:0|t", silver, coinIcons.silver)
	end

	if displayMode.showCopper then
		parts[#parts + 1] = string.format("%02d |T%d:0|t", copperValue, coinIcons.copper)
	end

	return table.concat(parts, " ")
end

local function FormatGoldDiff(diff)
	local sign = diff > 0 and "+" or diff < 0 and "-" or "±"
	local absVal = math.abs(diff)

	return sign .. " " .. FormatGold(absVal)
end

local function SetDiffTextColor(fontString, diff)
	local colors = AUR.GOLD_DISPLAY_DATA.colors
	local color = colors.neutral

	if diff > 0 then
		color = colors.positive
	elseif diff < 0 then
		color = colors.negative
	end

	fontString:SetTextColor(color[1], color[2], color[3])
end

local function GetPreviousGold(characterGUID, today)
	local characterHistory = AUR.Data.balance and AUR.Data.balance[characterGUID]

	if not characterHistory then
		return nil
	end

	local lastDate
	local previousGold

	for dateKey, dayData in pairs(characterHistory) do
		if dateKey < today and dayData["gold"] ~= nil and (not lastDate or dateKey > lastDate) then
			lastDate = dateKey
			previousGold = dayData["gold"]
		end
	end

	return previousGold
end

local function GetPosition()
	local settings = AUR.Settings.goldDisplay or {}
	local position = settings.position or {}
	local defaultPosition = AUR.GOLD_DISPLAY_DATA.defaultPosition

	return {
		point = position.point or defaultPosition.point,
		relativePoint = position.relativePoint or defaultPosition.relativePoint,
		x = position.x or defaultPosition.x,
		y = position.y or defaultPosition.y
	}
end

local function SavePosition()
	if not GoldDisplayFrame or not AUR.Settings.goldDisplay then
		return
	end

	local point, _, relativePoint, x, y = GoldDisplayFrame:GetPoint(1)

	if not point then
		return
	end

	AUR.Settings.goldDisplay.position = {
		point = point,
		relativePoint = relativePoint,
		x = x,
		y = y
	}
end

local function RestorePosition()
	local position = GetPosition()

	GoldDisplayFrame:ClearAllPoints()
	GoldDisplayFrame:SetPoint(position.point, UIParent, position.relativePoint, position.x, position.y)
end

local function CreateLogoButton(frame)
	local data = AUR.GOLD_DISPLAY_DATA
	local logoData = data.logo
	local button = CreateFrame("Button", nil, frame)
	button:SetSize(logoData.size, logoData.size)
	button:SetPoint("LEFT", frame, "LEFT", logoData.x, logoData.y)
	button:RegisterForClicks("LeftButtonUp")
	button:SetScript("OnClick", function()
		Overview:Show()
	end)

	local logo = button:CreateTexture(nil, "BACKGROUND")
	logo:SetTexture(Addon:GetMediaPath(logoData.path))
	logo:SetAllPoints()
	logo:SetAlpha(logoData.alpha)
end

local function CreateValue(parent, yOffset)
	local data = AUR.GOLD_DISPLAY_DATA
	local value = parent:CreateFontString(nil, "OVERLAY", data.valueFontObject)
	value:SetPoint("LEFT", parent, "LEFT", 0, yOffset)
	value:SetPoint("RIGHT", parent, "RIGHT", data.valueOffsetX, yOffset)
	value:SetJustifyH("RIGHT")
	value:SetWordWrap(false)

	return value
end

local function CreateFrameContent(frame)
	local data = AUR.GOLD_DISPLAY_DATA
	local content = frame.content

	CurrentGoldText = CreateValue(content, data.rows.currentValue)
	DailyChangeText = CreateValue(content, data.rows.changeValue)
end

local function CreateGoldDisplay()
	local data = AUR.GOLD_DISPLAY_DATA

	GoldDisplayFrame = AWL.Frames:CreatePopup(data)

	CreateLogoButton(GoldDisplayFrame)

	GoldDisplayFrame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		SavePosition()
	end)

	if GoldDisplayFrame.closeButton then
		GoldDisplayFrame.closeButton:SetScript("OnClick", function()
			GoldDisplay:SetVisible(false)
		end)
	end

	CreateFrameContent(GoldDisplayFrame)
	RestorePosition()
end

------------------------
--- Module Functions ---
------------------------

function GoldDisplay:Initialize()
	if GoldDisplayFrame then
		return
	end

	CreateGoldDisplay()
	self:Refresh()

	if AUR.Settings.goldDisplay["show"] then
		GoldDisplayFrame:Show()
	end
end

function GoldDisplay:SetVisible(visible)
	AUR.Settings.goldDisplay["show"] = visible == true

	if not GoldDisplayFrame then
		return
	end

	if AUR.Settings.goldDisplay["show"] then
		self:Refresh()
		GoldDisplayFrame:Show()
	else
		GoldDisplayFrame:Hide()
	end
end

function GoldDisplay:Refresh()
	if not GoldDisplayFrame then
		return
	end

	GoldDisplayFrame:SetWidth(GetDisplayMode().width)

	local currentGold = Utils:GetGold()
	local characterGUID = AWL.Utils:GetCharacterGUID()
	local previousGold = GetPreviousGold(characterGUID, Utils:GetToday())

	CurrentGoldText:SetText(FormatGold(currentGold))

	if previousGold == nil then
		DailyChangeText:SetText("-")
		SetDiffTextColor(DailyChangeText, 0)
		return
	end

	local dailyChange = currentGold - previousGold

	DailyChangeText:SetText(FormatGoldDiff(dailyChange))
	SetDiffTextColor(DailyChangeText, dailyChange)
end

function GoldDisplay:IsShown()
	return GoldDisplayFrame and GoldDisplayFrame:IsShown()
end
