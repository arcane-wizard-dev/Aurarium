---@meta

-- Chart

---@class AurariumChartWindow: ArcaneWizardLibraryWindowFrame
---@field inset ArcaneWizardLibraryInsetFrame
---@field footerCloseButton Button
---@field artwork Texture

---@class AurariumPlotFrame: Frame
---@field empty FontString
---@field singlePoint Texture
---@field hoverPoint Texture
---@field cursor Texture
---@field hoverIndex? integer

-- Overview

---@class AurariumOverviewFrame: ArcaneWizardLibraryWindowFrame
---@field moreMenu DropdownButton

---@class AurariumOverviewTable: ArcaneWizardLibraryTable
---@field nextButton Button
---@field prevButton Button
---@field regionDropdown? ArcaneWizardLibraryDropdown
---@field characterDropdown? ArcaneWizardLibraryDropdown
---@field monthHeader? FontString
---@field noEntryText? FontString
---@field historyRows? Frame[]
