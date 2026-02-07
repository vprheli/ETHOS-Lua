-- #########################################################################
-- #                                                                       #
-- # License GPLv2: http://www.gnu.org/licenses/gpl-2.0.html               #
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
-- ETHOS ShowAll widget - OpenTx based
-- File:   : main.lua
-- Author  : © RNDr.Vladimir Pribyl, CSc. (VPRHELI)
-- History : Date        Version Author   Comment
--           ----------  ------- -------- ------------------------------------
--           06.02.2025  1.0.0   VPRHELI  initial version
--           15.02.2025  1.0.1   VPRHELI  full X20 HW, X18 support
--           16.02.2025  1.0.2   VPRHELI  Flight mode, TX battery, RSSI
--           17.02.2025  1.0.3   VPRHELI  RSSI new model fix, fill channel sliders, DE translate table
--           04.03.2025  1.0.4   VPRHELI  translate table fix
--           08.08.2025  1.0.5   VPRHELI  Timers count fix
--           27.02.2026  1.0.6   VPRHELI  unsupported language fix
-- =============================================================================
--
-- Comment: Code is optimized for X20/X18 single zone (not full screen)
--                                X10/X12 works on full screen only

-- TODO different channel order in in drawSticks()

-- transmitter hardware
--
-- transmitter   screen  switches   trims   sliders   function buttons    gyro          gps
-- X20          800x480   SA-SH +4    6        5           6              yes
-- X18S         480x320   SA-SH +2   4+2       4           6              yes
-- X14 TWIN     640x360   SA-SF + 2   4        4           4              yes (X14S)
-- X12 HORUS    480x272   SA-SH       6        4           6              yes           yes
-- X10 HORUS    480x272   SA-SH       4        2  

local version    = "v1.0.6"
local tableFile  = assert(loadfile("/scripts/showall/translate.lua"))()
local transtable = tableFile.transtable
-- ========= LOCAL VARIABLES =============
local g_locale      = system.getLocale()
local LSmax         = nil
local idGyroX       = nil
local idGyroY       = nil
local idRSSI        = nil
local idTxBatt      = nil
local arrChannels   = {}
local arrSwitches   = {}
local arrLogics     = {}
local arrTrims      = {}
local arrFunctions  = {}
local arrSliders    = {}
local arrTimers     = {}

local g_rescan_seconds = 5  -- check how often rescan ID (find new LS ....)
local g_paint_period   = 4  -- 4x per second

-- ####################################################################
-- #  translate                                                       #
-- #    Language translate                                            #
-- ####################################################################
local function translate(key)
    -- check valid language
    if transtable[g_locale] and transtable[g_locale][key] then
      return transtable[g_locale][key]
    else
      -- if language is not available, return english text
      return transtable["en"][key]
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
-- *  printMessage                                                    #
-- ####################################################################
local function printMessage (widget, message)
  lcd.color(RED)
  lcd.font(FONT_STD)
  lcd.drawText(widget.zoneWidth / 2, widget.zoneHeight / 2 - 10, translate(message), TEXT_CENTERED)     
end
-- ####################################################################
-- *  GetIDs                                                          #
-- ####################################################################
local function GetIDs (widget)
  local name
  local ID
  -- channels
  for i = 0, 23 do
    arrChannels[i] = system.getSource({category=CATEGORY_CHANNEL, member=i})
    --print("### arrChannels : " .. arrChannels[i]:name() .. "  " .. arrChannels[i]:value())
  end
  -- sliders
  for i = 0, 23 do
    ID = system.getSource({category=CATEGORY_ANALOG, member=i})
    if ID:name() == "---" then
      break
    end
    arrSliders[i] = ID
    --print("### arrSliders : " .. arrSliders[i]:name() .. "  " .. arrSliders[i]:value())
  end
    -- switches SA .. SN
  for i = 0, 16 do
    ID = system.getSource({category=CATEGORY_SWITCH, member=i})
    if ID:name() == "---" then
      break
    end
    arrSwitches[i] = ID
    --print("### arrSwitches : " .. arrSwitches[i]:name() .. "  " .. arrSwitches[i]:value())
  end
    -- trims
  for i = 0, 5 do
    ID = system.getSource({category=CATEGORY_TRIM, member=i})
    if ID:name() == "---" then
      break
    end
    arrTrims[i] = ID
    --print("### arrTrims : " .. arrTrims[i]:name() .. "  " .. arrTrims[i]:value())
  end
    -- logic switches
  LSmax = widget.radio == 20 and 40 or 20
  for i = 0, LSmax do
    ID = system.getSource({category=CATEGORY_LOGIC_SWITCH, member=i})
    if ID:name() == "---" then
      break
    end
    arrLogics[i] = ID
    --print("### arrLogics : " .. arrLogics[i]:name() .. "  " .. arrLogics[i]:value() .. " pocet " .. #arrLogics)
  end
    -- function switches
  for i = 0, 16 do
    ID = system.getSource({category=CATEGORY_FUNCTION_SWITCH, member=i})
    if ID:name() == "---" then
      break
    end
    arrFunctions[i] = ID
    --print("### arrFunctions : " .. arrFunctions[i]:name() .. "  " .. arrFunctions[i]:value())
  end
  -- Timers
  for i = 0, 16 do
    ID = system.getSource({category=CATEGORY_TIMER, member=i})
    if ID:name() == "---" then
      break
    end
    arrTimers[i] = ID
    --print("### arrTimers : " .. arrTimers[i]:name() .. "  " .. arrTimers[i]:value())
  end
  
  -- internal gyro
  idGyroX = system.getSource({category=CATEGORY_GYRO, member=0})
  idGyroY = system.getSource({category=CATEGORY_GYRO, member=1})
  
  -- essential values
  -- RSSI signal
  idRSSI   = system.getSource("RSSI")
  idTxBatt = system.getSource({category=CATEGORY_SYSTEM, member=MAIN_VOLTAGE})

  widget.zoneWidth, widget.zoneHeight = lcd.getWindowSize()
  widget.bIsInitialized = true
end

-- ####################################################################
-- #  create                                                          #
-- #    this function is called whenever the widget is first          #
-- #    initialised.                                                  #
-- #    it's usefull for setting up widget variables or just          #
-- ####################################################################
local function create()
    return {  -- layout
              screenHeight   = nil,
              screenWidth    = nil,
              zoneHeight     = nil,
              zoneWidth      = nil,
              border         = false,
              colorTxt       = lcd.RGB(  0,   0,   0),
              colorLabel     = lcd.RGB(255, 255, 255),
              colorBkg       = lcd.RGB(  0, 192, 192),
              colorChannel   = lcd.RGB(200, 200, 200),
              fontS          = nil,
              fontSTD        = nil,
              textSheight    = nil,
              textSTDheight  = nil,
              -- config
              radio          = nil,
              stickMode      = nil,              
              -- status
              initPending    = true,
              runBgTasks     = false,
              bIsInitialized = false,
              simulation     = nil,
              last_time      = 0,
              last_paint     = 0,
    }
end

-- ####################################################################
-- *  paint                                                           #
-- ####################################################################
local function paint(widget)
  -- ********************************************************
  -- * drawSliders                       paint() local  *
  -- ********************************************************
  local function drawSliders (widget)
    local w       = widget.zoneWidth
    local h       = widget.zoneHeight
    local x       = widget.radio == 20 and 10 or 5
    local markLen = widget.radio == 20 and 20 or 10
    local markCnt = 20
    local h0      = h - 40
    local c0      = math.floor (h / 2)
    local dy      = math.floor (h0 / 40)
    local dx, y
    local cl, cr

    -- slider indexes in the arrSliders[] array
    local sliderLeft  = 9       -- X20
    local sliderRight = 10      -- X20
    
    if widget.radio ~= 20 then  -- X18
      sliderLeft  = 6
      sliderRight = 7
    end
    -- vertical sliders label
    lcd.font(widget.fontS)
    lcd.color(widget.colorLabel)
    -- vertical sliders label
    lcd.drawText (x     + markLen / 2, c0 - markCnt * dy - widget.textSheight, "SL" , TEXT_CENTERED)
    lcd.drawText (w - x - markLen / 2, c0 - markCnt * dy - widget.textSheight, "SR" , TEXT_CENTERED)

    lcd.color(widget.colorTxt)
    -- vertical sliders
    for i = 0, markCnt do
      dx = (i % 20 == 0) and 0 or ( widget.radio == 20 and 4 or 2)
      -- left slider
      lcd.drawLine (x + dx, c0 - i * dy, x + markLen - dx, c0 - i * dy)
      lcd.drawLine (x + dx, c0 + i * dy, x + markLen - dx, c0 + i * dy)
      -- right slider
      lcd.drawLine (w - x - dx, c0 - i * dy, w - x + dx - markLen, c0 - i * dy)
      lcd.drawLine (w - x - dx, c0 + i * dy, w - x + dx - markLen, c0 + i * dy)
    end
    -- slider thumbs
    lcd.color(COLOR_RED)
    local val = arrSliders[sliderLeft]:value()           -- left vertical slider
    local pos = markCnt * dy * val /1024
    lcd.drawFilledRectangle (x, c0 - dy - pos, markLen + 1, 2 * dy + 1)
    if val == 0 then      -- center slider
      lcd.color(COLOR_WHITE)
      lcd.drawLine (x, c0, x + markLen, c0)
    end
    lcd.color(COLOR_RED)
    val = arrSliders[sliderRight]:value()                -- right vertical slider
    pos = markCnt * dy * val /1024
    lcd.drawFilledRectangle (w - x - markLen, c0 - dy - pos, markLen + 1, 2 * dy + 1)
    if val == 0 then      -- center slider
      lcd.color(COLOR_WHITE)
      lcd.drawLine (w - x - markLen, c0, w - x, c0)
    end

    -- horizontal sliders
    dx = math.floor (w / 110)
    cl = markCnt * dx + (widget.radio == 20 and 67 or 35)
    cr = w - cl
    y  = x

    -- horizontal sliders label
    lcd.color(widget.colorLabel)
    lcd.drawText (cl + markCnt * dx + 8, h - y - markLen, "S1" , TEXT_LEFT)
    lcd.drawText (cr - markCnt * dx - 8, h - y - markLen, "S2" , TEXT_RIGHT)

    lcd.color(widget.colorTxt)

    for i = 0, markCnt do
      dy = (i % 20 == 0) and 0 or 4
      -- left slider
      lcd.drawLine (cl - i * dx, h - y - markLen + dy, cl - i * dx, h - y - dy)
      lcd.drawLine (cl + i * dx, h - y - markLen + dy, cl + i * dx, h - y - dy)
      -- right slider
      lcd.drawLine (cr - i * dx, h - y - markLen + dy, cr - i * dx, h - y - dy)
      lcd.drawLine (cr + i * dx, h - y - markLen + dy, cr + i * dx, h - y - dy)
    end
    -- slider thumbs
    lcd.color(COLOR_RED)
    val = arrSliders[4]:value()           -- left horizontal slider S1
    pos = markCnt * dx * val /1024
    lcd.drawFilledRectangle (cl + pos - dx, h - y - markLen, 2 * dx + 1, markLen + 1)
    if val == 0 then      -- center slider
      lcd.color(COLOR_WHITE)
      lcd.drawLine (cl, h - y - markLen, cl, h - y)
    end
    lcd.color(COLOR_RED)
    val = arrSliders[5]:value()           -- right horizontal slider S2
    pos = markCnt * dx * val /1024
    lcd.drawFilledRectangle (cr + pos - dx, h - y - markLen, 2 * dx + 1, markLen + 1)
    if val == 0 then      -- center slider
      lcd.color(COLOR_WHITE)
      lcd.drawLine (cr, h - y - markLen, cr, h - y)
    end

    -- Tandem X20 has additional red slider near function switches
    if widget.radio == 20 then
      -- red slider
      x       = 480
      y       = 134
      markCnt = 8
      markLen = 15
      dy      = math.floor (100 / markCnt)

      lcd.color(widget.colorLabel)
      -- slider label
      lcd.drawText (x + markLen / 2, y - widget.textSheight - 2, "S3" , TEXT_CENTERED)
      lcd.color(widget.colorTxt)
      for i = 0, markCnt do
        dx = (i % 4 == 0) and 0 or 4
        lcd.drawLine(x + dx, y + i * dy, x + markLen - dx, y + i * dy)
      end
      -- red slider thumb
      lcd.color(COLOR_RED)
      val = arrSliders[8]:value()           -- red slider Pot3
      pos = markCnt * dy * val /2048
      lcd.drawFilledRectangle (x, y + 4 * dy - dy / 2- pos, markLen + 2, dy + 1)
      if val == 0 then      -- center slider
        lcd.color(COLOR_WHITE)
        lcd.drawLine (x, y + 4 * dy, x + markLen + 1, y + 4 * dy)
      end
    end    
  end
  -- ********************************************************
  -- * drawVtrim                             paint() local  *
  -- ********************************************************
  local function drawVtrim (widget, id, x, y, label)
    local w        = widget.zoneWidth
    local h        = widget.zoneHeight
    local radius   = (widget.radio == 20 and 8 or 4)
    local markCnt  = 20
    local h0       = h - 40
    local c0       = math.floor (h / 2)
    local dy       = math.floor (h0 / 40)

    -- trim label
    lcd.font(widget.fontS)
    lcd.color(widget.colorLabel)
    lcd.drawText (x, c0 - markCnt * dy - widget.textSheight, label, TEXT_CENTERED)

    lcd.color(widget.colorTxt)
    lcd.drawAnnulusSector(x, c0 - markCnt * dy + radius, radius - 1, radius, -90,  90)
    lcd.drawAnnulusSector(x, c0 + markCnt * dy - radius, radius - 1, radius,  90, 270)
    lcd.drawLine (x - radius, c0 - markCnt * dy + radius, x - radius, c0 + markCnt * dy - radius)
    lcd.drawLine (x + radius, c0 - markCnt * dy + radius, x + radius, c0 + markCnt * dy - radius)
    -- thumbs
    lcd.color(COLOR_RED)
    local val = arrTrims[id]:value()             -- left trim - elevator (MODE 1)
    local pos = markCnt * dy * val /256
    local offset = (widget.radio == 20 and 10 or 6)
    lcd.drawFilledRectangle (x - offset, c0 - dy - pos, 2 * offset + 1, 2 * dy + 1)
    if val == 0 then      -- center slider
      lcd.color(COLOR_WHITE)
      lcd.drawLine (x - 8, c0 - 2, x + 8, c0 - 2)
      lcd.drawLine (x - 8, c0 + 2, x + 8, c0 + 2)
    end    
  end
  -- ********************************************************
  -- * drawHtrim                             paint() local  *
  -- ********************************************************
  local function drawHtrim (widget, id, x, y, label, labelPos)
    local w        = widget.zoneWidth
    local h        = widget.zoneHeight
    local radius   = (widget.radio == 20 and 8 or 4)
    local markCnt  = 20    
    local h0       = h - 40
    local c0       = math.floor (h / 2)
    local dx       = math.floor (w / 110) --math.floor (h0 / 40)

    -- trim label
    lcd.font(widget.fontS)
    lcd.color(widget.colorLabel)
    if labelPos == 0 then
      lcd.drawText (x + 20 * dx + radius, y - radius, label, TEXT_LEFT)
    else
      lcd.drawText (x - 20 * dx - radius, y - radius, label, TEXT_RIGHT)
    end

    lcd.color(widget.colorTxt)
    lcd.drawAnnulusSector(x - 20 * dx + radius, y, radius - 1, radius, 180,   0)
    lcd.drawAnnulusSector(x + 20 * dx - radius, y, radius - 1, radius,   0, 180)
    lcd.drawLine (x - 20 * dx + radius, y + radius, x + 20 * dx - radius, y + radius)
    lcd.drawLine (x - 20 * dx + radius, y - radius, x + 20 * dx - radius, y - radius)
    
    -- thumbs
    local yOff = 45
   
    lcd.color(COLOR_RED)
    local val = arrTrims[id]:value()             -- left trim - rudder (MODE 1)
    local pos = markCnt * dx * val /256
    local offset = (widget.radio == 20 and 10 or 6)    
    lcd.drawFilledRectangle (x - dx + pos, y - offset, 2 * dx + 1, 2 * offset + 1)
    if val == 0 then      -- center slider
      lcd.color(COLOR_WHITE)
      lcd.drawLine (x - 2, y - 8, x - 2, y + 8)
      lcd.drawLine (x + 2, y - 8, x + 2, y + 8)
    end    
  end
  -- ********************************************************
  -- * drawVtrimSmall                    paint() local  *
  -- ********************************************************
  local function drawVtrimSmall (widget, id, x, y, label)
    local w        = widget.zoneWidth
    local h        = widget.zoneHeight
    local radius   = (widget.radio == 20 and 8 or 4)
    local markCnt  = 20
    local h0       = h - (widget.radio == 20 and 140 or math.floor(h / 3))
    local c0       = math.floor (h / 2)
    local dy       = math.floor (h0 / 40)
    local thumb_dY = math.floor ((h - 40) / 40)

    -- trim label
    lcd.font(widget.fontS)
    lcd.color(widget.colorLabel)
    lcd.drawText (x, c0 - markCnt * dy - widget.textSheight, label, TEXT_CENTERED)

    lcd.color(widget.colorTxt)
    lcd.drawAnnulusSector(x, c0 - markCnt * dy + radius, radius - 1, radius, -90,  90)
    lcd.drawAnnulusSector(x, c0 + markCnt * dy - radius, radius - 1, radius,  90, 270)
    lcd.drawLine (x - radius, c0 - markCnt * dy + radius, x - radius, c0 + markCnt * dy - radius)
    lcd.drawLine (x + radius, c0 - markCnt * dy + radius, x + radius, c0 + markCnt * dy - radius)
  
      -- thumbs
    lcd.color(COLOR_RED)
    local val = arrTrims[id]:value()             -- left trim - elevator (MODE 1)
    local pos = markCnt * dy * val /256
    local offset = (widget.radio == 20 and 10 or 6)    
    lcd.drawFilledRectangle (x - offset, c0 - thumb_dY - pos, 2 * offset + 1, 2 * thumb_dY + 1)
    if val == 0 then      -- center slider
      lcd.color(COLOR_WHITE)
      lcd.drawLine (x - 8, c0 - 2, x + 8, c0 - 2)
      lcd.drawLine (x - 8, c0 + 2, x + 8, c0 + 2)
    end    
  end
  -- ********************************************************
  -- * drawTrims                             paint() local  *
  -- ********************************************************
  local function drawTrims (widget)
    local w        = widget.zoneWidth
    local h        = widget.zoneHeight
    local x        = (widget.radio == 20 and 45 or 28)
    local markCnt  = 20
    local h0       = h - 40
    local c0       = math.floor (h / 2)
    local dy       = math.floor (h0 / 40)
    local stOffset = (widget.radio == 20 and 50 or 35)
    drawVtrim (widget, 1,     x, c0, "T3" )         -- left  trim - elevator (MODE 1)
    drawVtrim (widget, 2, w - x, c0, "T2" )         -- right trim - throttle (MODE 1)
    
    drawVtrimSmall (widget, 4, w - x - stOffset,     c0, "T5" )
    drawVtrimSmall (widget, 5, w - x - stOffset / 2, c0, "T6" )
    
    local dx   = math.floor (w / 110)
    local cl   = 20 * dx + (widget.radio == 20 and 67 or 35)
    local cr   = w - cl
    local yOff = (widget.radio == 20 and 45 or 28)

    drawHtrim (widget, 0, cl, h - yOff, "T4", 0)
    drawHtrim (widget, 3, cr, h - yOff, "T1", 1)
  end
  -- ********************************************************
  -- * drawSwitchSymbol                      paint() local  *
  -- ********************************************************
  local function drawSwitchSymbol (x, y, val)
    lcd.color(widget.colorTxt)
    if val == 0 then
      lcd.drawText (x, y, "-" , TEXT_LEFT)
    elseif val > 0 then
      lcd.drawText (x, y, "↓" , TEXT_LEFT)
    else
      lcd.drawText (x, y, "↑" , TEXT_LEFT)
    end
  end
  -- ********************************************************
  -- * drawSwitches                          paint() local  *
  -- ********************************************************
  local function drawSwitches (widget, x, y)
    -- Switches
    local x0 = x
    local y0 = y
    local name

    lcd.font(widget.fontS)
    lcd.color(widget.colorTxt)
    text_w, text_h = lcd.getTextSize("SA")      
    for i = 0, #arrSwitches do
      if i > 0 and  i % 5 == 0 then
        x0 = x0 + 2 * text_w
        x = x0
        y = y0
      end
      name = string.format("S%s", string.char(65 + i))     -- user can rename switches
      lcd.drawText (x, y, name, TEXT_LEFT)
      drawSwitchSymbol (x + text_w + 4, y + 2, arrSwitches[i]:value())
      y = y + widget.textSheight
    end
  end
  -- ********************************************************
  -- * drawFuncBtn                           paint() local  *
  -- ********************************************************
  local function drawFuncBtn (widget, x,  y)
    local swArr = {}
    if widget.radio == 20 then
      swArr = {{-30, -30}, {-20, 0}, {-30, 30}, {30, -30}, {20, 0}, {30, 30}}
    else
      swArr = {{-20, -20}, {-10, 0}, {-20, 20}, {20, -20}, {10, 0}, {20, 20}}      
    end
    for i, v in ipairs(swArr) do
      lcd.color(widget.colorTxt)
      lcd.drawCircle(x + v[1], y + v[2], 6)
      if arrFunctions[i - 1]:value() > 0 then
        lcd.color(COLOR_BLUE)
        lcd.drawFilledCircle(x + v[1], y + v[2], 4)
      end
    end
  end
  -- ********************************************************
  -- * drawModelName                         paint() local  *
  -- ********************************************************
  local function drawModelName (widget, x, y)
    lcd.font(FONT_L_BOLD)
    lcd.color(widget.colorTxt)
    lcd.drawText (x, y, widget.modelName, TEXT_LEFT)
  end
  -- ********************************************************
  -- * drawSticks                            paint() local  *
  -- ********************************************************
  local function drawSticks (widget, x, y)
    local stickShortArr = {"A", "E", "T", "R"}
    local offset = (widget.radio == 20 and 20 or 15)
    lcd.font(widget.fontS)
    lcd.color(widget.colorTxt)
    for i = 1, #stickShortArr do
      lcd.drawText (x,          y - 5, stickShortArr[i] .. ":")
      lcd.drawText (x + offset, y - 5, math.floor (0.5 + arrChannels[i - 1]:value() / 10.24))
      y = y + widget.textSheight
    end
  end
  -- ********************************************************
  -- * drawChans                             paint() local  *
  -- ********************************************************
  local function drawChans (widget, x, y)
    local yTxtOff = -2
    local wBar
    local wRect  = (widget.radio == 20 and 72 or 40)
    local hRect  = (widget.radio == 20 and 10 or 6)
    local y0     = y
    local offset

    lcd.font(FONT_XS)
    for i = 1, 24 do
      if i > 1 and (i - 1) % 8 == 0 then
        x = x + (widget.radio == 20 and 110 or 80)
        y = y0
      end
      -- label
      if i % 2 ~= 0 then
        lcd.drawText (x -  3, y + yTxtOff, i, TEXT_RIGHT)
      end
      if i % 2 == 0 then
        offset = (widget.radio == 20 and 74 or 44)
        lcd.drawText (x + offset, y + yTxtOff, i, TEXT_LEFT)
      end
      -- bar outline
      lcd.drawRectangle (x, y, wRect, hRect)
      local val = (arrChannels[i - 1]:value() + 1024)/2048
      wBar = 4
      if val < 0 then
        val  = 0
      elseif val > 1 then
        val = 1
      else
        wBar = 2
      end
      local xBar = val * wRect - wBar / 2
      -- fill slider
      lcd.color(widget.colorChannel)
      lcd.drawFilledRectangle (x + 1, y + 1, xBar, hRect - 2)
      if val == 0.5 then
        lcd.color(COLOR_RED)
      else
        lcd.color(COLOR_BLACK)
      end
      lcd.drawFilledRectangle (x + xBar, y, wBar, hRect)
      lcd.color(COLOR_BLACK)
      y = y + (widget.radio == 20 and 13 or 9)
    end
  end
  -- ********************************************************
  -- * drawLS                                paint() local  *
  -- ********************************************************
	local function drawLS (widget, x,  y)
    local x0      = x
    local w       = (widget.radio == 20 and 10 or 8)
    local h       = (widget.radio == 20 and 10 or 8)
    local dX      = (widget.radio == 20 and 12 or 10)
    local dY      = (widget.radio == 20 and 13 or 11)
    local lsCount = (widget.radio == 20 and 30 or 20)    
    local i       = 0
    local v

    lcd.font(widget.fontS)
    while i < LSmax do
      if arrLogics[i] ~= nil then
        v = arrLogics[i]:value()
      else
        v = false
      end
      if v == false then
        -- undefined
        lcd.drawFilledRectangle(x+w/2-2, y+h/2-1, 3, 3)
      elseif v > 0 then
        -- defined and true
        lcd.drawFilledRectangle(x, y, w, h)
      else
        -- anything else
        lcd.drawRectangle(x, y, w, h)
      end

      i = i + 1
      if i%10 == 0 then
        x = x0
        y = y + dY
      elseif i%5 == 0 then
        x = x + dX + 3
      else
        x = x + dX
      end
    end
    lcd.drawText (x, y-2, "LS 01-"..LSmax, TEXT_LEFT)
  end
  -- ********************************************************
  -- * hms                                   paint() local  *
  -- ********************************************************
  local function hms (n)
    local stSign
    if n < 0 then
      stSign = "-"
      n = -n
    else
      stSign = " "
    end

    local hh = math.floor (n/3600)
    n = n % 3600
    local mm = math.floor (n/60)
    local ss = math.floor (n % 60)

    local function fmt (v)
      return #(v .. "") >=2 and v or ("0" ..v)
    end
    return stSign .. fmt(hh) .. ':' .. fmt(mm) .. ':' .. fmt(ss)
  end
  -- ********************************************************
  -- * drawTimers                        paint() local  *
  -- ********************************************************
  local function drawTimers (widget, x, y)
    local offset = (widget.radio == 20 and 22 or 17)
    lcd.font(widget.fontSTD)
    for i = 0, #arrTimers do
      local t = arrTimers[i]:value()
      lcd.drawText (x,        y, "t" .. (i+1) ..":")
      lcd.drawText (x+offset, y, hms (t))
      y = y + widget.textSTDheight + 2
    end
  end
  -- ********************************************************
  -- * drawGyro                          paint() local  *
  -- ********************************************************  
  local function drawGyro (widget, x, y)
    lcd.font(widget.fontS)
    lcd.color(widget.colorTxt)
    text_w, text_h = lcd.getTextSize("gyro ")
    
    lcd.drawText (x, y, "gyro ")
    lcd.drawText (x + text_w + 10, y,              "X: " .. idGyroX:value())
    lcd.drawText (x + text_w + 10, y +     text_h, "Y: " .. idGyroY:value())
  end
  -- ********************************************************
  -- * drawEssentials                    paint() local  *
  -- ********************************************************  
  local function drawEssentials (widget, x, y)
    local value
    local offset = (widget.radio == 20 and 80 or 40)
    
    -- Draw Tx voltage
    lcd.font(widget.fontS)    
    lcd.drawText   (x, y, "TxBatt : ", TEXT_RIGHT)
    lcd.drawNumber (x, y, idTxBatt:value(), idTxBatt:unit(), 1, TEXT_LEFT)

    -- draw RSSI
    if idRSSI ~= nil then
      value = idRSSI:value()
    end
    if value == nil then
      value = "---"
    end
    lcd.drawText   (x, y + widget.textSheight, "RSSI : ", TEXT_RIGHT)
    lcd.drawText   (x, y + widget.textSheight, value, TEXT_LEFT)
    
    -- draw flight mode
    --local currentFMval = system.getSource({category = CATEGORY_FLIGHT, member = CURRENT_FLIGHT_MODE}):value()     -- 0 nebo 1
    flightMode = system.getSource({category = CATEGORY_FLIGHT, member = FLIGHT_CURRENT_MODE}):stringValue()
    lcd.drawText (x, y + 2 * widget.textSheight, flightMode, TEXT_CENTERED)        

  end

  --print ("### paint")
  if lcd.isVisible() and widget.bIsInitialized == true then
    local runScript = false
    if widget.radio == 0 then
      printMessage (widget, "nohwsup")
    end
    if widget.radio == 20 then  -- 800x480
      if widget.zoneWidth < 784 then
        printMessage (widget, "wgtsmall")
      else
        Xmode   =  67
        Ymode   =   5
        Xswitch =  67
        Yswitch =  36
        Xfunc   = 286
        Yfunc   =  75
        Xstick  = Xswitch
        Ystick  = 135
        Xchan   = 140
        Ychan   = Ystick
        XLS     = 540
        YLS     =  39
        Xtim    = XLS
        Ytim    = 125
        Xgyr    = XLS
        Ygyr    = 210
        Xess    = 420
        Yess    =  36
        widget.fontS   = FONT_S
        widget.fontSTD = FONT_STD
        lcd.font(FONT_S)
        text_w, widget.textSheight = lcd.getTextSize("")
        lcd.font(FONT_STD)
        text_w, widget.textSTDheight = lcd.getTextSize("")
        
        runScript = true
      end
    elseif widget.radio == 18 then    -- 480x320
      if widget.zoneWidth < 472 or widget.zoneHeight < 210 then
        printMessage (widget, "wgtsmall")
      else      
        Xmode   =  40
        Ymode   =   5
        Xswitch =  Xmode
        Yswitch =  24
        Xfunc   = 150
        Yfunc   =  55
        Xstick  = Xswitch
        Ystick  = 100
        Xchan   =  90
        Ychan   = Ystick
        XLS     = 295
        YLS     = Yswitch
        Xtim    = 310
        Ytim    = Ystick
        Xgyr    = XLS
        Ygyr    = 60
        Xess    = 240
        Yess    = Yswitch
        widget.fontS   = FONT_XS
        widget.fontSTD = FONT_STD      
        lcd.font(FONT_XS)
        text_w, widget.textSheight = lcd.getTextSize("")
        lcd.font(FONT_S)
        text_w, widget.textSTDheight = lcd.getTextSize("")
        
        runScript = true 
      end
    else                              -- 480x272
      if widget.zoneWidth ~= 480 and widget.zoneHeight ~= 272  then
        printMessage (widget, "wgtsmall")
      else
        Xmode   =  40
        Ymode   =   5
        Xswitch =  Xmode
        Yswitch =  24
        Xfunc   = 150
        Yfunc   =  55
        Xstick  = Xswitch
        Ystick  = 100
        Xchan   = 50
        Ychan   = 155
        XLS     = 290
        YLS     = 50
        Xtim    = 310
        Ytim    = Ychan
        Xgyr    = XLS
        Ygyr    = 85
        Xess    = 160
        Yess    = YLS
        widget.fontS   = FONT_XS
        widget.fontSTD = FONT_STD      
        lcd.font(FONT_XS)
        text_w, widget.textSheight = lcd.getTextSize("")
        lcd.font(FONT_S)
        text_w, widget.textSTDheight = lcd.getTextSize("")        
        runScript = true 
      end
    end    
    if runScript == true then
      lcd.color(widget.colorBkg)
      lcd.drawFilledRectangle(0, 0, widget.zoneWidth, widget.zoneHeight)


      drawSliders   (widget)
      drawTrims     (widget)
      drawModelName (widget,  Xmode,   Ymode)
      drawSwitches  (widget,  Xswitch,  Yswitch)
      if widget.radio == 20 or widget.radio == 18 then
        drawFuncBtn    (widget, Xfunc,  Yfunc)
      end
      drawSticks     (widget, Xstick, Ystick)
      drawChans      (widget, Xchan,  Ychan)
      drawLS         (widget, XLS,    YLS)
      drawTimers     (widget, Xtim,   Ytim)
      drawGyro       (widget, Xgyr,   Ygyr)
      drawEssentials (widget, Xess,   Yess)    
    end
  end
end

-- ####################################################################
-- # wakeup                                                           #
-- #    this is the main loop that ethos calls every couple of ms     #
-- ####################################################################
local function wakeup(widget)
  local actual_time = os.clock()  -- actual time 
  if widget.initPending == true then
    -- TODO if necesssary
    widget.modelName    = model.name()
    local version       = system.getVersion()
    widget.screenHeight = version.lcdHeight
    widget.screenWidth  = version.lcdWidth
    widget.simulation   = version.simulation
    widget.stickMode    = system.getStickMode()
    
    -- detect transmitter
    local board = version.board
    if string.find(board,"20") then
      widget.radio = 20
    elseif string.find(board,"18") then
      widget.radio = 18
--    elseif string.find(board,"14") then     -- not supported yet
--      widget.radio = 14
    elseif string.find(board,"12") then
      widget.radio = 12
    elseif string.find(board,"10") then
      widget.radio = 10
    else
      widget.radio = 0        -- unsupported radio
    end
    
    widget.runBgTasks   = true
    widget.initPending  = false

    GetIDs (widget)
  end
  if widget.runBgTasks == true then
    if lcd.isVisible() then
      if actual_time > widget.last_time then
        widget.last_time = actual_time + g_rescan_seconds   -- new time for ID refresh
        GetIDs (widget)
      end
      if actual_time > widget.last_paint then
        last_paint = actual_time + 1 / g_paint_period
        lcd.invalidate ()
      end
    end
  end
end
-- ####################################################################
-- # configure                                                        #
-- #    Widget Configuration options                                  #
-- ####################################################################
local function configure(widget)
    -- Text color
    line = form.addLine(translate("frontColor"))
    form.addColorField(line, nil, function() return widget.colorTxt end, function(color) widget.colorTxt = color end)

    -- Label color
    line = form.addLine(translate("labelColor"))
    form.addColorField(line, nil, function() return widget.colorLabel end, function(color) widget.colorLabel = color end)

    -- Background color
    line = form.addLine(translate("backColor"))
    form.addColorField(line, nil, function() return widget.colorBkg end, function(color) widget.colorBkg = color end)
    
    -- Channel slider color
    line = form.addLine(translate("channelColor"))
    form.addColorField(line, nil, function() return widget.colorChannel end, function(color) widget.colorChannel = color end)
end
-- ####################################################################
-- # read                                                             #
-- #    read values from internal storage                             #
-- ####################################################################
local function read(widget)
  widget.colorTxt     = storage.read("colorTxt")
  widget.colorBkg     = storage.read("colorBkg")
  widget.colorLabel   = storage.read("colorLabel")
  widget.colorChannel = storage.read("colorChannel")
end
-- ####################################################################
-- # write                                                            #
-- #    write values to internal storage                              #
-- ####################################################################
local function write(widget)
	storage.write("colorTxt",     widget.colorTxt)
	storage.write("colorBkg",     widget.colorBkg)
	storage.write("colorLabel",   widget.colorLabel)
	storage.write("colorChannel", widget.colorChannel)
end
-- ####################################################################
-- # init                                                             #
-- #    this is where we 'setup' the widget                           #
-- ####################################################################
local function init()
    system.registerWidget(
      { key        = "showall",
        name       = name,
        create     = create,
        paint      = paint,
        wakeup     = wakeup,
        configure  = configure,
        read       = read,
        write      = write,
        persistent = false}
      )
end

return {init=init}
