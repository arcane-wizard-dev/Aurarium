local _, AUR = ...

if AUR.State and AUR.State.libraryIncompatible then return end

AUR.UIConfig.CurrencyMenu = {
	currencyIconSize = 16,
	warbandIconSize = 18,
	amountSpacing = 5,
	badgePadding = 8,
	currencyWidthPadding = 35,
	rowHeightPadding = 4
}
