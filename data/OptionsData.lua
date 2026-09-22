local _, AUR = ...

-- Complete defaults for every supported WoW variant.
AUR.OPTIONS_DEFAULTS = {
	["general"] = {
		["minimap-button"] = {
			["hide"] = false,
			["minimapPos"] = 225,
			["lock"] = false,
			["showInCompartment"] = false
		},
		["debug-mode"] = false,
	},
	["currency-overview"] = {
		["open-on-login"] = false,
		["hide-unchanged-entries"] = false,
	},
	["gold-display"] = {
		["show"] = true,
		["display-mode"] = "all",
		["position"] = { ["point"] = "CENTER", ["relativePoint"] = "CENTER", ["x"] = 0, ["y"] = 0 },
	},
}
