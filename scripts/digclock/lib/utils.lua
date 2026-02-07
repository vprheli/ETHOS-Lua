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
-- ETHOS utility library for Vario widget
-- File:   : utils.lua
-- Author  : RNDr.Vladimir Pribyl, CSc. (VPRHELI)
-- History : Date        Version Author   Comment
--           ----------  ------- -------- ------------------------------------
--           23.01.2025  1.0.0   VPRHELI  initial version
--           27.02.2026  1.0.1   VPRHELI  unsupported language fix
-- =============================================================================

local utils   = {}
local conf    = nil
local libs    = nil
local bitmaps = {}

-- ####################################################################
-- # utils.init                                                       #
-- ####################################################################
function utils.init(param_conf, param_libs)
  --print ("### utils.init()")
  conf   = param_conf
  libs   = param_libs
  return utils
end
-- ####################################################################
-- #  utils.translate                                                 #
-- #    Language translate                                            #
-- ####################################################################
function utils.translate(key)
    -- check valid language
    local locale     = conf.locale
    local transtable = conf.transtable

    if transtable[locale] and transtable[locale][key] then
      return transtable[locale][key]
    else
      -- if language is not available, return english text
      return transtable["en"][key]
    end
end
-- ####################################################################
-- #  utils.loadBitmap                                                #
-- ####################################################################
function utils.loadBitmap(filename)
  if bitmaps[filename] == nil then
    bitmaps[filename] = lcd.loadBitmap(conf.basePath .. conf.imgFolder .. filename)
  end
  return bitmaps[filename]
end
-- ####################################################################
-- #  utils.checkTelemetry                                            #
-- ####################################################################
function utils.checkTelemetry()
  local tlm  = system.getSource( { category=CATEGORY_SYSTEM_EVENT, member=SYSTEM_EVENT_TELEMETRY_ACTIVE} )
  conf.telemetryState = (tlm:value() == 100) and 1 or 0
end
-- ####################################################################
-- #  utils.checkFlightReset                                          #
-- ####################################################################
function utils.checkFlightReset(widget)
  local eventFlightReset  = system.getSource( { category=CATEGORY_SYSTEM_EVENT, member=SYSTEM_EVENT_FLIGHT_RESET} )
  if widget.FlightReset == 0 then     -- manual reset
    widget.FlightReset = (eventFlightReset:value() == 100) and 1 or 0
  end
end
-- ####################################################################
-- #  utils.printError                                                #
-- ####################################################################
function utils.printError (widget, message)
  lcd.color(RED)
  lcd.font(FONT_STD)
  lcd.drawText(widget.zoneWidth / 2, widget.zoneHeight / 2 - 10, utils.translate(message), TEXT_CENTERED)
end
-- ####################################################################
-- # utils.dumpResolution                                             #
-- ####################################################################
utils.dumpResolution = function (widget)
  print ("### screen    : " .. widget.screenWidth .. "x".. widget.screenHeight)
  print ("### zone      : " .. widget.zoneWidth .. "x" .. widget.zoneHeight)
  print ("### zone type : " .. widget.screenType)
end

return utils