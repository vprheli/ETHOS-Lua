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
-- ETHOS battery library
-- File:   : batLib.lua
-- Author  : RNDr.Vladimir Pribyl, CSc. (VPRHELI)
-- History : Date        Version Author   Comment
--           ----------  ------- -------- ------------------------------------
--           15.01.2025  0.0.1   VPRHELI  initial version
--           22.01.2025  0.9.0   VPRHELI  initial version
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

local batLib      = {}
local conf        = nil
local libs        = nil
local batteryData = {}

-- #################################################################### 
-- # batLib.init                                                      #
-- ####################################################################
function batLib.init(param_conf, param_libs)
  --print ("### batLib.init ()")
  conf   = param_conf 
  libs   = param_libs
  
  return batLib
end
-- #################################################################### 
-- #  batLib.CheckEnvironment                                         #
-- #    Read environment varibles                                     #
-- #################################################################### 
function batLib.CheckEnvironment (widget)
  local w, h = lcd.getWindowSize()
 
  if widget.screenHeight == nil or (w ~= widget.zoneWidth and h ~= widget.zoneHeight) then
    -- environment changed
    conf.darkMode = lcd.darkMode() 	
--    local color = lcd.themeColor (THEME_DEFAULT_COLOR)  -- 251723775 cerna /  251681451 bila
--    if color == 251723775 then
--      widget.conf.darkMode = BLACK
--    else
--      widget.conf.darkMode = WHITE
--    end

    local version = system.getVersion()
    widget.screenHeight = version.lcdHeight
    widget.screenWidth  = version.lcdWidth
    conf.simulation     = version.simulation
    
    widget.zoneHeight = h
    widget.zoneWidth  = w
    
    if widget.zoneWidth == 800 and widget.zoneHeight == 480 or widget.zoneWidth == 800 and widget.zoneHeight == 458 then
      widget.screenType = "X20fullScreen"                            -- battery icon 198x350
      widget.batteryIcon = libs.utils.loadBitmap("empty800480.png")
      widget.battW   = 198                                           -- battery large icon Width      ------------------   0    
      widget.battH   = 350                                           -- battery large icon Height     --       30     --
      widget.battX   = 50                                            -- battery X position            ------------------  30
      widget.battY   = (widget.zoneHeight - 350) / 3          -- battery Y position            --              --
      widget.battfdX = 3                                             -- battery fill dX               --      303     --
      widget.battfdY = 30                                            -- battery fill dY               ------------------ 333
      widget.battfW  = 190                                           -- battery fill Width            --       17     --
      widget.battfH  = 303                                           -- battery fill Height           ------------------ 350
    elseif widget.zoneWidth == 784 and widget.zoneHeight == 316 or widget.zoneWidth == 784 and widget.zoneHeight == 294 then
      widget.screenType = "X20fullScreenWithTitle"                   -- battery icon 111x200
      widget.batteryIcon = libs.utils.loadBitmap("empty480320.png")
      widget.battW   = 113                                           -- battery small icon Width      ------------------   0 
      widget.battH   = 200                                           -- battery small icon Height     --      17      --     
      widget.battX   = 50                                            -- battery X position            ------------------  17 
      widget.battY   = (widget.zoneHeight - 200) / 3          -- battery Y position            --              --     
      widget.battfdX = 1                                             -- battery fill dX               --     173      --     
      widget.battfdY = 17                                            -- battery fill dY               ------------------ 190 
      widget.battfW  = 111                                           -- battery fill Width            --      10      --     
      widget.battfH  = 173                                           -- battery fill Height           ------------------ 200 
    elseif widget.zoneWidth == 388 and widget.zoneHeight == 316 or widget.zoneWidth == 388 and widget.zoneHeight == 294 then
      widget.screenType = "X20halfScreen"
      widget.batteryIcon = libs.utils.loadBitmap("empty480320.png")
      widget.battW   = 113                                           -- battery small icon Width      ------------------   0    
      widget.battH   = 200                                           -- battery small icon Height     --      17      --    
      widget.battX   = (widget.zoneWidth - widget.battW - widget.battVwidth) / 3 ------------------  17    
      widget.battY   = (widget.zoneHeight - 200) / 3          -- battery Y position            --              --    
      widget.battfdX = 1                                             -- battery fill dX               --     173      --    
      widget.battfdY = 17                                            -- battery fill dY               ------------------ 190    
      widget.battfW  = 111                                           -- battery fill Width            --      10      --    
      widget.battfH  = 173                                           -- battery fill Height           ------------------ 200    
    elseif widget.zoneWidth == 300 and widget.zoneHeight == 280 or widget.zoneWidth == 300 and widget.zoneHeight == 258 then
      widget.screenType = "X20halfSreenWithSliders"    
      widget.batteryIcon = libs.utils.loadBitmap("empty480320.png")
      widget.battW   = 113                                           -- battery small icon Width      ------------------   0
      widget.battH   = 200                                           -- battery small icon Height     --      17      --
      widget.battX   = (widget.zoneWidth - widget.battW - widget.battVwidth) / 3 ------------------  17
      widget.battY   = (widget.zoneHeight - 200) / 3          -- battery Y position            --              --
      widget.battfdX = 1                                             -- battery fill dX               --     173      --
      widget.battfdY = 17                                            -- battery fill dY               ------------------ 190
      widget.battfW  = 111                                           -- battery fill Width            --      10      --
      widget.battfH  = 173                                           -- battery fill Height           ------------------ 200
    elseif widget.zoneWidth == 256 and widget.zoneHeight == 316 or widget.zoneWidth == 256 and widget.zoneHeight == 294 then
      widget.screenType = "X20thirdScreen"     
      widget.batteryIcon = libs.utils.loadBitmap("empty480320.png")
      widget.battW   = 113                                           -- battery small icon Width      ------------------   0
      widget.battH   = 200                                           -- battery small icon Height     --      17      --
      widget.battX   = (widget.zoneWidth - widget.battW - widget.battVwidth) / 3 ------------------  17
      widget.battY   = (widget.zoneHeight - 200) / 3          -- battery Y position            --              --
      widget.battfdX = 1                                             -- battery fill dX               --     173      --
      widget.battfdY = 17                                            -- battery fill dY               ------------------ 190
      widget.battfW  = 111                                           -- battery fill Width            --      10      --
      widget.battfH  = 173                                           -- battery fill Height           ------------------ 200
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
function batLib.getSourceValue(input)
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
-- #  batLib.getBestVoltage                                           #
-- #    Return either LiPo or VFAS voltage, prefer LiPo               #
-- #################################################################### 
function batLib.getBestVoltage (widget)
  local voltage = nil
  if widget.cellValue ~= nil then
    voltage = widget.cellValue
  elseif widget.voltage ~= nil then
    voltage = widget.voltage
  end
  return voltage
end
-- #################################################################### 
-- #  batLib.readSensors                                              #
-- #################################################################### 
function batLib.readSensors(widget)
  if conf.telemetryState == 1 then
    local sensor = widget.LipoSensor
    -- LiPo
    if sensor ~= nil and sensor:name() == "LiPo" then
      widget.cellsCount = sensor:value ({options=OPTION_CELLS_COUNT})
      -- read voltage of all connected cells
      for i = 1, widget.cellsCount do
        widget.cellsValueArr[i] = sensor:value({options=OPTION_CELL_INDEX(i)})
      end
      widget.cellValue    = sensor:value()
      widget.cellMinValue = sensor:value ({options=OPTION_CELL_LOWEST})
    else
      widget.cellValue    = nil
      widget.cellMinValue = nil
      widget.cellsCount   = nil
    end
 
    -- Voltage sensor
    local sensorV  = widget.VoltageSensor
    --print("#### widget.voltage  : " .. widget.voltage)
    if sensorV ~= nil and sensorV:name() == "VFAS" then
      widget.voltage = sensorV:value()
    else
      widget.voltage = nil
    end
    
    -- Current sensor
    local sensorA = widget.CurrentSensor
    if sensorA ~= nil then
      widget.current = sensorA:value()
      -- calculate current max
      if widget.current > widget.currMax then
        widget.currMax = widget.current
      end
    else
      widget.current = nil
      widget.currMax = 0
    end
    
    -- calculate max values, prepare battery voltage value I prefer LiPo sensor
    voltage = batLib.getBestVoltage (widget)
    -- I have current and voltage, I can calculate Power
    if voltage ~= nil and widget.current ~= nil then
      widget.batPow    = voltage * widget.current
      if widget.batPow > widget.batPowMax then
        widget.batPowMax = widget.batPow
      end
    end
  
   if widget.FlightReset == 1 then
     widget.FlightReset = 0
     widget.batPowMax   = 0
     widget.currMax     = 0     
    --print("#### Flight Reset ####")
  end
    --libs.utils.dumpSensorLiPo (sensor)
  end
end
-- #################################################################### 
-- #  calcCellMin                                                     #
-- #################################################################### 
function batLib.calcCellMin(widget)
  local calMin     = batteryData[101][1]        -- highest value
  local cellsCount = widget.cellsCount
  local calMinIdx  = nil
  local cells4sort = {}
  
  -- cellsCount = 6

  for i = 1, #widget.cellsValueArr do
    cells4sort[i] = widget.cellsValueArr[i]
  end
  table.sort(cells4sort)
  -- return null if all values are same
  if cells4sort[1] == cells4sort[#cells4sort] then
    return nil
  else
    return cells4sort[1]
  end
end
-- #################################################################### 
-- #  paintBattery                                                    #
-- #################################################################### 
function batLib.paintBattery (widget)
  -- ******************************************************** 
  -- * getPercentColor            paintBattery() local  *
  -- ********************************************************
  local function getPercentColor(cpercent)
    -- This function returns green at 100%, red bellow 30% and graduate in between
    if cpercent < 30 then
      return lcd.RGB(0xff, 0, 0)
    else
      g = math.floor(0xdf * cpercent / 100)
      r = 0xdf - g
      return lcd.RGB(r, g, 0)
    end
  end
  -- ********************************************************
  -- * formatNumber               paintBattery() local  *
  -- ********************************************************
  local function formatNumber(value, format)
    return string.format(format, value)
  end
  -- ********************************************************
  -- * drawBatteryVoltage         paintBattery() local  *
  -- ********************************************************
  local function drawBatteryVoltage(widget)
    local x       = widget.battW + 2 * widget.battX
    local y       = widget.battY
    local voltage = widget.cellValue ~= nil and widget.cellValue or widget.voltage

    -- flash yellow voltage if telemetry lost
    if conf.telemetryState == 0 then
      if widget.flash == 0 then
        widget.flash = 1
        lcd.color(YELLOW)
      else
        widget.flash = 0
        lcd.color(RED)
      end
    else
      lcd.color(YELLOW)
    end
    lcd.drawFilledRectangle (x, y, widget.battVwidth, widget.battVheight)
    
    lcd.font(FONT_XXL)
    lcd.color(BLACK)
    -- hold last value even we lose telemetry
    --lcd.drawText(x + widget.battVwidth / 2, y, formatNumber(voltage, "%.1f") .. "V", TEXT_CENTERED)

    if conf.telemetryState == 1 then
      lcd.drawText(x + widget.battVwidth / 2, y, formatNumber(voltage, "%.1f") .. "V", TEXT_CENTERED)
    else
      lcd.drawText(x + widget.battVwidth / 2, y, formatNumber(widget.lastVoltage, "%.1f") .. "V", TEXT_CENTERED)
    end
    return voltage
  end
  -- ********************************************************
  -- * drawBatteryCurrent         paintBattery() local  *
  -- ********************************************************
  local function drawBatteryCurrent(widget)
    if widget.CurrentSensor ~= nil then
      if widget.screenType == "X20fullScreen" or widget.screenType == "X20fullScreenWithTitle" then
        -- xxxxxxxxxxxxxxxx
        -- x  full frame  x  
        -- xxxxxxxxxxxxxxxx
        local x       = widget.battW + 2 * widget.battX + widget.battVwidth + widget.curColOffset
        local y       = widget.battY
        local current = widget.current
        
        lcd.color(BLUE)
        lcd.drawFilledRectangle (x, y, widget.battCFSwidth, widget.battVheight) 
        lcd.font(FONT_XXL)
        lcd.color(WHITE)
        if conf.telemetryState == 1 then
          lcd.drawText(x + widget.battCFSwidth / 2, y, formatNumber(current, "%.1f") .. "A", TEXT_CENTERED)
        else
          lcd.drawText(x + widget.battCFSwidth / 2, y, "---", TEXT_CENTERED)
        end        
        -- these zones has enough room for Power values
        y = y + widget.battVheight + widget.battCelldY
        lcd.font(FONT_STD)
        lcd.drawText(x + widget.battCFSwidth / 2, y, libs.utils.translate("curmax"), TEXT_CENTERED)
        
        if conf.telemetryState == 1 then
          -- draw Current Min / Max
          -- draw Power Min / Max if we have some voltage sensor
          lineStr = string.format("%2.1fA / %2.1fA", widget.current, widget.currMax)
          y = y + widget.battCellH + widget.battCelldY
          lcd.drawText(x + widget.battCFSwidth / 2, y, lineStr, TEXT_CENTERED)
          y = y + widget.battCellH + widget.battCelldY
          lineStr = string.format("%2.0fW / %2.0fW", widget.batPow, widget.batPowMax)
          lcd.drawText(x + widget.battCFSwidth / 2, y, lineStr, TEXT_CENTERED)
        else
          lineStr = "--- / ---"
          y = y + widget.battCellH + widget.battCelldY
          lcd.drawText(x + widget.battCFSwidth / 2, y, lineStr, TEXT_CENTERED)
          y = y + widget.battCellH + widget.battCelldY
          lcd.drawText(x + widget.battCFSwidth / 2, y, lineStr, TEXT_CENTERED)          
        end
      else
        -- draw current values behind the LiPo cells
        local x          = widget.battW + 2 * widget.battX 
        local y          = widget.battY + widget.battVheight + widget.battCelldY
        local current    = widget.current
        local cellsCount = (widget.LipoSensor ~= nil) and widget.cellsCount or 1
        
        if (widget.LipoSensor ~= nil) and (cellsCount <= 5) then
          y = y + cellsCount * (widget.battCellH + widget.battCelldY)
        end       
        
        lcd.color(BLUE)
        lcd.drawFilledRectangle (x, y, widget.battVwidth, widget.battVheight)    
        lcd.font(FONT_XXL)
        lcd.color(WHITE)
        if conf.telemetryState == 1 then
          lcd.drawText(x + widget.battVwidth / 2, y, formatNumber(current, "%.1f") .. "A", TEXT_CENTERED)
        else
          lcd.drawText(x + widget.battVwidth / 2, y, "---", TEXT_CENTERED)
        end
      end
    end
  end
  -- ********************************************************
  -- * drawBatteryPercentage      paintBattery() local  *
  -- ********************************************************
  local function drawBatteryPercentage(widget, percentage)
    local x,y
    x = 125
    x = widget.battX + widget.battW / 2
    y = 430
    y = widget.battY + widget.battH
    lcd.color(WHITE)
    lcd.font(FONT_XL)
    if conf.telemetryState == 1 then    
      lcd.drawText(x, y, formatNumber(percentage, "%.0f") .. "%", TEXT_CENTERED)
      --print ("### batteryPercentage = " .. percentage .. " %")
    else
      lcd.drawText(x, y, "---", TEXT_CENTERED)
    end
  end
  -- ********************************************************
  -- * getBatteryPercentage       paintBattery() local  *
  -- ********************************************************
  local function getBatteryPercentage(voltage, voltageRange, cellCount)
    if conf.telemetryState == 1 then
      for _, entry in ipairs(voltageRange) do
          local voltageEntry = entry[1] * cellCount
          if voltageEntry >= voltage then
              return entry[2]
          end
      end
    end
    return 0
  end
  -- ********************************************************
  -- * drawBatteryCells           paintBattery() local  *
  -- ********************************************************
  local function drawBatteryCells (widget)
    local cellPercent
    local cellColor
    local x, y
    local cellsCount = widget.cellsCount
    x = widget.battW + 2 * widget.battX
    y = widget.battY + widget.battVheight + widget.battCelldY

    -- for debug purpose
--    widget.cellsValueArr[1] = 4.14
--    widget.cellsValueArr[2] = 4.13
--    widget.cellsValueArr[3] = 4.14
--    widget.cellsValueArr[4] = 4.14
--    widget.cellsValueArr[5] = 4.15
--    widget.cellsValueArr[6] = 4.14
--    cellsCount = 6

    -- cells count could be nil when we use wgt without active telemetry or VFAS sensor instead of LiPo
    if cellsCount ~= nil then 
      -- calculate cellMin
      local calMinValue = batLib.calcCellMin(widget)

      lcd.font(FONT_STD)
      for i = 1, cellsCount do
        local markLowest = nil
        
        cellPercent = getBatteryPercentage (widget.cellsValueArr[i], batteryData, 1)
        cellColor   = getPercentColor (cellPercent)
        
        local dY = (i - 1) * (widget.battCellH + widget.battCelldY)
        lcd.color(conf.telemetryState == 1 and cellColor or lcd.RGB(128, 128, 128))
        lcd.drawFilledRectangle(x, y + dY, widget.battCellW, widget.battCellH)
        
        -- mark lowest value 
        --  - not mark if all cells has same value
        --  - mark all cells which has the lowest value (up to #cells-1)
        markLowest = (calMinValue ~= nil and calMinValue == widget.cellsValueArr[i]) and true or false
        
        -- draw cell value
        lcd.color(markLowest and YELLOW or WHITE)
        if conf.telemetryState == 1 then
          lcd.drawText(x + widget.battCellW + 10, y + dY, formatNumber(widget.cellsValueArr[i], "%.02f") .. " V", TEXT_LEFT)
        else
          lcd.color(lcd.RGB(128, 128, 128))
          lcd.drawText(x + widget.battCellW + 10, y + dY, "---", TEXT_LEFT)
        end
        
        -- draw lowest cell(s) frame
        lcd.color(WHITE)
        if markLowest == true and conf.telemetryState == 1 then
          lcd.drawRectangle(x - 4, y + dY - 4, widget.battVwidth + 8, widget.battCellH + 8) 
        end
      end
    end
  end
  -- ********************************************************
  -- * fillBattery                paintBattery() local  *
  -- ********************************************************
  local function fillBattery(widget, percentage)
    local x,y,w,h,color
    x = widget.battX + widget.battfdX
    y = widget.battY + widget.battfdY + (100 - percentage) * 0.01 * widget.battfH
    w = widget.battfW
    h = widget.battfH - (100 - percentage) * 0.01 * widget.battfH
    color = getPercentColor (percentage)
    
    lcd.color(conf.telemetryState == 1 and lcd.color(color) or lcd.color(BLACK))
    lcd.drawFilledRectangle(x, y, w, h)
  end  
  
  -- --------------------------------------------------------------------
  -- batLib.paintBattery() code starts here -----------------------------
  -- --------------------------------------------------------------------

  -- draw battery voltage in the yellow box
  local batteryVoltage = drawBatteryVoltage(widget)
  local cellsCount = widget.cellValue ~= nil and widget.cellsCount or widget.VFAScells
  local batteryPercentage = getBatteryPercentage(batteryVoltage, batteryData, cellsCount)
  drawBatteryPercentage(widget, batteryPercentage)
  
  -- paint current sensor if avialable ane wgt has enough room
  drawBatteryCurrent (widget)
  
  -- fill battery rectangle with percentage color
  fillBattery (widget, batteryPercentage)
  -- draw battery large icon
  lcd.drawBitmap(widget.battX, widget.battY, widget.batteryIcon)  
  
  -- finaly print each cell graphic
  drawBatteryCells (widget)
end

-- #################################################################### 
-- # batLib.paint                                                     #
-- ####################################################################
function batLib.paint (widget)
  libs.batLib.CheckEnvironment (widget)
  libs.batLib.readSensors(widget)
  -- force black background
  lcd.color(BLACK)
  lcd.drawFilledRectangle(0, 0, widget.zoneWidth, widget.zoneHeight)  
  -- telemetry lost => red zone frame
  if conf.telemetryState == 0 then
    lcd.color(RED)
    lcd.drawRectangle(0, 0, widget.zoneWidth, widget.zoneHeight, widget.noTelFrameT)  
  end
    
  if widget.BatType ~= conf.battypeuse then
    if widget.BatType == 0 then
      --print("### LIPO")
      batteryData = {{3.000,  0}, {3.093,  1}, {3.196,  2}, {3.301,  3}, {3.401,  4}, {3.477,  5}, {3.544,  6}, {3.601,  7}, {3.637,  8}, {3.664,  9},
                     {3.679, 10}, {3.683, 11}, {3.689, 12}, {3.692, 13}, {3.705, 14}, {3.710, 15}, {3.713, 16}, {3.715, 17}, {3.720, 18}, {3.731, 19},
                     {3.735, 20}, {3.744, 21}, {3.753, 22}, {3.756, 23}, {3.758, 24}, {3.762, 25}, {3.767, 26}, {3.774, 27}, {3.780, 28}, {3.783, 29},
                     {3.786, 30}, {3.789, 31}, {3.794, 32}, {3.797, 33}, {3.800, 34}, {3.802, 35}, {3.805, 36}, {3.808, 37}, {3.811, 38}, {3.815, 39},
                     {3.818, 40}, {3.822, 41}, {3.825, 42}, {3.829, 43}, {3.833, 44}, {3.836, 45}, {3.840, 46}, {3.843, 47}, {3.847, 48}, {3.850, 49},
                     {3.854, 50}, {3.857, 51}, {3.860, 52}, {3.863, 53}, {3.866, 54}, {3.870, 55}, {3.874, 56}, {3.879, 57}, {3.888, 58}, {3.893, 59},
                     {3.897, 60}, {3.902, 61}, {3.906, 62}, {3.911, 63}, {3.918, 64}, {3.923, 65}, {3.928, 66}, {3.939, 67}, {3.943, 68}, {3.949, 69},
                     {3.955, 70}, {3.961, 71}, {3.968, 72}, {3.974, 73}, {3.981, 74}, {3.987, 75}, {3.994, 76}, {4.001, 77}, {4.007, 78}, {4.014, 79},
                     {4.021, 80}, {4.029, 81}, {4.036, 82}, {4.044, 83}, {4.052, 84}, {4.062, 85}, {4.074, 86}, {4.085, 87}, {4.095, 88}, {4.105, 89},
                     {4.111, 90}, {4.116, 91}, {4.120, 92}, {4.125, 93}, {4.129, 94}, {4.135, 95}, {4.145, 96}, {4.176, 97}, {4.179, 98}, {4.193, 99},
                     {4.2, 100}}
      conf.battypeuse = 0
    elseif widget.BatType == 1 then
      --print("### HV LIPO")
      batteryData = {{3.200,  0}, {3.284,  1}, {3.369,  3}, {3.454,  2}, {3.539,  4}, {3.624,  5}, {3.633,  6}, {3.642,  7}, {3.651,  8}, {3.660,  9},
                     {3.669, 10}, {3.674, 11}, {3.679, 12}, {3.684, 13}, {3.689, 14}, {3.694, 15}, {3.700, 16}, {3.705, 17}, {3.710, 18}, {3.715, 19},
                     {3.720, 20}, {3.722, 21}, {3.725, 22}, {3.727, 23}, {3.729, 24}, {3.732, 25}, {3.734, 26}, {3.737, 27}, {3.740, 28}, {3.743, 29},
                     {3.746, 30}, {3.748, 31}, {3.751, 32}, {3.754, 33}, {3.757, 34}, {3.760, 35}, {3.765, 36}, {3.768, 37}, {3.771, 38}, {3.774, 39},
                     {3.777, 40}, {3.780, 41}, {3.785, 42}, {3.789, 43}, {3.793, 44}, {3.798, 45}, {3.803, 46}, {3.807, 47}, {3.812, 48}, {3.816, 49},
                     {3.821, 50}, {3.829, 51}, {3.834, 52}, {3.840, 53}, {3.845, 54}, {3.850, 55}, {3.860, 56}, {3.865, 57}, {3.870, 58}, {3.875, 59},
                     {3.880, 60}, {3.890, 61}, {3.898, 62}, {3.906, 63}, {3.914, 64}, {3.922, 65}, {3.930, 66}, {3.938, 67}, {3.946, 68}, {3.954, 69},
                     {3.962, 70}, {3.975, 71}, {3.989, 72}, {4.003, 73}, {4.017, 74}, {4.031, 75}, {4.040, 76}, {4.050, 77}, {4.059, 78}, {4.067, 79},
                     {4.075, 80}, {4.085, 81}, {4.096, 82}, {4.107, 83}, {4.118, 84}, {4.129, 85}, {4.140, 86}, {4.151, 87}, {4.162, 88}, {4.173, 89},
                     {4.184, 90}, {4.197, 91}, {4.209, 92}, {4.221, 93}, {4.233, 94}, {4.245, 95}, {4.270, 96}, {4.290, 97}, {4.310, 98}, {4.330, 99}, 
                     {4.350, 100}}
      conf.battypeuse = 1
    elseif widget.BatType == 2 then
      --print("### LION")
      batteryData = {{2.900,  1}, {2.950,  2}, {3.000,  3}, {2.650,  2}, {2.750,  4}, {2.800,  5}, {2.840,  6}, {2.880,  7}, {2.920,  8}, {2.960,  9},
                     {3.000, 10}, {3.150, 11}, {3.156, 12}, {3.162, 13}, {3.167, 14}, {3.173, 15}, {3.178, 16}, {3.184, 17}, {3.189, 18}, {3.195, 19},
                     {3.200, 20}, {3.203, 21}, {3.206, 22}, {3.209, 23}, {3.212, 24}, {3.215, 25}, {3.218, 26}, {3.221, 27}, {3.224, 28}, {3.227, 29},
                     {3.230, 30}, {3.232, 31}, {3.234, 32}, {3.236, 33}, {3.238, 34}, {3.240, 35}, {3.242, 36}, {3.244, 37}, {3.246, 38}, {3.248, 39}, 
                     {3.250, 40}, {3.251, 41}, {3.252, 42}, {3.253, 43}, {3.254, 44}, {3.255, 45}, {3.256, 46}, {3.257, 47}, {3.258, 48}, {3.259, 49},
                     {3.260, 50}, {3.262, 51}, {3.264, 52}, {3.266, 53}, {3.268, 54}, {3.270, 55}, {3.272, 56}, {3.274, 57}, {3.276, 58}, {3.278, 59},
                     {3.280, 60}, {3.282, 61}, {3.284, 62}, {3.286, 63}, {3.288, 64}, {3.290, 65}, {3.292, 66}, {3.294, 67}, {3.296, 68}, {3.298, 69},
                     {3.300, 70}, {3.303, 71}, {3.306, 72}, {3.309, 73}, {3.312, 74}, {3.315, 75}, {3.318, 76}, {3.321, 77}, {3.324, 78}, {3.327, 79},
                     {3.330, 80}, {3.333, 81}, {3.335, 82}, {3.337, 83}, {3.339, 84}, {3.400, 85}, {3.343, 86}, {3.345, 87}, {3.346, 88}, {3.348, 89},
                     {3.350, 90}, {3.354, 91}, {3.357, 92}, {3.360, 93}, {3.364, 94}, {3.367, 95}, {3.370, 96}, {3.374, 97}, {3.377, 98}, {3.380, 99},
                     {3.650, 100}}
      conf.battypeuse = 2
    else
      --print("### LIFE")
      batteryData = {{2.500,  0}, {2.600,  1}, {2.700,  3}, {2.650,  2}, {2.750,  4}, {2.800,  5}, {2.840,  6}, {2.880,  7}, {2.920,  8}, {2.960, 9},
                     {3.000, 10}, {3.150, 11}, {3.156, 12}, {3.162, 13}, {3.167, 14}, {3.173, 15}, {3.178, 16}, {3.184, 17}, {3.189, 18}, {3.195, 19},
                     {3.200, 20}, {3.203, 21}, {3.206, 22}, {3.209, 23}, {3.212, 24}, {3.215, 25}, {3.218, 26}, {3.221, 27}, {3.224, 28}, {3.227, 29},
                     {3.230, 30}, {3.232, 31}, {3.234, 32}, {3.236, 33}, {3.238, 34}, {3.240, 35}, {3.242, 36}, {3.244, 37}, {3.246, 38}, {3.248, 39},
                     {3.250, 40}, {3.251, 41}, {3.252, 42}, {3.253, 43}, {3.254, 44}, {3.255, 45}, {3.256, 46}, {3.257, 47}, {3.258, 48}, {3.259, 49},
                     {3.260, 50}, {3.262, 51}, {3.264, 52}, {3.266, 53}, {3.268, 54}, {3.270, 55}, {3.272, 56}, {3.274, 57}, {3.276, 58}, {3.278, 59}, 
                     {3.280, 60}, {3.282, 61}, {3.284, 62}, {3.286, 63}, {3.288, 64}, {3.290, 65}, {3.292, 66}, {3.294, 67}, {3.296, 68}, {3.298, 69}, 
                     {3.300, 70}, {3.303, 71}, {3.306, 72}, {3.309, 73}, {3.312, 74}, {3.315, 75}, {3.318, 76}, {3.321, 77}, {3.324, 78}, {3.327, 79}, 
                     {3.330, 80}, {3.334, 81}, {3.336, 82}, {3.337, 83}, {3.339, 84}, {3.400, 85}, {3.343, 86}, {3.345, 87}, {3.346, 88}, {3.348, 89},
                     {3.350, 90}, {3.354, 91}, {3.358, 92}, {3.361, 93}, {3.364, 94}, {3.367, 95}, {3.370, 96}, {3.374, 97}, {3.377, 98}, {3.380, 99},
                     {3.650, 100}}
      conf.battypeuse = 3
    end
  end
  
  if widget.screenType ~= "Wrongwgt" then
    -- LiPo Sensor            ID : 0x0300
    -- Voltage Sensor (VFAS)  ID : 0x0210
    -- Current Sensor         ID : 0x0200
--    if widget.LipoSensor == nil then
--      print ("### paint ### widget.LipoSensor     : nil")
--    else
--      print ("### paint ### widget.LipoSensor     : " .. widget.LipoSensor:name())    
--    end
--    if widget.VoltageSensor == nil then
--        print ("### paint ### widget.VoltageSensor  : nil")
--    else
--      print ("### paint ### widget.VoltageSensor  : " .. widget.VoltageSensor:name()) 
--    end
    if (widget.LipoSensor ~= nil) or (widget.VoltageSensor ~= nil) then
      batLib.paintBattery (widget)         
    else
      libs.utils.printError (widget, "badSensor")
    end
  else
    libs.utils.printError (widget, "wgtsmall")
  end
  
  if conf.simulation == true then
    lcd.font(FONT_S)
    lcd.color(widget.color1)
    text_w, text_h = lcd.getTextSize("")
    lcd.drawText(widget.zoneWidth - widget.noTelFrameT, widget.zoneHeight - text_h - widget.noTelFrameT, widget.zoneWidth.."x"..widget.zoneHeight, TEXT_RIGHT)
  end
end

return batLib