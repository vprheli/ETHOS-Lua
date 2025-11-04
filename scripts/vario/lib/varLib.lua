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
--           21.10.2025  1.1.0   andreaskuhl  feature: min/max values display
--           21.10.2025  1.1.1   andreaskuhl  optimize altitude value frame
--           04.11.2025  1.1.2   andreaskuhl  red negative values and some refactoring
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

local varLib = {}
local conf   = nil
local libs   = nil

-- ####################################################################
-- # varLib.init                                                      #
-- ####################################################################
function varLib.init(param_conf, param_libs)
  --print ("### varLib.init ()")
  conf = param_conf
  libs = param_libs

  return varLib
end

local function drawSignColoredNumber(x, y, value, decimals)
  decimals = decimals or 0
  if value >= 0 then
    lcd.color(conf.colors.white)
    lcd.drawNumber(x, y, value, nil, decimals, TEXT_CENTERED)
  else
    lcd.color(conf.colors.red)
    lcd.drawNumber(x, y, -value, nil, decimals, TEXT_CENTERED)
    lcd.color(conf.colors.white)
  end
end

-- ####################################################################
-- #  varLib.CheckEnvironment                                         #
-- #    Read environment varibles                                     #
-- ####################################################################
function varLib.CheckEnvironment(widget)
  local w, h = lcd.getWindowSize()

  if widget.screenHeight == nil or (w ~= widget.zoneWidth and h ~= widget.zoneHeight) then
    -- environment changed
    conf.darkMode       = lcd.darkMode()
    local version       = system.getVersion()

    widget.screenHeight = version.lcdHeight
    widget.screenWidth  = version.lcdWidth
    conf.simulation     = version.simulation

    widget.zoneHeight   = h
    widget.zoneWidth    = w

    if widget.zoneWidth == 800 and widget.zoneHeight == 480 or widget.zoneWidth == 800 and widget.zoneHeight == 458 then
      widget.screenType = "X20fullScreen"
    elseif widget.zoneWidth == 784 and widget.zoneHeight == 316 or widget.zoneWidth == 784 and widget.zoneHeight == 294 then
      widget.screenType = "X20fullScreenWithTitle" -- battery icon 111x200
    elseif widget.zoneWidth == 388 and widget.zoneHeight == 316 or widget.zoneWidth == 388 and widget.zoneHeight == 294 then
      widget.screenType = "X20halfScreen"
    elseif widget.zoneWidth == 300 and widget.zoneHeight == 280 or widget.zoneWidth == 300 and widget.zoneHeight == 258 then
      widget.screenType = "X20halfSreenWithSliders"
    elseif widget.zoneWidth == 256 and widget.zoneHeight == 316 or widget.zoneWidth == 256 and widget.zoneHeight == 294 then
      widget.screenType = "X20thirdScreen"
      -- X18 temporary fix for two zone size
    elseif widget.zoneWidth == 234 and widget.zoneHeight == 210 or widget.zoneWidth == 472 and widget.zoneHeight == 210 then
      widget.screenType = "X18halfScreen"
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
      widget.altitudeMax = sensor:value({ options = OPTION_SENSOR_MAX })
      widget.altitudeMin = sensor:value({ options = OPTION_SENSOR_MIN })
      --print("#### widget.altitude    : " .. widget.altitude .. ", max: " .. widget.altitudeMax .. ", min: " .. widget.altitudeMin)
    else
      widget.altitude = nil
    end
    -- Vertical Speed Sensor
    sensor = widget.VerticalSensor
    if sensor ~= nil then
      widget.vertSpeed = sensor:value()
      widget.vertSpeedMax = sensor:value({ options = OPTION_SENSOR_MAX })
      widget.vertSpeedMin = sensor:value({ options = OPTION_SENSOR_MIN })
      --print("#### widget.vSpeed    : " .. widget.vertSpeed .. ", max: " .. widget.vertSpeedMax .. ", min: " .. widget.vertSpeedMin)
    else
      widget.vertSpeed = nil
    end
  end
end

-- ####################################################################
-- #  paintVario                                                      #
-- ####################################################################
function varLib.paintVario(widget)
  -- ********************************************************
  -- * formatNumber                 paintVario() local  *
  -- ********************************************************
  local function formatNumber(value, format)
    return string.format(format, value)
  end

  -- ********************************************************
  -- * drawAltitudeScale            paintVario() local  *
  -- ********************************************************
  local function drawAltitudeScale(widget)
    local x = 0
    local y = 0
    local h = widget.zoneHeight
    local pointerY = math.floor(y + h / 2) -- pixel pointer position of the point (default in the middle)
    local levelY = pointerY / h            -- level factor (0..1) of the pointer position (default in the middle = 0.5)

    -- If widget is too narrow, value pointers must be displayed with an offset.
    -- => Value pointer for altitude at the bottom of the widget.
    if widget.zoneWidth < 388 then
      lcd.font(FONT_XXL)
      _, text_h = lcd.getTextSize("")
      pointerY = h - text_h - widget.noTelFrameT -- set pointer to bottom of widget
      levelY = pointerY / h                      -- calculate the level factor (~0.8)
    end

    -- gray background
    -- 30% opacity of BLACK
    lcd.color(lcd.RGB(0, 0, 0, 0.3))
    lcd.drawFilledRectangle(x, y, widget.frameX, h)

    lcd.color(conf.colors.white)
    lcd.pen(SOLID)
    lcd.font(FONT_L)
    text_w, text_h = lcd.getTextSize("")
    lcd.drawLine(x, y, x, y + h - 1)

    -- ticks
    local tick_len        = widget.markerL_len

    local scaleMajorTick  = 50                                           -- scale of major tick in meter
    local countMajorTick  = 5                                            -- number of major ticks in areaAltitude
    local divisionMinor   = 5                                            -- number of minor ticks per major tick

    local scaleMinorTick  = scaleMajorTick / divisionMinor               -- scale of minor tick in meter
    local areaAltitude    = scaleMajorTick * countMajorTick              -- scale area in meter
    local scalePxAltitude = h / areaAltitude                             -- pixels per meter
    local pixelMinorTick  = h / (countMajorTick * divisionMinor)         -- pixels per minor tick
    local pointerPxLevel  = pointerY + widget.altitude * scalePxAltitude -- Pixel count where pointer starts
    local countTickTop    = math.floor(areaAltitude / scaleMinorTick * levelY) + 1
    local countTickBottom = math.floor(areaAltitude / scaleMinorTick * (1 - levelY))

    local tickEnd         = math.floor((widget.altitude) / scaleMinorTick + countTickTop)    -- draw ticks above pointer
    local tickStart       = math.floor((widget.altitude) / scaleMinorTick - countTickBottom) -- draw ticks below pointer

    for tickNo = tickStart, tickEnd do
      local tickY = pointerPxLevel - tickNo * scalePxAltitude * scaleMinorTick
      if (tickY >= y + pixelMinorTick) and (tickY < h - pixelMinorTick) then
        if math.fmod(tickNo, divisionMinor) == 0 then -- major tick
          lcd.drawLine(x + 1, tickY, x + tick_len, tickY)
          drawSignColoredNumber(x + (widget.frameX - tick_len) / 2 + tick_len, tickY - text_h / 2,
            tickNo * scaleMinorTick)
        else -- minor tick
          lcd.drawLine(x + 1, tickY, x + tick_len / 2, tickY)
        end
      end
    end
    ------------------------------------------
    -- Altitude value                       --
    ------------------------------------------
    -- Altitude unit
    lcd.drawText(x + widget.frameX + 4, y + widget.frameY / 4, "Alt m")

    -- altitude value frame
    lcd.font(FONT_XXL)
    text_w, text_h = lcd.getTextSize("999")

    lcd.color(conf.colors.black)
    lcd.drawFilledRectangle(x + widget.frameX + widget.dblNumOffset, pointerY - text_h, text_w + 5, 2 * text_h)
    lcd.drawFilledTriangle(widget.frameX, pointerY, x + widget.frameX + widget.dblNumOffset, pointerY - text_h,
      x + widget.frameX + widget.dblNumOffset, pointerY + text_h)

    -- altitude value
    drawSignColoredNumber(x + widget.frameX + widget.dblNumOffset + (text_w / 2), pointerY - text_h / 2, widget.altitude)

    -- altitude min / max
    if widget.showMinMax then
      lcd.color(conf.colors.gray)
      lcd.font(FONT_S)
      local _, text_h2 = lcd.getTextSize("-999")
      lcd.drawNumber(x + widget.frameX + widget.dblNumOffset + (text_w / 2), pointerY - text_h / 2 - text_h2,
        widget.altitudeMax, nil, 0, TEXT_CENTERED)
      lcd.drawNumber(x + widget.frameX + widget.dblNumOffset + (text_w / 2), pointerY + text_h / 2, widget.altitudeMin,
        nil, 0, TEXT_CENTERED)
    end
  end

  -- ********************************************************
  -- * drawVertSpeedScale           paintVario() local  *
  -- ********************************************************
  local function drawVertSpeedScale(widget)
    local w = 30
    local h = widget.zoneHeight
    local x = widget.zoneWidth - 1
    local y = 0

    local pointerY = math.floor(y + h / 2) -- pixel pointer position of the point (default in the middle)
    local levelY = pointerY / h            -- level factor (0..1) of the pointer position (default in the middle = 0.5)

    -- If widget is too narrow, value pointers must be displayed with an offset.
    -- => Value pointer for vertical speed at the top of the widget.
    if widget.zoneWidth < 388 then
      lcd.font(FONT_XXL)
      text_w, text_h = lcd.getTextSize("")
      pointerY = pointerY - text_h / 2 - 2 * widget.noTelFrameT -- set pointer to bottom of widget
      levelY = pointerY / h                                     -- calculate the level factor (~0.2)
    end

    -- gray background
    -- 30% opacity of BLACK
    lcd.color(lcd.RGB(0, 0, 0, 0.3))
    lcd.drawFilledRectangle(x - widget.frameX, y, widget.frameX, h)

    lcd.color(conf.colors.white)
    lcd.pen(SOLID)
    lcd.font(FONT_L)
    text_w, text_h = lcd.getTextSize("-20")
    lcd.drawLine(x, y, x, y + h - 1)

    -- ticks
    local tick_len             = widget.markerR_len

    local scaleMajorTick       = 1                                                  -- scale of major tick in meter/second
    local countMajorTick       = 5                                                  -- number of major ticks in areaAltitude
    local divisionMinor        = 5                                                  -- number of minor ticks per major tick

    local scaleMinorTick       = scaleMajorTick / divisionMinor                     -- scale of minor tick in m/s
    local areaVerticalSpeed    = scaleMajorTick * countMajorTick                    -- scale area in m/s
    local scalePxVerticalSpeed = h / areaVerticalSpeed                              -- pixels per m/s
    local pixelMinorTick       = h / (countMajorTick * divisionMinor)               -- pixels per minor tick
    local pointerPxLevel       = pointerY + widget.vertSpeed * scalePxVerticalSpeed -- pixel count where pointer starts
    local countTickTop         = math.floor(areaVerticalSpeed / scaleMinorTick * levelY) + 1
    local countTickBottom      = math.floor(areaVerticalSpeed / scaleMinorTick * (1 - levelY))

    local tickEnd              = math.floor((widget.vertSpeed) / scaleMinorTick + countTickTop)    -- draw ticks above pointer
    local tickStart            = math.floor((widget.vertSpeed) / scaleMinorTick - countTickBottom) -- draw ticks below pointer

    for tickNo = tickStart, tickEnd do
      local tickY = pointerPxLevel - tickNo * scalePxVerticalSpeed * scaleMinorTick
      if (tickY >= y + pixelMinorTick) and (tickY < h - pixelMinorTick) then
        if math.fmod(tickNo, divisionMinor) == 0 then -- major tick
          lcd.drawLine(x - tick_len, tickY, x - 1, tickY)
          drawSignColoredNumber(x - text_w / 2 - tick_len, tickY - text_h / 2, tickNo * scaleMinorTick)
        else -- minor tick
          lcd.drawLine(x - tick_len / 2 - 1, tickY, x - 1, tickY)
        end
      end
    end

    ------------------------------------------
    -- Vertical Speed value                 --
    ------------------------------------------

    -- vertical speed unit
    lcd.drawText(x - widget.frameX - 4, y + widget.frameY / 4, "m/s", TEXT_RIGHT)

    -- vertical speed value frame
    lcd.font(FONT_XXL)
    text_w, text_h = lcd.getTextSize("99.0")

    lcd.color(conf.colors.black)
    lcd.drawFilledRectangle(x - widget.frameX - widget.dblNumOffset - text_w - 5, pointerY - text_h, text_w + 5,
      2 * text_h)
    lcd.drawFilledTriangle(x - widget.frameX, pointerY, x - widget.frameX - widget.dblNumOffset - 1, pointerY - text_h,
      x - widget.frameX - widget.dblNumOffset - 1, pointerY + text_h)

    -- vertical speed Value
    drawSignColoredNumber(x - widget.frameX - widget.dblNumOffset - (text_w / 2), pointerY - text_h / 2, widget
      .vertSpeed,
      1)

    if widget.showMinMax then
      lcd.color(conf.colors.gray)
      lcd.font(FONT_S)
      local _, text_h2 = lcd.getTextSize("-99.0")
      lcd.drawNumber(x - widget.frameX - widget.dblNumOffset - (text_w / 2), pointerY - text_h / 2 - text_h2,
        widget.vertSpeedMax, nil, 1, TEXT_CENTERED)
      lcd.drawNumber(x - widget.frameX - widget.dblNumOffset - (text_w / 2), pointerY + text_h / 2, widget.vertSpeedMin,
        nil, 1, TEXT_CENTERED)
    end
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
function varLib.paint(widget)
  libs.varLib.CheckEnvironment(widget)
  libs.varLib.readSensors(widget)
  -- force background
  --lcd.color(conf.colors.panelBackground)
  lcd.color(widget.bgcolor)
  lcd.drawFilledRectangle(0, 0, widget.zoneWidth, widget.zoneHeight)

  if widget.screenType ~= "Wrongwgt" then
    if (widget.VarioSensor ~= nil) or (widget.simulation and widget.simulationSource) then
      varLib.paintVario(widget)
    else
      libs.utils.printError(widget, "badSensor")
    end
  else
    libs.utils.printError(widget, "wgtsmall")
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
