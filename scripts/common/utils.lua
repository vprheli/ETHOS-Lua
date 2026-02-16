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
--           27.01.2025  1.0.0   VPRHELI  minor changes
--           11.03.2025  1.0.1   VPRHELI  sin() and cos()
--           10.05.2025  1.0.2   VPRHELI  iNAV Flight Mode
--           07.02.2026  1.0.3   VPRHELI  unsupported language fix
--           08.02.2026  1.0.4   VPRHELI  zone detection
-- =============================================================================

local utils   = {}
local conf    = nil
local libs    = nil
local bitmaps = {}
local sinus =   {[0]=0.0000,0.0175,0.0349,0.0523,0.0698,0.0872,0.1045,0.1219,0.1392,0.1564,
                     0.1736,0.1908,0.2079,0.2250,0.2419,0.2588,0.2756,0.2924,0.3090,0.3256,
                     0.3420,0.3584,0.3746,0.3907,0.4067,0.4226,0.4384,0.4540,0.4695,0.4848,
                     0.5000,0.5150,0.5299,0.5446,0.5592,0.5736,0.5878,0.6018,0.6157,0.6293,
                     0.6428,0.6561,0.6691,0.6820,0.6947,0.7071,0.7193,0.7314,0.7431,0.7547,
                     0.7660,0.7771,0.7880,0.7986,0.8090,0.8192,0.8290,0.8387,0.8480,0.8572,
                     0.8660,0.8746,0.8829,0.8910,0.8988,0.9063,0.9135,0.9205,0.9272,0.9336,
                     0.9397,0.9455,0.9511,0.9563,0.9613,0.9659,0.9703,0.9744,0.9781,0.9816,
                     0.9848,0.9877,0.9903,0.9925,0.9945,0.9962,0.9976,0.9986,0.9994,0.9998,1.0000}
local cosinus = {[0]=1.0000,0.9998,0.9994,0.9986,0.9976,0.9962,0.9945,0.9925,0.9903,0.9877,
                     0.9848,0.9816,0.9781,0.9744,0.9703,0.9659,0.9613,0.9563,0.9511,0.9455,
                     0.9397,0.9336,0.9272,0.9205,0.9135,0.9063,0.8988,0.8910,0.8829,0.8746,
                     0.8660,0.8572,0.8480,0.8387,0.8290,0.8192,0.8090,0.7986,0.7880,0.7771,
                     0.7660,0.7547,0.7431,0.7314,0.7193,0.7071,0.6947,0.6820,0.6691,0.6561,
                     0.6428,0.6293,0.6157,0.6018,0.5878,0.5736,0.5592,0.5446,0.5299,0.5150,
                     0.5000,0.4848,0.4695,0.4540,0.4384,0.4226,0.4067,0.3907,0.3746,0.3584,
                     0.3420,0.3256,0.3090,0.2924,0.2756,0.2588,0.2419,0.2250,0.2079,0.1908,
                     0.1736,0.1564,0.1392,0.1219,0.1045,0.0872,0.0698,0.0523,0.0349,0.0175,0.0000}

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
-- #  utils.GetZoneID                                                 #
-- #    Get best ZoneID for painting procedure                        #
-- ####################################################################
function utils.GetZoneID (widget)
  local w, h = lcd.getWindowSize()
  local zoneChange = false

  if (w ~= widget.zoneWidth or h ~= widget.zoneHeight) then  
    widget.zoneHeight = h
    widget.zoneWidth  = w
    widget.zoneID     = 0

--    print("")
--    print("### key " .. utils.translate ("wgname") .. " ###")
--    print("### zoneWidtht       " .. w)
--    print("### zoneHeight       " .. h)
    
    for i = 1, #widget.zoneMatrix do
--      print("### (" .. i ..") matrixWidth  " .. widget.zoneMatrix[i][0])
--      print("### (" .. i ..") matrixHeight " .. widget.zoneMatrix[i][1])

      if widget.zoneMatrix[i][0] <= widget.zoneWidth and widget.zoneMatrix[i][1]<= widget.zoneHeight then
--        print("### use zoneID " .. i)
        widget.zoneID = i
        break
      end
--      print("###")
    end
    zoneChange = true
    --print ("### GetZoneID " .. widget.zoneWidth .. "x" .. widget.zoneHeight .. " zoneID = " .. widget.zoneID)
  end
  return zoneChange
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
-- #  utils.checkTransmitter                                          #
-- ####################################################################
function utils.checkTransmitter (board)
  local transmitter
  if string.find(board,"20") then
    transmitter = 20
  elseif string.find(board,"18") then
    transmitter = 18
  elseif string.find(board,"14") then
    transmitter = 14
  elseif string.find(board,"12") then
    transmitter = 12
  elseif string.find(board,"10") then
    transmitter = 10
  else
    transmitter = 0        -- unsupported radio
  end
  --print("#### My transmitter is : " .. transmitter)
  return transmitter
end
-- #################################################################### 
-- # utils.sin                                                        #
-- ####################################################################
function utils.sin(x)
  local valsin
    if (x > 180) then
    x = x - 360
  end

  if (x > 90) then                      -- <90..180>
    valsin = sinus[math.floor(180-x)]
  elseif (x >= 0) then                  -- <0..90>
    valsin = sinus[math.floor(x)]
  elseif (x < -90) then                 -- <-180..-90>
    valsin = sinus[math.floor(math.abs(-180-x))] * -1
  else                                  -- <-90..0>
    valsin = sinus[math.floor(math.abs(x))] * -1
  end
  return valsin
end
-- #################################################################### 
-- # utils.cos                                                        #
-- ####################################################################
function utils.cos(x)
  local valcos
  if (x > 180) then
    x = x - 360
  end
  
  if (x > 90) then                      -- <90..180>
    valcos = cosinus[math.floor(180-x)] * -1
  elseif (x >= 0) then                  -- <0..90>
    valcos = cosinus[math.floor(x)]
  elseif (x < -90) then                 -- <-180..-90>
    valcos = cosinus[math.floor(math.abs(-180-x))] * -1
  else                                  -- <-90..0>
    valcos = cosinus[math.floor(math.abs(x))]
  end
  return valcos
end
-- #################################################################### 
-- #  utils.getSourceValue()                                          # 
-- #################################################################### 
function utils.getSourceValue(input)
  if input == nil then
    return 0
  end
  local value = 0  
  if input:state() then
    value = input:value()
  end
  return value
end
-- #################################################################### 
-- #  utils.iNavDecodeFmode                                           #
-- ####################################################################
function utils.iNavDecodeFmode(sensorId, decodedMode)
  local fm = 0
  if sensorId ~= nil then
    fm = utils.getSourceValue(sensorId)
    if fm ~= nil then
      local temp = math.floor(math.fmod(fm / 10000, 10))      
      decodedMode["flaperon"] = (temp & 1)
      decodedMode["autotune"] = (temp & 2) >> 1
      decodedMode["failsafe"] = (temp & 4) >> 2
      temp = math.floor(math.fmod(fm / 1000, 10))  
      decodedMode["gohome"]   = (temp & 1)
      decodedMode["waypoint"] = (temp & 2) >> 1
      decodedMode["headfree"] = (temp & 4) >> 2
      temp = math.floor(math.fmod(fm / 100, 10))        
      decodedMode["headhold"] = (temp & 1)
      decodedMode["althold"]  = (temp & 2) >> 1
      decodedMode["poshold"]  = (temp & 4) >> 2
      temp = math.floor(math.fmod(fm / 10, 10))        
      decodedMode["angle"]    = (temp & 1)
      decodedMode["horizon"]  = (temp & 2) >> 1
      decodedMode["manual"]   = (temp & 4) >> 2
      temp = math.floor(math.fmod(fm, 10))        
      decodedMode["ok2arm"]   = (temp & 1)
      decodedMode["armprev"]  = (temp & 2) >> 1
      decodedMode["armed"]    = (temp & 4) >> 2
    end
  end -- Flight Mode
  return fm
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
  --print ("### zone type : " .. widget.screenType)
end
-- #################################################################### 
-- # utils.dumpSensorLiPo                                             #
-- #################################################################### 
utils.dumpSensorLiPo = function (sensor)
  print ("### name     = " .. sensor:name())
  if sensor ~= nil and sensor:name() == "LiPo" then
    print ("### value    = " .. sensor:value() .. sensor:stringUnit())
    print ("### numCells = " .. sensor:value ({options=OPTION_CELLS_COUNT}))
    for i = 1, wgt.telemetry.cellsCount do
      print ("### cell[" .. i .. "]  = " .. sensor:value({options=OPTION_CELL_INDEX(i)}))
    end
  end
end

return utils