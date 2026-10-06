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
	inset = {width = 454, height = 430, bottom = 37, backgroundStyle = "character", backgroundAlpha = 1},
	contentInsets = {left = 10, right = 25, top = 15, bottom = 15},
	scrollStep = 20,
	buttonWidth = 100,
	tabs = {
		{id = "character", label = "currency-overview.tab.character"},
		{id = "account", label = "currency-overview.tab.account"},
		{id = "warband", label = "currency-overview.tab.warband"}
	}
}
