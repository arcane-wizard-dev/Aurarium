local addonName, AUR = ...

-- Library
local AWL = ArcaneWizardLibrary
local Addon = AWL:GetAddon(addonName)

-- Localization
local L = AUR.Localization

-- Current module
local Options = AUR.Modules.Options

-- Module imports
local GoldDisplay = AUR.Modules.GoldDisplay
local Utils = AUR.Modules.Utils

-- Variables
local dateFormatOptions = {}
for _, format in ipairs(AUR.DATE_FORMATS) do
	dateFormatOptions[#dateFormatOptions + 1] = {value = format, label = L["date-format." .. format]}
end

local goldDisplayModeOptions = {}
local GoldDisplayConfig = AUR.UIConfig.GoldDisplay

for _, option in ipairs(GoldDisplayConfig.displayModeOptions) do
	local previewParts = {}

	for _, coin in ipairs(option.coins) do
		previewParts[#previewParts + 1] = string.format(
			"%d |T%d:0|t",
			GoldDisplayConfig.displayModePreviewValues[coin],
			GoldDisplayConfig.coinIcons[coin]
		)
	end

	goldDisplayModeOptions[#goldDisplayModeOptions + 1] = {
		value = option.value,
		label = table.concat(previewParts, " ")
	}
end

local minimapButtonProxy = setmetatable({}, {
	__index = function(_, key)
		if key == "hide" then
			return not AUR.Settings.general["minimap-button"]["hide"]
		end
	end,
	__newindex = function(_, key, value)
		if key ~= "hide" then
			return
		end

		AUR.Settings.general["minimap-button"]["hide"] = not value

		if value then
			Utils.minimapButton:Show(addonName)
		else
			Utils.minimapButton:Hide(addonName)
		end
	end,
})

local dateFormatProxy = setmetatable({}, {
	__index = function(_, key)
		if key == "date-format" then return Utils:GetDateFormat() end
	end,
	__newindex = function(_, key, value)
		if key ~= "date-format" then return end
		AUR.Settings.general[key] = value
		if AUR.Modules.Overview:IsShown() then
			AUR.Modules.Overview:Refresh()
		end
		AUR.Modules.Chart:RefreshDateFormat()
	end,
})

local goldDisplayProxy = setmetatable({}, {
	__index = function(_, key)
		if key == "show" or key == "show-border" or key == "display-mode" then
			return AUR.Settings.goldDisplay[key]
		end
	end,
	__newindex = function(_, key, value)
		if key == "show" then
			GoldDisplay:SetVisible(value)
		elseif key == "show-border" or key == "display-mode" then
			AUR.Settings.goldDisplay[key] = value
			GoldDisplay:Refresh()
		end
	end,
})

------------------------
--- Module Functions ---
------------------------

function Options:Initialize()
	local category, layout = Settings.RegisterVerticalLayoutCategory(addonName)

	layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L["options.general"]))

	AWL.Settings:AddDropdown(category, {
		variableTable	= dateFormatProxy,
		settingKey		= addonName .. "_date-format",
		variableName	= "date-format",
		name			= L["options.general.date-format.name"],
		tooltip			= L["options.general.date-format.tooltip"],
		isNew			= true,
		default			= AUR.OPTIONS_DEFAULTS.general["date-format"],
		options			= dateFormatOptions
	})

	-- Minimap Button
	AWL.Settings:AddCheckbox(category, {
		variableTable	= minimapButtonProxy,
		settingKey		= addonName .. "_hide",
		variableName	= "hide",
		name			= L["options.general.minimap-button.name"],
		tooltip			= L["options.general.minimap-button.tooltip"],
		default			= not AUR.OPTIONS_DEFAULTS.general["minimap-button"].hide
	})

	-- Debug Mode
	AWL.Settings:AddCheckbox(category, {
		variableTable	= AUR.Settings.general,
		settingKey		= addonName .. "_debug-mode",
		variableName	= "debug-mode",
		name			= L["options.general.debug-mode.name"],
		tooltip			= L["options.general.debug-mode.tooltip"],
		default			= AUR.OPTIONS_DEFAULTS["general"]["debug-mode"]
	})

	layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L["options.currency-overview"]))

	-- Open on Login
	AWL.Settings:AddCheckbox(category, {
		variableTable	= AUR.Settings.currencyOverview,
		settingKey		= addonName .. "_open-on-login",
		variableName	= "open-on-login",
		name			= L["options.currency-overview.open-on-login.name"],
		tooltip			= L["options.currency-overview.open-on-login.tooltip"],
		default			= AUR.OPTIONS_DEFAULTS["currency-overview"]["open-on-login"]
	})

	layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L["options.gold-display"]))

	-- Show Gold Display
	AWL.Settings:AddCheckbox(category, {
		variableTable	= goldDisplayProxy,
		settingKey		= addonName .. "_gold-display-show",
		variableName	= "show",
		name			= L["options.gold-display.show.name"],
		tooltip			= L["options.gold-display.show.tooltip"],
		default			= AUR.OPTIONS_DEFAULTS["gold-display"]["show"]
	})

	-- Displayed Coins
	AWL.Settings:AddDropdown(category, {
		variableTable	= goldDisplayProxy,
		settingKey		= addonName .. "_gold-display-mode",
		variableName	= "display-mode",
		name			= L["options.gold-display.display-mode.name"],
		tooltip			= L["options.gold-display.display-mode.tooltip"],
		default			= AUR.OPTIONS_DEFAULTS["gold-display"]["display-mode"],
		options			= goldDisplayModeOptions
	})

	-- Show Border
	AWL.Settings:AddCheckbox(category, {
		variableTable	= goldDisplayProxy,
		settingKey		= addonName .. "_gold-display-show-border",
		variableName	= "show-border",
		name			= L["options.gold-display.show-border.name"],
		tooltip			= L["options.gold-display.show-border.tooltip"],
		default			= AUR.OPTIONS_DEFAULTS["gold-display"]["show-border"]
	})

	-- Profiles Section
	AWL.Settings:AddProfilesSection(layout, {
		useAccountProfile			= Addon:IsAccountProfile(),
		onSwitchProfile				= function()
			Addon:ToggleProfileMode()
			ReloadUI()
		end,
		onDeleteCharacterProfiles	= function()
			Addon:ResetAllCharacterProfiles()
			ReloadUI()
		end
	})

	-- About Section
	AWL.Settings:AddAboutSection(layout, addonName, AUR.CHANGELOG)

	Settings.RegisterAddOnCategory(category)

	Addon:SetMainCategoryId(category:GetID())
end
