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

-- =============================================================================
-- ETHOS GPS map
-- File:   : main.lua
-- Author  : Björn Pasteuning  Hobby4life 2022
--           RNDr.Vladimir Pribyl, CSc. (VPRHELI)
-- History : Date        Version Author   Comment
--           ----------  ------- -------- ------------------------------------
--                 2022  1.0.7   Björn    initial version
--           28.01.2025  1.0.8   VPRHELI  fixed and modified version
--           02.02.2025  2.0.0   VPRHELI  Autoselect map
--           07.02.2025  2.0.1   VPRHELI  ETHOS 1.6.1 fixed 1.6.0 #4941 bug in GPS coordinates
-- =============================================================================
-- 
--    From version HL4GPSMAP 2.0.1 onwards, use at least ETHOS 1.6.1
--
-- The modification of the original, no longer supported widget, allows you to use up to 32 map sources. 
-- The widget itself selects the necessary map according to GPS coordinates. 
-- This allows you to save several maps of different scales for one area, the airport. 
-- This allows you to store multiple maps of different scales for one area, airport.
-- You just need to save a more detailed map with a lower number than a map covering a larger area. 
-- As soon as you fly out of the detailed map, a larger map will automatically appear, and vice versa, 
-- as you get closer to the airport, a more detailed map will appear.
-- Or multiple detailed maps covering a larger area, one after the other
--
-- Rules of naming convention:
--    1) map1.lua up to map32.lua
--    2) bitmap name up to 10 characters
--    3) if more than one zoom for same place, then detailed map must have smaller number. System search map from 1..32
--    4) Use original map generator https://ethosmap.hobby4life.nl
--    5) Starting with map number 9, map[1..8].lua from the generator needs to be renamed to higher numbers.
--    6) "mapnames.lua" is no more used
-- Comments:
--    a) Stick simulator allows you to move models outside the displayed map. This setting allows you to test different map scales.
--    b) The German text was translated with the help of a translator. If you are a native speaker, please edit the texts in the "translate.lua".
--    c) I would be happy if you would send me the correction including other language mutations. I will publish them for others. Thank you.
--    d) If the model is outside the map edge, the last map remains displayed and the direction to the model is shown by a large arrow in the upper half of the map.
--    e) A red box appears when telemetry is lost
--    f) When telemetry is lost, the last known coordinates of the model are displayed
--    g) Changing the initial home position, if activated in the configuration menu, needs to be confirmed. This prevents an unwanted change.
--    h) The widget can only be displayed in full screen without a title.
--    i) The widget uses a different identification key. Therefore, it is not possible to use the original folder and configuration.
--       Save the maps.bmp and map[1..8].lua, delete the folder and copy this version and the maps back.
--    j) The distribution also includes several scale maps of the area around my home airport in Prague Lipence. 
--       If you use a stick simulator, you can try out how the widget works. Use simulator which set base coordinates.
--    k) When testing your maps, adjust the home coordinates for the simulator in the ReadSensors() function.
--    l) Tested on X20pro. Probably not working on X18.

------------------------------------------------------------------------------------------------
-- Set up of variables used in whole scope
------------------------------------------------------------------------------------------------
local Version           = "v2.0.0"
local mapImage                  -- Global use of map image
local Windsock                  -- Global use of windsock image
local DMSLatString      = ""    -- Global DMS Latitude string
local DMSLongString     = ""    -- Global DMS Longitude string
local Heading_Previous  = 0     -- Stores a global valid heading value used in drawArrow()
local TempLat           = 0     -- Default Compare Latitude, used in drawArrow()
local TempLong          = 0     -- Default Compare Latitude, used in drawArrow()
local LCD_Type          = 0     -- 0 = X10/12, 1 = X20
local Map_change        = false -- Flag used when a map is changed
local Run_Script        = false -- Used to control the whole paint loop
local Bearing           = 0     -- Global Bearing variable

local g_locale
local g_updates_per_second = 1                -- how many times per second display will be updated

-- load translate table from external file
local tableFile  = assert(loadfile("/scripts/h4lgpsmap/translate.lua"))()
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
------------------------------------------------------------------------------------------------
-- Language Setup
------------------------------------------------------------------------------------------------
local function name(widget)
  return translate ("wgname")    
end
------------------------------------------------------------------------------------------------
-- Default Source values upon creation of widget
------------------------------------------------------------------------------------------------
local function create()
    return {
--   widget
            GPSSource               = nil,    -- Configuration, GPS Source input
            GPSLAT                  = 0,      -- Configuration, Lattiude value from GPSSource
            GPSLONG                 = 0,      -- Configuration, Longitide value from GPSSource
            GPSLATlastValid         = 0,      -- Configuration, Lattiude value from GPSSource
            GPSLONGlastValid        = 0,      -- Configuration, Longitide value from GPSSource
            SpeedSource             = nil,    -- Configuration, Speed Source input
            SPEED                   = 0,      -- Configuration, Speed value from SpeedSource
            SPEED_UNIT              = 0,      -- Configuration, Speed Unit from SpeedSource
            AlitudeSource           = nil,    -- Configuration, Altitude Source input
            ALTITUDE                = 0,      -- Configuration, Altitude value from AlitudeSource
            ALTITUDE_UNIT           = 0,      -- Configuration, Altitude Unit from AlitudeSource
            CourseSource            = nil,    -- Configuration, Course Source input
            COURSE                  = 0,      -- Configuration, Course value from CourseSource
            StickSim                = false,  -- Configuration, True = Stick GPS simulation on, False = off
            SimLatSource            = nil,    -- Configuration, Simulator Latitude Source input
            SimLongSource           = nil,    -- Configuration, Simulator Longitude Source input
            SimLatValue             = 0,      -- Configuration, Simulator Lattiude value from SimLatSource
            SimLongValue            = 0,      -- Configuration, Simulator Lattiude value from SimLongSource
            SimLatOffset            = 0,      -- Configuration, Simulator Lattiude value from SimLatSource
            SimLongOffset           = 0,      -- Configuration, Simulator Lattiude value from SimLongSource 
            RSSISource              = nil,    -- Configuration, RSSI Source input
            RSSI                    = 0,      -- Configuration, RSSI value from RSSISource
            UNIT                    = 0,      -- Configuration, 0 = Metric, 1 = Imperial
            ResetSource             = nil,    -- Configuration, Reset Source Input
            GPS_Annotation          = 0,      -- Configuration, 0 = DMS, 1 = Decimal
            ArrowColor              = lcd.RGB(248,0,0),     -- Configuration, Arrow color
            HUD_Text_Color          = lcd.RGB(255,255,255), -- Configuration, HUD Text color
            Distance_Text_Color     = lcd.RGB(64,0,0),      -- Configuration, Distance Text color
            LineColor               = lcd.RGB(192,0,0),     -- Configuration, Line color
            Calculate_Bearing       = true,   -- Configuration, If Bearing must be calculated
            Update_Distance         = 25,     -- Configuration, Calculation between xx m/ft. use with Calculate_Bearing
            TX_VOLTAGE              = 0,      -- Widget wide TX Voltage Source
            HomePosX                = 0,      -- Widget wide Home X display position
            HomePosY                = 0,      -- Widget wide Home Y display position
            GpsPosX                 = 0,      -- Widget wide GPS X display position
            GpsPosY                 = 0,      -- Widget wide GPS Y display position
            HomeLat                 = 0,      -- Widget wide Home Lattitude
            HomeLong                = 0,      -- Widget wide Home Longitude
            MapNorth                = 0,      -- Widget wide Map Topside Image coordinate
            MapSouth                = 0,      -- Widget wide Map Bottomside Image coordinate
            MapWest                 = 0,      -- Widget wide Map Westside Image coordinate
            MapEast                 = 0,      -- Widget wide Map Eastside Image coordinate
            PlaneVisible            = false,  -- Widget wide Flag, uses of plane is inside or outside map visibility
            NS                      = "",     -- Widget wide North or South string
            EW                      = "",     -- Widget wide East or West string
            SPD                     = "",     -- Widget wide Speed unit
            Distance                = 0,      -- Widget wide Distance value
            rstValue                = 0,
            ForceHome               = false,  -- Widget wide Flag to Force Homing
            HomeSet                 = false,  -- Widget wide Flag if Home is set or not
            Draw_LCD                = false,  -- Widget wide Flag used in functions that have draw functions
            mapsArr                 = {},
            mapIndex                = nil,
            lcd_width               = nil,
            lcd_height              = nil,
            bMapSelected            = false,
            -- status
            telemetryState          = nil,    -- 1 or 0 if telemetry is available           
            initPending             = true,            
            last_time               = 0,
            }
end

------------------------------------------------------------------------------------------------
-- Calculates the radius between 2 X,Y points
------------------------------------------------------------------------------------------------
local function CalcRadius( x1, y1, x2, y2 )
  local dx = x1 - x2
  local dy = y1 - y2
  return math.sqrt ( dx * dx + dy * dy )
end

------------------------------------------------------------------------------------------------
-- Draws a Alert Box
------------------------------------------------------------------------------------------------
local function DrawAlertBox(widget,string,color,bkcolor)
      local str_w, str_h = lcd.getTextSize(string)
      lcd.pen(SOLID)
      lcd.color(bkcolor)
      lcd.drawFilledRectangle(((widget.lcd_width  /2) - (str_w/2)), ((widget.lcd_height /2) - (str_h/2)) - 4, str_w, str_h + 8)
      lcd.color(color)
      lcd.drawText(widget.lcd_width /2, (widget.lcd_height /2) - (str_h/2) + 4,string, TEXT_CENTERED)
      return
end

-- ####################################################################
-- #  DrawInfoBox                                                     #
-- #    Display GPS coordinates of last know model position           #
-- #################################################################### 
local function DrawInfoBox(widget)
  local X  = 380
  local Xa = X + 10
  local Ya = 422
  local Yb = 450 
      
  if widget.GPSLATlastValid ~= 0 and widget.GPSLONGlastValid ~= 0 then
    lcd.color(lcd.RGB(128,0,0,0.8))
    lcd.drawFilledRectangle(260,420,260,60)
    
    lcd.color(widget.HUD_Text_Color)
    lcd.font(FONT_BOLD)
    -- Draws Coordinates in bottom box
    lcd.drawText(X, Ya, translate("hudLAT"),  TEXT_RIGHT)
    lcd.drawText(X, Yb, translate("hudLONG"), TEXT_RIGHT)

    if widget.GPS_Annotation == 0 then
      lcd.drawText(Xa, Ya, DMSLatString,  TEXT_LEFT)
      lcd.drawText(Xa, Yb, DMSLongString, TEXT_LEFT)
    else
      lcd.drawText(Xa, Ya, math.abs(string.format("%.5f",widget.GPSLATlastValid))..widget.NS,  TEXT_LEFT)
      lcd.drawText(Xa, Yb, math.abs(string.format("%.5f",widget.GPSLONGlastValid))..widget.EW, TEXT_LEFT)
    end
  end
end

------------------------------------------------------------------------------------------------
-- Function to draw Arrow
------------------------------------------------------------------------------------------------
local function drawArrow(Start_X,Start_Y,Arrow_Width,Arrow_Length,Angle,Angle_Offset,Style,widget)

--        C
--       /|\
--      / | \
--     /  A  \
--    /   F   \
--   D----B----E

    --Calcutate point B from A Start position
    local B_X = Start_X + math.cos(math.rad(Angle + Angle_Offset)) * (Arrow_Length / 2)
    local B_Y = Start_Y + math.sin(math.rad(Angle + Angle_Offset)) * (Arrow_Length / 2)

    --Calcutate point C A Start position
    local C_X = Start_X + math.cos(math.rad((Angle + Angle_Offset) + 180)) * (Arrow_Length / 2)
    local C_Y = Start_Y + math.sin(math.rad((Angle + Angle_Offset) + 180)) * (Arrow_Length / 2)

    --Calcutate point D from B
    local D_X = B_X + math.cos(math.rad((Angle + Angle_Offset) + 90)) * (Arrow_Width / 2)
    local D_Y = B_Y + math.sin(math.rad((Angle + Angle_Offset) + 90)) * (Arrow_Width / 2)

    --Calcutate point E from B
    local E_X = B_X + math.cos(math.rad((Angle + Angle_Offset) + 270)) * (Arrow_Width / 2)
    local E_Y = B_Y + math.sin(math.rad((Angle + Angle_Offset) + 270)) * (Arrow_Width / 2)

    --Calcutate point F from A Start position, 10% of total length
    local F_X = Start_X + math.cos(math.rad(Angle + Angle_Offset)) * ((Arrow_Length / 2) - (Arrow_Length/100) * 10)
    local F_Y = Start_Y + math.sin(math.rad(Angle + Angle_Offset)) * ((Arrow_Length / 2) - (Arrow_Length/100) * 10)

    C_X = math.floor (C_X)
    C_Y = math.floor (C_Y)
    D_X = math.floor (D_X)
    D_Y = math.floor (D_Y)
    E_X = math.floor (E_X)
    E_Y = math.floor (E_Y)
    F_X = math.floor (F_X)
    F_Y = math.floor (F_Y)

    lcd.drawFilledTriangle(C_X,C_Y,F_X,F_Y,D_X,D_Y)
    lcd.drawFilledTriangle(C_X,C_Y,F_X,F_Y,E_X,E_Y)    

--    lcd.drawLine(D_X,D_Y,C_X,C_Y)
--    lcd.drawLine(C_X,C_Y,E_X,E_Y)

--    if Style > 0 then
--      lcd.drawLine(E_X,E_Y,F_X,F_Y)
--      lcd.drawLine(F_X,F_Y,D_X,D_Y)
--    else
--      lcd.drawLine(E_X,E_Y,D_X,D_Y)
--    end
end

------------------------------------------------------------------------------------------------
-- Function to Draw a bargraph
------------------------------------------------------------------------------------------------
local function drawBargraph(x,y, size,invert,background,gradient,color,value,min,max)

    --[[
      x          : X Coordinate
      y          : Y Coordinate
      size       : multiplication factor, 1 = Default 10px height
      invert     : true = right aligned, false = left aligned
      background : true = grey bar background, false = none
      gradient   : true = color gradient on, false = off
      color      : When gradient = false, use custom color i.e lcd.RGB(r,g,b)
      value      : value to work with
      min        : min value for bar indication range
      max        : max value for bar indication range
   --]]

    local Bar_Value = (value - min) / (max - min) * 100
    local Xpos1,Xpos2,Xpos3,Xpos4,Xpos5

    if invert then
      Xpos1 = (12 * size) - (0 * size)
      Xpos2 = (12 * size) - (3 * size)
      Xpos3 = (12 * size) - (6 * size)
      Xpos4 = (12 * size) - (9 * size)
      Xpos5 = (12 * size) - (12 * size)
    else
      Xpos1 = 0 * size
      Xpos2 = 3 * size
      Xpos3 = 6 * size
      Xpos4 = 9 * size
      Xpos5 = 12 * size
    end

    local Bar1 = 5
    local Bar2 = 20
    local Bar3 = 40
    local Bar4 = 60
    local Bar5 = 80

    local Height1 = 2 * size
    local Height2 = 4 * size
    local Height3 = 6 * size
    local Height4 = 8 * size
    local Height5 = 10 * size


    if background then
      lcd.color(lcd.RGB(150,150,150))
      lcd.drawFilledRectangle(x + Xpos1,y + Height5,2 * size,- Height1)
      lcd.drawFilledRectangle(x + Xpos2,y + Height5,2 * size,- Height2)
      lcd.drawFilledRectangle(x + Xpos3,y + Height5,2 * size,- Height3)
      lcd.drawFilledRectangle(x + Xpos4,y + Height5,2 * size,- Height4)
      lcd.drawFilledRectangle(x + Xpos5,y + Height5,2 * size,- Height5)
    end

    if Bar_Value > Bar1 then
      if gradient then
        lcd.color(COLOR_RED)
      else
        lcd.color(color)
      end
      lcd.drawFilledRectangle(x + Xpos1,y + Height5,2 * size,- Height1)
    end
    if Bar_Value > Bar2 then
      if gradient then
        lcd.color(COLOR_ORANGE)
      else
        lcd.color(color)
      end
      lcd.drawFilledRectangle(x + Xpos2,y + Height5,2 * size,- Height2)
    end
    if Bar_Value > Bar3 then
      if gradient then
        lcd.color(COLOR_YELLOW)
      else
        lcd.color(color)
      end
      lcd.drawFilledRectangle(x + Xpos3,y + Height5,2 * size,- Height3)
    end
    if Bar_Value > Bar4 then
      if gradient then
        lcd.color(lcd.RGB(0,200,0))
      else
        lcd.color(color)
      end
      lcd.drawFilledRectangle(x + Xpos4,y + Height5,2 * size,- Height4)
    end
    if Bar_Value > Bar5 then
      if gradient then
        lcd.color(COLOR_GREEN)
      else
        lcd.color(color)
      end
      lcd.drawFilledRectangle(x + Xpos5,y + Height5,2 * size,- Height5)
    end
end

------------------------------------------------------------------------------------------------
-- Function to Validate all sources, otherwise return default values.
------------------------------------------------------------------------------------------------
local function ValidateSources(widget)

    if widget.SPEED == nil then
        widget.SPEED = 0
    end

    if widget.SPEED_UNIT == nil then
        widget.SPEED_UNIT = 0
    end

    if widget.ALTITUDE == nil then
        widget.ALTITUDE = 0
    end

    if widget.ALTITUDE_UNIT == nil then
        widget.ALTITUDE_UNIT = 0
    end

    if system.getSource({category=CATEGORY_SYSTEM, member=MAIN_VOLTAGE}) ~= nil then
      widget.TX_VOLTAGE = system.getSource({category=CATEGORY_SYSTEM, member=MAIN_VOLTAGE}):value()
    else
      widget.TX_VOLTAGE = 0
    end

    if widget.RSSI == nil then
        widget.RSSI = 0
    end

end

------------------------------------------------------------------------------------------------
-- Calculates LCD X/Y Position on map from GPS coordinates
------------------------------------------------------------------------------------------------
local function CalcLCDPosition(widget)
    -- Calculates position on LCD of current GPS position
    widget.GpsPosX  = math.floor(widget.lcd_width  * ((widget.GPSLONG -  widget.MapWest)/(widget.MapEast  - widget.MapWest)))
    widget.GpsPosY  = math.floor(widget.lcd_height * ((widget.MapNorth - widget.GPSLAT) /(widget.MapNorth - widget.MapSouth)))
end

-- ####################################################################
-- #  CalcMapHomePos                                                  #
-- #################################################################### 
local function CalcMapHomePos(widget)
  widget.HomePosX = math.floor(widget.lcd_width  * ((widget.HomeLong - widget.MapWest) / (widget.MapEast  - widget.MapWest)))
  widget.HomePosY = math.floor(widget.lcd_height * ((widget.MapNorth - widget.HomeLat) / (widget.MapNorth - widget.MapSouth)))
end

------------------------------------------------------------------------------------------------
-- Sets home position
------------------------------------------------------------------------------------------------
local function SetHome(widget)
  if widget.GPSLAT ~= 0 and widget.GPSLONG ~= 0 then
    if widget.ForceHome or widget.HomeLat == 0 then
      system.playTone(1500,200, 200)
      system.playTone(1500,200)

      widget.HomeLat   = widget.GPSLAT
      widget.HomeLong  = widget.GPSLONG
  
      CalcMapHomePos(widget)
        
      widget.ForceHome = false
      widget.HomeSet   = true
    end

  end
end

-- ####################################################################
-- #  ConfirmHomeUpdate                                               #
-- #    Update Home position Dialog                                   #
-- #################################################################### 
local function ConfirmHomeUpdate(widget)
  local buttons = {
    {label=translate("dlgNo"), action=function() return true end},    
    {label=translate("dlgYes"),action=function()  widget.ForceHome = true return true end},
  }
  local dialog = form.openDialog({title    = translate("dlgTitle"), 
                                  message  = translate("dlgMsg"),
                                  width    = 500,
                                  buttons  = buttons,
                                  options  = TEXT_LEFT,
                                })
end
------------------------------------------------------------------------------------------------
-- Checks if Reset is triggered
------------------------------------------------------------------------------------------------
local function CheckReset(widget)
  -- Checks if Reset source is triggered, if so then forces a new Home init.
  if widget.rstValue == 100 then
    ConfirmHomeUpdate(widget)      -- new position has to be confirmed
  end
end

------------------------------------------------------------------------------------------------
-- Function to get North, South, East, West indicators
------------------------------------------------------------------------------------------------
local function GetNSEW(widget)
    if widget.GPSLAT > 0 then
      widget.NS = "N"
    else
      widget.NS = "S"
    end

    if widget.GPSLONG > 0 then
      widget.EW = "E"
    else
      widget.EW = "W"
    end
end

------------------------------------------------------------------------------------------------
-- Function to create formatted strings of values + units
------------------------------------------------------------------------------------------------
local function FormatValueString(widget,value)
  local unit
  if value > 999999 then
    if widget.UNIT == 1 then
      unit  = "mi"
      value = string.format("%.0f",(value / 5280))
    else
      unit  = "km"
      value = string.format("%.0f",(value / 1000))
    end
  elseif value > 999 then
    if widget.UNIT == 1 then
      unit  = "mi"
      value = string.format("%.1f",(value / 5280))
    else
      unit  = "km"
      value = string.format("%.1f",(value / 1000))
    end
  else
    if widget.UNIT == 1 then
      unit  = "ft"
      value = string.format("%.0f",value)
    else
      unit  = "m"
      value = string.format("%.0f",value)
    end
  end
  return value, unit
end

------------------------------------------------------------------------------------------------
-- Function to calculated bearing angle between 2 coordinates
------------------------------------------------------------------------------------------------
function CalcBearing(widget,PrevLat,PrevLong,NewLat,NewLong)
  local yCalc = math.sin(math.rad(NewLong)-math.rad(PrevLong)) * math.cos(math.rad(NewLat))
  local xCalc = math.cos(math.rad(PrevLat)) * math.sin(math.rad(NewLat)) - math.sin(math.rad(PrevLat)) * math.cos(math.rad(NewLat)) * math.cos(math.rad(NewLat) - math.rad(PrevLat))
  local bearing = math.deg(math.atan(yCalc,xCalc))
  if bearing < 0 then
    bearing = 360 + bearing
  end
  return bearing
end

------------------------------------------------------------------------------------------------
-- Function to calculate distance between 2 coordinates
------------------------------------------------------------------------------------------------
function CalcDistance(widget,PrevLat,PrevLong,NewLat,NewLong,unit)
  local earthRadius = 0
  if unit == 1 then
    earthRadius = 20902000  --feet  --3958.8 miles
  else
    earthRadius = 6371000   --meters
  end
  local dLat = math.rad(NewLat-PrevLat)
  local dLon = math.rad(NewLong-PrevLong)
  PrevLat = math.rad(PrevLat)
  NewLat = math.rad(NewLat)
  local a = math.sin(dLat/2) * math.sin(dLat/2) + math.sin(dLon/2) * math.sin(dLon/2) * math.cos(PrevLat) * math.cos(NewLat)
  local c = 2 * math.atan(math.sqrt(a), math.sqrt(1-a))
  return (earthRadius * c)
end

------------------------------------------------------------------------------------------------
-- Function to Convert Decimal to Degrees, Minutes, Seconds
------------------------------------------------------------------------------------------------
local function dec2deg(widget,decimal)
  local Degrees = math.floor(decimal)
  local Minutes = math.floor((decimal - Degrees) * 60)
  local Seconds = (((decimal - Degrees) * 60) - Minutes) * 60
  return Degrees, Minutes, Seconds
end

------------------------------------------------------------------------------------------------
-- Function to Build Decimal, Minutes, Seconds String
------------------------------------------------------------------------------------------------
local function BuildDMSstr(widget)
    -- Converts the gps coordinates to Degrees,Minutes,Seconds
    local LatD,LatM,LatS = dec2deg(widget,widget.GPSLAT)
    local LongD,LongM,LongS = dec2deg(widget,widget.GPSLONG)
    DMSLatString  = math.abs(LatD).."°"..LatM.."'"..string.format("%.1f",LatS)..widget.NS
    DMSLongString = math.abs(LongD).."°"..LongM.."'"..string.format("%.1f",LongS)..widget.EW
end

------------------------------------------------------------------------------------------------
-- Creates pre formatted Altitude strings
------------------------------------------------------------------------------------------------
--[[
    09 = UNIT_CENTIMETER           "cm"
    10 = UNIT_METER                "m"
    11 = UNIT_FOOT                 "ft"
    15 = UNIT_KPH                  "km/h"
    16 = UNIT_MPH                  "mph"
    17 = UNIT_KNOT                 "knots"
--]]

local function ConvertAltitude(widget)
  -- 0 = Metric m/kmh, 1 = Imperial ft/mph
  if widget.UNIT == 0 then
    if widget.ALTITUDE_UNIT == 9 then
      ALTITUDE = widget.ALTITUDE * 0.01
    elseif widget.ALTITUDE_UNIT == 10 then
      ALTITUDE = widget.ALTITUDE
    elseif widget.ALTITUDE_UNIT == 11 then
      ALTITUDE = widget.ALTITUDE * 0.3048
    else
      ALTITUDE = 0
    end
  else
    if widget.ALTITUDE_UNIT == 9 then
      ALTITUDE = widget.ALTITUDE * 0.032808399
    elseif widget.ALTITUDE_UNIT == 10 then
      ALTITUDE = widget.ALTITUDE * 3.2808399
    elseif widget.ALTITUDE_UNIT == 11 then
      ALTITUDE = widget.ALTITUDE
    else
      ALTITUDE =0
    end
  end
  return ALTITUDE
end

------------------------------------------------------------------------------------------------
-- Converts speed value according to unit of speed source
------------------------------------------------------------------------------------------------
local function ConvertSpeed(widget)
  -- 0 = Metric m/kmh, 1 = Imperial ft/mph
  if widget.UNIT == 0 then
    if widget.SPEED_UNIT == 15 then
      SPEED = widget.SPEED
    elseif widget.SPEED_UNIT == 16 then
      SPEED = widget.SPEED * 1.609344
    elseif widget.SPEED_UNIT == 17 then
      SPEED = widget.SPEED * 1.852
    else
      SPEED = 0
    end
  else
    if widget.SPEED_UNIT == 15 then
      SPEED = widget.SPEED * 0.621371192
    elseif widget.SPEED_UNIT == 16 then
      SPEED = widget.SPEED
    elseif widget.SPEED_UNIT == 17 then
      SPEED = widget.SPEED * 1.15077945
    else
      SPEED = 0
    end
  end
  return SPEED
end

-- ####################################################################
-- #  createStruct                                                    #
-- #################################################################### 
local function createStruct(north, south, west, east, image)
    return {mapNorth = north, mapSouth = south, mapWest = west, mapEast = east, mapImage = image}
end

-- ####################################################################
-- #  MapImgAutoLoad                                                  #
-- #################################################################### 
local function MapImgAutoLoad(widget)
  local fileName
  for i = 1, 32 do
    fileName = string.format("/scripts/h4lgpsmap/maps/map%d.lua", i)
    local f = io.open(fileName, "r")
    if f ~= nil then
      io.close(f)
      dofile(fileName)
      table.insert(widget.mapsArr, {createStruct(North, South, West, East, Image)})
    else
      break
    end
  end
  --print("### mapImgAutoLoad() loaded " .. #widget.mapsArr .. " files")
end

-- ####################################################################
-- #  MapAutoSelect                                                   #
-- #     automatically select map based on GPS coordinates            #
-- #################################################################### 
local function MapAutoSelect(widget)
  local mapNorth, mapSouth, mapWest, mapEast
  local mapLastIndex = widget.mapIndex
  
  widget.bMapSelected = false
  if widget.GPSLAT ~= 0 and widget.GPSLONG ~= 0 then
    for i, row in ipairs(widget.mapsArr) do
      for j, struct in ipairs(row) do
        if widget.GPSLAT < struct.mapNorth and widget.GPSLAT > struct.mapSouth and widget.GPSLONG < struct.mapEast and widget.GPSLONG > struct.mapWest then
          widget.MapNorth = struct.mapNorth
          widget.MapSouth = struct.mapSouth
          widget.MapWest  = struct.mapWest
          widget.MapEast  = struct.mapEast
          widget.mapIndex = i
          mapImage        = struct.mapImage          
          widget.bMapSelected = true
          break
        end
      end
      if widget.bMapSelected == true then
        break
      end
    end
    -- recalculate home position in different map zoom
    if mapLastIndex ~= widget.mapIndex then
      CalcMapHomePos(widget)
    end
  end
end


------------------------------------------------------------------------------------------------
-- Draws the HUD
------------------------------------------------------------------------------------------------
local function DrawHUD(widget)
  if widget.Draw_LCD then
    local  Ya,Yb,Yc,Xa,
           Xaa,Xb,Xbb,Xc,Xcc,Xd,Xdd,
           Title_X,Title_Y,
           TX_Voltage_X,TX_Voltage_Y,
           TX_Voltage_Bar_X,TX_Voltage_Bar_Y,
           RSSI_X,RSSI_Y,
           RSSI_Bar_X,RSSI_Bar_Y,
           Map_Distance,
           Value,
           Unit,
           DistanceBar_X,DistanceBar_Y,
           DistanceBar_Text_X,DistanceBar_Text_Y

    --Transparency Color Setup for top and bottom box
    lcd.pen(SOLID)
    lcd.color(lcd.RGB(128,128,128,0.8)) -- 80% Opacity

    -- X10 / X12 X/Y Display positions
    if LCD_Type == 0 then
      TX_Voltage_X          = 2
      TX_Voltage_Y          = 0
      TX_Voltage_Bar_X      = 80
      TX_Voltage_Bar_Y      = 2

      Title_X               = 240
      Title_Y               = 0
      RSSI_X                = 380
      RSSI_Y                = 0
      RSSI_Bar_X            = 460
      RSSI_Bar_Y            = 2

      Bar_Size              = 1.2

      Xa                    = 42
      Xaa                   = Xa + 5
      Xb                    = 190
      Xbb                   = Xb + 5
      Xc                    = 320
      Xcc                   = Xc + 5
      Xd                    = 425
      Xdd                   = Xd + 5

      Ya                    = 238
      Yb                    = 254

      DistanceBar_X         = 355
      DistanceBar_Y         = 227
      DistanceBar_Text_X    = 422
      DistanceBar_Text_Y    = 221


      lcd.drawFilledRectangle(0,0,480,16)
      lcd.drawFilledRectangle(0,238,480,34)
      lcd.drawFilledRectangle(410,222,70,14)


    -- X20 X/Y Display positions
    elseif LCD_Type == 1 then
      TX_Voltage_X          = 5
      TX_Voltage_Y          = 0
      TX_Voltage_Bar_X      = 125
      TX_Voltage_Bar_Y      = 2

      Title_X               = 400
      Title_Y               = 0
      RSSI_X                = 650
      RSSI_Y                = 0
      RSSI_Bar_X            = 765
      RSSI_Bar_Y            = 2

      Bar_Size              = 2

      Xa                    = 80
      Xaa                   = Xa + 10
      Xb                    = 330
      Xbb                   = Xb + 10
      Xc                    = 520
      Xcc                   = Xc + 10
      Xd                    = 710
      Xdd                   = Xd + 10

      Ya                    = 422
      Yb                    = 450

      DistanceBar_X         = 600
      DistanceBar_Y         = 402
      DistanceBar_Text_X    = 710
      DistanceBar_Text_Y    = 392

      lcd.drawFilledRectangle(0,0,800,24)
      lcd.drawFilledRectangle(0,420,800,60)
      lcd.drawFilledRectangle(695,392,105,24)

    end

    lcd.color(widget.HUD_Text_Color)
    if LCD_Type == 0 then
      lcd.font(FONT_STD)
    elseif LCD_Type == 1 then
      lcd.font(FONT_BOLD)
    end

    -- Top Bar
    lcd.drawText(TX_Voltage_X,TX_Voltage_Y,"BATT: "..widget.TX_VOLTAGE.."V", TEXT_LEFT)
    lcd.drawText(Title_X,Title_Y,translate("wgname").." "..Version,TEXT_CENTERED)
    lcd.drawText(RSSI_X,RSSI_Y,"RSSI: "..string.format("%.0f",widget.RSSI).."%", TEXT_LEFT)

    drawBargraph(TX_Voltage_Bar_X,TX_Voltage_Bar_Y, Bar_Size,false,true,true,nil,widget.TX_VOLTAGE,7.0,8.4)
    drawBargraph(RSSI_Bar_X,RSSI_Bar_Y, Bar_Size,false,true,false,lcd.RGB(255,255,255),widget.RSSI,30,100)
    if LCD_Type == 0 then
      lcd.font(FONT_BOLD)
    elseif LCD_Type == 1 then
      lcd.font(FONT_BOLD)
    end

    -- Draws the Distance bar
    Map_Distance = (CalcDistance(widget,widget.MapNorth,widget.MapWest,widget.MapNorth,widget.MapEast,widget.UNIT) / 10)

    lcd.color(COLOR_BLUE)
    lcd.drawFilledRectangle(DistanceBar_X,DistanceBar_Y,(widget.lcd_width / 10),4)
    lcd.color(COLOR_RED)
    lcd.drawFilledRectangle(DistanceBar_X , DistanceBar_Y - 5,2,14)
    lcd.drawFilledRectangle(DistanceBar_X + ((widget.lcd_width/10) - 2), DistanceBar_Y - 5,2,14)

    lcd.color(widget.HUD_Text_Color)

    Value, Unit = FormatValueString(widget,Map_Distance)

    lcd.drawText(DistanceBar_Text_X + ((widget.lcd_width/10) /2),DistanceBar_Text_Y,Value..Unit, TEXT_CENTERED)

    -- Draws Coordinates in bottom box
    lcd.drawText(Xa, Ya, translate("hudLAT"), TEXT_RIGHT)
    lcd.drawText(Xa, Yb,translate("hudLONG"), TEXT_RIGHT)

    if widget.GPS_Annotation == 0 then
      lcd.drawText(Xaa,Ya,DMSLatString, TEXT_LEFT)
      lcd.drawText(Xaa,Yb,DMSLongString,TEXT_LEFT)
    else
      lcd.drawText(Xaa,Ya,math.abs(string.format("%.5f",widget.GPSLAT))..widget.NS, TEXT_LEFT)
      lcd.drawText(Xaa,Yb,math.abs(string.format("%.5f",widget.GPSLONG))..widget.EW,TEXT_LEFT)
    end

    -- Draws Altitde, Speed, Distance, Bearing, Line Of Sight
    local Altitude = ConvertAltitude(widget)
    local Speed = ConvertSpeed(widget)
    local LOS = (math.sqrt(((widget.Distance/1000) * (widget.Distance/1000)) + ((Altitude/1000) * (Altitude/1000)))) * 1000

    lcd.drawText(Xb, Ya, translate("hudSpeed"),  TEXT_RIGHT)
    lcd.drawText(Xb, Yb, translate("hudAlt"),    TEXT_RIGHT)
    lcd.drawText(Xc, Ya, translate("hudCourse"), TEXT_RIGHT)
    lcd.drawText(Xd, Ya, translate("hudDist"),   TEXT_RIGHT)
    lcd.drawText(Xd, Yb, "LOS:",                 TEXT_RIGHT)
    
    if widget.UNIT == 1 then
      widget.SPD = "mph"
    else
      widget.SPD = "Km/h"
    end

    lcd.drawText(Xbb,Ya,string.format("%.0f",Speed)..widget.SPD,TEXT_LEFT)

    Value, Unit = FormatValueString(widget,Altitude)
    lcd.drawText(Xbb,Yb,Value..Unit,TEXT_LEFT)
    lcd.drawText(Xcc,Ya,string.format("%.0f",Bearing).."°",TEXT_LEFT)

    Value, Unit = FormatValueString(widget,widget.Distance)
    lcd.drawText(Xdd,Ya,Value..Unit,TEXT_LEFT)

    Value, Unit = FormatValueString(widget,LOS)
    lcd.drawText(Xdd,Yb,Value..Unit,TEXT_LEFT)

    lcd.drawText(Xc,Yb,translate("hudBearing"), TEXT_RIGHT)
    lcd.drawText(Xcc,Yb,string.format("%.0f",math.floor(CalcBearing(widget,widget.HomeLat,widget.HomeLong,widget.GPSLAT,widget.GPSLONG))).."°", TEXT_LEFT)

  end
end

------------------------------------------------------------------------------------------------
-- Checks if correct display type is used and sets LCD_Type flag
------------------------------------------------------------------------------------------------
local function CheckDisplayType(widget)
    widget.lcd_width, widget.lcd_height = lcd.getWindowSize()      
    if widget.lcd_width == 800 and widget.lcd_height == 480 then
      LCD_Type = 1
      Run_Script = true
    elseif widget.lcd_width == 480 and widget.lcd_height == 272 then
      LCD_Type = 0
      Run_Script = true
    else
      lcd.font(FONT_STD)
      lcd.color(COLOR_WHITE)
      lcd.drawText(widget.lcd_width /2,widget.lcd_height /2 -12, translate("errFullDisp"), TEXT_CENTERED)
      lcd.drawText(widget.lcd_width /2,widget.lcd_height /2 +12, translate("errNoTitle"),  TEXT_CENTERED)
      Run_Script = false
    end
end

------------------------------------------------------------------------------------------------
-- Draws the Plane
------------------------------------------------------------------------------------------------
local function DrawPlane(widget)
  if widget.Draw_LCD then
    local Travelled_Distance = CalcDistance(widget, widget.GPSLAT, widget.GPSLONG, TempLat, TempLong, widget.UNIT)
    if Travelled_Distance == nil then
      Travelled_Distance = 0
    end

    if widget.Calculate_Bearing then
      -- Checks if there is any movement between current and previous position
      -- If so then also check if this movement is bigger then widget.Update_Distance
      -- If both conditions meet, then update heading angle.
      if (widget.GPSLAT ~= TempLat or widget.GPSLONG ~= TempLong) and Travelled_Distance > widget.Update_Distance then
        Bearing  = CalcBearing(widget,TempLat,TempLong,widget.GPSLAT,widget.GPSLONG)
        TempLat  = widget.GPSLAT
        TempLong = widget.GPSLONG
      -- Checks if there is no movement, then return previous heading angle.
      elseif widget.GPSLAT == TempLat and widget.GPSLONG == TempLong and Travelled_Distance == 0 then
        Bearing = Heading_Previous
      -- return previous heading angle in any other case.
      else
        Bearing = Heading_Previous
      end
    else
      -- If Bearing
      if widget.COURSE ~= nil then
        Bearing = widget.COURSE
      end
    end

    lcd.pen(SOLID)
    local w,h
    if LCD_Type == 0 then
      w = 15
      h = 30
    elseif LCD_Type == 1 then
      w = 30
      h = 50
    end

    if widget.PlaneVisible then
      lcd.color(widget.ArrowColor - 0x9000000)      -- aply alpha channel 0xF000000 is o alpha 0x9000000 is 0.4 alpha
      drawArrow(widget.GpsPosX,widget.GpsPosY,w,h,Bearing,90,2,widget)
      Heading_Previous = Bearing
    else
      lcd.font(FONT_XXL)
      DrawAlertBox(widget, translate("errOutOfMap"), COLOR_WHITE, lcd.RGB(255,0,0,0.4))
      lcd.pen(SOLID) 
      lcd.color(COLOR_RED)
      homeBearing  = CalcBearing(widget,widget.HomeLat,widget.HomeLong,widget.GPSLAT,widget.GPSLONG)        
      drawArrow(widget.lcd_width / 2, widget.lcd_height / 4, 2*w, 2*h, homeBearing, 90, 2, widget)
    end
  end
end

------------------------------------------------------------------------------------------------
-- Draws the Home Position
------------------------------------------------------------------------------------------------
local function DrawHomePosition(widget)
  if widget.Draw_LCD then
    if widget.HomeSet then
      local Radius
      if LCD_Type == 0 then
        Radius = 8
      else
        Radius = 15
      end
      -- Draws the Home Circle and Windsock
      lcd.color(widget.ArrowColor)
      
      lcd.drawFilledCircle(widget.HomePosX, widget.HomePosY, Radius)
      lcd.drawBitmap(widget.HomePosX-30, widget.HomePosY-30, Windsock, 0, 0)

      -- Draws the line between Home and Plane
      lcd.color(widget.LineColor)
      lcd.pen(DOTTED)
      lcd.drawLine(widget.HomePosX,widget.HomePosY,widget.GpsPosX,widget.GpsPosY)

      -- Calculates the middle LCD X/Y point between gps and home
      local MidLosX = ((widget.GpsPosX + widget.HomePosX)/2)
      local MidLosY = ((widget.GpsPosY + widget.HomePosY)/2)
      
--      No more used
--      if MidLosX < (widget.lcd_width /8) then
--        MidLosX = (widget.lcd_width /8)
--      elseif MidLosX > (widget.lcd_width - (widget.lcd_width /8)) then
--        MidLosX = widget.lcd_width - (widget.lcd_width /8)
--      end

--      if MidLosY < (widget.lcd_height /4) then
--        MidLosY = (widget.lcd_height /4)
--      elseif MidLosY > (widget.lcd_height - (widget.lcd_height /4)) then
--        MidLosY = widget.lcd_height - (widget.lcd_height /4)
--      end

      -- Draws a circle arround plane to midpoint of line
      lcd.pen(DOTTED)
      lcd.color(COLOR_MAGENTA)
      lcd.drawCircle(widget.GpsPosX,widget.GpsPosY,CalcRadius(widget.GpsPosX,widget.GpsPosY,MidLosX,MidLosY))

      widget.Distance = math.floor(CalcDistance(widget,widget.GPSLAT,widget.GPSLONG,widget.HomeLat,widget.HomeLong,widget.UNIT))

      -- Draws the Distance on next to the line between Home and Plane
      lcd.font(FONT_STD)
      lcd.color(widget.Distance_Text_Color)
      local text_w, text_h = lcd.getTextSize("")
      local Value, Unit = FormatValueString(widget,widget.Distance)
      lcd.drawText(MidLosX, MidLosY - (text_h /2), Value..Unit , TEXT_CENTERED)
    end
  end
end

------------------------------------------------------------------------------------------------
-- Checks if valid GPS source is available or values are available otherwise display No Signal
------------------------------------------------------------------------------------------------
local function CheckGPS(widget)
    if widget.StickSim then
      widget.Draw_LCD = true
    elseif widget.GPSSource == nil or widget.GPSSource:state() == false then
      lcd.font(FONT_XXL)
      DrawAlertBox(widget, translate("errNoGPS"), COLOR_WHITE, lcd.RGB(255,0,0,0.4))
      DrawInfoBox(widget)
      widget.Draw_LCD = false
      return
    elseif widget.GPSLAT < -90 or widget.GPSLAT > 90 or widget.GPSLONG < -180 or widget.GPSLONG > 180 then
      lcd.font(FONT_XXL)
      DrawAlertBox(widget,tanslate("errWrongData"), COLOR_WHITE, lcd.RGB(255,0,0,0.4))
      widget.Draw_LCD = false
      return
    else
      widget.Draw_LCD = true
    end
end

------------------------------------------------------------------------------------------------
-- Converts Source input to Map positions
------------------------------------------------------------------------------------------------
local function GpsSimInput(widget)
    -- GPS Simulator by source input
    if widget.StickSim then
      widget.SimLatOffset  = widget.SimLatOffset  + widget.SimLatValue  * (widget.MapNorth - widget.MapSouth) / 32768
      widget.SimLongOffset = widget.SimLongOffset + widget.SimLongValue * (widget.MapEast  - widget.MapWest)  / 32768
      
      widget.GPSLAT  = widget.GPSLAT  + widget.SimLatOffset 
      widget.GPSLONG = widget.GPSLONG + widget.SimLongOffset
      
--      widget.GPSLAT  = (((widget.SimLatValue  - -1024) * (widget.MapNorth - widget.MapSouth) ) / (1024 - -1024)) + widget.MapSouth
--      widget.GPSLONG = (((widget.SimLongValue - -1024) * (widget.MapEast  - widget.MapWest)  ) / (1024 - -1024)) + widget.MapWest
    end
end

------------------------------------------------------------------------------------------------
-- Checks if Plane is visible on the map
------------------------------------------------------------------------------------------------
local function CheckPlaneOnMap(widget)
    -- Checks if plane is visible on the map
    if widget.GPSLAT < widget.MapNorth and widget.GPSLAT > widget.MapSouth and widget.GPSLONG < widget.MapEast and widget.GPSLONG > widget.MapWest then
      widget.PlaneVisible = true
    else
      widget.PlaneVisible = false
    end
end

-- #################################################################### 
-- #  ReadSensors                                                     #
-- #################################################################### 
function ReadSensors(widget)
  -- Checks if widget.GPSSource is available
  -- Then derrives Lattitude and Longitude values in widget.GPSLat & widget.GPSLong
  -- Also checks if the values are valid by checking its state. Used with "NO GPS AVAILABLE"
  if widget.GPSSource then
    local Lat_Value  = widget.GPSSource:value({options=OPTION_LATITUDE})
    local Long_Value = widget.GPSSource:value({options=OPTION_LONGITUDE})
  
    -- !VPR
    -- Change Your home coordinates for testing
    local version = system.getVersion()
    if version.simulation == true then
      -- Lipence model position
      Lat_Value  = 49.9830972
      Long_Value = 14.3772672
    end
   
    local GPSState = widget.GPSSource:state()
    if Lat_Value == nil then
      Lat_Value = 0
    end
    if Long_Value == nil then
      Long_Value = 0
    end
    if widget.GPSLAT ~= Lat_Value or widget.GPSLONG ~= Long_Value then
      widget.GPSLAT  = Lat_Value       -- ETHOS 1.6.1 appied issue #4941 of ETHOS 1.6.0
      widget.GPSLONG = Long_Value
    end
    if GPSState == true then
      widget.GPSLATlastValid  = widget.GPSLAT     -- store for signal lost
      widget.GPSLONGlastValid = widget.GPSLONG 
    end
  end

  -- Checks if widget.SpeedSource is available, Then store its value in widget.SPEED
  -- Also gets unit from widget.SpeedSource, Then store its value in widget.SPEED_UNIT
  if widget.SpeedSource then
    local SpeedValue = widget.SpeedSource:value()
    local SpeedUnit  = widget.SpeedSource:unit()
    if widget.SPEED ~= SpeedValue then
      widget.SPEED = SpeedValue
    end
      if widget.SPEED_UNIT ~= SpeedUnit then
      widget.SPEED_UNIT = SpeedUnit
    end
  end

  -- Checks if widget.AltitudeSource is available, Then store its value in widget.ALTITUDE
  -- Also gets unit from widget.AltitudeSource, Then store its value in widget.ALTITUDE_UNIT
  if widget.AltitudeSource then
    local AltitudeValue = widget.AltitudeSource:value()
    local AltitudeUnit  = widget.AltitudeSource:unit()
    if widget.ALTITUDE ~= AltitudeValue then
      widget.ALTITUDE = AltitudeValue
    end
    if widget.ALTITUDE_UNIT ~= AltitudeUnit then
      widget.ALTITUDE_UNIT = AltitudeUnit
    end
  end

  -- Checks if widget.CourseSource is available, Then store its value in widget.COURSE
  if widget.CourseSource then
    local CourseValue = widget.CourseSource:value()
    if widget.COURSE ~= CourseValue then
      widget.COURSE = CourseValue
    end
  end

  -- Checks if widget.RSSISource is available, Then store its value in widget.RSSI
  -- Also checks if the values are valid by checking its state. Used with "NO GPS AVAILABLE"
  if widget.RSSISource then
    local RSSIValue = widget.RSSISource:value()
    local RSSIState = widget.RSSISource:state()
    if widget.RSSI ~= RSSIValue then
      widget.RSSI = RSSIValue
    end
  end

  -- Checks if widget.SimLatSource is available, Then store its value in widget.SimLatValue
  -- These are used for Stick GPS Simulation
  if widget.StickSim then
    if widget.SimLatSource then
      local newValue = widget.SimLatSource:value()
      if widget.SimLatSource ~= newValue then
        widget.SimLatValue = newValue
      end
    end
  end

  -- Checks if widget.SimLongSource is available, Then store its value in widget.SimLongValue
  -- These are used for Stick GPS Simulation
  if widget.StickSim then
    if widget.SimLongSource then
      local newValue = widget.SimLongSource:value()
      if widget.SimLongSource ~= newValue then
        widget.SimLongValue = newValue
      end
    end
  end
end

-- ####################################################################
-- #  CheckTelemetry                                                  #
-- #################################################################### 
local function CheckTelemetry(widget)
  local tlm  = system.getSource( { category=CATEGORY_SYSTEM_EVENT, member=SYSTEM_EVENT_TELEMETRY_ACTIVE} )
  local oldState = widget.telemetryState 
  widget.telemetryState = (tlm:value() == 100) and 1 or 0
end
------------------------------------------------------------------------------------------------
-- Main Loop
------------------------------------------------------------------------------------------------
local function paint(widget)
    CheckDisplayType(widget)    -- Checks wheter run on X20 or X10/X12

    if Run_Script then
      CheckTelemetry(widget)      -- Checks if telemetry is active
      ReadSensors(widget)
      ValidateSources(widget)     -- Validates Sources otherwise return default values
      GpsSimInput(widget)         -- Stick Simulator function
      MapAutoSelect(widget)       -- select map from all available stored maps, if any
      CalcLCDPosition(widget)     -- Calls function to calculate LCD X/Y position from current GPS position
      SetHome(widget)             -- Stores new Home Position on Reset
      CheckPlaneOnMap(widget)     -- Check if Plane is visible on the map

      -- Draws the map image only when valid.
      if mapImage ~= nil then
        lcd.drawBitmap(0, 0, mapImage)
      end

      CheckGPS(widget)            -- Checks if valid GPS signal is preset otherwise return
      --CheckTelemetry(widget)      -- Checks if telemetry is active
      DrawHomePosition(widget)    -- Draws Home Position
      DrawPlane(widget)           -- Draws Arrow or Out of range
      GetNSEW(widget)             -- Gets all units
      BuildDMSstr(widget)         -- Builds DMS strings
      DrawHUD(widget)             -- Draws HUD
      if widget.telemetryState == 0 then
        lcd.color(COLOR_RED)
        lcd.drawRectangle(0, 0, widget.lcd_width, widget.lcd_height, 3)  
      end
--      DrawInfoBox(widget)
    end
end

------------------------------------------------------------------------------------------------
-- All Sources are updated in this Wakeup event, if new values are available then invalidate the LCD.
------------------------------------------------------------------------------------------------
local function wakeup(widget)
  local actual_time = os.clock()  -- Získání aktuálního času
  
  if widget.initPending == true then
    -- TODO if necesssary
    MapImgAutoLoad(widget)
    widget.initPending = false
  end
  
  -- Checks if widget.ResetSource is available, Then store its value in widget.rstValue
  if widget.ResetSource then
    local newValue = widget.ResetSource:value()
    if widget.rstValue ~= newValue then
      widget.rstValue = newValue
      CheckReset(widget)          -- Checks if sates of sources are changed
    end
  end      
  
  if actual_time > widget.last_time then
    widget.last_time = actual_time + 1 / g_updates_per_second   -- new time for widget refresh
    if lcd.isVisible() then
      lcd.invalidate()
    end
  end
end

------------------------------------------------------------------------------------------------
-- Widget Configuration options
------------------------------------------------------------------------------------------------
local function configure(widget)

  -- Units
    line = form.addLine(translate("mnUnits"))
    local field_units = form.addChoiceField(line, form.getFieldSlots(line)[0], {{translate("mnMetric"), 0}, {translate("mnImperial"), 1}}, function() return widget.UNIT end, function(value) widget.UNIT = value end)

  -- GPS Source
    line = form.addLine(translate("mnGPSsrc"))
    form.addSourceField(line, nil, function() return widget.GPSSource end, function(value) widget.GPSSource = value end)

  -- Speed Source
    line = form.addLine(translate("mnSpeedSrc"))
    form.addSourceField(line, nil, function() return widget.SpeedSource end, function(value) widget.SpeedSource = value end)

  -- Altitude Source
    line = form.addLine(translate("mnAltSrc"))
    form.addSourceField(line, nil, function() return widget.AltitudeSource end, function(value) widget.AltitudeSource = value end)

  -- RSSI Source
    line = form.addLine(translate("mnRSSIsrc"))
    form.addSourceField(line, nil, function() return widget.RSSISource end, function(value) widget.RSSISource = value end)

  -- Reset Source
    line = form.addLine(translate("mnResetSrc"))
    form.addSourceField(line, nil, function() return widget.ResetSource end, function(value) widget.ResetSource = value end)

  -- Course Source
    line = form.addLine(translate("mnCourseSrc"))
    widget.field_course_source = form.addSourceField(line, nil, function() return widget.CourseSource end, function(value) widget.CourseSource = value end)
    widget.field_course_source:enable(not widget.Calculate_Bearing)

  -- Calculate GPS Course
    line = form.addLine(translate("mnCalcCrs"))
    local field_calc_bearing = form.addBooleanField(line, form.getFieldSlots(line)[0], function() return widget.Calculate_Bearing end,
      function(value)
        widget.Calculate_Bearing = value
        widget.field_update_distance:enable(value)
        widget.field_course_source:enable(not value)
      end)

  -- Update Course after x Distance
    line = form.addLine(translate("mnDistUnit"))
    --local slots = form.getFieldSlots(line, {0})
    widget.field_update_distance = form.addNumberField(line, nil, 0, 1000, function() return widget.Update_Distance end, function(value) widget.Update_Distance = value end)
    widget.field_update_distance:enable(widget.Calculate_Bearing)

  -- Annotation DMS/Decimal
    line = form.addLine(translate("mnGPScoord"))
    local field_gps_annotation = form.addChoiceField(line, form.getFieldSlots(line)[0], {{translate("mnDMS"), 0},{translate("mnDecimal"), 1}}, function() return widget.GPS_Annotation end, function(value) widget.GPS_Annotation = value end)


  -- Arrow Color
    line = form.addLine(translate("mnArrColor"))
    local field_arrowcolor = form.addColorField(line, nil, function() return widget.ArrowColor end, function(color) widget.ArrowColor = color end)

  -- HUD Text Color
    line = form.addLine(translate("mnHUDcol"))
    local field_hudtextcolor = form.addColorField(line, nil, function() return widget.HUD_Text_Color end, function(color) widget.HUD_Text_Color = color end)

  -- Distance Text Color
    line = form.addLine(translate("mnDistTxtCol"))
    local field_disttextcolor = form.addColorField(line, nil, function() return widget.Distance_Text_Color end, function(color) widget.Distance_Text_Color = color end)

  -- Line Color
    line = form.addLine(translate("mnLineCol"))
    local field_linecolor = form.addColorField(line, nil, function() return widget.LineColor end, function(color) widget.LineColor = color end)

     -- Stick Simulator
    line = form.addLine(translate("mnStickSim"))
    local field_stickSim = form.addBooleanField(line, form.getFieldSlots(line)[0],
      function() return widget.StickSim end,
        function(value)
          widget.StickSim = value
            widget.field_latSource:enable(value)
            widget.field_longSource:enable(value)
        end)

        -- Source choice
    line = form.addLine(translate("mnStickLat"))
    widget.field_latSource = form.addSourceField(line, nil, function() return widget.SimLatSource end, function(value) widget.SimLatSource = value end)
    widget.field_latSource:enable(widget.StickSim)

        -- Source choice
    line = form.addLine(translate("mnStickLon"))
    widget.field_longSource = form.addSourceField(line, nil, function() return widget.SimLongSource end, function(value) widget.SimLongSource = value end)
    widget.field_longSource:enable(widget.StickSim)
end

------------------------------------------------------------------------------------------------
-- Widget Storage - Reads all configured parameters
------------------------------------------------------------------------------------------------
local function read(widget)
    widget.GPSSource                    = storage.read("GPS_Source")
    widget.SpeedSource                  = storage.read("Speed_Source")
    widget.AltitudeSource               = storage.read("Altitude_Source")
    widget.CourseSource                 = storage.read("Course_Source")
    widget.ResetSource                  = storage.read("Reset_Source")
    widget.RSSISource                   = storage.read("RSSI_Source")
    widget.UNIT                         = storage.read("Unit")
    widget.GPS_Annotation               = storage.read("GPS_Annotation")
    widget.ArrowColor                   = storage.read("ArrowColor")
    widget.HUD_Text_Color               = storage.read("HUD_Text_Color")
    widget.Distance_Text_Color          = storage.read("Distance_Text_Color")
    widget.LineColor                    = storage.read("LineColor")
    widget.Calculate_Bearing            = storage.read("Calculate_Bearing")
    widget.Update_Distance              = storage.read("Update_Distance")
    widget.SimLatSource                 = storage.read("Lat_Source")
    widget.SimLongSource                = storage.read("Long_Source")
    widget.StickSim                     = storage.read("StickSim")
end

------------------------------------------------------------------------------------------------
-- Widget Storage - Writes all configured parameters
------------------------------------------------------------------------------------------------
local function write(widget)
    storage.write("GPS_Source"          , widget.GPSSource)
    storage.write("Speed_Source"        , widget.SpeedSource)
    storage.write("Altitude_Source"     , widget.AltitudeSource)
    storage.write("Course_Source"       , widget.CourseSource)
    storage.write("Reset_Source"        , widget.ResetSource)
    storage.write("RSSI_Source"         , widget.RSSISource)
    storage.write("Unit"                , widget.UNIT)
    storage.write("GPS_Annotation"      , widget.GPS_Annotation)
    storage.write("ArrowColor"          , widget.ArrowColor)
    storage.write("HUD_Text_Color"      , widget.HUD_Text_Color)
    storage.write("Distance_Text_Color" , widget.Distance_Text_Color)
    storage.write("LineColor"           , widget.LineColor)
    storage.write("Calculate_Bearing"   , widget.Calculate_Bearing)
    storage.write("Update_Distance"     , widget.Update_Distance)
    storage.write("Lat_Source"          , widget.SimLatSource)
    storage.write("Long_Source"         , widget.SimLongSource)
    storage.write("StickSim"            , widget.StickSim)

end

------------------------------------------------------------------------------------------------
-- Widget Initialisation
------------------------------------------------------------------------------------------------
local function init()
    g_locale = system.getLocale()
    Windsock = lcd.loadBitmap("/scripts/h4lgpsmap/images/windsock.png")
    mapImage = lcd.loadBitmap("/scripts/h4lgpsmap/maps/GPSMAP.png")
    system.registerWidget({key="gps20", name=name, create=create, paint=paint, wakeup=wakeup, configure=configure, read=read, write=write})
end

return {init=init}
