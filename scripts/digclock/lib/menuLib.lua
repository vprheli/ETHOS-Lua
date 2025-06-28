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
-- ETHOS menu library for Vario widget
-- File:   : menuLib.lua
-- Author  : RNDr.Vladimir Pribyl, CSc. (VPRHELI)
-- History : Date        Version Author   Comment
--           ----------  ------- -------- ------------------------------------
--           23.01.2025  1.0.0   VPRHELI  initial version
-- =============================================================================

local menuLib     = {}
local conf        = nil
local libs        = nil

-- ####################################################################
-- # menuLib.init                                                     #
-- ####################################################################
function menuLib.init(param_conf, param_libs)
  --print ("### menuLib.init()")
  conf   = param_conf
  libs   = param_libs

  return menuLib
end

-- ####################################################################
-- # menuLib.configure                                                #
-- #    Widget Configuration options                                  #
-- ####################################################################
function menuLib.configure(widget)
  print ("### menuLib.configure()")

  -- Battery Capacity Version
  line = form.addLine(libs.utils.translate ("menuname") .. "  " .. conf.version)

  -- Vario Sensor
  line = form.addLine(libs.utils.translate("StopWatch"))
  form.addSourceField(line, nil, function() return widget.StopWatch end,
                                 function (value)
                                    if value:name() == "---" then
                                      widget.StopWatch = nil
                                    else
                                      widget.StopWatch = value
                                    end
                                 end)

  -- Segment Color
  line = form.addLine(libs.utils.translate ("segmentColor"))
  local segment_colors = { { libs.utils.translate ("colorRed"),    0 },
                           { libs.utils.translate ("colorGreen"),  1 },
                           { libs.utils.translate ("colorYellow"), 2 },
                        }
  local function get_segment_color() return widget.segmentColor end
  local function set_segment_color(type) widget.segmentColor = type end
  form.addChoiceField(line, nil, segment_colors, get_segment_color, set_segment_color)

  -- Background color
  line = form.addLine(libs.utils.translate("bgcolor"))
  form.addColorField(line, nil, function() return widget.bgcolor end, function(color) widget.bgcolor = color end)

    -- Text color
  line = form.addLine(libs.utils.translate("txtcolor"))
  form.addColorField(line, nil, function() return widget.txtcolor end, function(color) widget.txtcolor = color end)

end

return menuLib