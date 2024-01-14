local L = CLASSIC_CALENDAR_L
local localeString = tostring(GetLocale())
local date = date
local time = time

CALENDAR_INVITESTATUS_INFO = {
	["UNKNOWN"] = {
		name		= UNKNOWN,
		color		= NORMAL_FONT_COLOR,
	},
	[Enum.CalendarStatus.Confirmed] = {
		name		= CALENDAR_STATUS_CONFIRMED,
		color		= GREEN_FONT_COLOR,
	},
	[Enum.CalendarStatus.Available] = {
		name		= CALENDAR_STATUS_ACCEPTED,
		color		= GREEN_FONT_COLOR,
	},
	[Enum.CalendarStatus.Declined] = {
		name		= CALENDAR_STATUS_DECLINED,
		color		= RED_FONT_COLOR,
	},
	[Enum.CalendarStatus.Out] = {
		name		= CALENDAR_STATUS_OUT,
		color		= RED_FONT_COLOR,
	},
	[Enum.CalendarStatus.Standby] = {
		name		= CALENDAR_STATUS_STANDBY,
		color		= ORANGE_FONT_COLOR,
	},
	[Enum.CalendarStatus.Invited] = {
		name		= CALENDAR_STATUS_INVITED,
		color		= NORMAL_FONT_COLOR,
	},
	[Enum.CalendarStatus.Signedup] = {
		name		= CALENDAR_STATUS_SIGNEDUP,
		color		= GREEN_FONT_COLOR,
	},
	[Enum.CalendarStatus.NotSignedup] = {
		name		= CALENDAR_STATUS_NOT_SIGNEDUP,
		color		= GRAY_FONT_COLOR,
	},
	[Enum.CalendarStatus.Tentative] = {
		name		= CALENDAR_STATUS_TENTATIVE,
		color		= ORANGE_FONT_COLOR,
	},
}

CalendarType = {
	Player = 0,
	Community = 1,
	RaidLockout = 2,
	RaidReset = 3,
	Holiday = 4,
	HolidayWeekly = 5,
	HolidayDarkmoon = 6,
	HolidayBattleground = 7,
}

CalendarInviteType = {
	Normal = 0,
	Signup = 1,
}

CalendarEventType = {
	Raid = 0,
	Dungeon = 1,
	PvP = 2,
	Meeting = 3,
	Other = 4,
	HeroicDeprecated = 5,
}

CalendarTexturesType = {
	Dungeons = 0,
	Raid = 1,
}

local currentCalendarTime = C_DateAndTime.GetCurrentCalendarTime()

local state = {
	monthOffset=0,
	presentDate={
		year=currentCalendarTime.year,
		month=currentCalendarTime.month,
		day=currentCalendarTime.day
	},
	currentEventIndex=0,
	currentMonthOffset=0
}

CALENDAR_FILTER_BATTLEGROUND = L.Options[localeString]["CALENDAR_FILTER_BATTLEGROUND"];

-- Date Utilities

local function dumpTable(o)
	if type(o) == 'table' then
	   local s = '{ '
	   for k,v in pairs(o) do
		  if type(k) ~= 'number' then k = '"'..k..'"' end
		  s = s .. '['..k..'] = ' .. dumpTable(v) .. ','
	   end
	   return s .. '} '
	else
	   return tostring(o)
	end
end

local SECONDS_IN_DAY = 24 * 60 * 60

local function fixLuaDate(dateD)
	local result = {
		year=dateD.year,
		month=dateD.month,
		monthDay=dateD.day,
		weekDay=dateD.wday,
		day=dateD.day,
		hour=dateD.hour,
		min=dateD.min,
		minute=dateD.min
	}
	return result
end

local function dateGreaterThan(date1, date2)
	return time(date1) > time(date2)
end

local function dateLessThan(date1, date2)
	return time(date1) < time(date2)
end

local function dateIsOnFrequency(eventDate, epochDate, frequency)
	-- If one date has DST and the other doesn't, this fails
	local eventDateTime = time(SetMinTime(eventDate))
	local epochDateTime = time(SetMinTime(epochDate))

	if date("*t", eventDateTime).isdst then
		-- add an hour to DST datetimes
		 eventDateTime = eventDateTime + 60*60
	end

	return ((eventDateTime - epochDateTime) / (SECONDS_IN_DAY)) % frequency == 0
end

local function adjustMonthByOffset(dateD, offset)
	dateD.month = dateD.month + offset
	if dateD.month > 12 then
		dateD.year = dateD.year + 1
		dateD.month = 1
	elseif dateD.month == 0 then
		dateD.year = dateD.year - 1
		dateD.month = 12
	end
end

local function tableHasValue(tab, val)
	for _, value in ipairs(tab) do
		if value == val then
			return true
		end
	end

	return false
end

function newEventGetTextures(eventType)
	-- Stubbing C_Calendar.EventGetTextures to actually return textures, and only SoD-available raids/dungeons
	if eventType == 0 then
		-- Raids
		return {
			{
				title=L.DungeonLocalization[localeString].Dungeons.BlackfathomDeeps.name,
				isLfr=false,
				difficultyId=0,
				mapId=0,
				expansionLevel=0,
				iconTexture="Interface/LFGFrame/LFGIcon-BlackfathomDeeps"
			},
			{
				title=L.DungeonLocalization[localeString].Dungeons.Gnomeregan.name,
				isLfr=false,
				difficultyId=0,
				mapId=0,
				expansionLevel=0,
				iconTexture="Interface/LFGFrame/LFGIcon-Gnomeregan"
			}
		}
	end

	if eventType == 1 then
		-- Dungeons, alphabetically sorted
		return {
			{
				title=L.DungeonLocalization[localeString].Dungeons.Deadmines.name,
				isLfr=false,
				difficultyId=0,
				mapId=0,
				expansionLevel=0,
				iconTexture="Interface/LFGFrame/LFGIcon-Deadmines"
			},
			{
				title=L.DungeonLocalization[localeString].Dungeons.RazorfenKraul.name,
				isLfr=false,
				difficultyId=0,
				mapId=0,
				expansionLevel=0,
				iconTexture="Interface/LFGFrame/LFGIcon-RazorfenKraul"
			},
			{
				title=L.DungeonLocalization[localeString].Dungeons.ScarletMonastery.name,
				isLfr=false,
				difficultyId=0,
				mapId=0,
				expansionLevel=0,
				iconTexture="Interface/LFGFrame/LFGIcon-ScarletMonastery"
			},
			{
				title=L.DungeonLocalization[localeString].Dungeons.ShadowfangKeep.name,
				isLfr=false,
				difficultyId=0,
				mapId=0,
				expansionLevel=0,
				iconTexture="Interface/LFGFrame/LFGIcon-ShadowfangKeep"
			},
			{
				title=L.DungeonLocalization[localeString].Dungeons.StormwindStockades.name,
				isLfr=false,
				difficultyId=0,
				mapId=0,
				expansionLevel=0,
				iconTexture="Interface/LFGFrame/LFGIcon-StormwindStockades"
			},
			{
				title=L.DungeonLocalization[localeString].Dungeons.WailingCaverns.name,
				isLfr=false,
				difficultyId=0,
				mapId=0,
				expansionLevel=0,
				iconTexture="Interface/LFGFrame/LFGIcon-WailingCaverns"
			}
		}
	end

	return {}
end

local RaidResets = {
	{
		name=L.DungeonLocalization[localeString].Dungeons.BlackfathomDeeps.name,
		firstReset = {
			year=2023,
			month=12,
			day=3
		},
		frequency=3
	},
	-- {
	-- 	name=L.DungeonLocalization[localeString].DungeonNames.Gnomeregan.name,
	-- 	firstReset = {
	-- 		year=2024,
	-- 		month=2,
	-- 		day=10
	-- 	},
	-- 	frequency=3
	-- }
}

function stubbedGetNumDayEvents(monthOffset, monthDay)
	-- Stubbing C_Calendar.getNumDayEvents to return fake events
	local originalEventCount = C_Calendar.GetNumDayEvents(monthOffset, monthDay)
	local monthInfo = C_Calendar.GetMonthInfo(monthOffset)
	local eventDate = {
		year = monthInfo.year,
		month = monthInfo.month,
		day = monthDay
	}
	local eventTime = time(eventDate)

	for _, holiday in next, GetClassicHolidays() do
		local holidayMinStartTime = time(SetMinTime(holiday.startDate))
		if eventTime < holidayMinStartTime then
			break
		end

		local holidayMaxEndTime = time(SetMaxTime(holiday.endDate))

		if (holiday.CVar == nil or GetCVar(holiday.CVar) == "1") and eventTime >= holidayMinStartTime and eventTime <= holidayMaxEndTime then
			originalEventCount = originalEventCount + 1
		end
	end

	if GetCVar("calendarShowResets") ~= "0" then
		for _, raid in next, RaidResets do
			if dateGreaterThan(eventDate, raid.firstReset) and dateIsOnFrequency(eventDate, raid.firstReset, raid.frequency) then
				originalEventCount = originalEventCount + 1
			end
		end
	end

	return originalEventCount
end

function stubbedGetDayEvent(monthOffset, monthDay, index)
	-- Stubbing C_Calendar.GetDayEvent to return events
	local originalEventCount = C_Calendar.GetNumDayEvents(monthOffset, monthDay)
	local originalEvent = C_Calendar.GetDayEvent(monthOffset, monthDay, index)
	local monthInfo = C_Calendar.GetMonthInfo(monthOffset)
	local eventDate = {
		year = monthInfo.year,
		month = monthInfo.month,
		day = monthDay
	}
	local eventTime = time(eventDate)
	local matchingEvents = {}

	if originalEvent == nil then
		for _, holiday in next, GetClassicHolidays() do
			local holidayMinStartTime = time(SetMinTime(holiday.startDate))
			if eventTime < holidayMinStartTime then
				break
			end

			local holidayMaxEndTime = time(SetMaxTime(holiday.endDate))

			if (holiday.CVar == nil or GetCVar(holiday.CVar) == "1") and eventTime >= holidayMinStartTime and eventTime <= holidayMaxEndTime then
				local artDisabled = false
				if holiday.artConfig and CCConfig[holiday.artConfig] == false then
					artDisabled = true
				end

				-- single-day event
				if (holiday.startDate.year == holiday.endDate.year and holiday.startDate.month == holiday.endDate.month and holiday.startDate.day == holiday.endDate.day) then
					local iconTexture = nil
					local ZIndex = 1
					if not artDisabled then
						iconTexture = holiday.startTexture
						ZIndex = holiday.ZIndex
					end

					local eventTable = { -- CalendarEvent
						title=holiday.name,
						isCustomTitle=true,
						startTime=fixLuaDate(holiday.startDate),
						endTime=fixLuaDate(holiday.endDate),
						calendarType="HOLIDAY",
						eventType=CalendarEventType.Other,
						iconTexture=iconTexture, -- single-day events only have one texture
						modStatus="",
						inviteStatus=0,
						invitedBy="",
						inviteType=CalendarInviteType.Normal,
						difficultyName="",
						dontDisplayBanner=false,
						dontDisplayEnd=false,
						isLocked=false,
						sequenceType="",
						sequenceIndex=1,
						numSequenceDays=1,
						ZIndex=ZIndex
					}
					tinsert(matchingEvents, eventTable)
				else
					local numSequenceDays = math.floor((time(SetMinTime(holiday.endDate)) - holidayMinStartTime) / SECONDS_IN_DAY) + 1
					local sequenceIndex = math.floor((time(SetMinTime(eventDate)) - holidayMinStartTime) / SECONDS_IN_DAY) + 1

					local iconTexture, sequenceType
					local ZIndex = holiday.ZIndex
					-- Assign start/ongoing/end texture based on sequenceIndex compared to numSequenceDays
					if sequenceIndex == 1 then
						iconTexture = holiday.startTexture
						sequenceType = "START"
					elseif sequenceIndex == numSequenceDays then
						iconTexture = holiday.endTexture
						sequenceType = "END"
					else
						iconTexture = holiday.ongoingTexture
						sequenceType = "ONGOING"
					end

					if artDisabled then
						iconTexture = nil
						ZIndex=1
					end

					local dontDisplayBanner
					if not iconTexture then
						dontDisplayBanner = true
						ZIndex=1
					else
						dontDisplayBanner = false
					end

					local eventTable = { -- CalendarEvent
						title=holiday.name,
						isCustomTitle=true,
						startTime=fixLuaDate(holiday.startDate),
						endTime=fixLuaDate(holiday.endDate),
						calendarType="HOLIDAY",
						sequenceType=sequenceType,
						eventType=CalendarEventType.Other,
						iconTexture=iconTexture,
						modStatus="",
						inviteStatus=0,
						invitedBy="",
						inviteType=CalendarInviteType.Normal,
						sequenceIndex=sequenceIndex,
						numSequenceDays=numSequenceDays,
						difficultyName="",
						dontDisplayBanner=dontDisplayBanner,
						dontDisplayEnd=false,
						isLocked=false,
						ZIndex=ZIndex
					}
					tinsert(matchingEvents, eventTable)
				end
			end
		end

		if GetCVar("calendarShowResets") ~= "0" then
			for _, raid in next, RaidResets do
				if dateGreaterThan(eventDate, raid.firstReset) and dateIsOnFrequency(eventDate, raid.firstReset, raid.frequency) then
					local eventTable = {
						eventType=CalendarEventType.Other,
						sequenceType="",
						isCustomTitle=true,
						startTime=fixLuaDate(date("*t", time({
							year=eventDate.year,
							month=eventDate.month,
							day=eventDate.day,
							hour=8,
							min=0
						}))),
						difficultyName="",
						invitedBy="",
						inviteStatus=0,
						dontDisplayEnd=false,
						isLocked=false,
						title=raid.name,
						calendarType="RAID_RESET",
						inviteType=CalendarInviteType.Normal,
						sequenceIndex=1,
						dontDisplayBanner=false,
						modStatus="",
						ZIndex=1
					}
					tinsert(matchingEvents, eventTable)
				end
			end
		end

		if next(matchingEvents) == nil or matchingEvents[index - originalEventCount] == nil then
			assert(false, string.format("Injected event expected for date: %s", dumpTable(eventDate)))
		else
			table.sort(matchingEvents, function(a,b)
				return a.ZIndex > b.ZIndex
			end)
			return matchingEvents[index - originalEventCount]
		end
	end

	-- Strip difficulty name since Classic has no difficulties
	originalEvent.difficultyName = ""

	return originalEvent
end

function stubbedSetMonth(offset)
	-- C_Calendar.SetMonth updates the game's internal monthOffset that is applied to GetDayEvent and GetNumDayEvents calls,
	-- we have to stub it to do the same for our stubbed methods
	state.currentMonthOffset = state.currentMonthOffset + offset
	C_Calendar.SetMonth(offset)

	adjustMonthByOffset(state.presentDate, offset)
end

function stubbedSetAbsMonth(month, year)
	-- Reset state
	state.presentDate.year = year
	state.presentDate.month = month
	state.currentEventIndex = 0
	state.currentMonthOffset = 0
	C_Calendar.SetAbsMonth(month, year)
end

function communityName()
	-- Gets Guild Name from Player since built in functionality is broken
	local communityName, _ = GetGuildInfo("player")
	return communityName
end

-- Slash command /calendar to open the calendar

SLASH_CALENDAR1, SLASH_CALENDAR2 = '/cal', '/calendar'

function SlashCmdList.CALENDAR(_msg, _editBox)
	Calendar_Toggle()
end

function newGetHolidayInfo(offsetMonths, monthDay, eventIndex)
	-- return C_Calendar.GetHolidayInfo(offsetMonths, monthDay, eventIndex)
	-- Because classic doesn't return any events, we're completely replacing this function
	local event = stubbedGetDayEvent(offsetMonths, monthDay, eventIndex)

	local eventName = event.title
	local eventDesc

	for _, holiday in next, GetClassicHolidays() do
		-- No way to differentiate the locations of darkmoon faire
		if eventName == holiday.name then
			eventDesc = holiday.description
		end
	end

	if eventDesc == nil then
		return
	else
		return {
			name=eventName,
			startTime=event.startTime,
			endTime=event.endTime,
			description=eventDesc
		}
	end
end


function UpdateCalendarState(year, month, day)
	state.presentDate.year = year
	state.presentDate.month = month
	state.presentDate.day = day
end

function stubbedGetEventIndex()
	local original = C_Calendar.GetEventIndex()
	if (original and original.offsetMonths == state.presentDate.currentMonthOffset and original.monthDay == state.presentDate.day and original.eventIndex == state.currentEventIndex) then
		-- If there is an original event and our state matches up
		return original
	end

	return {
		offsetMonths=state.currentMonthOffset,
		monthDay=state.presentDate.day,
		eventIndex=state.currentEventIndex
	}
end

function stubbedOpenEvent(monthOffset, day, eventIndex)
	-- Normally, event side panels are opened by the OnEvent handler, however that doesn't work for injected events
	-- So instead, we have hooked into the OpenEvent function to perform the same logic as the event handler
	local original_event = C_Calendar.GetDayEvent(monthOffset, day, eventIndex)
	state.currentEventIndex = eventIndex
	state.currentMonthOffset = monthOffset

	if original_event ~= nil then
		C_Calendar.OpenEvent(monthOffset, day, eventIndex)
	else
		local injectedEvent = stubbedGetDayEvent(monthOffset, day, eventIndex)
		if injectedEvent.calendarType == "HOLIDAY" then
			CalendarFrame_ShowEventFrame(CalendarViewHolidayFrame)
		elseif injectedEvent.calendarType == "RAID_RESET" then
			CalendarFrame_ShowEventFrame(CalendarViewRaidFrame)
		end
	end
end

-- Hide the default Time-of-Day frame because it occupies the same spot as the calendar button
-- This is the same decision Blizzard made according to their comments
GameTimeFrame:Hide()

function stubbedGetRaidInfo(monthOffset, day, eventIndex)
	-- Stubbing to return injected reset events
	local originalInfo = C_Calendar.GetRaidInfo(monthOffset, day, eventIndex)
	if originalInfo ~= nil then
		return originalInfo
	else
		local injectedRaidEvent = stubbedGetDayEvent(monthOffset, day, eventIndex)
		return {
			name=injectedRaidEvent.title,
			difficultyName="",
			time=injectedRaidEvent.startTime
		}
	end
end

-- Guild Event Copying
eventClipboard = false
eventPasteGuildInvites = false
eventUpdateGuildInvites = false
eventType = ""
eventInfo = {}
inviteTable = {}
dayButton = {}

-- Returns true if "player" can edit event
function stubbedContextMenuEventCanEdit(monthOffset, day, eventIndex)
	local playerName = UnitName("player")
	local eventInfoTemp = stubbedGetDayEvent(monthOffset, day, eventIndex)
	if eventInfoTemp["modStatus"] == "CREATOR" or eventInfoTemp["modStatus"] == "MODERATOR" then
		return true
	else
		return false
	end
end

-- (DEPRECIATED/UNUSED) Returns true if "player" can remove event
function stubbedContextMenuEventCanRemove(monthOffset, day, eventIndex)
	local playerName = UnitName("player")
	local eventInfoRemove = stubbedGetDayEvent(monthOffset, day, eventIndex)
	if eventInfoRemove["modStatus"] == "CREATOR" then
		return true
	else
		return false
	end
end

-- Load in for UIMenu_AddButton:CALENDAR_COPY_EVENT event
function stubbedCalendarDayContextMenu_CopyEvent(monthOffset, day, eventIndex)
	eventInfo = stubbedGetDayEvent(monthOffset, day, eventIndex)
	if eventInfo["calendarType"] == "GUILD_EVENT" then -- If "GUILD_EVENT" event type pass to modified functions
		eventClipboard = true
		eventType = "GUILD_EVENT"
		C_Calendar.OpenEvent(monthOffset, day, eventIndex)
	else -- If all other event types, pass to native function
		eventClipboard = true
		C_Calendar.ContextMenuEventCopy()
	end
end

-- Returns true if event is copied
function stubbedContextMenuEventClipboard()
	return eventClipboard
end

-- Loads in data to be copied from Parent event
function copyEvent()
	if eventClipboard == true and eventType == "GUILD_EVENT" then
		local descriptionTemp = C_Calendar.GetEventInfo()
		eventInfo["description"] = descriptionTemp["description"]
		eventInfo["textureIndex"] = descriptionTemp["textureIndex"]
		local numInvites = C_Calendar.GetNumInvites()
		inviteTable = {}
		for i=1,numInvites do
			table.insert(inviteTable, C_Calendar.EventGetInvite(i))
		end
		C_Calendar.CloseEvent()
	end
end

-- Modified paste function
function stubbedCalendarDayContextMenu_PasteEvent()
	dayButton = CalendarContextMenu.dayButton
	if eventInfo["calendarType"] == "GUILD_EVENT" then -- If "GUILD_EVENT" event type the create new event using copied data
		local monthInfo = C_Calendar.GetMonthInfo(dayButton.monthOffset)
		C_Calendar.CreateGuildSignUpEvent()
		
		local d = C_DateAndTime.GetCurrentCalendarTime()
		C_Calendar.EventSetDate(monthInfo["month"], dayButton.day, d.year)
		C_Calendar.EventSetTime(eventInfo["startTime"]["hour"], eventInfo["startTime"]["minute"])
		C_Calendar.EventSetTitle(eventInfo["title"])
		C_Calendar.EventSetDescription(eventInfo["description"])
		C_Calendar.EventSetType(eventInfo["eventType"])
		if eventInfo["textureIndex"] ~= nil then C_Calendar.EventSetTextureID(eventInfo["textureIndex"]) end
		C_Calendar.AddEvent()
	else -- If all other event types, pass to native function
		eventInfo = {}
		inviteTable = {}
		eventClipboard = false
		C_Calendar.ContextMenuEventPaste(dayButton.monthOffset, dayButton.day)
	end
end

-- Gets newly created eventIndex and opens event for updating Invitation list
function updateEventInvites(day, monthOffset)
	local eventIndex = 0
	if eventClipboard == true and monthOffset == dayButton.monthOffset and day == dayButton.day then
		local numDayEvents = C_Calendar.GetNumDayEvents(dayButton.monthOffset, dayButton.day)
		if numDayEvents ~= nil then
			for i=1,numDayEvents do
				local eventInfoTemp = stubbedGetDayEvent(dayButton.monthOffset, dayButton.day, i)
				if eventInfoTemp["startTime"]["hour"] == eventInfo["startTime"]["hour"] and eventInfoTemp["startTime"]["minute"] == eventInfo["startTime"]["minute"] and eventInfoTemp["title"] == eventInfo["title"] then
					eventIndex = i
					break
				end
			end
			C_Calendar.OpenEvent(dayButton.monthOffset, dayButton.day, eventIndex)
			eventPasteGuildInvites = true
		end
		eventClipboard = false
	end
end

-- Create invitations in the new event
function pasteInvitations()
	local canEditEvent = C_Calendar.EventCanEdit()
	local canSendInvite = C_Calendar.CanSendInvite()
	if eventClipboard == false and eventPasteGuildInvites == true and canSendInvite == true and canEditEvent == true then
		for k, v in next, inviteTable do
			if v["name"] ~= UnitName("player") then
				C_Calendar.EventInvite(v["name"])
			end
		end
		eventPasteGuildInvites = false
		eventUpdateGuildInvites = true
	end
end

-- Update newly created invitations in new event
function updatePastedInvitions()
	local canEditEvent = C_Calendar.EventCanEdit()
	if eventClipboard == false and eventPasteGuildInvites == false and eventUpdateGuildInvites == true and canEditEvent == true then
		local numInvites = C_Calendar.GetNumInvites()
		local numMatched = 0
		if numInvites > 0 then
			local inviteExistingTable = {}
			for k, v in next, inviteTable do
				C_Calendar.EventSetInviteStatus(k, v["inviteStatus"])
				local singleInvite = C_Calendar.EventGetInvite(k)
				table.insert(inviteExistingTable, singleInvite)
			end
			for k, v in next, inviteTable do
				if inviteTable["inviteStatus"] == inviteExistingTable["inviteStatus"] then
					numMatched = numMatched + 1
				end
			end
			if numMatched == numInvites then
				C_Calendar.CloseEvent()
				eventInfo = {}
				inviteTable = {}
				eventClipboard = false
				eventUpdateGuildInvites = false
			end
		end
	end
end
