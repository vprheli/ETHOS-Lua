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
-- ETHOS menu library for Battery Capacity
-- File:   : menuLib.lua
-- Author  : RNDr.Vladimir Pribyl, CSc. (VPRHELI)
-- History : Date        Version Author   Comment
--           ----------  ------- -------- ------------------------------------
--           15.01.2025  0.0.1   VPRHELI  initial version
--           27.01.2025  1.0.0   VPRHELI  minor changes
--           07.02.2025  1.0.2   VPRHELI  LiFePo4 name change
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
  --print ("### menuLib.configure()")
  
  local cellsEnabled = widget.VoltageSensor
  -- Battery Capacity Version
  line = form.addLine(libs.utils.translate ("menuname") .. "  " .. conf.version)
  
  -- Battery Type
  line = form.addLine(libs.utils.translate ("battype"))
  local battery_types = { { "Lipo",    0 },
                          { "HV Lipo", 1 },
                          { "Lion",    2 },
                          { "LiFePO4", 3 }
                        }
  local function get_battery_type() return widget.BatType end
  local function set_battery_type(type) widget.BatType = type end
  form.addChoiceField(line, nil, battery_types, get_battery_type, set_battery_type)
  
  -- Battery Capacity
  -- one turn = 30 pulses = 3000mAh
  local line = form.addLine(libs.utils.translate("wgname"))
  local field = form.addNumberField(line, nil, 0, 6000, function() return widget.batCapmAh end, function(value) widget.batCapmAh = value end)
  field:suffix("mAh")
  field:default(1000)
  field:step(50)
  
  -- Lipo Sensor
  --form.addLine("Sensor Selection:")
  line = form.addLine(libs.utils.translate("LiPo"))
  form.addSourceField(line, nil, function() return widget.LipoSensor end, 
                                 function (value)
                                    if value:name() == "---" then
                                      widget.LipoSensor = nil
                                    else
                                      widget.LipoSensor = value
                                    end
                                 end)     
  
  -- Voltage Sensor
  line = form.addLine(libs.utils.translate("VoltageSensor"))
  form.addSourceField(line, nil, function() return widget.VoltageSensor end, 
                                 function (value)
                                    if value:name() == "---" then
                                      widget.VoltageSensor = nil
                                    else
                                      widget.VoltageSensor = value
                                    end
                                    cellsForm:enable(widget.VoltageSensor ~= nil)
                                 end) 

  -- Battery Cells Count
  line = form.addLine(libs.utils.translate("VFAScells"))
  local battery_cells = { { "1S", 1 },
                          { "2S", 2 },
                          { "3S", 3 },
                          { "4S", 4 },
                          { "5S", 5 },
                          { "6S", 6 },
                          { "7S", 7 },
                          { "8S", 8 },                          
                        }
  local function get_battery_cells() return widget.VFAScells end
  local function set_battery_cells(type) widget.VFAScells = type end                        
  cellsForm = form.addChoiceField(line, nil, battery_cells, get_battery_cells, set_battery_cells)
  cellsForm:enable(cellsEnabled ~= nil)
  
  -- Current Sensor
  line = form.addLine(libs.utils.translate("CurrSensor"))
  form.addSourceField(line, nil, function() return widget.CurrentSensor end,
                                 function (value)
                                    if value:name() == "---" then
                                      widget.CurrentSensor = nil
                                    else
                                      widget.CurrentSensor = value
                                    end
                                 end)     
  
  -- Some color
  line = form.addLine(libs.utils.translate("color1"))
  form.addColorField(line, nil, function() return widget.color1 end, function(color) widget.color1 = color end)

end

return menuLib