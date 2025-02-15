-- #########################################################################
-- #                                                                       #
-- # License GPLv2: http://www.gnu.org/licenses/gpl-2.0.html               #
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
-- ETHOS ShowAll widget - OpenTx based
-- File:   : main.lua
-- Author  : © RNDr.Vladimir Pribyl, CSc. (VPRHELI)
-- History : Date        Version Author   Comment
--           ----------  ------- -------- ------------------------------------
--           06.02.2025  1.0.0   VPRHELI  initial version
--           15.02.2025  1.0.1   VPRHELI  full Xěé HW, X18 support
-- =============================================================================
-- 2025-01-18 by RNDr.Vladimir Pribyl
--
-- TODO different stick MODE
--      letove mody

-- transmitter hardware
--
-- transmitter   screen  switches   trims   sliders   function buttons    gyro          gps
-- X20          800x480   SA-SH +4    6        5           6              yes
-- X18          800x480   SA-SH +2   4+2       4           6              yes
-- X14 TWIN     640x480   SA-SF + 2   4        4           4              yes (X14S)
-- X12 HORUS    480x272   SA-SH       6        4           6              yes           yes
-- X10 HORUS    480x272   SA-SH       4        2  

local version           = "v1.0.1"
local transtable        = { en = { wgname          = "Showall",
                                   frontColor      = "Select front color",
                                   backColor       = "Select background color",
                                   labelColor      = "Select label color",
                                   wgtsmall        = "Small Widget",
                                   nohwsup         = "Unsupported radio",
                                 },
                            cz = {
                                   wgname          = "Showall",
                                   frontColor      = "Vyberte barvu textu a grafiky",
                                   backColor       = "Vyberte barvu pozadí",
                                   labelColor      = "Vyberta barvu popisek",
                                   wgtsmall        = "Málo místa",
                                   nohwsup         = "Nepodporované rádio",
                                 }
                          }
-- ========= LOCAL VARIABLES =============
local g_locale      = system.getLocale()
local idGyroX       = nil
local idGyroY       = nil
local arrChannels   = {}
local arrSwitches   = {}
local arrLogics     = {}
local arrTrims      = {}
local arrFunctions  = {}
local arrSliders    = {}
local arrTimers     = {}

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
  for i = 0, 2 do
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
              colorLabel     = lcd.RGB(128, 128, 128),
              colorBkg       = lcd.RGB(  0, 192, 192),
              textSheight    = nil,
              textSTDheight  = nil,
              -- config
              radio          = nil,
              stickMode      = nil,              
              -- status
              initPending    = true,
              runBgTasks     = false,
              simulation     = nil,
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
    local w, h    = lcd.getWindowSize()
    local x       = 10
    local markLen = 20
    local markCnt = 20
    local h0      = h - 40
    local c0      = math.floor (h / 2)
    local dy      = math.floor (h0 / 40)
    local dx, y
    local cl, cr

    local sliderLeft   = 9      -- X20
    local sliderRight = 10      -- X20
    
    if widget.radio == 18 then  -- X18
      sliderLeft  = 6
      sliderRight = 7
    end
    -- vertical sliders label
    lcd.font(FONT_S)
    lcd.color(widget.colorLabel)
    -- horizontal sliders label
    lcd.drawText (x     + markLen / 2, c0 - markCnt * dy - widget.textSheight, "SL" , TEXT_CENTERED)
    lcd.drawText (w - x - markLen / 2, c0 - markCnt * dy - widget.textSheight, "SR" , TEXT_CENTERED)

    lcd.color(widget.colorTxt)
    -- vertical sliders
    for i = 0, markCnt do
      dx = (i % 20 == 0) and 0 or 4
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
    dx = dy
    cl = 67 + markCnt * dx
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
    local w, h     = lcd.getWindowSize()
    local radius   = 8
    local markCnt  = 20
    local h0       = h - 40
    local c0       = math.floor (h / 2)
    local dy       = math.floor (h0 / 40)

    -- trim label
    lcd.font(FONT_S)
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
    lcd.drawFilledRectangle (x - 10, c0 - dy - pos, 21, 2 * dy + 1)
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
    local w, h     = lcd.getWindowSize()
    local radius   = 8
    local markCnt  = 20    
    local h0       = h - 40
    local c0       = math.floor (h / 2)
    local dx       = math.floor (h0 / 40)

    -- trim label
    lcd.font(FONT_S)
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
    lcd.drawFilledRectangle (x - dx + pos, y - 10, 2 * dx + 1, 21)
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
    local w, h     = lcd.getWindowSize()
    local radius   = 8
    local markCnt  = 20
    local h0       = h - 140
    local c0       = math.floor (h / 2)
    local dy       = math.floor (h0 / 40)
    local thumb_dY = math.floor ((h - 40) / 40)

    -- trim label
    lcd.font(FONT_S)
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
    lcd.drawFilledRectangle (x - 10, c0 - thumb_dY - pos, 21, 2 * thumb_dY + 1)
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
    local w, h     = lcd.getWindowSize()
    local x        = 45
    local markCnt  = 20
    local h0       = h - 40
    local c0       = math.floor (h / 2)
    local dy       = math.floor (h0 / 40)
    drawVtrim (widget, 1,     x, c0, "T3" )         -- left  trim - elevator (MODE 1)
    drawVtrim (widget, 2, w - x, c0, "T2" )         -- right trim - throttle (MODE 1)
    
    drawVtrimSmall (widget, 4, w - x - 50, c0, "T5" )
    drawVtrimSmall (widget, 5, w - x - 25, c0, "T6" )
    
    local dx   = dy
    local cl   = 67 + 20 * dx
    local cr   = w - cl
    local yOff = 45

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

    lcd.font(FONT_S)
    text_w, text_h = lcd.getTextSize("")
    lcd.color(widget.colorTxt)
    for i = 0, #arrSwitches do
      if i > 0 and  i % 5 == 0 then
        x0 = x0 + 50
        x = x0
        y = y0
      end
      name = string.format("S%s", string.char(65 + i))     -- user can rename switches
      lcd.drawText (x, y, name, TEXT_LEFT)
      drawSwitchSymbol (x + 25, y + 2, arrSwitches[i]:value())
      y = y + text_h
    end
  end
  -- ********************************************************
  -- * drawFuncBtn                           paint() local  *
  -- ********************************************************
  local function drawFuncBtn (widget, x,  y)
    local swArr = {{-30, -30}, {-20, 0}, {-30, 30}, {30, -30}, {20, 0}, {30, 30}}
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
    lcd.font(FONT_S)
    lcd.color(widget.colorTxt)
    text_w, text_h = lcd.getTextSize("")
    for i = 1, #stickShortArr do
      lcd.drawText (x,      y - 5, stickShortArr[i] .. ":")
      lcd.drawText (x + 20, y - 5, math.floor (0.5 + arrChannels[i - 1]:value() / 10.24))
      y = y + text_h
    end
  end
  -- ********************************************************
  -- * drawChans                             paint() local  *
  -- ********************************************************
  local function drawChans (widget, x, y)
    local yTxtOff = -2
    local wBar
    local wRect  = 72
    local y0     = y

    lcd.font(FONT_XS)
    for i = 1, 24 do
      if i > 1 and (i - 1) % 8 == 0 then
        x = x + 110
        y = y0
      end
      -- label
      if i % 2 ~= 0 then
        lcd.drawText (x -  3, y + yTxtOff, i, TEXT_RIGHT)
      end
      if i % 2 == 0 then
        lcd.drawText (x + 74, y + yTxtOff, i, TEXT_LEFT)
      end
      -- bar outline
      lcd.drawRectangle (x, y, wRect, 10)
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
      if val == 0.5 then
        lcd.color(COLOR_RED)
      else
        lcd.color(COLOR_BLACK)
      end
      lcd.drawFilledRectangle (x + xBar, y, wBar, 10)
      lcd.color(COLOR_BLACK)
      y = y + 13

    end
  end
  -- ********************************************************
  -- * drawLS                                paint() local  *
  -- ********************************************************
	local function drawLS (widget, x,  y)
    local x0 = x
    local w = 10
    local h = 10
    local i = 0
    local v

    lcd.font(FONT_S)
    while i < 20 do
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
        y = y + 13
      elseif i%5 == 0 then
        x = x + 18
      else
        x = x + 12
      end
    end
    lcd.drawText (x, y-2, "LS 01-"..20, TEXT_LEFT)
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
    lcd.font(FONT_STD)
    for i = 0, 2 do
      local t = arrTimers[i]:value()
      lcd.drawText (x, y, "t" .. (i+1) ..":")
      lcd.drawText (x+22, y, hms (t))
      y = y + widget.textSTDheight + 2
    end
  end
  -- ********************************************************
  -- * drawGyro                          paint() local  *
  -- ********************************************************  
  local function drawGyro (widget, x, y)
    lcd.font(FONT_S)
    lcd.color(widget.colorTxt)
    text_w, text_h = lcd.getTextSize("gyro ")
    
    lcd.drawText (x, y, "gyro ")
    lcd.drawText (x + text_w + 10, y,              "X: " .. idGyroX:value())
    lcd.drawText (x + text_w + 10, y +     text_h, "Y: " .. idGyroY:value())
  end
  
  --print ("### paint")
  if lcd.isVisible() then
    if widget.radio ~= 20 and widget.radio ~= 18 then
      printMessage (widget, "nohwsup")
    elseif widget.zoneWidth < 784 then
      printMessage (widget, "wgtsmall")
    else
      lcd.color(widget.colorBkg)
      lcd.drawFilledRectangle(0, 0, widget.zoneWidth, widget.zoneHeight)

      drawSliders   (widget)
      drawTrims     (widget)
      drawModelName (widget,  67,   5)
      if widget.radio == 20 or widget.radio == 18 then
        drawSwitches  (widget,  67,  36)
      end
      drawFuncBtn   (widget, 286,  75)
      drawSticks    (widget,  67, 135)
      drawChans     (widget, 140, 135)
		  drawLS        (widget, 540,  39)
		  drawTimers    (widget, 540, 125)
      drawGyro      (widget, 540, 210)
    end
  end
end

-- ####################################################################
-- # wakeup                                                           #
-- #    this is the main loop that ethos calls every couple of ms     #
-- ####################################################################
local function wakeup(widget)
  if widget.initPending == true then
    -- TODO if necesssary
    local w, h = lcd.getWindowSize()
    widget.zoneHeight = h
    widget.zoneWidth  = w

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
    elseif string.find(board,"14") then
      widget.radio = 14
    elseif string.find(board,"12") then
      widget.radio = 12
    elseif string.find(board,"10") then
      widget.radio = 10
    else
      widget.radio = 0        -- unsupported yet
    end
    
    lcd.font(FONT_S)
    text_w, widget.textSheight = lcd.getTextSize("")
    lcd.font(FONT_STD)
    text_w, widget.textSTDheight = lcd.getTextSize("")

    widget.runBgTasks   = true
    widget.initPending  = false

    GetIDs (widget)
  end
  if widget.runBgTasks == true then
    lcd.invalidate ()
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

    -- Backround color
    line = form.addLine(translate("labelColor"))
    form.addColorField(line, nil, function() return widget.colorLabel end, function(color) widget.colorLabel = color end)

    -- Backround color
    line = form.addLine(translate("backColor"))
    form.addColorField(line, nil, function() return widget.colorBkg end, function(color) widget.colorBkg = color end)
end
-- ####################################################################
-- # read                                                             #
-- #    read values from internal storage                             #
-- ####################################################################
local function read(widget)
  widget.colorTxt   = storage.read("colorTxt")
  widget.colorBkg   = storage.read("colorBkg")
  widget.colorLabel = storage.read("colorLabel")
end
-- ####################################################################
-- # write                                                            #
-- #    write values to internal storage                              #
-- ####################################################################
local function write(widget)
	storage.write("colorTxt",   widget.colorTxt)
	storage.write("colorBkg",   widget.colorBkg)
	storage.write("colorLabel", widget.colorLabel)
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
