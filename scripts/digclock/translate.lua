-- multilanguage text table
-- if Yo want add your supported mother language, extend table and let me know, I will push it in the Git

local transtable   = { en = { wgname          = "Battery Capacity",
                              menuname        = "Battery Capacity",
                              StopWatch       = "Stopwatch",
                              segmentColor    = "Select segment color",
                              colorRed        = "Red",
                              colorGreen      = "Green",
                              colorYellow     = "Yellow",
                              wgtsmall        = "Small Widget",
                              badSensor       = "Bad sensor type",
                              noTelemetry     = "No Telemetry",
                              bgcolor         = "Select background color",
                              txtcolor        = "Select text color",
                           },
                      cs = {
                              wgname          = "Digitalni stopky",
                              menuname        = "Digitální stopky",
                              StopWatch       = "Stopky",
                              segmentColor    = "Vyberte barvu segmentů",
                              colorRed        = "Červená",
                              colorGreen      = "Zelená",
                              colorYellow     = "Žlutá",
                              wgtsmall        = "Málo místa",
                              badSensor       = "Špatně zvolený senzor",
                              noTelemetry     = "Chybí telemetrie",
                              bgcolor         = "Vyberte barvu pozadí",
                              txtcolor        = "Vyberte barvu textu",
                           },
                      de = {
                              wgname          = "Stoppuhr",
                              menuname        = "Stoppuhr",
                              StopWatch       = "Stoppuhr",
                              segmentColor    = "Segmentfarbe auswählen",
                              colorRed        = "Rot",
                              colorGreen      = "Grün",
                              colorYellow     = "Gelb",
                              wgtsmall        = "Kleines Widget",
                              badSensor       = "Schlechter Sensortyp",
                              noTelemetry     = "Keine Telemetrie",
                              bgcolor         = "Hintergrundfarbe auswählen",
                              txtcolor        = "Textfarbe auswählen",
                           }
                    }                         
return {transtable = transtable}