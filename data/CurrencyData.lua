local _, AUR = ...

AUR.CURRENCY_CATEGORY_ORDER = {
	"misc",         -- 1
	"profession",	-- 280
	"tradeskills",  -- 273
	"pvp",          -- 2, 247
	"dungeonraid",  -- 22
	"delves",       -- 281
	"season",		-- 268, 263, 265
	"timerunning",	-- 266
	false,          -- Separator between general and expansion currencies
	--"classic",    -- 4
	"tbc",          -- 23
	"wotlk",        -- 21
	"cata",         -- 81
	"mop",          -- 133
	"wod",          -- 137
	"legion",       -- 141
	"bfa",          -- 143
	"sl",           -- 245
	"df",           -- 250
	"tww",			-- 260
	"mid"			-- 264, 283
}

AUR.CURRENCY_PATCH_CATEGORIES = {legion = true, bfa = true, sl = true, df = true, tww = true, mid = true}

-- Optional patch is the playable content introduction, not the first beta/PTR database entry.
AUR.CURRENCIES = {
	CLASSIC = {},

	TBC = {
		{id = 1900, category = "pvp"},                           -- Arenapunkte
		{id = 1901, category = "pvp"},                           -- Ehrenpunkte
	},

	MISTS = {
		{id = 515, category = "misc"},                           -- Gewinnlos des Dunkelmond-Jahrmarkts
		{id = 241, category = "misc"},                           -- Siegel des Champions
		{id = 416, category = "misc"},                           -- Abzeichen des Weltenbaums

		{id = 1901, category = "pvp"},                           -- Ehrenpunkte
		{id = 390, category = "pvp"},                            -- Eroberungspunkte
		{id = 391, category = "pvp"},                            -- Belobigungsabzeichen von Tol Barad

		{id = 395, category = "dungeonraid"},                    -- Gerechtigkeitspunkte
		{id = 396, category = "dungeonraid"},                    -- Tapferkeitspunkte
		{id = 614, category = "dungeonraid"},                    -- Partikel der Dunkelheit
		{id = 615, category = "dungeonraid"},                    -- Essenz des verderbten Todesschwinge

		{id = 738, category = "mop"},                            -- Geringes Amulett des Glücks
		{id = 777, category = "mop"},                            -- Zeitlose Münze
	},

	RETAIL = {
		{id = 81, category = "misc"},                            -- Feinschmeckerpreis
		{id = 402, category = "misc"},                           -- Eisentatzmarke
		{id = 515, category = "misc"},                           -- Gewinnlos des Dunkelmond-Jahrmarkts
		{id = 2588, category = "misc", patch = "10.1.5"},        -- Abzeichen: Reiter v. Azeroth
		{id = 3100, category = "misc", patch = "11.0.5"},        -- Bronzedrachenfeierabzeichen
		{id = 3309, category = "misc", patch = "11.1.7"},        -- Höllensteinscherbe
		{id = 3363, category = "misc", patch = "12.0.0"},        -- Gemeinschaftscoupons

		{id = 3256, category = "profession", patch = "12.0.1"},  -- Tatkraft des Alchemiefachmanns
		{id = 3257, category = "profession", patch = "12.0.1"},  -- Tatkraft des Schmiedefachmanns
		{id = 3258, category = "profession", patch = "12.0.1"},  -- Tatkraft des Verzauberungsfachmanns
		{id = 3259, category = "profession", patch = "12.0.1"},  -- Tatkraft des Ingenieursfachmanns
		{id = 3260, category = "profession", patch = "12.0.1"},  -- Tatkraft des Kräuterkundefachmanns
		{id = 3261, category = "profession", patch = "12.0.1"},  -- Tatkraft des Inschriftenfachmanns
		{id = 3262, category = "profession", patch = "12.0.1"},  -- Tatkraft des Juwelierfachmanns
		{id = 3263, category = "profession", patch = "12.0.1"},  -- Tatkraft des Lederverarbeitungsfachmanns
		{id = 3264, category = "profession", patch = "12.0.1"},  -- Tatkraft des Bergbaufachmanns
		{id = 3265, category = "profession", patch = "12.0.1"},  -- Tatkraft des Kürschnereifachmanns
		{id = 3266, category = "profession", patch = "12.0.1"},  -- Tatkraft des Schneiderfachmanns
		{id = 3546, category = "profession", patch = "12.1.0"},  -- Gewundenes Filament

		{id = 391, category = "pvp"},                            -- Belobigungsabzeichen von Tol Barad
		{id = 1602, category = "pvp", patch = "8.0.1"},          -- Eroberung
		{id = 1792, category = "pvp", patch = "9.0.1"},          -- Ehre
		{id = 2123, category = "pvp", patch = "10.0.2"},         -- Blutige Abzeichen

		{id = 1166, category = "dungeonraid"},                   -- Zeitverzerrtes Abzeichen

		{id = 2803, category = "delves", patch = "11.0.2"},      -- Lorenmünze
		{id = 3028, category = "delves", patch = "11.0.2"},      -- Restaurierter Kastenschlüssel
		{id = 3356, category = "delves", patch = "11.2.5"},      -- Unbesudelte Manakristalle

		{id = 1704, category = "tbc"},                           -- Geistsplitter

		{id = 241, category = "wotlk"},                          -- Siegel des Champions

		{id = 416, category = "cata"},                           -- Abzeichen des Weltenbaums
		{id = 614, category = "cata"},                           -- Partikel der Dunkelheit
		{id = 615, category = "cata"},                           -- Essenz des verderbten Todesschwinge

		{id = 738, category = "mop"},                            -- Geringes Amulett des Glücks
		{id = 777, category = "mop"},                            -- Zeitlose Münze

		{id = 823, category = "wod"},                            -- Apexiskristalle
		{id = 824, category = "wod"},                            -- Garnisonsressourcen
		{id = 1101, category = "wod"},                           -- Öl

		-- Patch 7.0.3
		{id = 1149, category = "legion", patch = "7.0.3"},       -- Blindes Auge
		{id = 1155, category = "legion", patch = "7.0.3"},       -- Uraltes Mana
		{id = 1220, category = "legion", patch = "7.0.3"},       -- Ordensressourcen
		{id = 1226, category = "legion", patch = "7.0.3"},       -- Nethersplitter
		{id = 1275, category = "legion", patch = "7.0.3"},       -- Kuriose Münze

		-- Patch 7.1.5
		{id = 1299, category = "legion", patch = "7.1.5"},       -- Kämpfergold

		-- Patch 7.2.0
		{id = 1342, category = "legion", patch = "7.2.0"},       -- Kriegsvorräte der Legionsrichter

		-- Patch 7.3.0
		{id = 1508, category = "legion", patch = "7.3.0"},       -- Verschleierter Argunit

		-- Patch 7.3.2
		{id = 1533, category = "legion", patch = "7.3.2"},       -- Erweckende Essenz

		-- Patch 8.0.1
		{id = 1560, category = "bfa", patch = "8.0.1"},          -- Kriegsressourcen
		{id = 1710, category = "bfa", patch = "8.0.1"},          -- Seefahrerdublone

		-- Patch 8.1.0
		{id = 1717, category = "bfa", patch = "8.1.0"},          -- Dienstmedaille der 7. Legion

		-- Patch 8.2.0
		{id = 1721, category = "bfa", patch = "8.2.0"},          -- Prismatische Manaperle

		-- Patch 8.3.0
		{id = 1719, category = "bfa", patch = "8.3.0"},          -- Verderbte Andenken
		{id = 1755, category = "bfa", patch = "8.3.0"},          -- Manifestierte Visionen
		{id = 1803, category = "bfa", patch = "8.3.0"},          -- Echos aus Ny'alotha

		-- Patch 9.0.2
		{id = 1767, category = "sl", patch = "9.0.2"},           -- Stygia
		{id = 1813, category = "sl", patch = "9.0.2"},           -- Reservoiranima
		{id = 1816, category = "sl", patch = "9.0.2"},           -- Sündensteinfragmente
		{id = 1819, category = "sl", patch = "9.0.2"},           -- Medaillon des Dienstes
		{id = 1820, category = "sl", patch = "9.0.2"},           -- Durchfluteter Rubin
		{id = 1828, category = "sl", patch = "9.0.2"},           -- Seelenasche
		{id = 1885, category = "sl", patch = "9.0.2"},           -- Dankbare Gabe

		-- Patch 9.1.0
		{id = 1906, category = "sl", patch = "9.1.0"},           -- Seelenglut
		{id = 1931, category = "sl", patch = "9.1.0"},           -- Katalogisierte Forschung
		{id = 1977, category = "sl", patch = "9.1.0"},           -- Stygische Glut

		-- Patch 9.2.0
		{id = 1979, category = "sl", patch = "9.2.0"},           -- Chiffren der Ersten
		{id = 2009, category = "sl", patch = "9.2.0"},           -- Kosmischer Flux

		-- Patch 10.0.2
		{id = 2003, category = "df", patch = "10.0.2"},          -- Vorräte der Dracheninseln
		{id = 2118, category = "df", patch = "10.0.2"},          -- Elementarüberfluss
		{id = 2122, category = "df", patch = "10.0.2"},          -- Sturmsiegel

		-- Patch 10.1.5
		{id = 2594, category = "df", patch = "10.1.5"},          -- Parakausale Flocken

		-- Patch 10.2.0
		{id = 2650, category = "df", patch = "10.2.0"},          -- Smaragdgrüner Tautropfen
		{id = 2777, category = "df", patch = "10.2.0"},          -- Trauminfusion

		-- Patch 10.2.5
		{id = 2657, category = "df", patch = "10.2.5"},          -- Mysteriöses Fragmentp

		-- Patch 11.0.2
		{id = 2815, category = "tww", patch = "11.0.2"},         -- Resonanzkristalle
		{id = 3055, category = "tww", patch = "11.0.2"},         -- Angelfestabzeichen von Mereldar
		{id = 3056, category = "tww", patch = "11.0.2"},         -- Kej

		-- Patch 11.0.7
		{id = 3090, category = "tww", patch = "11.0.7"},         -- Flammengesegnetes Eisen

		-- Patch 11.1.0
		{id = 3218, category = "tww", patch = "11.1.0"},         -- Leere Kaja'Cola-Dose
		{id = 3220, category = "tww", patch = "11.1.0"},         -- Altertümliche Kaja'Cola-Dose
		{id = 3226, category = "tww", patch = "11.1.0"},         -- Marktforschung

		-- Patch 11.1.5
		{id = 3149, category = "tww", patch = "11.1.5"},         -- Versetzte verderbte Andenkena

		-- Patch 11.2.0
		{id = 3303, category = "tww", patch = "11.2.0"},         -- Ungebundene Münze

		-- Patch 12.0.1
		{id = 3316, category = "mid", patch = "12.0.1"},         -- Leerenlichtmergel
		{id = 3377, category = "mid", patch = "12.0.1"},         -- Ungetrübter Überfluss
		{id = 3379, category = "mid", patch = "12.0.1"},         -- Übersprudelndes Arkana
		{id = 3392, category = "mid", patch = "12.0.1"},         -- Überrest der Pein

		-- Patch 12.0.5
		{id = 3373, category = "mid", patch = "12.0.5"},         -- Anglerperlen
		{id = 3393, category = "mid", patch = "12.0.5"},         -- Illusionäre Münze
		{id = 3405, category = "mid", patch = "12.0.5"},         -- Feldauszeichnung

		-- Patch 12.1.0
		{id = 3448, category = "mid", patch = "12.1.0"},         -- Korrosive Münze
	},

	FOREVER = {
		{id = 515, category = "misc"},                           -- Dunkelmond-Gewinnlos

		{id = 3402, category = "tradeskills"},                   -- Händlergunst

		{id = 1792, category = "pvp"},                           -- Ehrenpunkte
		{id = 3468, category = "pvp"},                           -- Rangpunkte

		{id = 3469, category = "dungeonraid"},                   -- Tarnished Undermine Real
	}
}

AUR.WARBAND_CURRENCIES = {
	{id = 2032, category = "misc", patch = "10.0.5"},            -- Händlerdevisen
}
