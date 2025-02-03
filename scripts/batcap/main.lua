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
-- battery icon is inspired by Zavionix Bat/Cells "V2.1.4"

-- =============================================================================
-- ETHOS battery widget
-- File:   : main.lua
-- Author  : © RNDr.Vladimir Pribyl, CSc. (VPRHELI)
-- History : Date        Version Author   Comment
--           ----------  ------- -------- ------------------------------------
--           15.01.2025  0.0.1   VPRHELI  initial version
--           27.01.2025  1.0.0   VPRHELI  minor changes
-- =============================================================================
--
-- TODO
-- carbon background - taken from the net and height according to the lowest widget - I would name it carbon.bmp
-- white background

local version           = "v1.0.1"
local environment       = system.getVersion()
-- multilanguage text table
-- if Yo want add your supported mother language, extend table and let me know, I will push it in the Git
local transtable        = { en = { wgname          = "Battery Capacity",
                                   menuname        = "Battery Capacity",
                                   battype         = "Battery Type",
                                   LiPo            = "Lipo Sensor",
                                   VoltageSensor   = "Voltage Sensor",
                                   VFAScells       = "Battery Cells Count",
                                   CurrSensor      = "Current Sensor",
                                   curmax          = "Current / Max",
                                   wgtsmall        = "Small Widget",
                                   badSensor       = "Bad sensor type",
                                   noTelemetry     = "No Telemetry",
                                   color1          = "Select color",
                                 },
                            cz = {
                                   wgname          = "Kapacita baterie",
                                   menuname        = "Kapacita baterie",
                                   battype         = "Typ baterie",
                                   LiPo            = "Lipo senzor",
                                   VoltageSensor   = "Senzor napětí",
                                   VFAScells       = "Počet článků baterie",
                                   CurrSensor      = "Senzor proudu",
                                   curmax          = "Aktuální / Max",
                                   wgtsmall        = "Málo místa",
                                   badSensor       = "Špatně zvolený senzor",
                                   noTelemetry     = "Chybí telemetrie",
                                   color1          = "Vyberte barvu",
                                 },
                            de = {
                                   wgname          = "Batteriekapazitat",
                                   menuname        = "Batteriekapazität",
                                   battype         = "Akku-Typ",
                                   LiPo            = "Lipo-Sensor",
                                   VoltageSensor   = "Spannungssensor",
                                   VFAScells       = "Anzahl der Batteriezellen",
                                   CurrSensor      = "Stromsensor",
                                   curmax          = "Aktuell / Max",
                                   wgtsmall        = "Kleines Widget",
                                   badSensor       = "Schlechter Sensortyp",
                                   noTelemetry     = "Keine Telemetrie",
                                   color1          = "Wähle Farbe",
                                 }                                 
                          }
                          
local utils   = {}
local libs    = { menuLib  = nil,
                  batLib   = nil,
                  utils    = nil}
local g_libInitDone    = false

-- #############
-- # conf      #
-- #############
 local conf = {
                version        = version,
                locale         = system.getLocale(),
                basePath       = "/scripts/batcap/",
                libFolder      = "lib/",
                imgFolder      = "img/",
                transtable     = transtable,
                telemetryState = nil,
                lastTelState   = nil,       -- last telemetry state
                simulation     = nil,
                darkMode       = nil,
                battypeuse     = -1         -- which battery type is used { "Lipo", 0 },{ "HV Lipo", 1 },{ "Lion", 2 },{ "LiFe", 3 } default Lipo
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
    libs.batLib  = loadLibrary("batLib")
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
          LiPoSensor     = nil,        -- FrSky FLVS
          CurrentSensor  = nil,        -- FrSky FAS40/80
          VoltageSensor  = nil,        -- FrSky FAS40/80
          -- LiPo Values
          cellsCount     = nil,
          cellsValueArr  = {},
          cellValue      = nil,
          cellMinValue   = nil,                   
          -- VFAS Values
          voltage        = nil,
          VFAScells      = 3,
          current        = nil,
          currMax        = 0,          -- battery current X.XA
          batPow         = nil,        -- battery Power
          batPowMax      = 0,          -- battery Power Max                      
          lastVoltage    = 0,          -- last battery votage when we lose telemetry
          BatType        = 0,
          batCapmAh      = 0,
          FlightReset    = 0,          -- should be zero
          -- config
          color1         = lcd.RGB(0xEA, 0x5E, 0x00),   
          transtable     = transtable,
          -- status
          initPending    = true,
          runBgTasks     = false,
          -- layout
          batteryIcon    = nil,      -- empty battery icon
          screenHeight   = nil,
          screenWidth    = nil, 
          zoneHeight     = nil,
          zoneWidth      = nil,
          battX          = nil,      -- battery large icon X position update in CheckEnvironment()
          battY          = nil,      -- battery large icon Y position update in CheckEnvironment()
          battW          = nil,      -- battery large icon Width      update in CheckEnvironment()
          battH          = nil,      -- battery large icon Height     update in CheckEnvironment()
          battfdX        = nil,      -- battery fill dX               update in CheckEnvironment()
          battfdY        = nil,      -- battery fill dY               update in CheckEnvironment()
          battfW         = nil,      -- battery fill Width            update in CheckEnvironment()
          battfH         = nil,      -- battery fill Height           update in CheckEnvironment()
          screenType     = "",
          flash          = 0,        -- flash voltage rectangle YELLOW / RED if telemetry lost
          last_time      = 0,
          battVwidth     = 130,      -- battery voltage/current frame width
          battCFSwidth   = 200,      -- battery current full frame width
          battVheight    = 42,       -- battery voltage/current frame height
          battCellW      = 60,       -- battery cell rectangle Width
          battCellH      = 23,       -- battery cell rectangle Height
          battCelldY     = 6,        -- battery cell rectangle vertical offset
          curColOffset   = 20,       -- current column offset for full page zone 
          noTelFrameT    = 3,        -- thickness of no telemetry frame
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
  widget.BatType                  = storage.read("BatType")  
  widget.batCapmAh                = storage.read("batCapmAh")
  widget.LipoSensor               = storage.read("LipoSensor")
  widget.VoltageSensor            = storage.read("VoltageSensor")
  widget.VFAScells                = storage.read("VFAScells")
  widget.CurrentSensor            = storage.read("CurrentSensor")
  widget.color1                   = storage.read("color1")
  
--  print ("")
--  if widget.LipoSensor == nil then
--    print ("### read ### widget.LipoSensor     : nil")
--  else
--    print ("### read ### widget.LipoSensor     : " .. widget.LipoSensor:name())    
--  end
--  if widget.VoltageSensor == nil then
--      print ("### read ### widget.VoltageSensor  : nil")
--  else
--    print ("### read ### widget.VoltageSensor  : " .. widget.VoltageSensor:name())    
--  end
--  if widget.CurrentSensor == nil then
--      print ("### read ### widget.CurrentSensor  : nil")
--  else
--    print ("### read ### widget.CurrentSensor  : " .. widget.CurrentSensor:name()) 
--  end
--  if widget.VFAScells == nil then
--      print ("### read ### widget.VFAScells      : nil")
--  else
--    print ("### read ### widget.VFAScells      : " .. widget.VFAScells)    
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
--  if widget.LipoSensor == nil then
--      print ("### write ### widget.LipoSensor    : nil")
--  else
--    print ("### write ### widget.LipoSensor    : " .. widget.LipoSensor:name())    
--  end
--  if widget.VoltageSensor == nil then
--      print ("### write ### widget.VoltageSensor : nil")
--  else
--    print ("### write ### widget.VoltageSensor : " .. widget.VoltageSensor:name())    
--  end
--  if widget.CurrentSensor == nil then
--      print ("### write ### widget.CurrentSensor : nil")
--  else
--    print ("### write ### widget.CurrentSensor : " .. widget.CurrentSensor:name()) 
--  end
--  if widget.VFAScells == nil then
--      print ("### write ### widget.VFAScells     : nil")
--  else
--    print ("### write ### widget.VFAScells     : " .. widget.VFAScells)    
--  end
  
  storage.write("BatType"       , widget.BatType)  
	storage.write("batCapmAh"     , widget.batCapmAh)
	storage.write("LipoSensor"    , widget.LipoSensor)  
	storage.write("VoltageSensor" , widget.VoltageSensor)  
  storage.write("VFAScells"     , widget.VFAScells)  
  storage.write("CurrentSensor" , widget.CurrentSensor)  
	storage.write("color1"        , widget.color1)

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
    libs.utils.checkFlightReset(widget)
    if conf.telemetryState ~= conf.lastTelState then
      -- telemetry state changed
      --print ("### telemetry state changed")
      if conf.lastTelState == 1 then
        widget.lastVoltage = libs.batLib.getBestVoltage (widget)
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
	local key = "BatCap"			  -- unique key - keep it less that 8 chars

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
