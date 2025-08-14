-- multilanguage text table
-- if Yo want add your supported mother language, extend table and let me know, I will push it in the Git
-- Warm thanks to my Italian colleague Francesco Salvi for the translation into Italian

local transtable        = { en = { wgname          = "Flights",
                                   menuname        = "Flights",
                                   frame           = "Border",
                                   txtColorF       = "Select flights text color",
                                   txtColorT       = "Select time text color",
                                   preset          = "Preset",
                                   flights         = " Flights",
                                   flightswitch    = "Flight active switch",
                                   trigger         = "Trigger switch",
                                   trigerdelay     = "Trigger delay",
                                 },
                            cs = {
                                   wgname          = "Citac letu",
                                   menuname        = "Čítač letů",
                                   frame           = "Rámeček",
                                   txtColorF       = "Barva textu letů",
                                   txtColorT       = "Barva textu celkového času",                                   
                                   preset          = "Přednastaveno",
                                   flights         = " letů",
                                   flightswitch    = "Spínač aktivního letu",
                                   trigger         = "Spínač události",
                                   trigerdelay     = "Minimální trvání události",
                                 },
                            it = { wgname          = "Voli",
                                   menuname        = "Voli",
                                   frame           = "Cornice",
                                   txtColorF       = "Seleziona colore testo",
                                   txtColorT       = "Seleziona colore tempo",
                                   preset          = "Preimpostato",
                                   flights         = " Voli",
                                   flightswitch    = "Interrutore di volo attivo",
                                   trigger         = "Interrutore di attivazione",
                                   trigerdelay     = "Ritardo di attivazione",
                                 }                                 
                          }
                          
return {transtable = transtable}