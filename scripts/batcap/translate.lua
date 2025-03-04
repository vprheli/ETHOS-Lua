-- multilanguage text table
-- if Yo want add your supported mother language, extend table and let me know, I will push it in the Git

local transtable  = { en = { wgname          = "Battery Capacity",
                             menuname        = "Battery Capacity",
                             battype         = "Battery Type",
                             LiPo            = "Lipo Sensor",
                             VoltageSensor   = "Voltage Sensor",
                             VFAScells       = "Battery Cells Count",
                             CurrSensor      = "Current Sensor",
                             curmax          = "Current / Max",
                             wgtsmall        = "Small Widget",
                             badSensor       = "Bad sensor type",
                             noTelemetry     = "No Telemetry",
                             color1          = "Select color",
                           },
                      cs = {
                             wgname          = "Kapacita baterie",
                             menuname        = "Kapacita baterie",
                             battype         = "Typ baterie",
                             LiPo            = "Lipo senzor",
                             VoltageSensor   = "Senzor napětí",
                             VFAScells       = "Počet článků baterie",
                             CurrSensor      = "Senzor proudu",
                             curmax          = "Aktuální / Max",
                             wgtsmall        = "Málo místa",
                             badSensor       = "Špatně zvolený senzor",
                             noTelemetry     = "Chybí telemetrie",
                             color1          = "Vyberte barvu",
                           },
                      de = {
                             wgname          = "Batteriekapazitat",
                             menuname        = "Batteriekapazität",
                             battype         = "Akku-Typ",
                             LiPo            = "Lipo-Sensor",
                             VoltageSensor   = "Spannungssensor",
                             VFAScells       = "Anzahl der Batteriezellen",
                             CurrSensor      = "Stromsensor",
                             curmax          = "Aktuell / Max",
                             wgtsmall        = "Kleines Widget",
                             badSensor       = "Schlechter Sensortyp",
                             noTelemetry     = "Keine Telemetrie",
                             color1          = "Wähle Farbe",
                           }                                 
                    }
                          
return {transtable = transtable}