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
-- ETHOS menu library for Vario widget
-- File:   : menuLib.lua
-- Author  : RNDr.Vladimir Pribyl, CSc. (VPRHELI)
-- History : Date        Version Author   Comment
--           ----------  ------- -------- ------------------------------------
--           23.01.2025  0.0.1   VPRHELI  initial version
--           22.01.2025  0.9.0   VPRHELI  initial version
-- =============================================================================

local menuLib     = {}
local conf        = nil
local libs        = nil

-- #################################################################### 
-- # menuLib.init                                                     #
-- ####################################################################
function menuLib.init(param_conf, param_libs)
  print ("### menuLib.init()")
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
  
  local cellsEnabled = widget.VoltageSensor
  -- Battery Capacity Version
  line = form.addLine(libs.utils.translate ("wgname") .. "  " .. conf.version)
  
  -- Vario Sensor
  line = form.addLine(libs.utils.translate("VarioSensor"))
  form.addSourceField(line, nil, function() return widget.VarioSensor end, 
                                 function (value)
                                    if value:name() == "---" then
                                      widget.VarioSensor = nil
                                    else
                                      widget.VarioSensor = value
                                    end
                                 end) 

  -- Vertical Speed Sensor  
  line = form.addLine(libs.utils.translate("VertSensor"))
  form.addSourceField(line, nil, function() return widget.VerticalSensor end, 
                                 function (value)
                                    if value:name() == "---" then
                                      widget.VerticalSensor = nil
                                    else
                                      widget.VerticalSensor = value
                                    end
                                 end) 
  -- Some color
  line = form.addLine(libs.utils.translate("color1"))
  form.addColorField(line, nil, function() return widget.color1 end, function(color) widget.color1 = color end)

end

return menuLib