local _, AUR = ...

local AWL = ArcaneWizardLibrary
local CurrencyMenu = AUR.Modules.CurrencyMenu
local Utils = AUR.Modules.Utils
local Data = AUR.CURRENCY_MENU_DATA

local function GetCharacterBalances(characterKey)
	local balances = {}

	for key, value in pairs(Utils:GetLatestBalances(characterKey)) do
		balances[key] = value
	end

	if characterKey == AWL.Utils:GetCharacterGUID() then
		balances.gold = AUR.State.gold

		for _, entries in pairs(AUR.State.currencies.character) do
			for _, entry in ipairs(entries) do
				if entry.info and entry.info.quantity ~= nil then
					balances[entry.key] = entry.info.quantity
				end
			end
		end
	end

	return balances
end

local function GetBalances(scope, characterKey)
	if scope == "warband" then return {}, true end

	if scope == "character" then
		characterKey = characterKey or AWL.Utils:GetCharacterGUID()
		if characterKey == AWL.Utils:GetCharacterGUID() then return {gold = AUR.State.gold}, true end

		return Utils:GetLatestBalances(characterKey), false
	end

	local balances = {}

	for _, character in ipairs(Utils:GetSortedCharacters()) do
		for key, value in pairs(GetCharacterBalances(character.key)) do
			balances[key] = (balances[key] or 0) + value
		end
	end

	return balances, false
end

local function FormatAmount(quantity, info)
	if quantity == nil then return "-" end

	local amount = BreakUpLargeNumbers(quantity)

	if info and info.maxQuantity and info.maxQuantity > 0 then
		amount = amount .. "/" .. BreakUpLargeNumbers(info.maxQuantity)
	end

	return amount
end

local function InitializeButton(button, entry, text)
	local iconSize = entry.key:sub(1, 2) == "w-" and Data.warbandIconSize or Data.currencyIconSize
	local icon = button:AttachTexture()
	icon:SetSize(iconSize, iconSize)
	icon:SetPoint("RIGHT")
	icon:SetTexture(entry.iconFileID)

	local amount = button:AttachFontString()
	amount:SetFontObject(button.fontString:GetFontObject())
	amount:SetTextColor(1, 1, 1)
	amount:SetPoint("RIGHT", icon, "LEFT", -Data.amountSpacing, 0)
	amount:SetJustifyH("RIGHT")
	amount:SetText(text)
	local amountWidth = amount:GetUnboundedStringWidth()
	amount:SetWidth(amountWidth)

	local fontString = button.fontString
	local nameWidth = fontString:GetUnboundedStringWidth()
	fontString:SetWidth(nameWidth)
	local badgeWidth = 0

	if entry.isNew and MenuTemplates and MenuTemplates.AttachNewFeatureFrame then
		local badge = MenuTemplates.AttachNewFeatureFrame(button)
		local badgeTextWidth = badge:GetTextWidth()
		badgeWidth = badgeTextWidth + Data.badgePadding * 2
		badge:SetPoint("CENTER", fontString, "RIGHT", badgeTextWidth / 2 + Data.badgePadding, 0)
	end

	return nameWidth + iconSize + amountWidth + badgeWidth + Data.currencyWidthPadding, iconSize + Data.rowHeightPadding
end

local function AddEntry(parent, option, context)
	local currencyButton = parent:CreateRadio(option.label, context.isSelected, context.onSelected, option.value)
	local entry = option.entry
	if not entry then return end

	local info = context.useLiveBalances and entry.info or nil
	---@type number|nil
	local quantity = context.balances[entry.key] or 0

	if context.useLiveBalances then
		quantity = info and info.quantity
	end

	local amount = FormatAmount(quantity, info)

	currencyButton:AddInitializer(function(button)
		return InitializeButton(button, entry, amount)
	end)
end

local function AddOptions(root, options, context)
	for _, option in ipairs(options) do
		if option.divider then
			root:CreateDivider()
		elseif option.children then
			local category = root:CreateButton(option.label)
			local previousPatch

			for _, child in ipairs(option.children) do
				local entry = child.entry

				if AUR.CURRENCY_PATCH_CATEGORIES[option.category] and entry.patch and entry.patch ~= previousPatch then
					if previousPatch then
						category:CreateDivider()
					end

					category:CreateTitle(string.format(AUR.Localization["currency-overview.menu.patch"], entry.patch))
					previousPatch = entry.patch
				end

				AddEntry(category, child, context)
			end
		else
			AddEntry(root, option, context)
		end
	end
end

function CurrencyMenu:GetOptions(scope)
	local L, options = AUR.Localization, {}

	if scope ~= "warband" then
		options[1] = {label = L["currency-overview.category.gold"], value = "gold"}
	end

	local categories = AUR.State.currencies[scope == "warband" and "warband" or "character"] or {}
	if not next(categories) then return options end

	local dividerPending = #options > 0

	for _, category in ipairs(AUR.CURRENCY_CATEGORY_ORDER) do
		if category == false then
			dividerPending = #options > 0
		end

		local entries = categories[category]

		if entries and #entries > 0 then
			if dividerPending then
				options[#options + 1] = {divider = true}
				dividerPending = false
			end

			local children = {}
			options[#options + 1] = {label = L["currency-overview.category." .. category], category = category, children = children}

			for _, entry in ipairs(entries) do
				children[#children + 1] = {label = entry.name, value = entry.key, icon = entry.iconFileID, entry = entry}
			end
		end
	end

	return options
end

function CurrencyMenu:Populate(root, config)
	local options = config.options or self:GetOptions(config.scope)

	if #options == 0 then
		if config.emptyText then
			root:CreateButton(config.emptyText):SetEnabled(false)
		end
		return
	end

	local balances, useLiveBalances = GetBalances(config.scope, config.characterKey)

	AddOptions(root, options, {
		balances = balances,
		useLiveBalances = useLiveBalances,
		isSelected = config.isSelected,
		onSelected = config.onSelected
	})
end
