local addonName, AUR = ...

if AUR.State and AUR.State.libraryIncompatible then return end

-- Library
local AWL = ArcaneWizardLibrary
local Addon = AWL:GetAddon(addonName)

-- Localization
local L = AUR.Localization

-- Variables
local handlers = Addon:CreateCompartmentHandlers({
	tooltip = L["minimap-button.tooltip"],
	onLeftClick = function()
		if AUR.Modules.Overview:IsShown() then
			AUR.Modules.Overview:Hide()
		else
			AUR.Modules.Overview:Show()
		end
	end
})

------------------------
--- Public Functions ---
------------------------

function Aurarium_CompartmentOnEnter(self, button)
	handlers.OnEnter(self, button)
end

function Aurarium_CompartmentOnLeave()
	handlers.OnLeave()
end

function Aurarium_CompartmentOnClick(self, button)
	handlers.OnClick(self, button)
end
