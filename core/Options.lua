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
local defaults = AUR.OPTIONS_DEFAULTS
local goldDisplayModeOptions = {}
local goldDisplayData = AUR.GOLD_DISPLAY_DATA

for _, option in ipairs(goldDisplayData.displayModeOptions) do
	local previewParts = {}

	for _, coin in ipairs(option.coins) do
		previewParts[#previewParts + 1] = string.format(
			"%d |T%d:0|t",
			goldDisplayData.displayModePreviewValues[coin],
			goldDisplayData.coinIcons[coin]
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

local currencyOverviewProxy = setmetatable({}, {
	__index = function(_, key)
		if key == "hide-unchanged-entries" then
			return AUR.Settings.currencyOverview["hide-unchanged-entries"]
		end
	end,
	__newindex = function(_, key, value)
		if key ~= "hide-unchanged-entries" then
			return
		end

		AUR.Settings.currencyOverview["hide-unchanged-entries"] = value

		if AUR.Modules.Overview and AUR.Modules.Overview:IsShown() then
			AUR.Modules.Overview:Refresh()
		end
	end,
})

local goldDisplayProxy = setmetatable({}, {
	__index = function(_, key)
		if key == "show" or key == "display-mode" then
			return AUR.Settings.goldDisplay[key]
		end
	end,
	__newindex = function(_, key, value)
		if key == "show" then
			GoldDisplay:SetVisible(value)
		elseif key == "display-mode" then
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

	-- Minimap Button
	AWL.Settings:AddCheckbox(category, {
		variableTable	= minimapButtonProxy,
		settingKey		= addonName .. "_hide",
		variableName	= "hide",
		name			= L["options.general.minimap-button.name"],
		tooltip			= L["options.general.minimap-button.tooltip"],
		default			= not defaults.general["minimap-button"].hide
	})

	-- Debug Mode
	AWL.Settings:AddCheckbox(category, {
		variableTable	= AUR.Settings.general,
		settingKey		= addonName .. "_debug-mode",
		variableName	= "debug-mode",
		name			= L["options.general.debug-mode.name"],
		tooltip			= L["options.general.debug-mode.tooltip"],
		default			= defaults["general"]["debug-mode"]
	})

	layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L["options.currency-overview"]))

	-- Open on Login
	AWL.Settings:AddCheckbox(category, {
		variableTable	= AUR.Settings.currencyOverview,
		settingKey		= addonName .. "_open-on-login",
		variableName	= "open-on-login",
		name			= L["options.currency-overview.open-on-login.name"],
		tooltip			= L["options.currency-overview.open-on-login.tooltip"],
		default			= defaults["currency-overview"]["open-on-login"]
	})

	-- Hide Unchanged Entries
	AWL.Settings:AddCheckbox(category, {
		variableTable	= currencyOverviewProxy,
		settingKey		= addonName .. "_hide-unchanged-entries",
		variableName	= "hide-unchanged-entries",
		name			= L["options.currency-overview.hide-unchanged-entries.name"],
		tooltip			= L["options.currency-overview.hide-unchanged-entries.tooltip"],
		default			= defaults["currency-overview"]["hide-unchanged-entries"]
	})

	layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L["options.gold-display"]))

	-- Show Gold Display
	AWL.Settings:AddCheckbox(category, {
		variableTable	= goldDisplayProxy,
		settingKey		= addonName .. "_gold-display-show",
		variableName	= "show",
		name			= L["options.gold-display.show.name"],
		tooltip			= L["options.gold-display.show.tooltip"],
		default			= defaults["gold-display"]["show"]
	})

	-- Displayed Coins
	AWL.Settings:AddDropdown(category, {
		variableTable	= goldDisplayProxy,
		settingKey		= addonName .. "_gold-display-mode",
		variableName	= "display-mode",
		name			= L["options.gold-display.display-mode.name"],
		tooltip			= L["options.gold-display.display-mode.tooltip"],
		default			= defaults["gold-display"]["display-mode"],
		options			= goldDisplayModeOptions
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
