local _, AUR = ...

if AUR.State and AUR.State.libraryIncompatible then return end

local ArtworkConfig = {
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
	sidebarSeparatorTop = 150,
	sidebarExtremaSeparatorTop = 361,
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

AUR.UIConfig.Chart = {
	artwork = ArtworkConfig,
	window = {
		texture = "chart/chart-frame.tga"
	},
	inset = {backgroundStyle = "shaded-alt"},
	footer = {
		buttonWidth = 100,
		buttonTextPadding = 24
	},
	margin = 12,
	header = {
		top = ArtworkConfig.captionTop - ArtworkConfig.bodyTop,
		height = 24,
		infoGap = 24
	},
	sidebar = {
		width = ArtworkConfig.sidebarRight - ArtworkConfig.bodyLeft,
		controlWidth = 188,
		buttonWidth = 100,
		buttonTextPadding = 24,
		inputWidth = 128,
		inputLeft = 5,
		sectionTop = 34,
		viewTop = 110,
		currencyTop = 162,
		periodTop = 214,
		customButtonTop = 248,
		customPanelTop = 354,
		customPanelHeight = 160,
		firstInputTop = 16,
		lastInputTop = 58,
		applyTop = 90,
		statusTop = 116,
		highestTop = 300,
		lowestTop = 326
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
		left = ArtworkConfig.plotLeft - ArtworkConfig.chartLeft,
		right = ArtworkConfig.chartRight - ArtworkConfig.plotRight,
		top = ArtworkConfig.plotTop - ArtworkConfig.bodyTop,
		bottom = ArtworkConfig.bodyBottom - ArtworkConfig.plotBottom
	},
	axisGap = {x = 10, y = 10},
	dateAxis = {
		maximumLabels = 7,
		labelGap = 20
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
	axisStepMultipliers = {1, 2, 3, 4, 5, 6, 8, 10, 20},
	pointSize = 6,
	pointSpacing = 4,
	extrema = {
		pointSize = 12,
		labelGap = 8,
		color = {1, 1, 1}
	},
	tooltipGap = 8,
	lineThickness = 2,
	lineTexture = "chart/smooth-line.tga",
	lineJoinTexture = "chart/smooth-point.tga",
	gridThickness = 1,
	errorColor = {1, 0.3, 0.3},
	positiveColor = {0.2, 1, 0.2},
	normalColor = {1, 1, 1},
	gridSteps = ArtworkConfig.gridSteps,
	maxSegments = 600,
	lineColor = {1, 0.78, 0.2, 1}
}
