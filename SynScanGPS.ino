// SynScan GPS emulator using an Arduino with a GPS
// Copyright (C) 2014-2020 tazounet

#include <stdint.h>
#include <Adafruit_GPS.h>
#include <SoftwareSerial.h>

// The following line enables a fix for UBlox NEO modules that typically work
// at 9600 baud for default. It will assume that the module starts with that baud rate
// and will change the baud rate to 4800 on startup.
//#define UBLOX_NEO_SWITCH_FROM_DEFAULT_BAUDRATE

// SynScan binary message
// User Position, Velocity & Time II (D1h)
struct BinaryMsg {
  uint16_t weekNo;
  uint32_t timeOfWeek;
  uint32_t date;
  uint32_t time;
  int32_t latitude;
  int32_t longitude;
  int16_t  altitude;
  uint16_t heading;
  uint16_t speed;
  uint8_t  fixIndicator;
  uint8_t  qualityOfFix;
  uint8_t  numberOfSv;
  uint8_t  numberOfSvInFix;
  uint8_t  gdop;
  uint8_t  pdop;
  uint8_t  hdop;
  uint8_t  vdop;
  uint8_t  tdop;
} __attribute__((packed));

static void synscanSendBinMsg(BinaryMsg *binMsg);

// GPS class
#define  GPS_PORT Serial
Adafruit_GPS gps(&GPS_PORT);

// SynScan connexion
#define RXPIN 8
#define TXPIN 9
SoftwareSerial nss(RXPIN, TXPIN);

// LED
#define LED_PIN         13
#define LED_BLINK_TIME  500

// Global State
bool sendBinaryMsg = false;
long lastLedTime;

// Synscan command buffer
#define BUFF_SIZE 15
char synscanBuff[BUFF_SIZE] = {0};
uint8_t synscanBuffOffset = 0;

uint8_t uint2bcd(uint8_t ival)
{
   return ((ival / 10) << 4) | (ival % 10);
}

// Compute binary message checksum
static char computeChecksum(char* buf, uint16_t len)
{
  char chksum = 0;
 
  for (uint16_t i = 0; i < len; i++)
  {
    chksum ^= buf[i];
  }
  
  return chksum;
}

static void synscanEncode(char c)
{
  // Add byte to buffer
  if (synscanBuffOffset < BUFF_SIZE - 1)
  {
    synscanBuff[synscanBuffOffset] = c;
    synscanBuffOffset++;
  }

  if (c == '\n')
  {
    // End of command
    if (strncmp(synscanBuff, "%%\xf1\x13\x00\xe2\r\n", synscanBuffOffset) == 0)
    {
      // No output
      sendBinaryMsg = false;
      
      // Send ack
      char msg[7] = {'%', '%', '\x06', '\x13', '\x15', '\r', '\n'};
      synscanSendMsg(msg, 7);
    }
    else if (strncmp(synscanBuff, "%%\xf1\x13\x03\xe1\r\n", synscanBuffOffset) == 0)
    {
      // Binary output
      sendBinaryMsg = true;
      
      // Send ack
      char msg[7] = {'%', '%', '\x06', '\x13', '\x15', '\r', '\n'};
      synscanSendMsg(msg, 7);
    }
    
    // Clean buff
    synscanBuffOffset = 0;
  }
}

static void synscanSendBinMsg(BinaryMsg *binMsg)
{
  uint16_t size = 4 + sizeof(BinaryMsg);
  char msg[size];

  msg[0] = '%';
  msg[1] = '%';
  msg[2] = '\xf2';
  msg[3] = '\xd1';
  
  memcpy(msg + 4, binMsg, sizeof(BinaryMsg));

  for (uint16_t i = 0; i < size; i++)
  {
    nss.write(msg[i]);
  }
  
  // Checksum
  nss.write(computeChecksum(msg, size));
  
  // End
  nss.write('\r');
  nss.write('\n');
}

static void synscanSendMsg(char *msg, uint16_t len)
{
  for (uint16_t i = 0; i < len; i++)
  {
    nss.write(msg[i]);
  }
}

//
// SETUP
//
void setup()
{
#ifdef UBLOX_NEO_SWITCH_FROM_DEFAULT_BAUDRATE
  GPS_PORT.begin(9600);
  byte message[] = {
    0xB5, 0x62, // header
    0x06, 0x00, // class id
    0x14, 0x00, // length in bytes (20)
    0x01,                   // port id
    0x00,                   // reserved0
    0x00, 0x00,             // txReady
    0xD0, 0x08, 0x00, 0x00, // mode (no parity, 1 stop bit, 8 bit data)
    0xC0, 0x12, 0x00, 0x00, // baudrate (4800)
    0x07, 0x00,             // inProtoMask
    0x03, 0x00,             // outProtoMask
    0x00, 0x00,             // reserved4
    0x00, 0x00,             // reserved5
    0xcf,                   // CK_A
    0xe4,                   // CK_B
  };
  GPS_PORT.write(message, sizeof(message));
  delay(600);
#endif

  // Init GPS connexion
  gps.begin(4800);
  
  // Init SynScan connexion
  nss.begin(4800);
  
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);
  lastLedTime = millis();
}

//
// LOOP
//
void loop()
{
  // Read command from SynScan
  while (nss.available())
  {
    // Read synscan msg
    synscanEncode(nss.read());
  }
 
  // Read GPS msg
  gps.read();

  if (gps.newNMEAreceived())
  {
    if (gps.parse(gps.lastNMEA()))
    {
      BinaryMsg binMsg = {0};
      uint8_t tmpBytes[4];
      
      binMsg.weekNo = 0; // not used
      binMsg.timeOfWeek = 0; // not used

      tmpBytes[0] = uint2bcd(gps.day);
      tmpBytes[1] = uint2bcd(gps.month);
      tmpBytes[2] = uint2bcd(gps.year);
      tmpBytes[3] = 0;
      memcpy(&(binMsg.date), tmpBytes, 4);

      tmpBytes[0] = uint2bcd(gps.seconds);
      tmpBytes[1] = uint2bcd(gps.minute);
      tmpBytes[2] = uint2bcd(gps.hour);
      tmpBytes[3] = 0;
      memcpy(&(binMsg.time), tmpBytes, 4);

      binMsg.latitude = (int32_t) (gps.latitudeDegrees / 360.0 * 4294967296);
      binMsg.longitude = (int32_t) (gps.longitudeDegrees / 360.0 * 4294967296);
      binMsg.altitude = (int16_t) gps.altitude;
      binMsg.heading = (uint16_t) gps.magvariation;
      binMsg.speed = (uint16_t) gps.speed;
      switch (gps.fixquality)
      {
        case 1 : binMsg.fixIndicator = 0; // GPS
        case 2 : binMsg.fixIndicator = 1; // DGPS
        default : binMsg.fixIndicator = 5; // Invalid
      }

      if (gps.fix)
      {
        binMsg.qualityOfFix = gps.fixquality_3d - 1; // 2D fix or 3D fix
      }
      else
      {
        binMsg.qualityOfFix = 0; // no fix
      }
      binMsg.numberOfSv = gps.satellites;
      binMsg.numberOfSvInFix = gps.satellites;
      binMsg.gdop = 1;
      binMsg.pdop = (uint8_t) gps.PDOP;
      binMsg.hdop = (uint8_t) gps.HDOP;
      binMsg.vdop = (uint8_t) gps.VDOP;
      binMsg.tdop = 1;

      // Synscan ask for GPS data
      if (sendBinaryMsg)
      {
        synscanSendBinMsg(&binMsg);
      }
    }
  }
  if (gps.fix){
    digitalWrite(LED_PIN, HIGH);
  } else {
    long cur_time = millis();
    if (cur_time - lastLedTime >= LED_BLINK_TIME) {
      digitalWrite(LED_PIN, !digitalRead(LED_PIN));
      lastLedTime = cur_time;
    }
  }
}
