[![Build Status](https://github.com/birkholz/ClassicCalendar/workflows/CI/badge.svg)](https://github.com/birkholz/ClassicCalendar/actions?workflow=CI)
[![ClassicCalendar on Discord](https://img.shields.io/badge/discord-ClassicCalendar-738bd7.svg?style=flat)](https://discord.gg/CMxKsBQFKp) 

# This addon is no longer maintained, as I stopped playing WoW classic

---

# Classic Calendar

A port of the official Blizzard_Calendar addon from WotLK classic to Season of Discovery and Classic Era. Made possible because of the existence of the core calendar functions `C_Calendar` being present in the classic client even though the interface isn't there. However, even though the calendar functions exist, the only things that worked immediately were player-created events (oddly enough) and raid lockouts, so those functions worked without any changes necessary. For events such as holidays, the game simply acts as if they don't exist. So in the process of porting the addon, these issues have been fixed by injecting the responses we'd expect the game to provide. This means that while we've strived to make the data as accurate as possible, it's ultimately not the game itself as the source, so issues may arise with the dates/strings/textures not being correct. Anywhere where we didn't have an authoritative source of the data, we've made our best guess. Please report any issues you encounter [here](https://github.com/birkholz/ClassicCalendar/issues).

![preview image](./preview.png)

## Features

* A calendar that functions identically to the one found in WotlK classic and retail, while matching the expectations of being in Classic
* Filters to control which categories of events are visible
* Holidays
* Battleground Weekends, including which BG has the call to arms
* Darkmoon Faire's schedule, including the location
* Player-created events visible to anyone invited
* Guild events visible to everyone in the guild
* Raid/dungeon events
* In-game mail notifications when an event is cancelled (we have no control over this)
* The ability to copy/paste events from one day to another
* The ability to mass-invite everyone from an event to your party/raid
* A flashing calendar icon to notify you of pending invites

## Accessing the Calendar

* Clicking the Calendar button at the top right of the minimap, replacing the time-of-day indicator
* Typing `/cal`/`/calendar` in chat, or `/caloptions`/`/calendaroptions` to open the addon options

## Known Issues

* Holiday dates & times may be wrong
* No ability to disable the in-game mail notifications. This is outside of the addon's control and how the game handles events being deleted.
* Pressing escape closes the entire calendar instead of 1 panel at a time. Unfortunately the original implementation uses privileged execution, and causes the "Addon has been blocked from an action only available to the Blizzard UI" error. We have not found an alternative way of implementing this.
* Guild Announcements are unavailable, as are Community events. Both are features that only function in later versions of WoW and aren't really portable because of underlying systems being nonexistent.

## Contributing

We try to keep all changes separate from the original files where possible in case there are ever upstream changes that we want to merge in. Pull Requests are welcome, though only features that fit in Classic will be considered, and anything that doesn't reflect the official calendar must be disabled by default and only enabled through the addon's settings.


## Changes from Blizzard's code

Here we will document all changes that we've made in order to get the calendar functioning as it should. If Blizzard was interested in adding the calendar to SoD themselves, these are the issues they'd need to fix.

* `C_Calendar.GetNumDayEvents` and `C_Calendar.GetDayEvent` return player-created events (using the other `C_Calendar` functions) authored by yourself and any events you're invited to by others. They also correctly return raid lockouts, that is, when your current raid lockout(s) expire(s). But they don't return holidays or raid resets at all. No Darkmoon Faire, no Winter Veil, no Call to Arms, etc. No raid resets even in classic era. Fixing this is the bulk of the work of Classic Calendar. However, most of these holidays have fixed schedules or are tied to real world events like solstices, so we can fairly accurately place their dates presumably the same way sites like Wowhead do. The times that things start and end, however, are undocumented anywhere we could find, so we've combined what we know from Wrath, patch notes when events were added, or server reset times. That's why while dates are probably mostly correct, start/end times may be way off.
* Likewise to the above, `C_Calendar.GetHolidayInfo` exists and functions, but acts as if none of the holidays exist, basically making it worthless. This is where holiday descriptions are returned, so we dumped all the different localized descriptions from this function in Wrath's client and inject the dumped descriptions to make this function work. This approach is mostly fine, though the description of Children's Week references cities that don't exist in classic era, so we still need to update that in every localization.
* `CALENDAR_FIRST_WEEKDAY` defines the starting weekday of the calendar (Sunday or Monday). However, it isn't changing under the circumstances that it does in Wrath and later, instead it always returns Sunday. We added an option to choose the starting weekday that overrides this global in the calendar code.
* `C_Calendar.EventGetTextures` returns dungeons and raids for Classic Era correctly, though they all have the default raid icon texture instead of their respective dungeon/raid icons. It hasn't been updated for SoD to only return the dungeons/raids available, or the dungeons that have been turned into raids. The correct textures exist in the classic client, so we just had to inject them into the otherwise correct response, and for SoD we had to cut out the unavailable dungeons/raids and move the converted dungeons into the raid response.
* `CALENDAR_INVITESTATUS_INFO`, `CalendarType`, `CalendarInviteType`, `CalendarEventType`, `CalendarTexturesType` global enums are all missing. They are present in the exported interface code from classic era, however, so we simply copied them from the exported code.
* `CALENDAR_FILTER_BATTLEGROUND` is returning the Wrath "PvP Brawls" text, not a relevant text for classic's battleground holidays. We replaced it with new localized strings that make more sense in classic era.
* No guild permission for managing guild events exists, so we removed the `CanEditGuildEvent` condition as there is no alternative. This means everyone can make guild events. This could be used by people to spam others' calendars, but guild masters can always kick such players.
* `CALENDAR_EVENT_ALARM` event is never fired, even for player-created events that the client otherwise handles how it should. To replace this, we run a function every minute that checks for any upcoming player events and runs the same code the event would've (plus some additional options).
