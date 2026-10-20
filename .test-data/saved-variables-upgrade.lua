-- Synthetic SavedVariables: previous addon version with the current database schema; fill defaults and remove obsolete options.
-- No real player data. Version "test" is the version supplied by the test harness.

Aurarium_Options_v5 = {
	["account"] = {
		["currency-overview"] = {
			["hide-unchanged-entries"] = true,
			["obsolete-option"] = 1,
			["open-on-login"] = true,
		},
		["general"] = {
			["debug-mode"] = "obsolete-type",
			["minimap-button"] = {
				["hide"] = false,
				["minimapPos"] = 90,
				["obsolete"] = true,
			},
		},
		["gold-display"] = {
			["display-mode"] = "all",
			["obsolete-option"] = 1,
			["show"] = false,
		},
		["obsolete-section"] = {
			["enabled"] = true,
		},
	},
	["global"] = {
		["obsolete"] = true,
		["version"] = "fixture-previous",
	},
	["profileKeys"] = {
		["Player-TEST-CURRENT"] = {
			["open-settings"] = false,
			["use-account"] = false,
		},
		["Player-TEST-OFFLINE"] = {
			["open-settings"] = false,
			["use-account"] = true,
		},
	},
	["profiles"] = {
		["Player-TEST-CURRENT"] = {
			["currency-overview"] = {
				["hide-unchanged-entries"] = true,
				["obsolete-option"] = 1,
				["open-on-login"] = true,
			},
			["general"] = {
				["debug-mode"] = "obsolete-type",
				["minimap-button"] = {
					["hide"] = true,
					["minimapPos"] = 0,
					["obsolete"] = true,
				},
			},
			["gold-display"] = {
				["display-mode"] = "all",
				["obsolete-option"] = 1,
				["show"] = false,
			},
			["obsolete-section"] = {
				["enabled"] = true,
			},
		},
		["Player-TEST-OFFLINE"] = {
			["currency-overview"] = {
				["hide-unchanged-entries"] = true,
				["obsolete-option"] = 1,
				["open-on-login"] = true,
			},
			["general"] = {
				["debug-mode"] = "obsolete-type",
				["minimap-button"] = {
					["hide"] = false,
					["minimapPos"] = 270,
					["obsolete"] = true,
				},
			},
			["gold-display"] = {
				["display-mode"] = "all",
				["obsolete-option"] = 1,
				["show"] = false,
			},
			["obsolete-section"] = {
				["enabled"] = true,
			},
		},
	},
}

Aurarium_DataDates = {
	[1] = "2026-01-02",
	[2] = "2026-01-03",
}

Aurarium_DataCharacter = {}

Aurarium_DataBalance = {}

Aurarium_DataCharacter_v2 = {
	["Player-TEST-CURRENT"] = {
		["class"] = "MAGE",
		["faction"] = "Alliance",
		["name"] = "Test Character",
		["realm"] = "Test Realm",
	},
	["Player-TEST-OFFLINE"] = {
		["class"] = "WARRIOR",
		["faction"] = "Horde",
		["name"] = "Offline Character",
		["realm"] = "Test Realm",
	},
}

Aurarium_DataBalance_v2 = {
	["Player-TEST-CURRENT"] = {
		["2026-01-02"] = {
			["c-515"] = 0,
			["gold"] = 1250000,
		},
		["2026-01-03"] = {
			["c-515"] = 25,
			["gold"] = 0,
		},
	},
	["Player-TEST-OFFLINE"] = {
		["2026-01-02"] = {
			["gold"] = 750000,
		},
	},
	["Warband"] = {
		["2026-01-02"] = {
			["w-2032"] = 100,
		},
		["2026-01-03"] = {
			["w-2032"] = 0,
		},
	},
}

Aurarium_DataTokenPrices = {
	["2026-01-02"] = 2400000000,
	["2026-01-03"] = 2450000000,
}
