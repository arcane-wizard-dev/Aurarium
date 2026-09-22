local _, AUR = ...

local AWL = ArcaneWizardLibrary

if AWL.GAME_TYPE_MISTS then
	AUR.CURRENCY_CATEGORY_ORDER = {
		"misc",         -- 1
		"pvp",          -- 2
		--"dungeonraid",  -- 22
		--"classic",      -- 4
		--"tbc",          -- 23
		--"wotlk",        -- 21
		--"cata",         -- 81
		"mop",          -- 133
		--"wod",          -- 137
		--"legion",       -- 141
		--"bfa",          -- 143
		--"sl",           -- 245
		--"df",           -- 250
		--"tww"           -- 260
	}

	AUR.CHARACTER_CURRENCIES = {
		misc = {
			515		-- Gewinnlos des Dunkelmond-Jahrmarkts
		},
		pvp = {
			391	    -- Belobigungsabzeichen von Tol Barad
		},
		mop = {
			738,	-- Geringes Amulett des Glücks
			777		-- Zeitlose Münze
		}
	}
elseif AWL.GAME_TYPE_RETAIL or AWL.GAME_TYPE_FOREVER then
	AUR.CURRENCY_CATEGORY_ORDER = {
		"misc",         -- 1
		"profession",	-- 280
		"pvp",          -- 2
		"dungeonraid",  -- 22
		"season",		-- 268, 263, 265
		"timerunning",	-- 266
		--"classic",    -- 4
		--"tbc",        -- 23
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

	AUR.WARBAND_CURRENCIES = {
		misc = {
			2032,	-- Händlerdevisen
		}
	}

	AUR.CHARACTER_CURRENCIES = {
		misc = {
			515,    -- Gewinnlos des Dunkelmond-Jahrmarkts
			2588,	-- Abzeichen: Reiter v. Azeroth
			3309,	-- Höllensteinscherbe
			3363	-- Gemeinschaftscoupons
		},
		profession = {
			3256,	-- Tatkraft des Alchemiefachmanns
			3257,	-- Tatkraft des Schmiedefachmanns
			3258,	-- Tatkraft des Verzauberungsfachmanns
			3259,	-- Tatkraft des Ingenieursfachmanns
			3260,	-- Tatkraft des Kräuterkundefachmanns
			3261,	-- Tatkraft des Inschriftenfachmanns
			3262,	-- Tatkraft des Juwelierfachmanns
			3263,	-- Tatkraft des Lederverarbeitungsfachmanns
			3264,	-- Tatkraft des Bergbaufachmanns
			3265,	-- Tatkraft des Kürschnereifachmanns
			3266,	-- Tatkraft des Schneiderfachmanns
			3546	-- Gewundenes Filament
		},
		pvp = {
			391,    -- Belobigungsabzeichen von Tol Barad
			1602,	-- Eroberung
			1792,	-- Ehre
			2123	-- Blutige Abzeichen
		},
		dungeonraid = {
			1166	-- Zeitverzerrtes Abzeichen
		},
		season = {
			2803	-- Lorenmünze
		},
		timerunning = {
			--3252	-- Bronze
			--3268	-- Ewige Macht
			--3292	-- Ewiges Wissen
		},
		wotlk = {
			241		-- Siegel des Champions
		},
		cata = {
			416,	-- Abzeichen des Weltenbaums
			614,	-- Partikel der Dunkelheit
			615		-- Essenz des verderbten Todesschwinge
		},
		mop = {
			738,	-- Geringes Amulett des Glücks
			777		-- Zeitlose Münze
		},
		wod = {
			823,	-- Apexiskristalle
			824,	-- Garnisonsressourcen
			1101	-- Öl
		},
		legion = {
			1149,    -- Blindes Auge
			1155,    -- Uraltes Mana
			1220,    -- Ordensressourcen
			1226,    -- Nethersplitter
			1275,    -- Kuriose Münze
			1342,    -- Kriegsvorräte der Legionsrichter
			1508,    -- Verschleierter Argunit
			1533	 -- Erweckende Essenz
		},
		bfa = {
			1299,	--Kämpfergold
			1560,	--Kriegsressourcen
			1710,	--Seefahrerdublone
			1717,	--Dienstmedaille der 7. Legion
			1719,	--Verderbte Andenken
			1721,	--Prismatische Manaperle
			1755,	--Manifestierte Visionen
			1803	--Echos aus Ny'alotha
		},
		sl = {
			1767,	--Stygia
			1813,	--Reservoiranima
			1816,	--Sündensteinfragmente
			1819,	--Medaillon des Dienstes
			1820,	--Durchfluteter Rubin
			1828,	--Seelenasche
			1885,	--Dankbare Gabe
			1906,	--Seelenglut
			1931,	--Katalogisierte Forschung
			1977,	--Stygische Glut
			1979,	--Chiffren der Ersten
			2009	--Kosmischer Flux
		},
		df = {
			2003,	-- Vorräte der Dracheninseln
			2118,	-- Elementarüberfluss
			2122,	-- Sturmsiegel
			2594,	-- Parakausale Flocken
			2650,	-- Smaragdgrüner Tautropfen
			2657,	-- Mysteriöses Fragmentp
			2777	-- Trauminfusion
		},
		tww = {
			2815,	-- Resonanzkristalle
			3055,	-- Angelfestabzeichen von Mereldar
			3056,	-- Kej
			3090,	-- Flammengesegnetes Eisen
			3149,	-- Versetzte verderbte Andenkena
			3218,   -- Leere Kaja'Cola-Dose
			3220,   -- Altertümliche Kaja'Cola-Dose
			3226,	-- Marktforschung
			3303	-- Ungebundene Münze
		},
		mid = {
			3316,	-- Leerenlichtmergel
			3373,	-- Anglerperlen
			3392,	-- Überrest der Pein
			3377,	-- Ungetrübter Überfluss
			3379,	-- Übersprudelndes Arkana
			3385,	-- Leuchtender Staub
			3393,	-- Illusionäre Münze
			3405,	-- Feldauszeichnung
			3448	-- Korrosive Münze
		}
	}
end
