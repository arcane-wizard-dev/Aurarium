local _, AUR = ...

AUR.UIConfig.Overview = {
	window = {
		width = 470,
		height = 560,
		style = "standard",
		backgroundAlpha = 1,
		showPortrait = true,
		showCloseButton = true,
		movable = true,
		closeOnEscape = true
	},
	portrait = {x = -5, y = 8},
	inset = {width = 454, height = 410, bottom = 37, backgroundStyle = "shaded", backgroundAlpha = 1},
	monthHeading = {x = 5, y = 90},
	history = {
		rowHeight = 20,
		highlightTexture = ArcaneWizardLibrary.Textures.tableActiveBackground,
		hoverAlpha = 0.3,
		columns = {
			{text = "currency-overview.table.date", width = 75},
			{text = "currency-overview.table.amount", width = 150},
			{text = "currency-overview.table.difference"}
		}
	},
	scrollStep = 20,
	buttonWidth = 100,
	buttonOffset = {x = 6, y = -5},
	moreMenu = {
		minimumWidth = 80,
		height = 20,
		x = -18,
		y = -39,
		textInset = 10,
		arrowSize = 16,
		menuGap = 6,
		itemPadding = 4,
		itemHeight = 20,
		itemTextOffsetY = 0,
		iconGap = 4,
		icon = {
			size = 14,
			texture = "Interface\\AddOns\\Aurarium\\assets\\chart\\menu-icon.tga",
			color = {1, 0.82, 0, 1}
		}
	},
	dropdown = {
		characterWidth = 125,
		currencyWidth = 200,
		height = 25,
		offset = {x = 6, y = 24}
	},
	menu = {
		factionIconSize = 18,
		characterWidthPadding = 20,
		rowHeightPadding = 4
	},
	tokenPriceFormat = "%s |T237618:0|t",
	tabIndices = {character = 1, account = 2, warband = 3, token = 4},
	tabs = {
		{id = "character", label = "currency-overview.tab.character"},
		{id = "account", label = "currency-overview.tab.account"},
		{id = "warband", label = "currency-overview.tab.warband"},
		{id = "token", label = "wow-token.title"}
	}
}
