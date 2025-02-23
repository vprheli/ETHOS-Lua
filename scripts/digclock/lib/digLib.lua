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
-- ETHOS Digital library
-- File:   : batLib.lua
-- Author  : RNDr.Vladimir Pribyl, CSc. (VPRHELI)
-- History : Date        Version Author   Comment
--           ----------  ------- -------- ------------------------------------
--           23.01.2025  1.0.0   VPRHELI  initial version
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

local digLib      = {}
local conf        = nil
local libs        = nil

-- ####################################################################
-- # digLib.init                                                      #
-- ####################################################################
function digLib.init(param_conf, param_libs)
  --print ("### digLib.init ()")
  conf   = param_conf
  libs   = param_libs

  return digLib
end
-- ####################################################################
-- #  digLib.loadBitmap                                               #
-- ####################################################################
function digLib.loadBitmap(filename)
  bitmap = lcd.loadBitmap(conf.basePath .. conf.imgFolder .. filename)
  return bitmap
end
-- ####################################################################
-- #  digLib.loadDigits                                               #
-- ####################################################################
function digLib.loadDigits(color, size)
  local digits = {}
  for i = 0, 9 do
    digits[i] = digLib.loadBitmap(string.format("/%s/%d-%d.png", color, size, i))
  end
  digits[10] = digLib.loadBitmap(string.format("/%s/%d-col.png", color, size))
  digits[11] = digLib.loadBitmap(string.format("/%s/%d-none.png", color, size))
  return digits
end
-- ####################################################################
-- #  digLib.GetColorText                                             #
-- ####################################################################
function digLib.GetColorText (index)
  local colorText
  if index == 0 then
    colorText = "red"
  elseif index == 1 then
    colorText = "green"
  else
    colorText = "yellow"
  end
  return colorText
end
-- ####################################################################
-- #  digLib.CheckEnvironment                                         #
-- #    Read environment varibles                                     #
-- ####################################################################
function digLib.CheckEnvironment (widget)
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
      widget.screenType = "X20fullScreen"
      widget.digits   = digLib.loadDigits(digLib.GetColorText (widget.segmentColor), 134)       -- segment icon 134x221
      widget.iconH    = 221
      widget.iconW    = 134
      widget.icon_dX  = 15
      widget.iconColW = 62
      local timeW     = 4 * widget.iconW + widget.iconColW + 4 * widget.icon_dX
      widget.iconX    = math.floor((widget.zoneWidth  - timeW) / 2)
      widget.iconY    = math.floor((widget.zoneHeight - widget.iconH) / 2)
    elseif widget.zoneWidth == 784 and widget.zoneHeight == 316 or widget.zoneWidth == 784 and widget.zoneHeight == 294 then
      widget.screenType = "X20fullScreenWithTitle"
      widget.digits   = digLib.loadDigits(digLib.GetColorText (widget.segmentColor), 134)       -- segment icon 134x221
      widget.iconH    = 221
      widget.iconW    = 134
      widget.icon_dX  = 15
      widget.iconColW = 62
      local timeW     = 4 * widget.iconW + widget.iconColW + 4 * widget.icon_dX
      widget.iconX    = math.floor((widget.zoneWidth  - timeW) / 2)
      widget.iconY    = math.floor((widget.zoneHeight - widget.iconH) / 2)
    elseif widget.zoneWidth == 784 and widget.zoneHeight == 154 or widget.zoneWidth == 784 and widget.zoneHeight == 132 then
      widget.screenType = "X20halfScreenVert"
      widget.digits   = digLib.loadDigits(digLib.GetColorText (widget.segmentColor), 80)       -- segment icon 80x132
      widget.iconH    = 132
      widget.iconW    = 80
      widget.icon_dX  = 15
      widget.iconColW = 40
      local timeW     = 4 * widget.iconW + widget.iconColW + 4 * widget.icon_dX
      widget.iconX    = math.floor((widget.zoneWidth  - timeW) / 2)
      widget.iconY    = math.floor((widget.zoneHeight - widget.iconH) / 2)
    elseif widget.zoneWidth == 388 and widget.zoneHeight == 316 or widget.zoneWidth == 388 and widget.zoneHeight == 294 then
      widget.screenType = "X20halfScreenHor"
      widget.digits   = digLib.loadDigits(digLib.GetColorText (widget.segmentColor), 80)       -- segment icon 80x132
      widget.iconH    = 132
      widget.iconW    = 80
      widget.icon_dX  = 7
      widget.iconColW = 40
      local timeW     = 4 * widget.iconW + widget.iconColW + 4 * widget.icon_dX
      widget.iconX    = math.floor((widget.zoneWidth  - timeW) / 2)
      widget.iconY    = math.floor((widget.zoneHeight - widget.iconH) / 2)
    elseif widget.zoneWidth == 388 and widget.zoneHeight == 132 or widget.zoneWidth == 388 and widget.zoneHeight == 154 then
      widget.screenType = "X20quadScreen"
      widget.digits   = digLib.loadDigits(digLib.GetColorText (widget.segmentColor), 80)       -- segment icon 80x132
      widget.iconH    = 132
      widget.iconW    = 80
      widget.icon_dX  = 7
      widget.iconColW = 40
      local timeW     = 4 * widget.iconW + widget.iconColW + 4 * widget.icon_dX
      widget.iconX    = 0 --math.floor((widget.zoneWidth  - timeW) / 2)
      widget.iconY    = math.floor((widget.zoneHeight - widget.iconH) / 2)
    elseif widget.zoneWidth == 300 and widget.zoneHeight == 280 or widget.zoneWidth == 300 and widget.zoneHeight == 258 then
      widget.screenType = "X20halfSreenWithSliders"
      widget.digits   = digLib.loadDigits(digLib.GetColorText (widget.segmentColor), 48)       -- segment icon 48x78
      widget.iconH    = 78
      widget.iconW    = 48
      widget.icon_dX  = 7
      widget.iconColW = 24
      local timeW     = 4 * widget.iconW + widget.iconColW + 4 * widget.icon_dX
      widget.iconX    = math.floor((widget.zoneWidth  - timeW) / 2)
      widget.iconY    = math.floor((widget.zoneHeight - widget.iconH) / 2)
    elseif widget.zoneWidth == 300 and widget.zoneHeight == 114 or widget.zoneWidth == 300 and widget.zoneHeight == 136 then
      widget.screenType = "X20quadSreenWithSliders"
      widget.digits   = digLib.loadDigits(digLib.GetColorText (widget.segmentColor), 34)       -- segment icon 34x56
      widget.iconH    = 56
      widget.iconW    = 34
      widget.icon_dX  = 7
      widget.iconColW = 17
      local timeW     = 4 * widget.iconW + widget.iconColW + 4 * widget.icon_dX
      widget.iconX    = math.floor((widget.zoneWidth  - timeW) / 2)
      widget.iconY    = math.floor((widget.zoneHeight - widget.iconH) / 2)
    elseif widget.zoneWidth == 256 and widget.zoneHeight == 316 or widget.zoneWidth == 256 and widget.zoneHeight == 294 then
      widget.screenType = "X20thirdScreenHigh"
      widget.digits   = digLib.loadDigits(digLib.GetColorText (widget.segmentColor), 48)       -- segment icon 48x78
      widget.iconH    = 78
      widget.iconW    = 48
      widget.icon_dX  = 7
      widget.iconColW = 24
      local timeW     = 4 * widget.iconW + widget.iconColW + 4 * widget.icon_dX
      widget.iconX    = math.floor((widget.zoneWidth  - timeW) / 2)
      widget.iconY    = math.floor((widget.zoneHeight - widget.iconH) / 2)
    elseif widget.zoneWidth == 256 and widget.zoneHeight == 78 or widget.zoneWidth == 256 and widget.zoneHeight == 100 or
           widget.zoneWidth == 256 and widget.zoneHeight == 132 or widget.zoneWidth == 256 and widget.zoneHeight == 154 then
      widget.screenType = "X20thirdScreen"
      widget.digits   = digLib.loadDigits(digLib.GetColorText (widget.segmentColor), 48)       -- segment icon 48x78
      widget.iconH    = 78
      widget.iconW    = 48
      widget.icon_dX  = 7
      widget.iconColW = 24
      local timeW     = 4 * widget.iconW + widget.iconColW + 4 * widget.icon_dX
      widget.iconX    = math.floor((widget.zoneWidth  - timeW) / 2)
      widget.iconY    = math.floor((widget.zoneHeight - widget.iconH) / 2)
    elseif widget.zoneWidth == 200 and widget.zoneHeight == 64 or widget.zoneWidth == 200 and widget.zoneHeight == 86 then
      widget.digits   = digLib.loadDigits(digLib.GetColorText (widget.segmentColor), 34)       -- segment icon 34x56
      widget.iconH    = 56
      widget.iconW    = 34
      widget.icon_dX  = 7
      widget.iconColW = 17
      local timeW     = 4 * widget.iconW + widget.iconColW + 4 * widget.icon_dX
      widget.iconX    = math.floor((widget.zoneWidth  - timeW) / 2)
      widget.iconY    = math.floor((widget.zoneHeight - widget.iconH) / 2)
    else -- 256
      widget.screenType = "Wrongwgt"
    end
    -- not tested and supported yet
    -- 480x722  "X10fullScreen" ??
    -- 480x320  "X18fullScreen"
    -- 640x360  "X10fullScreen" ??

  -- If there is enough space, I will display the timer name
  lcd.font(FONT_XL)
  text_w, text_h = lcd.getTextSize("")
  if ((widget.zoneHeight - widget.iconH) / 2 > text_h) and widget.StopWatch ~= nil  then
    widget.paintName = true
  else
    widget.paintName = false
  end

    --libs.utils.dumpResolution (widget)
  end
end
-- ####################################################################
-- #  digLib.getSourceValue                                           #
-- ####################################################################
function digLib.getSourceValue(input)
  if input == nil then
    return nil
  end
  local value = input:value()
  return value
end
-- ####################################################################
-- #  digLib.readSensors                                              #
-- ####################################################################
function digLib.readSensors(widget)
  widget.swtime = digLib.getSourceValue(widget.StopWatch)
end
-- ####################################################################
-- #  diglib.paintDigital                                             #
-- ####################################################################
function digLib.paintDigital (widget)
  local digitsArr = {}
  swValue = widget.swtime
  if swValue > 0 and swValue < 3600 then
      tSec        = swValue % 60
      tMin        = (swValue - tSec) / 60
      digitsArr[0] = math.floor(tMin / 10)
      digitsArr[1] = tMin - (digitsArr[0] * 10)
      digitsArr[2] = 10
      digitsArr[3] = math.floor(tSec / 10)
      digitsArr[4] = tSec - (digitsArr[3] * 10)
  elseif swValue <= 0 and swValue > -3599 then
      tSec        = (swValue * -1) % 60
      tMin        = (swValue * -1 - tSec) / 60
      digitsArr[0] = math.floor(tMin / 10)
      digitsArr[1] = tMin - (digitsArr[0] * 10)
      digitsArr[2] = 10
      digitsArr[3] = math.floor(tSec / 10)
      digitsArr[4] = tSec - (digitsArr[3] * 10)
 else
      digitsArr[0] = 10
      digitsArr[1] = 10
      digitsArr[2] = 10
      digitsArr[3] = 10
      digistArr[4] = 10
  end

  local dXoffset = widget.iconX
  for i = 0, 4 do
    lcd.drawBitmap(dXoffset, widget.iconY, widget.digits[digitsArr[i]])
    if i == 2 then
      dXoffset = dXoffset + widget.iconColW + widget.icon_dX
    else
      dXoffset = dXoffset + widget.iconW + widget.icon_dX
    end
  end

  if widget.paintName == true then
    lcd.font(FONT_STD)
    lcd.color(widget.txtcolor)
    text_w, text_h = lcd.getTextSize("")
    dY = (widget.zoneHeight - widget.iconH) / 4 - text_h / 2
    lcd.drawText(widget.zoneWidth /2, dY, widget.StopWatch:name(), TEXT_CENTERED)
  end

end
-- ####################################################################
-- # digLib.paint                                                     #
-- ####################################################################
function digLib.paint (widget)
  digLib.CheckEnvironment (widget)
  digLib.readSensors(widget)
  -- force background
  lcd.color(widget.bgcolor)
  lcd.drawFilledRectangle(0, 0, widget.zoneWidth, widget.zoneHeight)

  if widget.screenType ~= "Wrongwgt" then
    if (widget.StopWatch ~= nil) then
      digLib.paintDigital (widget)
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

  if conf.simulation == true then
    lcd.font(FONT_S)
    lcd.color(conf.colors.red)
    text_w, text_h = lcd.getTextSize("")
    --lcd.drawText(widget.zoneWidth - widget.noTelFrameT, widget.zoneHeight - text_h - widget.noTelFrameT, widget.zoneWidth.."x"..widget.zoneHeight, TEXT_RIGHT)
  end
end

return digLib