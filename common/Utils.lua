local addonName, AUR = ...

-- Library
local AWL = ArcaneWizardLibrary
local Addon = AWL:GetAddon(addonName)

-- Localization
local L = AUR.Localization

-- Current module
local Utils = AUR.Modules.Utils

-----------------------
--- Local Functions ---
-----------------------

local function PrintChatMessage(color, prefix, msg)
	DEFAULT_CHAT_FRAME:AddMessage(color:WrapTextInColorCode(prefix .. ": ") .. tostring(msg))
end

local function RemoveLegacyEntry(database, realm, name)
	if not database[realm] then return end

	database[realm][name] = nil
	if not next(database[realm]) then
		database[realm] = nil
	end
end

local function MigrateLegacyEntry(config)
	local realmData = config.legacy[config.realm]
	local legacyEntry = realmData and realmData[config.name]
	if legacyEntry then
		AWL.Utils:MergeMissingTableEntries(config.target[config.guid], legacyEntry)
		RemoveLegacyEntry(config.legacy, config.realm, config.name)
		return true
	end
	return false
end

------------------------
--- Module Functions ---
------------------------

function Utils:GetToday()
	return date("%Y-%m-%d")
end

function Utils:GetGold()
	return GetMoney()
end

function Utils:PrintMessage(msg)
	PrintChatMessage(NORMAL_FONT_COLOR, addonName, msg)
end

function Utils:PrintDebug(msg)
	if AUR.Settings.general["debug-mode"] then
		PrintChatMessage(ORANGE_FONT_COLOR, addonName .. " (Debug)", msg)
	end
end

function Utils:OpenSettings()
	if not Addon:OpenCategory() then
		self:PrintDebug("In combat. The options menu cannot be opened.")
		return false
	end

	return true
end

function Utils:UpdateCharacterData(characterGUID, refreshMetadata)
	local name, realm = AWL.Utils:GetCharacterAndRealm()

	local migratedCharacter = MigrateLegacyEntry({
		legacy = Aurarium_DataCharacter, target = Aurarium_DataCharacter_v2,
		guid = characterGUID, name = name, realm = realm
	})
	local migratedBalance = MigrateLegacyEntry({
		legacy = Aurarium_DataBalance, target = Aurarium_DataBalance_v2,
		guid = characterGUID, name = name, realm = realm
	})

	if Aurarium_DataBalance.Warband then
		AWL.Utils:MergeMissingTableEntries(Aurarium_DataBalance_v2.Warband, Aurarium_DataBalance.Warband)
		Aurarium_DataBalance.Warband = nil
	end

	local metadata = AUR.Data.character[characterGUID]
	if refreshMetadata or migratedCharacter or migratedBalance then
		metadata.name = name
		metadata.realm = realm
		metadata.class = UnitClassBase("player")
		metadata.faction = UnitFactionGroup("player")
	end

	-- Only characters that have completed their first GUID-based login are visible.
	local entries = {}
	for guid, history in pairs(AUR.Data.balance) do
		if guid ~= "Warband" then
			local character = AUR.Data.character[guid] or {}
			entries[guid] = {
				key = guid, name = character.name or guid, realm = character.realm or "",
				metadata = character, history = history
			}
		end
	end
	AUR.State.characterEntries = entries
end

function Utils:GetCharacterEntry(characterKey)
	return AUR.State.characterEntries[characterKey]
end

function Utils:GetSortedCharacters()
	local characters = {}
	for _, entry in pairs(AUR.State.characterEntries) do
		table.insert(characters, entry)
	end
	table.sort(characters, function(a, b)
		if a.realm ~= b.realm then return a.realm < b.realm end
		if a.name ~= b.name then return a.name < b.name end
		return a.key < b.key
	end)
	return characters
end

function Utils:DeleteCharacterData(characterKey)
	if characterKey == AWL.Utils:GetCharacterGUID() then
		return false, "current-character"
	end
	local entry = self:GetCharacterEntry(characterKey)
	if not entry then return false, "not-found" end

	AUR.Data.balance[characterKey] = nil
	AUR.Data.character[characterKey] = nil
	AUR.State.characterEntries[characterKey] = nil
	return true
end

function Utils:InitializeDatabase(isLogin)
	local dbInit = Addon:InitializeOptions({
		databaseName = "Aurarium_Options_v5",
		defaults = AUR.OPTIONS_DEFAULTS,
		requireCharacterRealmKey = true,
		onOpenSettings = function() return self:OpenSettings() end
	})

	if not dbInit then
		return nil
	end

	local characterGUID = dbInit.characterGUID

	AUR.Settings.global = dbInit.global
	AUR.Settings.general = dbInit.settings["general"]
	AUR.Settings.currencyOverview = dbInit.settings["currency-overview"]
	AUR.Settings.goldDisplay = dbInit.settings["gold-display"]

	if not Aurarium_DataDates then
		Aurarium_DataDates = {}
	end

	if not Aurarium_DataCharacter then
		Aurarium_DataCharacter = {}
	end

	if not Aurarium_DataBalance then
		Aurarium_DataBalance = {}
	end

	if not Aurarium_DataCharacter_v2 then
		Aurarium_DataCharacter_v2 = {}
	end

	if not Aurarium_DataBalance_v2 then
		Aurarium_DataBalance_v2 = {}
	end

	AUR.Data.dates = Aurarium_DataDates
	AUR.Data.character = Aurarium_DataCharacter_v2
	AUR.Data.balance = Aurarium_DataBalance_v2

	local createdCharacter = not AUR.Data.character[characterGUID]
	AUR.Data.character[characterGUID] = AUR.Data.character[characterGUID] or {}
	AUR.Data.balance[characterGUID] = AUR.Data.balance[characterGUID] or {}

	if AWL.GAME_TYPE_RETAIL or AWL.GAME_TYPE_FOREVER or Aurarium_DataBalance.Warband then
		AUR.Data.balance.Warband = AUR.Data.balance.Warband or {}
	end

	self:UpdateCharacterData(characterGUID, isLogin or createdCharacter)

	return dbInit
end

function Utils:InitializeMinimapButton()
	self.minimapButton = Addon:RegisterMinimapButton({
		db = AUR.Settings.general["minimap-button"],
		tooltip = L["minimap-button.tooltip"],
		onLeftClick = function()
			if AUR.Modules.Overview:IsShown() then
				AUR.Modules.Overview:Hide()
			else
				AUR.Modules.Overview:Show()
			end
		end
	})
end
