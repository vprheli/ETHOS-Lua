-- #########################################################################
-- #                                                                       #
-- # License GPLv3: https://www.gnu.org/licenses/gpl-3.0.html              #
-- #                                                                       #
-- # This program is free software; you can redistribute it and/or modify  #
-- # it under the terms of the GNU General Public License version 3 as     #
-- # published by the Free Software Foundation.                            #
-- #                                                                       #
-- # This program is distributed in the hope that it will be useful        #
-- # but WITHOUT ANY WARRANTY; without even the implied warranty of        #
-- # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         #
-- # GNU General Public License for more details.                          #
-- #                                                                       #
-- #########################################################################
--
-- =============================================================================
-- ETHOS battery widget
-- File:   : main.lua
-- Author  : © RNDr.Vladimir Pribyl, CSc. (VPRHELI)
-- History : Date        Version Author   Comment
--           ----------  ------- -------- ------------------------------------
--           23.01.2025  1.0.0   VPRHELI  initial version
--           28.01.2025  1.0.1   VPRHELI  Getting timer value, HW different in simulator
--           23.02.2025  1.0.3   VPRHELI  separate translate table
--           04.03.2025  1.0.4   VPRHELI  translate table fix
-- =============================================================================
--
-- TODO

local version           = "v1.0.4"
local environment       = system.getVersion()
-- load translate table from external file
local tableFile  = assert(loadfile("/scripts/digclock/translate.lua"))()
local transtable = tableFile.transtable
local utils   = {}
local libs    = { menuLib  = nil,
                  digLib   = nil,
                  utils    = nil}
local g_libInitDone    = false

 colors = {
    white            = COLOR_WHITE,
    black            = COLOR_BLACK,
    red              = COLOR_RED,
    panelBackground  = lcd.RGB(0,   160, 224),
  }
-- #############
-- # conf      #
-- #############
 local conf = {
                version        = version,
                locale         = system.getLocale(),
                basePath       = "/scripts/digclock/",
                libFolder      = "lib/",
                imgFolder      = "img/",
                transtable     = transtable,
                telemetryState = nil,
                lastTelState   = nil,       -- last telemetry state
                simulation     = nil,
                darkMode       = nil,
                colors         = colors,
              }

local g_last_time    = 0                      -- last time of refreshed display
local g_updates_per_second = 2                -- how many times per second display will be updated

-- ####################################################################
-- # loadLibrary                                                      #
-- ####################################################################
function loadLibrary(filename)
  local lib = dofile(conf.basePath .. conf.libFolder .. filename..".lua")
  if lib.init ~= nil then
    lib.init(conf, libs)
  end
  return lib
end
-- ####################################################################
-- *  name                                                            #
-- *    return Widget name                                            #
-- ####################################################################
local function name(widget)
  return libs.utils.translate ("wgname")
end
-- ####################################################################
-- *  initLibraries                                                   #
-- *    return Widget name                                            #
-- ####################################################################
local function initLibraries(widget)
  --print ("### initLibraries()")
  if g_libInitDone == false then
    g_libInitDone = true
    -- load libraries
    libs.utils   = loadLibrary("utils")
    libs.menuLib = loadLibrary("menuLib")
    libs.digLib  = loadLibrary("digLib")
  end
end
-- ####################################################################
-- #  create                                                          #
-- #    this function is called whenever the widget is first          #
-- #    initialised.                                                  #
-- #    it's usefull for setting up widget variables or just          #
-- ####################################################################
local function create()
  --print ("### function create()")

	return {
            -- Stopwatch
            StopWatch      = nil,        -- Stopwatch
            swMember       = nil,
            swtime         = nil,
            FlightReset    = 0,          -- should be zero
            -- config
            bgcolor        = lcd.RGB(0, 0, 0),
            txtcolor       = lcd.RGB(128, 128, 128),
            segmentColor   = lcd.RGB(255, 0, 0),
            transtable     = transtable,
            digits         = {},
            paintName      = false,
            -- status
            initPending    = true,
            runBgTasks     = false,
            -- layout
            screenHeight   = nil,
            screenWidth    = nil,
            zoneHeight     = nil,
            zoneWidth      = nil,
            screenType     = "",
            iconX          = nil,
            iconW          = nil,
            iconH          = nil,
            iconY          = nil,
            iconColW       = nil,
            icon_dX        = nil,
            last_time      = 0,
            noTelFrameT    = 3,      -- thickness of no telemetry frame
          }
end
-- ####################################################################
-- *  paint                                                           #
-- ####################################################################
local function paint(widget)
  --print ("### function paint()")
  libs.digLib.paint (widget)
end
-- ####################################################################
-- # menu                                                             #
-- #    add a menu item to the configuration menu popup of the widget #
-- 3    usefull if adding new tools                                   #
-- ####################################################################
local function menu(widget)
  --print ("### function menu()")
	-- add a menu item to the configuration menu popup of the widget
	-- usefull if adding new tools

	return {
		--   { "Entry 1", function() end},
		--   { "Entry 2", function() end},
	}
end
-- ####################################################################
-- # configure                                                        #
-- #    Widget Configuration options                                  #
-- ####################################################################
local function configure(widget)
  --print ("### function configure()")
  libs.menuLib.configure (widget)
  widget.screenHeight = nil         -- force digLib.CheckEnvironment (widget)
  widget.swMember     = nil
end
-- ####################################################################
-- # read                                                             #
-- #    read values from internal storage                             #
-- ####################################################################
local function read(widget)
  --print ("### function read()")
  widget.StopWatch              = storage.read("StopWatch")
  widget.segmentColor           = storage.read("segmentColor")
  widget.bgcolor                = storage.read("bgcolor")
  widget.txtcolor               = storage.read("txtcolor")

	return true
end
-- ####################################################################
-- # write                                                            #
-- #    write values to internal storage                              #
-- ####################################################################
local function write(widget)
  storage.write("StopWatch"    , widget.StopWatch)
  storage.write("segmentColor" , widget.segmentColor)
	storage.write("bgcolor"      , widget.bgcolor)
	storage.write("txtcolor"     , widget.txtcolor)

	return true
end
-- ####################################################################
-- # event                                                            #
-- #    trigger whenever the widget is in focus and and               #
-- #    even occurs such as a button or screen click                  #
-- ####################################################################
local function event(widget, category, value, x, y)
  --print ("### function event()")
	--print ("### Event received:", category, value, x, y)

	return false
end
-- ####################################################################
-- # wakeup                                                           #
-- #    this is the main loop that ethos calls every couple of ms     #
-- ####################################################################
local function wakeup(widget)
  local actual_time = os.clock()  -- Získání aktuálního času

  if widget.initPending == true then
    -- TODO if necesssary
    widget.runBgTasks  = true
    widget.initPending = false
  end

  if widget.runBgTasks == true then
    libs.utils.checkTelemetry()
    if actual_time > widget.last_time then
      widget.last_time = actual_time + 1 / g_updates_per_second   -- new time for widget refresh
      if lcd.isVisible() then
        lcd.invalidate ();                                        -- full screen refresh
      end
    end
  end
  return
end

-- ####################################################################
-- # init                                                             #
-- #    this is where we 'setup' the widget                           #
-- ####################################################################
local function init()
  --print ("### function init()")
	local key = "digsw"			  -- unique key - keep it less that 8 chars

  initLibraries ()   -- load all becessary libraries

  system.registerWidget(
        {
            key       = key,				  -- unique project id
            name      = name,				  -- name of widget - objevi se v seznamu Widgetu
            create    = create,			  -- function called when creating widget
            configure = configure,		-- function called when configuring the widget (use ethos forms)
            paint     = paint,				-- function called when lcd.invalidate() is called
            wakeup    = wakeup,			  -- function called as the main loop
            read      = read,				  -- function called when starting widget and reading configuration params
            write     = write,				-- function called when saving values / changing values in the configuration menu
            event     = event,				-- function called when buttons or screen clips occur
            menu      = menu,				  -- function called to add items to the menu
            persistent = false,			  -- true or false to make the widget carry values between sessions and models (not safe imho)
        }
  )

end

return {init = init}
