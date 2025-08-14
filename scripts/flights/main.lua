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
-- ETHOS Flight & Flight total time counters
-- File:   : main.lua
-- Author  : © RNDr.Vladimir Pribyl, CSc. (VPRHELI)
--
-- History : Date        Version Author   Comment
--           ----------  ------- -------- ------------------------------------
--           18.01.2025  1.0.0   VPRHELI  initial version based on "Flights widget 2.0.1" of "d_wheel" USA
--           07.08.2025  1.1.0   VPRHELI  history total flight counter, Italian language supported
--           08.08.2025  1.1.1   VPRHELI  reset flight update file immedietly
--           14.08.2025  1.1.2   VPRHELI  correct flight counter bug
-- =============================================================================
--
-- Warm thanks to my Italian colleague Francesco Salvi for the translation into Italian
--
local version      = "v1.1.2"
local g_filesPath  = "/scripts/flights/Files/"
local g_locale     = system.getLocale()
-- load translate table from external file
local tableFile  = assert(loadfile("/scripts/flights/translate.lua"))()
local transtable = tableFile.transtable

-- ####################################################################
-- #  translate                                                       #
-- #    Language translate                                            #
-- #################################################################### 
local function translate(key)
    -- check valid language
    if transtable[g_locale] and transtable[g_locale][key] then
      return transtable[g_locale][key]
    else
      -- if language is not available, return key
      return key
    end
end
-- #################################################################### 
-- *  name                                                            #
-- *    return Widget name                                            #
-- #################################################################### 
local function name(widget)
  return translate ("wgname")
end

-- #################################################################### 
-- #  create                                                          #
-- #    this function is called whenever the widget is first          #
-- #    initialised.                                                  #
-- #    it's usefull for setting up widget variables or just          #
-- #################################################################### 
local function create()
    return {
      flights        = 0,       -- number of flights
      preset         = 0,       -- 
      newPreset      = 0,       -- preset value from widget configuration
      flights_total  = 0,       -- total seconds of all flight
      flight_time    = 0,
      flightSwitch   = nil,
      flightActive   = false,
      flightUpdated  = false,   -- true if trigger sec > trigDelay
      trigDelay      = 0,       -- widget configuration
      triggerSwitch  = nil,
      triggerActive  = false,   -- 
      triggerSec     = 0,
      updateFlight   = false,
      modelName      = nil,
      last_time      = 0,
      -- status
      initPending    = false,
      FlightReset    = 0,
      telemetryState = nil,
      -- layout
      zoneHeight     = nil,
      zoneWidth      = nil,
      timeFont       = nil,
      fontFlightH    = nil,
      fontTimeH      = nil,
      radio          = "",
      border         = false,
      noTelFrameT    = 3,        -- thickness of no telemetry frame      
      colorF         = lcd.RGB(0x00, 0xFC, 0x00),     -- color flights text
      colorT         = lcd.RGB(0x00, 0xFC, 0xC0),     -- color flight time text
    }
end

-- #################################################################### 
-- *  wgtinitialize                                                   #
-- ####################################################################
local function wgtinitialize (widget)
    widget.modelName = model.name()
    widget.flight_time = os.clock()
 
    local board = system.getVersion().board
    if string.find(board,"10") then
      widget.radio = "10"
    end
    if string.find(board,"12") then
      widget.radio = "12"
    end
    if string.find(board,"14") then
      widget.radio = "14"
    end
    if string.find(board,"20") then
      widget.radio = "20"
    end
    if string.find(board,"18") then
      widget.radio = "18"
    end
    if string.find(board,"TWXLITE") then
      widget.radio = "TWXLITE"
    end
    if string.find(board,"XE") then
      widget.radio = "XE"
    end
end
-- #################################################################### 
-- *  paint                                                           #
-- ####################################################################
local function paint(widget)
  -- ********************************************************
  -- * CheckEnvironment                  paint() local  *
  -- *  Read environment varibles                       *
  -- ********************************************************
  local function CheckEnvironment (widget)
    local w, h = lcd.getWindowSize()
   
    if w ~= widget.zoneWidth and h ~= widget.zoneHeight then
      -- environment changed
      widget.zoneHeight = h
      widget.zoneWidth  = w
      -- Define positions
      if h < 50 then
        widget.timeFont = FONT_XS
      elseif h < 80 then
        widget.timeFont = FONT_L_BOLD
      elseif h > 170 then
        widget.timeFont = FONT_XL
      else
        widget.timeFont = FONT_L
      end
      if widget.radio == "14" then
        widget.timeFont = FONT_XS
      end
      
      lcd.font(FONT_XL)
      _, widget.fontFlightH  = lcd.getTextSize("")
      lcd.font(widget.timeFont)
      _, widget.fontTimeH  = lcd.getTextSize("")      
    end
  end
  -- ********************************************************
  -- * checkTelemetry                    paint() local  *
  -- ********************************************************  
  local function checkTelemetry(widget)
    local tlm  = system.getSource( { category=CATEGORY_SYSTEM_EVENT, member=SYSTEM_EVENT_TELEMETRY_ACTIVE} )
    widget.telemetryState = (tlm:value() == 100) and 1 or 0
  end

  CheckEnvironment (widget)
  checkTelemetry(widget)  
  
  if lcd.isVisible() then
    local box_center = widget.zoneWidth / 2
    local dY = (widget.zoneHeight - widget.fontFlightH - widget.fontTimeH) /  3
 
    --lcd.color(lcd.darkMode() and COLOR_WHITE or COLOR_BLACK)
    lcd.color(widget.colorT)
    local border_w, border_h = lcd.getWindowSize("")
    if widget.border then
      lcd.drawRectangle(0, 0, border_w, border_h)
    end

    -- display number of flights
    lcd.font(FONT_XL)
    lcd.color(widget.colorF)
    lcd.drawText(box_center, dY, math.floor(widget.flights)..translate("flights"), CENTERED)

    -- display total flight time
    local s,m,h,d,t
    t = widget.flights_total
    d = math.floor (t / 86400)
    t = t - d * 86400
    h = math.floor (t / 3600)
    t = t - h * 3600
    m = math.floor (t / 60)
    s = t - m * 60
    lcd.font(widget.timeFont)
    lcd.color(widget.colorT)
    lcd.drawText(box_center, 2 * dY + widget.fontFlightH, string.format("%d - %02d:%02d:%02d", d,h,m,s), CENTERED)
  end
  -- telemetry lost => red zone frame
  if widget.telemetryState == 0 then
    lcd.color(COLOR_RED)
    lcd.drawRectangle(0, 0, widget.zoneWidth, widget.zoneHeight, widget.noTelFrameT)
  end  
end

-- #################################################################### 
-- # wakeup                                                           #
-- #    this is the main loop that ethos calls every couple of ms     #
-- #################################################################### 
local function wakeup(widget)
  -- ********************************************************
  -- * checkFlightReset                 wakeup() local  *
  -- ********************************************************  
  local function checkFlightReset(widget)
    local eventFlightReset  = system.getSource( { category=CATEGORY_SYSTEM_EVENT, member=SYSTEM_EVENT_FLIGHT_RESET} )
    if widget.FlightReset == 0 then     -- manual reset
      widget.FlightReset = (eventFlightReset:value() == 100) and 1 or 0
    end
  end
  -- ********************************************************
  -- * readSwitches                     wakeup() local  *
  -- ********************************************************
  local function readSwitches (widget)
    if widget.flightSwitch ~= nil then
      widget.flightActive  = widget.flightSwitch:state()
    else
      widget.flightActive = false
    end
    if widget.triggerSwitch ~= nil then
      widget.triggerActive  = widget.triggerSwitch:state()
    else
      widget.triggerActive = false
    end
  end  
  -- ********************************************************
  -- * fileRead                         wakeup() local  *
  -- ********************************************************  
  local function fileRead ()
    file = io.open(g_filesPath .. widget.modelName .. "-Flights.txt", "r")
    if file ~= nil then
      file:seek("set")
      local line = file:read("*l")
      file:close()
      _, _, flights, flights_total = string.find (line, "(%d+),(%d+)")
      if widget.flights_total ~= nil then
        widget.flights_total = flights_total
      end
      if widget.flights ~= nil then
        widget.flights = flights
      end
    end
  end
  -- ********************************************************
  -- * fileWrite                        wakeup() local  *
  -- ********************************************************  
  local function fileWrite ()
    file = io.open(g_filesPath .. widget.modelName .. "-Flights.txt", "w")
    file:seek("set") 
    file:write(widget.flights .. "," .. widget.flights_total)
    file:close()
  end
  
  local actual_time = os.clock()  -- Získání aktuálního času
  if actual_time > widget.last_time then
    widget.last_time = actual_time + 1
    -- just change battery and fly again. Reset flight by transmitter menu allow initialize fly counter.
    checkFlightReset(widget)
    if widget.FlightReset == 1 then
      -- *********************************
      -- **   RESET FLIGHT          **
      -- *********************************    
      widget.FlightReset    = 0
      widget.triggerSec     = 0
      widget.flightUpdated  = false
    end    
    
    local lastflightActive = widget.flightActive
    readSwitches (widget)  
    
    if widget.flightActive == true then
      if lastflightActive == false then
        -- *********************************
        -- **   NEW FLIGHT STARTED    **
        -- *********************************
        widget.flight_time = os.clock()
        widget.triggerSec    = 0
        widget.flightUpdated = false
      end
    elseif lastflightActive ~= widget.flightActive then
      -- fly Active switch os off
      -- *********************************
      -- **   FLIGHT FINISHED       **
      -- *********************************
      if widget.flightUpdated == true then
        -- increase flight counter if flight trigger is active
        widget.flights_total = math.floor (widget.flights_total + (os.clock() - widget.flight_time))
        system.playTone(2000,250)
        widget.updateFlight = true
      end
    end
    if widget.triggerActive == true and widget.flightUpdated == false then
      widget.triggerSec = widget.triggerSec + 1
      if widget.triggerSec >= widget.trigDelay then
        -- *********************************
        -- **   NEW FLIGHT DETECTED   **
        -- *********************************
        widget.flights = widget.flights + 1
        widget.newPreset = widget.flights
        widget.preset    = widget.flights
        system.playTone(500,250)
        widget.flightUpdated = true
        widget.updateFlight  = true           -- new flight will be displayed
      end
    end    
    lcd.invalidate () 
  end

  if widget.initPending == false then
    widget.initPending = true
    wgtinitialize (widget)    -- read layout and radio parameters
    -- read data from file
    fileRead ()
    widget.newPreset = widget.flights
    widget.preset    = widget.flights
  else
    if widget.preset ~= widget.newPreset then
      widget.preset = widget.newPreset
      widget.flights = widget.preset
      -- ??? what about total flight time
    end
    -- *********************************
    -- ** RESET FLIGHT COUNTERS   **
    -- *********************************
    if widget.newPreset == -1 then
      system.playTone(2000,250,250)
      system.playTone(2000,250)
      widget.flights   = 0
      widget.preset    = 0
      widget.newPreset = 0
      widget.flights_total = 0
      widget.flightUpdated = false
      widget.updateFlight  = true
    end    
  end
  -- *********************************
  -- ** UPDATE FLIGHTS FILE     **
  -- *********************************  
  if widget.updateFlight == true then
    widget.updateFlight = false
    fileWrite ()
    if lcd.isVisible() then
      lcd.invalidate ()                                         -- full screen refresh
    end
  end
end
-- #################################################################### 
-- # configure                                                        #
-- #    Widget Configuration options                                  #
-- ####################################################################
local function configure(widget)
  
    line = form.addLine(translate ("menuname") .. "  " .. version)
    
    line = form.addLine(translate("flightswitch"))
    form.addSwitchField(line, form.getFieldSlots(line)[0], function() return widget.flightSwitch end, function(value) widget.flightSwitch = value end)
  
    line = form.addLine(translate("trigger"))
    form.addSwitchField(line, form.getFieldSlots(line)[0], function() return widget.triggerSwitch end, function(value) widget.triggerSwitch = value end)
    
    -- trigger delay enter
    line = form.addLine(translate("trigerdelay"))
    form.addNumberField(line, nil,0, 1000, function() return widget.trigDelay end, function(value) widget.trigDelay = value end)                                   
    -- preset enter
    line = form.addLine(translate("preset"))
    form.addNumberField(line, nil,-1, 5120, function() return widget.newPreset end, function(value) widget.newPreset = value end)
    -- paint frame option
    line = form.addLine(translate("frame"))
    form.addBooleanField(line, form.getFieldSlots(line)[0], function() return widget.border end, function(value) widget.border = value end)
    
    -- Text color Flight
    line = form.addLine(translate("txtColorF"))
    form.addColorField(line, nil, function() return widget.colorF end, function(color) widget.colorF = color end)
    
    -- Text color Flight Time
    line = form.addLine(translate("txtColorT"))
    form.addColorField(line, nil, function() return widget.colorT end, function(color) widget.colorT = color end)

end
-- #################################################################### 
-- # read                                                             #
-- #    read values from internal storage                             #
-- #################################################################### 
local function read(widget)
  widget.border        = storage.read("Border")
  widget.colorF        = storage.read("ColorF")
  widget.colorT        = storage.read("ColorT")
  widget.trigDelay     = storage.read("trigDelay")
  widget.triggerSwitch = storage.read("triggerSwitch")
  widget.flightSwitch  = storage.read("flightSwitch")
end
-- #################################################################### 
-- # write                                                            #
-- #    write values to internal storage                              #
-- #################################################################### 
local function write(widget)
  storage.write("Border",         widget.border)
	storage.write("ColorF",         widget.colorF)  
	storage.write("ColorT",         widget.colorT)  
	storage.write("trigDelay",      widget.trigDelay)  
	storage.write("triggerSwitch",  widget.triggerSwitch)  
	storage.write("flightSwitch",   widget.flightSwitch)  
end
-- #################################################################### 
-- # init                                                             #
-- #    this is where we 'setup' the widget                           #
-- #################################################################### 
local function init()
    system.registerWidget(
      { key        = "flights",
        name       = name,
        create     = create,
        paint      = paint,
        wakeup     = wakeup,
        configure  = configure,
        read       = read,
        write      = write,
        persistent = true}
      )
end

return {init=init}
