local _, AUR = ...

local Layout = {
	width = 980,
	height = 640,
	textureSize = 2048,
	textureScale = 2,
	artworkLeft = 10,
	artworkTop = 60,
	artworkRight = 970,
	artworkBottom = 598,
	bodyLeft = 20,
	bodyTop = 74,
	bodyRight = 960,
	bodyBottom = 588,
	sidebarRight = 232,
	sidebarDividerInset = 8,
	sidebarSeparatorLeft = 32,
	sidebarSeparatorRight = 220,
	sidebarSeparatorTop = 194,
	chartLeft = 252,
	chartRight = 948,
	captionTop = 92,
	captionSeparator = 128,
	chartTop = 210,
	chartBottom = 554,
	plotLeft = 306,
	plotRight = 922,
	plotTop = 236,
	plotBottom = 518,
	gridSteps = 4,
	infoLeft = 932,
	infoTop = 96,
	infoSize = 16
}

AUR.CHART_DATA = {
	artwork = Layout,
	window = {
		texture = "chart/chart-frame.tga"
	},
	footer = {
		buttonWidth = 100,
		buttonTextPadding = 24,
		right = 12,
		bottom = 12
	},
	periods = { "7days", "30days", "90days", "month", "last-month", "year", "all", "custom" },
	defaultPeriod = "30days",
	days = { ["7days"] = 7, ["30days"] = 30, ["90days"] = 90 },
	margin = 12,
	header = {
		top = Layout.captionTop - Layout.bodyTop,
		height = 24,
		badgeGap = 24
	},
	sidebar = {
		width = Layout.sidebarRight - Layout.bodyLeft,
		controlWidth = 188,
		buttonWidth = 100,
		buttonTextPadding = 24,
		inputWidth = 128,
		inputLeft = 5,
		scopeTop = 34,
		characterTop = 144,
		currencyTop = 202,
		periodTop = 260,
		customButtonTop = 300,
		customPanelTop = 336,
		customPanelHeight = 178,
		firstInputTop = 20,
		lastInputTop = 74,
		applyTop = 108,
		statusTop = 140
	},
	summary = {
		top = 72,
		height = 44,
		gap = 20,
		labelTop = 0,
		valueTop = 20,
		valueHeight = 24,
		keys = {"start", "end", "change"}
	},
	labelGap = 5,
	plot = {
		left = Layout.plotLeft - Layout.chartLeft,
		right = Layout.chartRight - Layout.plotRight,
		top = Layout.plotTop - Layout.bodyTop,
		bottom = Layout.bodyBottom - Layout.plotBottom
	},
	axisGap = {x = 10, y = 10},
	dateAxis = {
		maximumLabels = 7,
		labelGap = 20,
		daySteps = {1, 2, 7, 14},
		monthSteps = {1, 2, 3, 6, 12}
	},
	grid = {
		axisColor = {170 / 255, 170 / 255, 170 / 255, 1},
		horizontalColor = {96 / 255, 96 / 255, 96 / 255, 1},
		verticalColor = {65 / 255, 65 / 255, 65 / 255, 1},
		tickLength = 4
	},
	axisUnits = {
		{value = 1000000, label = "chart.unit.million"},
		{value = 1000, label = "chart.unit.thousand"}
	},
	axisPadding = 0.1,
	flatAxisPadding = 0.01,
	axisStepMultipliers = {1, 2, 5, 10, 20},
	pointSize = 6,
	pointSpacing = 4,
	lineThickness = 2,
	gridThickness = 1,
	errorColor = {1, 0.3, 0.3},
	positiveColor = {0.2, 1, 0.2},
	normalColor = {1, 1, 1},
	gridSteps = Layout.gridSteps,
	maxSegments = 600,
	lineColor = { 1, 0.78, 0.2, 1 }
}
