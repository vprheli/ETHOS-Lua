-- #########################################################################
-- #                                                                       #
-- # License GPLv3: https://www.gnu.org/licenses/gpl-3.0.html              #
-- #                                                                       #
-- # This program is free software; you can redistribute it and/or modify  #
-- # it under the terms of the GNU General Public License version 2 as     #
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
--           23.01.2025  0.0.1   VPRHELI  initial version
--           27.01.2025  1.0.0   VPRHELI  minor changes
-- =============================================================================
--
-- TODO

local version           = "v1.0.0"
local environment       = system.getVersion()
-- multilanguage text table
-- if Yo want add your supported mother language, extend table and let me know, I will push it in the Git
local transtable        = { en = { wgname          = "Vario",
                                   menuname        = "Vario",
                                   VarioSensor     = "Height sensor",
                                   VertSensor      = "Vertical speed sensor",
                                   wgtsmall        = "Small Widget",
                                   badSensor       = "Bad sensor type",
                                   noTelemetry     = "No Telemetry",
                                   bgcolor         = "Select background color",
                                 },
                            cz = { wgname          = "Vario",
                                   menuname        = "Vário",
                                   VarioSensor     = "Senzor výšky",
                                   VertSensor      = "Senzor vertikální rychlosti",
                                   wgtsmall        = "Málo místa",
                                   badSensor       = "Špatně zvolený senzor",
                                   noTelemetry     = "Chybí telemetrie",
                                   bgcolor         = "Vyberte barvu pozadí",
                                 },
                            de = { wgname          = "Vario",
                                   menuname        = "Vário",
                                   VarioSensor     = "Höhensensor",
                                   VertSensor      = "Vertikaler Geschwindigkeitssensor",
                                   wgtsmall        = "Kleines Widget",
                                   badSensor       = "Schlechter Sensortyp",
                                   noTelemetry     = "Keine Telemetrie",
                                   bgcolor         = "Hintergrundfarbe auswählen",
                                 }                                 
                          }
                          
local utils   = {}
local libs    = { menuLib  = nil,
                  batLib   = nil,
                  utils    = nil}
local g_libInitDone    = false
 
 colors = {
    white            = WHITE,
    black            = BLACK,
    red              = RED,
    panelBackground  = lcd.RGB(0,   160, 224),
  }
-- #############
-- # conf      #
-- #############
 local conf = {
                version        = version,
                locale         = system.getLocale(),
                basePath       = "/scripts/vario/",
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
local g_updates_per_second = 1                -- how many times per second display will be updated

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
    libs.batLib  = loadLibrary("varLib")
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
                   -- telemetry
                   VarioSensor    = nil,        -- FrSky Vario ADV, FrSky Archer Plus GR8
                   VerticalSensor = nil,
                   -- Vario Values
                   altitude       = nil,
                   vertSpeed      = nil,
                   lastAltitude   = nil,
                   FlightReset    = 0,          -- should be zero
                   -- layout
                   bgcolor        = lcd.RGB(0, 160, 224),   
                   transtable     = transtable,
                   -- status
                   initPending    = true,
                   runBgTasks     = false,                   
                   -- layout
                   screenHeight   = nil,
                   screenWidth    = nil, 
                   zoneHeight     = nil,
                   zoneWidth      = nil,
                   screenType     = "",
                   last_time      = 0,
                   noTelFrameT    = 5,      -- thickness of no telemetry frame
                   frameX         = 60,     -- X frame size for pitch attitude markers
                   frameY         = 18,     -- Y frame size for pitch attitude markers
                   markerL_len    = 10,
                   markerR_len    = 8,
                   dblNumOffset   = 38,
                 }
end
-- #################################################################### 
-- *  paint                                                           #
-- ####################################################################
local function paint(widget)
  --print ("### function paint()")  
  libs.batLib.paint (widget)
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
  print ("### function configure()")
  libs.menuLib.configure (widget)
  widget.screenHeight = nil         -- force varLib.CheckEnvironment (widget)
end
-- #################################################################### 
-- # read                                                             #
-- #    read values from internal storage                             #
-- #################################################################### 
local function read(widget)
  --print ("### function read()")
  widget.VarioSensor              = storage.read("Vario")  
  widget.VerticalSensor           = storage.read("VSpeed") 
  widget.color1                   = storage.read("color1")
  
--  print ("")
--  if widget.VarioSensor == nil then
--    print ("### read ### widget.VarioSensor     : nil")
--  else
--    print ("### read ### widget.VarioSensor     : " .. widget.VarioSensor:name())    
--  end
	return true
end
-- #################################################################### 
-- # write                                                            #
-- #    write values to internal storage                              #
-- #################################################################### 
local function write(widget)
  --print ("### function write()")
--  print ("")
--  if widget.VarioSensor == nil then
--      print ("### write ### widget.VarioSensor    : nil")
--  else
--    print ("### write ### widget.VarioSensor    : " .. widget.VarioSensor:name())    
--  end

  storage.write("Vario"       , widget.VarioSensor)  
  storage.write("VSpeed"      , widget.VerticalSensor)  
	storage.write("color1"      , widget.color1)

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
	
	return true
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
    --libs.utils.checkFlightReset(widget)           -- not necessary in this widget
    if conf.telemetryState ~= conf.lastTelState then
      -- telemetry state changed
      --print ("### telemetry state changed")
      if conf.lastTelState == 1 then
        widget.lastAltitude = widget.altitude
      end
      conf.lastTelState = conf.telemetryState
      -- let transmitter and widgets until sensors are back on
      widget.last_time = actual_time  + 3      
    end

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
	local key = "Vario"			  -- unique key - keep it less that 8 chars

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
