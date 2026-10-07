local _, AUR = ...

AUR.OVERVIEW_DATA = {
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
	inset = {width = 454, height = 430, bottom = 37, backgroundStyle = "character", backgroundAlpha = 1},
	contentInsets = {left = 10, right = 25, top = 15, bottom = 15},
	monthHeading = {x = 5, y = 70},
	history = {
		rowWidth = 414,
		rowHeight = 20,
		hoverAlpha = 0.3,
		columns = {date = 5, amount = 80, difference = 230}
	},
	scrollStep = 20,
	buttonWidth = 100,
	buttonOffset = {x = 5, y = -5},
	moreMenu = {
		minimumWidth = 80,
		height = 20,
		x = -18,
		y = -36,
		textInset = 10,
		arrowSize = 16,
		menuGap = 6,
		itemPadding = 4,
		itemHeight = 20,
		iconGap = 4,
		icon = {
			size = 14,
			barWidth = 3,
			barGap = 2,
			barHeights = {4, 8, 12},
			color = {1, 0.82, 0, 1}
		}
	},
	dropdown = {
		characterWidth = 125,
		currencyWidth = 200,
		height = 25,
		offset = 5
	},
	menu = {
		factionIconSize = 18,
		characterWidthPadding = 20,
		rowHeightPadding = 4
	},
	tabIndices = {character = 1, account = 2, warband = 3},
	tabs = {
		{id = "character", label = "currency-overview.tab.character"},
		{id = "account", label = "currency-overview.tab.account"},
		{id = "warband", label = "currency-overview.tab.warband"}
	}
}
