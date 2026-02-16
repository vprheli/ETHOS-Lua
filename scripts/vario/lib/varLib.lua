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
-- ETHOS Vario library
-- File:   : varLib.lua
-- Author  : RNDr.Vladimir Pribyl, CSc. (VPRHELI)
-- History : Date        Version Author   Comment
--           ----------  ------- -------- ------------------------------------
--           23.01.2025  0.0.1   VPRHELI  initial version
--           27.01.2025  1.0.0   VPRHELI  minor changes
--           16.02.2025  1.0.1   VPRHELI  removing opacity bitmaps, use opacity color
--           10.02.2026  1.1.0   VPRHELI  common util.lua, widget paint type zone size detection
--           16.02.2026  1.1.1   VPRHELI  show vertical speed in color
-- =============================================================================
-- Snsor IDs
-- https://openrcforums.com/forum/viewtopic.php?t=5701
-- RSSI     0xF101
-- AccX     0x0700
-- AccY     0x0710
-- AccZ     0x0720
-- LiPo     0x0300
-- VARIO    0x0110    Vert.rychlost
-- Alt      0x0100    Vyska
-- gAlt     0x0820
-- gSpeed   0x0830
-- VFAS     0x0210
-- CURRENT  0x0200 (name = Proud)

local varLib      = {}
local conf        = nil
local libs        = nil

-- #################################################################### 
-- # varLib.init                                                      #
-- ####################################################################
function varLib.init(param_conf, param_libs)
  print ("### varLib.init ()")
  conf   = param_conf 
  libs   = param_libs
  
  return varLib
end
-- ####################################################################
-- #  varLib.SetZoneMatrix                                            #
-- #    Set zone dimensions matrix                                    #
-- ####################################################################
function varLib.SetZoneMatrix (widget)
  lcd.font(FONT_XXL)
  textX_w, textX_h = lcd.getTextSize("-10.0")
  lcd.font(FONT_L)
  textL_w, textL_h = lcd.getTextSize("A")
  lcd.font(FONT_S)
  textS_w, textS_h = lcd.getTextSize("1")  
  
  -- ##############
  -- # Paint Pram #
  -- ##############
  local pp = { x = 0,
             y = 0,
             h = 0,
             zoneW    = 0,
             centerYA = 0,
             centetYS = 0,
             text_hS  = 0,
             text_hL  = 0,
             text_wL  = 0,
             text_hX  = 0,
             text_wX  = 0}
  widget.pp = pp

  widget.pp.text_hL = textL_h  
  widget.pp.text_wL = textL_w 
  widget.pp.text_hX = textX_h  
  widget.pp.text_wX = textX_w 
  widget.pp.text_hS = textS_h 
  
  widget.zoneMatrix[1] = {}
  widget.zoneMatrix[1][0] = 2 * widget.frameX + 2 * textX_w + 2 * textX_w / 3   --[i][0] minimal width
  widget.zoneMatrix[1][1] = 2 * textX_h + textL_h                               --[i][1] minimal height
  
  widget.zoneMatrix[2] = {}
  widget.zoneMatrix[2][0] = 2 * widget.frameX + 2 * textX_w / 3                 --[i][0] minimal width
  widget.zoneMatrix[2][1] = 4 * textX_h + textL_h                               --[i][1] minimal height
  
  widget.zoneMatrix[3] = {}
  widget.zoneMatrix[3][0] = 2 * textX_w                                         --[i][0] minimal width
  widget.zoneMatrix[3][1] = 2 * textX_h                                         --[i][1] minimal height
end
-- ####################################################################
-- #  varLib.SetZoneParam                                             #
-- #    Set zone paint parameters based on widget.zoneID              #
-- ####################################################################
function varLib.SetZoneParam (widget)
  --print ("### varLib.SetZoneParam ()")
  
  conf.darkMode = lcd.darkMode()
  local version = system.getVersion()

  widget.screenHeight = version.lcdHeight
  widget.screenWidth  = version.lcdWidth
  conf.simulation     = version.simulation

  if widget.zoneID == 1 then
    widget.pp.xA       = 0
    widget.pp.xS       = widget.zoneWidth - 1    
    widget.pp.y        = 0
    widget.pp.h        = widget.zoneHeight
    widget.pp.centerYA = math.floor(widget.pp.y + widget.pp.h/2)
    widget.pp.centerYS = math.floor(widget.pp.y + widget.pp.h/2)
  elseif widget.zoneID == 2 then
    widget.pp.xA        = 0
    widget.pp.xS       = widget.zoneWidth - 1        
    widget.pp.y        = 0
    widget.pp.h        = widget.zoneHeight
    widget.pp.centerYA = math.floor(widget.pp.y + widget.pp.h/2) + widget.pp.text_hX  + 2 * widget.noTelFrameT
    widget.pp.centerYS = math.floor(widget.pp.y + widget.pp.h/2) - widget.pp.text_hX  - 2 * widget.noTelFrameT
    widget.pp.text_hX  = widget.pp.text_hX
  elseif widget.zoneID == 3 then
    widget.pp.xA       = 0
    widget.pp.xS       = widget.zoneWidth / 2        
    widget.pp.y        = 0
    widget.pp.h        = widget.zoneHeight
    widget.pp.zoneW    = widget.zoneWidth / 2
    widget.pp.centerYA = math.floor(widget.pp.y + widget.pp.h/2)
    widget.pp.centerYS = math.floor(widget.pp.y + widget.pp.h/2)
    widget.pp.text_hX  = widget.pp.text_hX    
  end
end
-- #################################################################### 
-- #  getSourceValue                                                  # 
-- #################################################################### 
function varLib.getSourceValue(input)
  if input == nil then
    return 0
  end
  local value = input.value
  if value == nil then
    return 0
  end
  return value(input)
end
-- #################################################################### 
-- #  varLib.readSensors                                              #
-- #################################################################### 
function varLib.readSensors(widget)
  if conf.telemetryState == 1 then
    -- Altitude sensor (Vario)
    local sensor = widget.VarioSensor
    if sensor ~= nil then
      widget.altitude    = sensor:value()
      widget.altitudeMin = sensor:value({options=OPTION_SENSOR_MIN})
      widget.altitudeMax = sensor:value({options=OPTION_SENSOR_MAX})
      --print("#### widget.altitude  : " .. widget.altitude)
      if widget.showAltNegative == false and widget.altitude < 0 then
        widget.altitude = 0
      end
    else
      widget.altitude = nil
    end
    -- Vertical Speed Sensor
    sensor = widget.VerticalSensor
    if sensor ~= nil then
      widget.vertSpeed    = sensor:value()
      widget.vertSpeedMin = sensor:value({options=OPTION_SENSOR_MIN})      
      widget.vertSpeedMax = sensor:value({options=OPTION_SENSOR_MAX})
      --print("#### widget.vSpeed    : " .. widget.vertSpeed)
    else
      widget.vertSpeed = nil
    end
  end
end
-- #################################################################### 
-- #  paintVario                                                      #
-- #################################################################### 
function varLib.paintVario (widget)
  -- ********************************************************
  -- * formatNumber                 paintVario() local  *
  -- ********************************************************
  local function formatNumber(value, format)
    return string.format(format, value)
  end
  -- ******************************************************** 
  -- * getVarioColor                paintVario() local  *
  -- ********************************************************
  local function getVarioColor (vertSpeed, limit)
    if limit <= 0 then return lcd.RGB(0, 0, 0) end

    -- intenzity calculation 0.0 to 1.0
    local intensity = math.abs(vertSpeed) / limit
    if intensity > 1 then intensity = 1 end
    
    local colorVal = math.floor(intensity * 255)    -- scale 0-255 RGB

    if vertSpeed > 0 then         -- pozitive value (black -> green)
      return lcd.RGB(0, colorVal, 0)
    elseif vertSpeed < 0 then     -- negative value (black -> red)
      return lcd.RGB(colorVal, 0, 0)
    else
      return lcd.RGB(0, 0, 0)   -- zero - black
    end
  end
  -- ********************************************************
  -- * drawAltitudeScale            paintVario() local  *
  -- ********************************************************
  local function drawAltitudeScale(widget)
    local x = widget.pp.xA
    local y = widget.pp.y
    
    -- gray background
    -- 30% opacity of BLACK
    lcd.color(lcd.RGB(0,0,0,0.3))
    lcd.drawFilledRectangle (x, y, 60, widget.pp.h)
    
    lcd.color(conf.colors.white)
    lcd.pen(SOLID)
    lcd.drawLine(x, y, x, y + widget.pp.h - 1)
    
    -- markers
    local marker_len = widget.markerL_len
    local scaleAlt = math.floor(widget.pp.h / 60)
    local AltZero = widget.pp.centerYA + widget.altitude * scaleAlt   -- pocet pixlu kde zacina nula
    for sign = 1, -1, -2 do    
      for dist = 0, 199 do
        local markerY = AltZero - 5 * dist * scaleAlt * sign
--        if (markerY >= h) or (markerY < y) then 
--          break
--      end
        if (markerY >= (y + widget.frameY/2)) and (markerY < (y + widget.pp.h - widget.frameY/2)) then
          lcd.drawLine (x, markerY, x + marker_len, markerY)
          if math.fmod (dist, 2) == 0 then
            lcd.drawNumber (x+(widget.frameX - marker_len) / 2 + marker_len, markerY - widget.pp.text_hL/2, 5 * dist * sign, nil, 0, TEXT_CENTERED)
          end
        end
      end
      if widget.showAltNegative == false then
        break
      end
    end
    ------------------------------------------
    -- Altitude value                       --
    ------------------------------------------    
    -- Altitude unit
    lcd.drawText (x + widget.frameX + 4, y + widget.frameY / 4, "Alt m")
    -- altitude value frame
    lcd.font(FONT_XXL)
    lcd.color(conf.colors.black)
    
    lcd.drawFilledRectangle (x + widget.frameX + 2 * widget.pp.text_hX / 3,
                             widget.pp.centerYA - widget.pp.text_hX,
                             widget.pp.text_wX,
                             2 * widget.pp.text_hX)
    lcd.drawFilledTriangle (x + widget.frameX,
                            widget.pp.centerYA,
                            widget.frameX + 2 * widget.pp.text_hX / 3,
                            widget.pp.centerYA + widget.pp.text_hX,
                            widget.frameX + 2 * widget.pp.text_hX / 3,
                            widget.pp.centerYA - widget.pp.text_hX)                          
    
    -- altitude value
    lcd.color(conf.colors.white) 
    lcd.font(FONT_XXL)
    lcd.drawNumber (x + widget.frameX + ((2 * widget.pp.text_wX / 3 + widget.pp.text_wX) / 2),
                    widget.pp.centerYA - widget.pp.text_hX / 2,
                    widget.altitude,
                    nil,
                    0,
                    TEXT_CENTERED)
    if widget.showMinMax then
      lcd.font(FONT_S)
      lcd.drawNumber(x + widget.frameX + ((2 * widget.pp.text_wX / 3 + widget.pp.text_wX) / 2),
                     widget.pp.centerYA - widget.pp.text_hX / 2 - widget.pp.text_hS,
                     widget.altitudeMax,
                     nil,
                     0,
                     TEXT_CENTERED)
      lcd.drawNumber(x + widget.frameX + ((2 * widget.pp.text_wX / 3 + widget.pp.text_wX) / 2),
                     widget.pp.centerYA + widget.pp.text_hX / 2,
                     widget.altitudeMin,
                     nil,
                     0,
                     TEXT_CENTERED)                   
    end
  end
  -- ********************************************************
  -- * drawVertSpeedScale           paintVario() local  *
  -- ********************************************************
  local function drawVertSpeedScale(widget)
    local x = widget.pp.xS
    local y = widget.pp.y
    
    -- gray background    
    -- 30% opacity of BLACK
    lcd.color (lcd.RGB(0,0,0,0.3))
    lcd.drawFilledRectangle (x - widget.frameX, y, widget.frameX, widget.pp.h)
    
    lcd.color (conf.colors.white)        
    lcd.font (FONT_L)
    -- vario Vertical Speed scale
    lcd.drawLine (x, y, x, y + widget.pp.h - 1)
    
    -- markers
    local scalevSpd = 12
    local marker_len = widget.markerR_len    
    local vSpdZero = widget.pp.centerYS + 5 * widget.vertSpeed * scalevSpd   -- pocet pixlu kde zacina nula
    for sign = -1, 1, 2 do
      for dist = 0, 50 do
        local markerY = vSpdZero - dist * scalevSpd * sign
        if (markerY >= (y + widget.frameY/2)) and (markerY < (y + widget.pp.h - widget.frameY/2)) then      
          lcd.drawLine(x - marker_len - 1,
                       markerY,
                       x - 1, markerY)
          if math.fmod (dist, 5) == 0 then
            lcd.drawLine(x - 2 * marker_len, 
                         markerY,
                         x - 1, markerY)
            lcd.drawNumber(x - widget.pp.text_wL / 2 - 2 * marker_len,   --(widget.frameX - marker_len) / 2
                          markerY - widget.pp.text_hL/2,
                          sign * dist / 5, nil, nil, TEXT_CENTERED)
          end        
        end
      end
    end
    ------------------------------------------
    -- Vertical Speed value                 --
    ------------------------------------------
    -- Vertical speed unit
    lcd.drawText(x - widget.frameX - 4, y + widget.frameY / 4, "m/s", TEXT_RIGHT)
    -- vertical speed value frame
    lcd.font(FONT_XXL)
    if widget.showVScolored == true then
      lcd.color(getVarioColor (widget.vertSpeed, 5))
    else
      lcd.color(conf.colors.black)
    end
    
    lcd.drawFilledRectangle (x - widget.frameX - 2 * widget.pp.text_hX / 3 - widget.pp.text_wX,
                             widget.pp.centerYS - widget.pp.text_hX,
                             widget.pp.text_wX,
                             2 * widget.pp.text_hX) 
    lcd.drawFilledTriangle (x - widget.frameX,
                            widget.pp.centerYS,  x - widget.frameX - 2 * widget.pp.text_hX / 3 - 1,
                            widget.pp.centerYS - widget.pp.text_hX,
                            x - widget.frameX - 2 * widget.pp.text_hX / 3 - 1,
                            widget.pp.centerYS + widget.pp.text_hX)
        
    -- vertical speed Value
    lcd.color(conf.colors.white)        
    lcd.drawNumber (x - widget.frameX - ((2 * widget.pp.text_hX / 3 + widget.pp.text_wX) / 2),
                    widget.pp.centerYS - widget.pp.text_hX / 2,
                    widget.vertSpeed,
                    nil,
                    1,
                    TEXT_CENTERED)   
    if widget.showMinMax then
      lcd.font(FONT_S)
      lcd.drawNumber(x - widget.frameX - ((2 * widget.pp.text_wX / 3 + widget.pp.text_wX) / 2),
                     widget.pp.centerYA - widget.pp.text_hX / 2 - widget.pp.text_hS,
                     widget.vertSpeedMax,
                     nil,
                     1,
                     TEXT_CENTERED)
      lcd.drawNumber(x - widget.frameX - ((2 * widget.pp.text_wX / 3 + widget.pp.text_wX) / 2),
                     widget.pp.centerYA + widget.pp.text_hX / 2,
                     widget.vertSpeedMin,
                     nil,
                     1,
                     TEXT_CENTERED)                   
    end                  
  end
  -- ********************************************************
  -- * drawSimpleAltitude           paintVario() local  *
  -- ********************************************************
  local function drawSimpleAltitude(widget)
    lcd.color (conf.colors.black)    
    lcd.drawFilledRectangle (widget.pp.xA + widget.pp.zoneW / 2 - widget.pp.text_wX / 2,
                             widget.pp.centerYA - widget.pp.text_hX,
                             widget.pp.text_wX,
                             2 * widget.pp.text_hX)
    lcd.color(conf.colors.white)        
    lcd.font(FONT_XXL)
    lcd.drawNumber (widget.pp.xA + widget.pp.zoneW / 2,
                    widget.pp.y + widget.pp.centerYA - widget.pp.text_hX / 2,
                    widget.altitude,
                    nil,
                    0,
                    TEXT_CENTERED) 
    if widget.showMinMax then
      lcd.font(FONT_S)
      lcd.drawNumber(widget.pp.xA + widget.pp.zoneW / 2,
                     widget.pp.centerYA - widget.pp.text_hX / 2 - widget.pp.text_hS,
                     widget.altitudeMax,
                     nil,
                     0,
                     TEXT_CENTERED)
      lcd.drawNumber(widget.pp.xA + widget.pp.zoneW / 2,
                     widget.pp.centerYA + widget.pp.text_hX / 2,
                     widget.altitudeMin,
                     nil,
                     0,
                     TEXT_CENTERED)                   
    end                  
  end
  -- ********************************************************
  -- * drawSimpleSpeed           paintVario() local  *
  -- ********************************************************
  local function drawSimpleSpeed(widget)
    speedColor = getVarioColor (widget.vertSpeed, 5)
    lcd.color (lcd.color (lcd.RGB(0,0,0,0.3)))
    lcd.drawFilledRectangle (widget.pp.xS,
                             widget.pp.y,
                             widget.pp.zoneW,
                             widget.pp.h)
    lcd.color (speedColor)      
    lcd.drawFilledRectangle (widget.pp.xS + widget.pp.zoneW / 2 - widget.pp.text_wX / 2,
                             widget.pp.y + widget.pp.centerYA - widget.pp.text_hX,
                             widget.pp.text_wX,
                             2 * widget.pp.text_hX)
    -- vertical speed Value
    
    lcd.color(conf.colors.white)        
    lcd.font(FONT_XXL)
    lcd.drawNumber (widget.pp.xS + widget.pp.zoneW / 2,
                    widget.pp.y + widget.pp.centerYS - widget.pp.text_hX / 2,
                    widget.vertSpeed,
                    nil,
                    1,
                    TEXT_CENTERED)
    if widget.showMinMax then
      lcd.font(FONT_S)
      lcd.drawNumber(widget.pp.xS + widget.pp.zoneW / 2,
                     widget.pp.centerYA - widget.pp.text_hX / 2 - widget.pp.text_hS,
                     widget.vertSpeedMax,
                     nil,
                     1,
                     TEXT_CENTERED)
      lcd.drawNumber(widget.pp.xS + widget.pp.zoneW / 2,
                     widget.pp.centerYA + widget.pp.text_hX / 2,
                     widget.vertSpeedMin,
                     nil,
                     1,
                     TEXT_CENTERED)                   
    end                   
  end
  ------------------------------------------
  -- left part Altitude from vario        --
  ------------------------------------------
  if widget.altitude ~= nil then
    if widget.zoneID == 3 then
      drawSimpleAltitude (widget)
    else
      drawAltitudeScale (widget)
    end
  end
  ------------------------------------------
  -- right part Vertical Speed from vario --
  ------------------------------------------
  if widget.vertSpeed ~= nil then
    if widget.zoneID == 3 then
      drawSimpleSpeed (widget)
    else
      drawVertSpeedScale (widget)
    end
  end
end
-- #################################################################### 
-- # varLib.paint                                                     #
-- ####################################################################
function varLib.paint (widget)
  libs.varLib.readSensors(widget)
  -- force background
  --lcd.color(conf.colors.panelBackground)
  lcd.color(widget.bgcolor)
  lcd.drawFilledRectangle(0, 0, widget.zoneWidth, widget.zoneHeight)  
  
  if widget.zoneID ~= 0 then
    if (widget.VarioSensor ~= nil) then
      varLib.paintVario (widget)         
    else
      libs.utils.printError (widget, "badSensor")
    end
  else
    libs.utils.printError (widget, "wgtsmall")
  end
    -- telemetry lost => red zone frame
  if conf.telemetryState == 0 then
    lcd.color(conf.colors.red)
    lcd.drawRectangle(0, 0, widget.zoneWidth, widget.zoneHeight, widget.noTelFrameT)  
  end
end

return varLib