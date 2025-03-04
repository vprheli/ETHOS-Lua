-- multilanguage text table
-- if Yo want add your supported mother language, extend table and let me know, I will push it in the Git

local transtable        = { en = { wgname          = "Vario",
                                   menuname        = "Vario",
                                   VarioSensor     = "Height sensor",
                                   VertSensor      = "Vertical speed sensor",
                                   wgtsmall        = "Small Widget",
                                   badSensor       = "Bad sensor type",
                                   noTelemetry     = "No Telemetry",
                                   bgcolor         = "Select background color",
                                 },
                            cs = { wgname          = "Vario",
                                   menuname        = "Vário",
                                   VarioSensor     = "Senzor výšky",
                                   VertSensor      = "Senzor vertikální rychlosti",
                                   wgtsmall        = "Málo místa",
                                   badSensor       = "Špatně zvolený senzor",
                                   noTelemetry     = "Chybí telemetrie",
                                   bgcolor         = "Vyberte barvu pozadí",
                                 },
                            de = { wgname          = "Vario",
                                   menuname        = "Vário",
                                   VarioSensor     = "Höhensensor",
                                   VertSensor      = "Vertikaler Geschwindigkeitssensor",
                                   wgtsmall        = "Kleines Widget",
                                   badSensor       = "Schlechter Sensortyp",
                                   noTelemetry     = "Keine Telemetrie",
                                   bgcolor         = "Hintergrundfarbe auswählen",
                                 }                                 
                          }
                          
return {transtable = transtable}