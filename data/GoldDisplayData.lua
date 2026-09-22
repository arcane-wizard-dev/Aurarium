local _, AUR = ...

AUR.GOLD_DISPLAY_DATA = {
	width = 180,
	height = 50,
	backgroundStyle = "solid-black",
	backgroundAlpha = 0.6,
	showBorder = true,
	borderStyle = "gold",
	showCloseButton = false,
	movable = true,
	closeOnEscape = false,
	valueFontObject = "GameFontHighlightSmall",
	logo = {
		path = "icon.blp",
		size = 30,
		alpha = 0.4,
		x = 9,
		y = 0
	},
	coinIcons = {
		gold = 237618,
		silver = 237620,
		copper = 237617
	},
	defaultDisplayMode = AUR.OPTIONS_DEFAULTS["gold-display"]["display-mode"],
	displayModes = {
		gold = {
			width = 120,
			showSilver = false,
			showCopper = false
		},
		["gold-silver"] = {
			width = 150,
			showSilver = true,
			showCopper = false
		},
		all = {
			width = 180,
			showSilver = true,
			showCopper = true
		}
	},
	displayModeOptions = {
		{ value = "gold", coins = { "gold" } },
		{ value = "gold-silver", coins = { "gold", "silver" } },
		{ value = "all", coins = { "gold", "silver", "copper" } }
	},
	displayModePreviewValues = {
		gold = 1,
		silver = 23,
		copper = 45
	},
	colors = {
		positive = {0, 1, 0},
		negative = {1, 0.2, 0.2},
		neutral = {1, 1, 1}
	},
	defaultPosition = AUR.OPTIONS_DEFAULTS["gold-display"].position,
	rows = {
		currentValue = 9,
		changeValue = -9
	},
	valueOffsetX = 2
}
