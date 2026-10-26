local _, AUR = ...

if AUR.State and AUR.State.libraryIncompatible then return end

AUR.DATE_FORMATS = {"ymd", "mdy", "dmy"}

AUR.MONTH_KEYS = {
	"month.jan", "month.feb", "month.mar", "month.apr", "month.may", "month.jun",
	"month.jul", "month.aug", "month.sep", "month.oct", "month.nov", "month.dec"
}
