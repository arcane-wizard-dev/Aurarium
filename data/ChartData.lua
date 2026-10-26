local _, AUR = ...

if AUR.State and AUR.State.libraryIncompatible then return end

AUR.CHART_DATA = {
	periods = { "7days", "30days", "90days", "month", "last-month", "year", "all", "custom" },
	defaultPeriod = "30days",
	days = { ["7days"] = 7, ["30days"] = 30, ["90days"] = 90 }
}
