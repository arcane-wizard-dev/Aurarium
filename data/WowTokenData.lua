local _, AUR = ...

if AUR.State and AUR.State.libraryIncompatible then return end

AUR.WOW_TOKEN_DATA = {
	defaultPollSeconds = 300,
	regions = {"US", "KR", "EU", "TW", "CN"}
}
