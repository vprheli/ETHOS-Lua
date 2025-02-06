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
-- ETHOS Vario library
-- File:   : batLib.lua
-- Author  : RNDr.Vladimir Pribyl, CSc. (VPRHELI)
-- History : Date        Version Author   Comment
--           ----------  ------- -------- ------------------------------------
--           23.01.2025  0.0.1   VPRHELI  initial version
--           27.01.2025  1.0.0   VPRHELI  minor changes
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
-- #  varLib.CheckEnvironment                                         #
-- #    Read environment varibles                                     #
-- #################################################################### 
function varLib.CheckEnvironment (widget)
  local w, h = lcd.getWindowSize()
 
  if widget.screenHeight == nil or (w ~= widget.zoneWidth and h ~= widget.zoneHeight) then
    -- environment changed
    conf.darkMode = lcd.darkMode() 	
    local version = system.getVersion()
    
    widget.screenHeight = version.lcdHeight
    widget.screenWidth  = version.lcdWidth
    conf.simulation     = version.simulation
    
    widget.zoneHeight = h
    widget.zoneWidth  = w
    
    if widget.zoneWidth == 800 and widget.zoneHeight == 480 or widget.zoneWidth == 800 and widget.zoneHeight == 458 then
      widget.screenType = "X20fullScreen"                            -- battery icon 198x350
      --widget.batteryIcon = libs.utils.loadBitmap("empty800480.png")
    elseif widget.zoneWidth == 784 and widget.zoneHeight == 316 or widget.zoneWidth == 784 and widget.zoneHeight == 294 then
      --widget.screenType = "X20fullScreenWithTitle"                   -- battery icon 111x200
      widget.batteryIcon = libs.utils.loadBitmap("empty480320.png")
    elseif widget.zoneWidth == 388 and widget.zoneHeight == 316 or widget.zoneWidth == 388 and widget.zoneHeight == 294 then
      widget.screenType = "X20halfScreen"
      --widget.batteryIcon = libs.utils.loadBitmap("empty480320.png")
    elseif widget.zoneWidth == 300 and widget.zoneHeight == 280 or widget.zoneWidth == 300 and widget.zoneHeight == 258 then
      widget.screenType = "X20halfSreenWithSliders"    
      --widget.batteryIcon = libs.utils.loadBitmap("empty480320.png")
    elseif widget.zoneWidth == 256 and widget.zoneHeight == 316 or widget.zoneWidth == 256 and widget.zoneHeight == 294 then
      widget.screenType = "X20thirdScreen"     
      --widget.batteryIcon = libs.utils.loadBitmap("empty480320.png")
    else
      widget.screenType = "Wrongwgt"
    end
    -- not tested and supported yet
    -- 480x722  "X10fullScreen" ??
    -- 480x320  "X18fullScreen"
    -- 640x360  "X10fullScreen" ??
    --libs.utils.dumpResolution (widget)
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
      widget.altitude = sensor:value()
      --print("#### widget.altitude  : " .. widget.altitude)
    else
      widget.altitude = nil
    end
    -- Vertical Speed Sensor
    sensor = widget.VerticalSensor
    if sensor ~= nil then
      widget.vertSpeed = sensor:value()
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
  -- * getOpacityImg                paintVario() local  *
  -- ********************************************************
  local function getOpacityImg(h)
    return libs.utils.loadBitmap(string.format("frame-60x%d.png", h))
  end
  -- ********************************************************
  -- * drawAltitudeScale            paintVario() local  *
  -- ********************************************************
  local function drawAltitudeScale(widget)
    local x = 0
    local y = 0
    local h = widget.zoneHeight
    local centerY = math.floor(y + h/2)    
    
    if widget.zoneWidth < 388 then
      lcd.font(FONT_XXL)
      text_w, text_h = lcd.getTextSize("")
      centerY = h - text_h - widget.noTelFrameT
    end
    -- gray background
    -- 30% opacity of BLACK
    lcd.drawBitmap(x, y, getOpacityImg(h), widget.frameX, h)
    
    lcd.color(conf.colors.white)
    lcd.pen(SOLID)
    lcd.font(FONT_L)
    text_w, text_h = lcd.getTextSize("")
    lcd.drawLine(x, y, x, y + h - 1)
    
    -- markers
    local marker_len = widget.markerL_len
    local scaleAlt = math.floor(h / 60)
    local AltZero = centerY + widget.altitude * scaleAlt   -- pocet pixlu kde zacina nula
    for dist = 0, 199 do
      local markerY = AltZero - 5 * dist * scaleAlt
      if (markerY < (y + widget.frameY / 2)) then
        break
      elseif (markerY < (y + h- widget.frameY/2)) then
        lcd.drawLine(x, markerY, x + marker_len, markerY)
        if math.fmod (dist, 2) == 0 then
          lcd.drawNumber(x+(widget.frameX - marker_len) / 2 + marker_len, markerY - text_h/2, 5 * dist, nil, 0, TEXT_CENTERED)
        end
      end
    end
    ------------------------------------------
    -- Altitude value                       --
    ------------------------------------------    
    -- Altitude unit
    lcd.drawText(x+widget.frameX + 4, y + widget.frameY / 4, "Alt m")
    -- altitude value frame
    lcd.font(FONT_XXL)
    text_w, text_h = lcd.getTextSize("300")
    lcd.color(conf.colors.black)
    
    lcd.drawFilledRectangle (x + widget.frameX + widget.dblNumOffset, centerY - text_h, text_w, 2 * text_h)
    lcd.drawFilledTriangle(widget.frameX, centerY,  x + widget.frameX + widget.dblNumOffset, centerY - text_h, x + widget.frameX + widget.dblNumOffset, centerY + text_h)
    
    -- altitude value
    lcd.color(conf.colors.white) 
    lcd.font(FONT_XXL)
    text_w, text_h = lcd.getTextSize("300")
    --lcd.drawNumber(x + widget.frameX + widget.dblNumOffset, centerY - text_h / 2, widget.altitude, nil, 0, TEXT_LEFT)       
    lcd.drawNumber(x + widget.frameX + widget.dblNumOffset + (text_w / 2), centerY - text_h / 2, widget.altitude, nil, 0, TEXT_CENTERED) 
  end
  -- ********************************************************
  -- * drawVertSpeedScale           paintVario() local  *
  -- ********************************************************
  local function drawVertSpeedScale(widget)
    local w = 30
    local h = widget.zoneHeight    
    local x = widget.zoneWidth - 1
    local y = 0

    local centerX = math.floor(x + w/2)
    local centerY = math.floor(y + h/2)
    
        if widget.zoneWidth < 388 then
      lcd.font(FONT_XXL)
      text_w, text_h = lcd.getTextSize("")
      centerY = centerY - text_h / 2 - 2 * widget.noTelFrameT
    end
    -- gray background    
    -- 30% opacity of BLACK
    lcd.drawBitmap(x - widget.frameX, y, getOpacityImg(h), widget.frameX, h)
    
    lcd.color(conf.colors.white)        
    lcd.font(FONT_L)
    text_w, text_h = lcd.getTextSize("-20")
    -- vario Vertical Speed scale
    lcd.drawLine(x, y, x, y + h - 1)
    
    -- markers
    local scalevSpd = 12
    local marker_len = widget.markerR_len    
    local vSpdZero = centerY + 5 * widget.vertSpeed * scalevSpd   -- pocet pixlu kde zacina nula
    for sign = -1, 1, 2 do
      for dist = 0, 50 do
        local markerY = vSpdZero - dist * scalevSpd * sign
        if (markerY >= (y + widget.frameY/2)) and (markerY < (y + h- widget.frameY/2)) then      
          lcd.drawLine(x - marker_len - 1,
                       markerY,
                       x - 1, markerY)
          if math.fmod (dist, 5) == 0 then
            lcd.drawLine(x - 2 * marker_len, 
                         markerY,
                         x - 1, markerY)
            lcd.drawNumber(x - text_w / 2 - 2 * marker_len,   --(widget.frameX - marker_len) / 2
                          markerY - text_h/2,
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
    text_w, text_h = lcd.getTextSize("-10.0")
    lcd.color(conf.colors.black)
    
    lcd.drawFilledRectangle (x - widget.frameX - widget.dblNumOffset - text_w, centerY - text_h, text_w, 2 * text_h)      
    lcd.drawFilledTriangle(x - widget.frameX, centerY,  x - widget.frameX - widget.dblNumOffset - 1, centerY - text_h, x - widget.frameX - widget.dblNumOffset - 1, centerY + text_h)
        
    -- vertical speed Value
    lcd.color(conf.colors.white)        
    --lcd.drawNumber(x - widget.frameX - widget.dblNumOffset, centerY - text_h / 2, widget.vertSpeed, nil, 1, TEXT_RIGHT)    
    lcd.drawNumber(x - widget.frameX - widget.dblNumOffset - (text_w /2), centerY - text_h / 2, widget.vertSpeed, nil, 1, TEXT_CENTERED)    

  end
  
  ------------------------------------------
  -- left part Altitude from vario        --
  ------------------------------------------
  if widget.altitude ~= nil then
    drawAltitudeScale(widget)
  end
  ------------------------------------------
  -- right part Vertical Speed from vario --
  ------------------------------------------
  if widget.vertSpeed ~= nil then
    drawVertSpeedScale(widget)
  end
end
-- #################################################################### 
-- # varLib.paint                                                     #
-- ####################################################################
function varLib.paint (widget)
  libs.batLib.CheckEnvironment (widget)
  libs.batLib.readSensors(widget)
  -- force background
  --lcd.color(conf.colors.panelBackground)
  lcd.color(widget.bgcolor)  
  lcd.drawFilledRectangle(0, 0, widget.zoneWidth, widget.zoneHeight)  
  
  if widget.screenType ~= "Wrongwgt" then
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
  
--  if conf.simulation == true then
--    lcd.font(FONT_S)
--    lcd.color(conf.colors.red)
--    text_w, text_h = lcd.getTextSize("")
--    lcd.drawText(widget.zoneWidth - widget.frameX - widget.noTelFrameT, widget.zoneHeight - text_h - widget.noTelFrameT, widget.zoneWidth.."x"..widget.zoneHeight, TEXT_RIGHT)
--  end
end

return varLib