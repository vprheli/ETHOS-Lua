//================================================================================================
// Projekt     : SynScanGPS
// Popis       : Firmware for SynScan NMEA GPS
// Soubor      : SynScanGPS.ino
// Autor       : original source  https://github.com/tazounet/SynScanGPS 
//               for RP2040 Dual Core adapted RNDr.Vladimir Pribyl, CSc
// e-mail      : vprheli@gmail.com
// Firma       : Copyright (c) 2026, All rights reserved
// Konfigurace : ------------------------------------
//               Chip type           : RC2040 (Dual Core)
//               Program type        : Application
//               Clock frequency     : 200 MHz
//               ------------------------------------
// Prekladac   : Arduino IDE 1.8.5 & VisualMicro
// Deska       : RP2040 Pico
// Historie    : Datum       Verze   Autor    popis
//               ----------  ------- -------- ----------------------------------------------------
//               01.10.2026  1.0.0   VPR      uvodni verze
//================================================================================================

#include <stdint.h>
#include <Adafruit_GPS.h>
#include <pico/mutex.h>       // Hardware mutex secure CPU Core data sharing
#include "NeoPixel.h"         // onboard RGB LED library

/***************************************************************************
* FUNCTION DEFINITIONS                                                     *
***************************************************************************/
uint32_t PackBcdToUint32 (uint8_t b0, uint8_t b1, uint8_t b2, uint8_t b3);

/***************************************************************************
* GLOBAL VARIABLES AND DEFINITIONS                                         *
***************************************************************************/

#define DEBUG_PRINT     0

// UART port pins of RP2040
#define GPS_TX_PIN 0
#define GPS_RX_PIN 1
#define SS_TX_PIN  4
#define SS_RX_PIN  5

// Serial port mapping : Serial1 is UART0, Serial2 is UART1
#define GPS_PORT Serial1   // UART0 -> connected to GPS
#define SS_PORT  Serial2   // UART1 -> connected to TTL to RS232 and SynScan Hand Controller
#define DBG_PORT Serial    // RS2040 USB port

Adafruit_GPS gps(&GPS_PORT);

// Onboard NeoPixel LED in Waveshare RP2040-Zero
#define NEOPIXEL_PIN        16  // internal pin for RGB LED
#define NEOPIXEL_COUNT      1   // board has only 1 LED
#define LED_BLINK_TIME      500

NeoPixel rgbLed(NEOPIXEL_COUNT, NEOPIXEL_PIN, NEO_GRB + NEO_KHZ800);

// SynScan binary sructure - loop response for command 2
struct BinaryMsg {
  uint16_t     weekNo;
  uint32_t     timeOfWeek;
  uint32_t     date;
  uint32_t     time;
  int32_t      latitude;
  int32_t      longitude;
  int16_t      altitude;
  uint16_t     heading;
  uint16_t     speed;
  uint8_t      fixIndicator;
  uint8_t      qualityOfFix;
  uint8_t      numberOfSv;
  uint8_t      numberOfSvInFix;
  uint8_t      gdop;
  uint8_t      pdop;
  uint8_t      hdop;
  uint8_t      vdop;
  uint8_t      tdop;
} __attribute__((packed));

// Global variables for CPU core sharing
#define NMEA_SIZE 128
BinaryMsg         globalBinMsg = {0};
uint8_t           globalNMEAmsg[NMEA_SIZE];
bool              globalGpsFix = false;
auto_init_mutex(msgMutex);                      // Memory lock initialization

volatile bool     _sendBinaryMsg  = false;
volatile bool     _sendNMEAMsg    = false;

// SynScan sekvence
// command 1 - stop periodic loop sending of binary or NMEA data
uint8_t           SynScanCmd1[]  = { 0x25, 0x25, 0xF1, 0x13, 0x00, 0xE2, 0x0D, 0x0A };
// commadn 2 - request for sending binary data (BinaryMsg)
uint8_t           SynScanCmd2[]  = { 0x25, 0x25, 0xF1, 0x13, 0x03, 0xE1, 0x0D, 0x0A };
// command 3 - request for sending @GGA NMEA data
uint8_t           SynScanCmd3[]  = { 0x25, 0x25, 0xF1, 0x13, 0x01, 0xE3, 0x0D, 0x0A };
// ACK response
uint8_t           SynScanAck[]   = { 0x25, 0x25, 0x06, 0x13, 0x15, 0x0D, 0x0A };

// Synscan buffer for commands
#define BUFF_SIZE 15
uint8_t           synscanBuff[BUFF_SIZE] = {0};
uint8_t           synscanBuffOffset = 0;
uint32_t          LED_fixColor = rgbLed.Color(0, 255, 0);

/***************************************************************************
* FUNCTION: setup()                                        VPR 02.10.2026  *
***************************************************************************/
// CPU core 0: SynScan and LED comminication
void setup() {
   // UART inicialization for SynScan
   SS_PORT.setTX(SS_TX_PIN);
   SS_PORT.setRX(SS_RX_PIN);
   SS_PORT.begin(4800, SERIAL_8N1);

   // onboard RGB LED initialization
   rgbLed.begin();
   rgbLed.setBrightness(30); // RGB LED brightness (0-255), 30 is enough
   rgbLed.clear();           // switch off LED at boot
   rgbLed.show();            // update LED settings
}
/***************************************************************************
* FUNCTION: loop()                                         VPR 02.10.2026  *
***************************************************************************/
void loop() {
   // SynScan reading
   while (SS_PORT.available()) {
      synscanEncode(SS_PORT.read());
   }

   // If SynScan need some data, we copy and send them
   // response for command 2
   if (_sendBinaryMsg) {
      BinaryMsg msgToSend;

      mutex_enter_blocking(&msgMutex);
      memcpy(&msgToSend, &globalBinMsg, sizeof(BinaryMsg));
      mutex_exit(&msgMutex);
      #if DEBUG_PRINT == 1
         DBG_PORT.print("sending binary data\n");
      #endif
      synscanSendBinMsg(&msgToSend);
   }
   // response for command 3
   if (_sendNMEAMsg) {
      uint8_t     NMEAtoSend[NMEA_SIZE];
      uint16_t    NMEAsize;

      mutex_enter_blocking(&msgMutex);
      NMEAsize = strlen((char*)globalNMEAmsg);
      memcpy(NMEAtoSend, globalNMEAmsg, NMEAsize);
      mutex_exit(&msgMutex);
      #if DEBUG_PRINT == 1
         DBG_PORT.print("sending NMEA data\n");
      #endif
      synscanSendMsg (NMEAtoSend, NMEAsize);
   }
   // update RGB LED status according GPS fix
   static long lastLedTime = millis();
   static bool ledState    = false;

   if (globalGpsFix) {
      // solid GREEN for valid GPS fix
      rgbLed.setPixelColor(0, LED_fixColor);
      rgbLed.show();
   } else {
      // flash RED when GPS search sattelites
      long cur_time = millis();
      if (cur_time - lastLedTime >= LED_BLINK_TIME) {
         ledState = !ledState;
         if (ledState) {
            rgbLed.setPixelColor(0, rgbLed.Color(255, 0, 0));     // RED
         } else {
            rgbLed.clear();                                       // Switch OFF
         }
         rgbLed.show();
         lastLedTime = cur_time;
      }
   }
}
/***************************************************************************
* FUNCTION: setup1()                                       VPR 02.10.2026  *
***************************************************************************/
// CPU core 1: GPS port handling in background
void setup1() {
   //  UART for dron mini GPS (FlyfishRC M10 Mini GPS)
   GPS_PORT.setTX(GPS_TX_PIN);
   GPS_PORT.setRX(GPS_RX_PIN);
   GPS_PORT.begin(115200, SERIAL_8N1);
   gps.begin(115200);

   // Adafruit GPS library
   gps.sendCommand(PMTK_SET_NMEA_OUTPUT_RMCGGA);
   gps.sendCommand(PMTK_SET_NMEA_UPDATE_1HZ);

   #if DEBUG_PRINT == 1
      DBG_PORT.begin(115200);
   #endif
}
/***************************************************************************
* FUNCTION: loop1()                                        VPR 02.10.2026  *
***************************************************************************/
// GPS data handling
void loop1() {

   static   uint8_t sec = 0;
   struct   tm t;
   char   * lastNMEA;

   gps.read();

   if (gps.newNMEAreceived()) {
      lastNMEA = gps.lastNMEA();
      // If NMEA message is $CGA, we store them for command 3
      if (strstr(lastNMEA, "GGA") != NULL) {
         mutex_enter_blocking(&msgMutex);
         // secured data copy for core 0 as null terminated string
         memcpy(globalNMEAmsg, lastNMEA, strlen(lastNMEA) + 1);
         mutex_exit(&msgMutex);
      }
      if (gps.parse(lastNMEA)) {
         BinaryMsg localBinMsg = { 0 };

         t.tm_sec   = gps.seconds;
         t.tm_min   = gps.minute;
         t.tm_hour  = gps.hour;
         t.tm_mday  = gps.day;
         t.tm_mon   = gps.month - 1;                  // tm_mon [0 .. 11]
         t.tm_year  = (2000 + gps.year) - 1900;       // tm_year years from 1900
         t.tm_isdst = 0;                              // GPS works only in UTC time

         // conversion internal timestamp (secnds from 1.1.1970)
         time_t unixTime = mktime(&t);

         // Constants for GPS epoch (started  6. January 1980 00:00:00 UTC)
         const time_t   gpsEpochUnix  = 315964800;    // difference Unix and GPS epoch in seconds
         const uint32_t secondsInWeek = 604800;       // 7 days * 24 hours * 3600 seconds
         time_t secondsSinceEpoch = unixTime - gpsEpochUnix;

         // 1. Spočítáme celkový počet týdnů od roku 1980
         localBinMsg.weekNo = (uint16_t)(secondsSinceEpoch / secondsInWeek);

         // 2. Spočítáme čas od začátku aktuálního GPS týdne (v milisekundách)
         uint32_t remainderSeconds = secondsSinceEpoch % secondsInWeek;
         localBinMsg.timeOfWeek    = (remainderSeconds * 1000) + gps.milliseconds;

//       localBinMsg.weekNo          = 0;
//       localBinMsg.timeOfWeek      = 0;

         localBinMsg.date            = PackBcdToUint32(gps.day,     gps.month,  gps.year, 0);
         localBinMsg.time            = PackBcdToUint32(gps.seconds, gps.minute, gps.hour, 0);

         localBinMsg.latitude        = (int32_t)(gps.latitudeDegrees  / 360.0 * 4294967296.0);
         localBinMsg.longitude       = (int32_t)(gps.longitudeDegrees / 360.0 * 4294967296.0);
         localBinMsg.altitude        = (int16_t) gps.altitude;
         localBinMsg.heading         = (uint16_t)gps.magvariation;
         localBinMsg.speed           = (uint16_t)gps.speed;

         // Podle specifikace SynScan protokolu z nového projektu
         localBinMsg.fixIndicator    = gps.fix ? 1              : 0;
         localBinMsg.qualityOfFix    = gps.fix ? gps.fixquality : 0;

         localBinMsg.numberOfSv      = gps.satellites;
         localBinMsg.numberOfSvInFix = gps.satellites;
         localBinMsg.gdop            = 10; // Fixní výchozí hodnota škálovaná na nové zobrazení
         localBinMsg.pdop            = (uint8_t)(gps.PDOP * 10.0);
         localBinMsg.hdop            = (uint8_t)(gps.HDOP * 10.0);
         localBinMsg.vdop            = (uint8_t)(gps.VDOP * 10.0);
         localBinMsg.tdop            = 10;

         if (sec != gps.seconds) {
            // memory lock and secure data transfer to CPU code 0
            mutex_enter_blocking(&msgMutex);
            memcpy(&globalBinMsg, &localBinMsg, sizeof(BinaryMsg));

            globalGpsFix = gps.fix;
            mutex_exit(&msgMutex);

            LED_fixColor = localBinMsg.qualityOfFix == 0 ? rgbLed.Color(255, 0, 0) : ((localBinMsg.qualityOfFix == 1) ? rgbLed.Color(0, 255, 0) : rgbLed.Color(0, 0, 255));

            sec = gps.seconds;
         }
      }
   }
}
/***************************************************************************
* FUNCTION: uint2bcd()                                     VPR 02.10.2026  *
***************************************************************************/
uint8_t uint2bcd(uint8_t ival) {
   return ((ival / 10) << 4) | (ival % 10);
}
/***************************************************************************
* FUNCTION: PackBcdToUint32()                              VPR 02.10.2026  *
***************************************************************************/
uint32_t PackBcdToUint32(uint8_t b0, uint8_t b1, uint8_t b2, uint8_t b3 = 0)
{
   uint8_t byte0 = uint2bcd(b0);
   uint8_t byte1 = uint2bcd(b1);
   uint8_t byte2 = uint2bcd(b2);
   uint8_t byte3 = uint2bcd(b3);

   return (uint32_t)(byte0 | (byte1 << 8) | (byte2 << 16) | (byte3 << 24));
}
/***************************************************************************
* FUNCTION: computeChecksum()                              VPR 02.10.2026  *
***************************************************************************/
static uint8_t computeChecksum(uint8_t* buf, uint16_t len) {
   uint8_t chksum = 0;
   for (uint16_t i = 0; i < len; i++) {
      chksum ^= buf[i];
   }
   return chksum;
}
/***************************************************************************
* FUNCTION: synscanSendMsg()                               VPR 02.10.2026  *
***************************************************************************/
static void synscanSendMsg(uint8_t* msg, uint16_t len) {
   SS_PORT.write(msg, len);
   #if DEBUG_PRINT == 1
      printHexBuffer((uint8_t*)msg, len);
   #endif
   SS_PORT.flush();
}
/***************************************************************************
* FUNCTION: synscanSendBinMsg()                            VPR 02.10.2026  *
***************************************************************************/
static void synscanSendBinMsg(BinaryMsg* binMsg) {
   uint16_t size = 4 + sizeof(BinaryMsg) + 3;
   char msg[size];

   msg[0] = '%';
   msg[1] = '%';
   msg[2] = '\xf2';
   msg[3] = '\xd1';

   memcpy(msg + 4, binMsg, sizeof(BinaryMsg));
   msg[size - 3] = computeChecksum((uint8_t*)msg, size - 3);
   msg[size - 2] = '\r';
   msg[size - 1] = '\n';

   for (uint16_t i = 0; i < size; i++) {
      SS_PORT.write(msg[i]);
   }
   #if DEBUG_PRINT == 1
      printHexBuffer ((uint8_t *)msg, size);
   #endif
   SS_PORT.flush ();
}
/***************************************************************************
* FUNCTION: synscanEncode()                                VPR 02.10.2026  *
***************************************************************************/
static void synscanEncode(char c) {
   if (synscanBuffOffset < BUFF_SIZE - 1) {
      synscanBuff[synscanBuffOffset] = c;
      synscanBuffOffset++;
   }

   if (c == '\n') {
      if (memcmp(synscanBuff, SynScanCmd1, sizeof(SynScanCmd1)) == 0) {
         _sendBinaryMsg = false;
         _sendNMEAMsg   = false;
         #if DEBUG_PRINT == 1
            DBG_PORT.print("command 1\n");
         #endif
         synscanSendMsg(SynScanAck, sizeof(SynScanAck));
      } else if (memcmp(synscanBuff, SynScanCmd2, sizeof(SynScanCmd2)) == 0) {
         // set periodic send Binary data
         _sendBinaryMsg = true;
         #if DEBUG_PRINT == 1
            DBG_PORT.print("command 2\n");
         #endif
         synscanSendMsg(SynScanAck, sizeof(SynScanAck));
      } else if (memcmp(synscanBuff, SynScanCmd3, sizeof(SynScanCmd3)) == 0) {
         // set periodic send NMEA data
         _sendNMEAMsg = true;
         #if DEBUG_PRINT == 1
            DBG_PORT.print("command 3\n");
         #endif
         synscanSendMsg(SynScanAck, sizeof(SynScanAck));
      }
      synscanBuffOffset = 0;
   }
}
/***************************************************************************
* FUNCTION: printHexBuffer()                               VPR 11.10.2026  *
***************************************************************************/
// Just for debugging on USB RJ2040 port
#if DEBUG_PRINT == 1
void printHexBuffer(const uint8_t* buffer, size_t length) {
   if (buffer == nullptr || length == 0) return;

   const int bytesPerLine = 16;
   const int indentSize   = 16; // Délka řetězce "10:37:11:568 -> " pro zarovnání

   for (size_t offset = 0; offset < length; offset += bytesPerLine) {
      size_t chunkLength = (length - offset < bytesPerLine) ? (length - offset) : bytesPerLine;

      // OPRAVA: Pokud tiskneme 2. nebo další řádek bloku, odsadíme ho mezerami
      if (offset > 0) {
         for (int i = 0; i < indentSize; i++) {
            DBG_PORT.print(' ');
         }
      }

      // 1. ČÁST: Výpis HEX hodnot
      for (int i = 0; i < bytesPerLine; i++) {
         if (i < chunkLength) {
            uint8_t b = buffer[offset + i];
            if (b < 0x10) DBG_PORT.print('0'); // Doplnění nuly pro jednociferná HEX čísla
            DBG_PORT.print(b, HEX);
            DBG_PORT.print(' ');
         } else {
            DBG_PORT.print(F("   ")); // Výplň pro chybějící HEX bajty
         }

         // Extra mezera uprostřed bloku (po 8 bajtech) pro lepší čitelnost
         if (i == 7) {
            DBG_PORT.print(' ');
         }
      }

      // Oddělovač mezi HEX a ASCII
      DBG_PORT.print(F(" : "));

      // 2. ČÁST: Výpis ASCII znaků
      for (int i = 0; i < bytesPerLine; i++) {
         if (i < chunkLength) {
            uint8_t b = buffer[offset + i];
            // Zobrazení pouze tisknutelných ASCII znaků
            if (b >= 0x20 && b <= 0x7E) {
               DBG_PORT.print((char)b);
            } else {
               DBG_PORT.print('.');
            }
         } else {
            DBG_PORT.print(' '); // Výplň prázdných míst v ASCII části
         }
      }

      DBG_PORT.println();
   }
}
#endif

//  ###################################################
//  #  PROTOCOL SAMPLE                                #
//  ###################################################
//
//  10.10.2026 16:58:16 <- prijat command 1
//                      <- 25 25 F1 13 00 E2 0D 0A                          : . % %......
//  10.10.2026 16:58:16 -> odesilam ACK
//                      -> 25 25 06 13 15 0D 0A                             : % %.....
//
//  10.10.2026 16:58:20 <- prijat command 2
//                      <- 25 25 F1 13 03 E1 0D 0A                          : % %......
//  10.10.2026 16:58:20 -> odesilam ACK
//                      -> 25 25 06 13 15 0D 0A                             : % %.....
// 
//  10.10.2026 16:58:21 -> odesilam binarni data
//                      -> 25 25 F2 D1 87 09 F3 9E  1C 22 10 10 26 00 21 58 : % %......."..&.!X
//                         14 00 AA 34 9E 23 02 2C  41 0A E6 00 B4 00 00 00 : ...4.#., A.......
//                         01 02 0A 0A 0A 0C 08 09  0A AF 0D 0A             : ............
//   
//  10.10.2026 16:58:21 <- prijat command 1
//                      <- 25 25 F1 13 00 E2 0D 0A                          : % %......
//  10.10.2026 16:58:21 -> odesilam ACK
//                      -> 25 25 06 13 15 0D 0A                             : % %.....
//   
//  10.10.2026 16:58:22 <- prijat command 2
//                      <- 25 25 F1 13 03 E1 0D 0A                          : % %......
//  10.10.2026 16:58:22 -> odesilam ACK
//                      -> 25 25 06 13 15 0D 0A                             : % %.....
//      
//  10.10.2026 16:58:23 -> odesilam binarni data
//                      -> 25 25 F2 D1 87 09 A5 A6  1C 22 10 10 26 00 23 58 : % %......."..&.#X
//                         14 00 AA 34 9E 23 02 2C  41 0A E6 00 B4 00 00 00 : ...4.#., A.......
//                         01 02 0A 0A 0A 0C 08 09  0A C3 0D 0A             : ............
//    
//  10.10.2026 16:58:24 -> odesilam binarni data
//                      -> 25 25 F2 D1 87 09 86 AA  1C 22 10 10 26 00 24 58 : % %......."..&.$X
//                         14 00 AA 34 9E 23 02 2C  41 0A E6 00 B4 00 00 00 : ...4.#., A.......
//                         01 02 0A 0A 0A 0C 08 09  0A EB 0D 0A             : ............
//  
//  10.10.2026 16:58:25 -> odesilam binarni data
//                      -> 25 25 F2 D1 87 09 6B AE  1C 22 10 10 26 00 25 58 : % %....k.."..&.%X
//                         14 00 AA 34 9E 23 02 2C  41 0A E6 00 B4 00 00 00 : ...4.#., A.......
//                         01 02 0A 0A 0A 0C 08 09  0A 03 0D 0A             : ............
//
//  10.10.2026 16:58:26 <- prijat command 1
//                      <- 25 25 F1 13 00 E2 0D 0A                          : % %......
//  10.10.2026 16:58:27 -> odesilam ACK
//                      -> 25 25 06 13 15 0D 0A                             : % %.....
//   
//  10.10.2026 16:58:30 <- prijat command 3
//                      <- 25 25 F1 13 01 E3 0D 0A                          : % %......
//  10.10.2026 16:58:30 -> odesilam ACK
//                      -> 25 25 06 13 15 0D 0A                             : % %.....
//   
//  
//  10.10.2026 16:58:31 -> odesilam NMEA GNGGA
//                      -> 24 47 4E 47 47 41 2C 31  34 35 38 33 31 2E 30 30 : $GNGGA, 145831.00
//                         2C 35 30 35 2E 32 36 38  30 2C 4E 2C 30 31 34 32 : , 505.2680, N, 0142
//                         35 2E 32 33 30 30 2C 45  2C 31 2C 31 30 2C 30 2E : 5.2300, E, 1, 10, 0.
//                         38 2C 32 33 30 2E 30 2C  4D 2C 30 2E 30 2C 4D 2C : 8, 230.0, M, 0.0, M,
//                         2C 2A 37 46 0D 0A                                : , * 7F..
//  
//  10.10.2026 16:58:32 -> odesilam NMEA GNGGA
//                      -> 24 47 4E 47 47 41 2C 31  34 35 38 33 32 2E 30 30 : $GNGGA, 145832.00
//                         2C 35 30 35 2E 32 36 38  30 2C 4E 2C 30 31 34 32 : , 505.2680, N, 0142
//                         35 2E 32 33 30 30 2C 45  2C 31 2C 31 30 2C 30 2E : 5.2300, E, 1, 10, 0.
//                         38 2C 32 33 30 2E 30 2C  4D 2C 30 2E 30 2C 4D 2C : 8, 230.0, M, 0.0, M,
//                         2C 2A 37 43 0D 0A      
//
//  10.10.2026 16:58:33 -> odesilam NMEA GNGGA
//                      -> 24 47 4E 47 47 41 2C 31  34 35 38 33 33 2E 30 30 : $GNGGA, 145833.00
//                         2C 35 30 35 2E 32 36 38  30 2C 4E 2C 30 31 34 32 : , 505.2680, N, 0142
//                         35 2E 32 33 30 30 2C 45  2C 31 2C 31 30 2C 30 2E : 5.2300, E, 1, 10, 0.
//                         38 2C 32 33 30 2E 30 2C  4D 2C 30 2E 30 2C 4D 2C : 8, 230.0, M, 0.0, M,
//                         2C 2A 37 44 0D 0A                                : , * 7D..
//  
//  10.10.2026 16:58:34 -> odesilam NMEA GNGGA
//                      -> 24 47 4E 47 47 41 2C 31  34 35 38 33 34 2E 30 30 : $GNGGA, 145834.00
//                         2C 35 30 35 2E 32 36 38  30 2C 4E 2C 30 31 34 32 : , 505.2680, N, 0142
//                         35 2E 32 33 30 30 2C 45  2C 31 2C 31 30 2C 30 2E : 5.2300, E, 1, 10, 0.
//                         38 2C 32 33 30 2E 30 2C  4D 2C 30 2E 30 2C 4D 2C : 8, 230.0, M, 0.0, M,
//                         2C 2A 37 41 0D 0A                                : , * 7A..
//      
//  10.10.2026 16:58:34 <- prijat command 1
//                      <- 25 25 F1 13 00 E2 0D 0A                          : % %......
//  10.10.2026 16:58:34 -> odesilam ACK
//                      -> 25 25 06 13 15 0D 0A                             : % %.....
//        
//  10.10.2026 16:58:35 <- prijat command 1
//                      <- 25 25 F1 13 00 E2 0D 0A                          : % %......
//  10.10.2026 16:58:35 -> odesilam ACK
//                      -> 25 25 06 13 15 0D 0A : % %.....
//  

