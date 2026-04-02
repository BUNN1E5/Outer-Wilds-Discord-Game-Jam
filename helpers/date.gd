@tool
extends Resource

class_name Date

static func Create(seconds : float) -> Date:
	var date :Date = Date.new()
	date.seconds = seconds
	return date
	pass

@export var seconds : float :
	set(time):
		seconds = time
		
		var day_seconds : int = int(seconds) % 86400
		hour = day_seconds / 3600
		minute = (day_seconds % 3600) / 60
		second = day_seconds % 60
		
		var D : int = floor(seconds / 86400) #Total Days
		var Z : int = D + 719468 # Epoch Shift
		var E : int = floor(Z / 146097) # Curr Era
		var DOE : int = Z - (E * 146097) #Day of Era
		var YOE : int = floor(DOE - (DOE/1460) + (DOE/36524) - (DOE/146096)) / 365#Year of Era
		var Y : int = YOE + (E * 400) #prelim Year
		var DOY : int = DOE - (365 * YOE + floor(YOE/4) - floor(YOE/100)) #Day of Year
		var Ms : int = floor(5 * DOY + 2) / 153 #Shifted Month
		day = DOY - floor((153 * Ms + 2)/5) + 1
		Ms += 3
		if Ms > 12:
			Ms -= 12
			Y += 1
		month = Ms
		year = Y
		notify_property_list_changed()

@export var second : int
@export var minute : int
@export var hour : int
@export var day : int
@export var month : int
@export var year : int
