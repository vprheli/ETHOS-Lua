
![VPR-heli_crop](https://github.com/user-attachments/assets/c20f1842-3afb-4ef8-9f90-24fd48db7957)
<HR>
<H1>ETHOS Lua widget scripts</H1>

>[!IMPORTANT]
My new scripts are gradually using the shared library utils.lua in the scripts/common folder. Compare the /lib folder in the transmitter with the folder in git and if you find the file only in the transmitter and not in git, delete it from the transmitter and don't forget to copy content of the /common folder



I am a passionate modeler and programmer, specializing in, among other things, creating Lua scripts for the FrSky ETHOS / OpenTx operating system. My goal is to optimize the experience of using transmitters such as the FrSky Horus X12S and X20 by using custom widgets and tools that provide users with important information, such as battery status or other telemetry data. I enjoy developing intuitive and effective solutions that expand the capabilities of these modern devices. My work combines a passion for model making and programming, while focusing on details that increase user comfort and system reliability.

All my widgets are multilingual. In the current version they support English, German and Czech. The language can be easily added to the code. If you are a native speaker of a language not listed, please translate the texts in the translate.lua file and let me know, I will publish them for others.

All scripts support X20 radios. Some also support radios with lower display resolution.

<H2>ETHOS Battery widget</H2>
This widget graphically displays the battery charge status. It uses telemetry data from <B>FrSky FLVS ADV, FrSky FASx0 ADV, FrSky FASxyz ADV</B> sensors to obtain the necessary data.
The presented screenshots are from the X20pro simulator, which currently only has predefined fixed values ​​from telemetry sensors.

![batcap-fullwindow2](https://github.com/user-attachments/assets/2f1a6e0b-681f-4e38-87ee-c408efeab61c)
![batcap-halfwindow2](https://github.com/user-attachments/assets/8f07df64-6f62-46b8-b739-06a6bd00374f)
![batcap-menu2](https://github.com/user-attachments/assets/7e75bcc0-6a2c-4726-83ca-3667fcb94271)

It depends on what combination of sensors you choose and the specific data how the sensor will look. The voltage to capacity conversion tables support LiPo, high voltage LiPo, Lion and LiFe batteries.

<H2>ETHOS Vario widget</H2>
Widget for displaying telemetry from Vario sensor.

![vario-halfwindow](https://github.com/user-attachments/assets/c6dd3739-6096-4729-8e28-dafa8f15ef78)

<H2>ETHOS Digital Stopwatch widget</H2>
The widget displays the stopwatch reading in digital form on a seven-segment display.

![Digital-full](https://github.com/user-attachments/assets/500ffb62-e5ed-4706-8648-adef7c70764a)
![Digital-half](https://github.com/user-attachments/assets/ba68800a-61f7-405e-a4cb-f245a9df6355)

<H2>ETHOS h4lgpsmap (fixed and modified) widget</H2>
I also modified the unsupported H4LGPSMAP widget that displays the map and the model's position using the GPS sensor.
This version supports up to 32 saved maps. The map is automatically loaded when the model flies into the specified GPS range of the map.
This allows you to use multiple maps of different scales for the same area. If the model leaves the detailed map, a map with a wider area is automatically displayed. In this case, it is only necessary that the more detailed map has a lower number than the map with a larger area.
The second option is to create tiles from the maps of the same magnification and thus cover larger areas.
Multilingual support.

![h4lgpsmap](https://github.com/user-attachments/assets/ec95bcae-51b3-4030-8903-9fc5a36da1ee)

<H2>ETHOS ShowAll widget</H2>
Modification of the OpenTx script showing the states of the controls on the X20, X18, X12 and X10 transmitters.

![ShowAll-X20-small](https://github.com/user-attachments/assets/9bbd08fd-a531-4158-aea4-754392e2dd96)

<h2> ETHOS Flights widget </h2>
This is a simple flight counter including total flight time.
Two conditions are set in the configuration screen.<BR>
1) The condition when the flight is taken as real and the minimum duration of this condition<BR>
2) The condition when the flight begins and ends.
The first condition eliminates testing the model before takeoff, engine tuning, etc. and only by fulfilling this condition for a set period of time will the flight counter increase. <I>This can be, for example, the minimum position of the throttle lever for a certain period of time.</I>
</BR>The second condition is then used to obtain the total flight duration. <I>This can be, for example, engine activation, starting and stopping the counter...</I>
<BR><B>If the first condition is not met, the flight duration is not added.</B>
<BR>
<img width="309" height="100" alt="obrazek" src="https://github.com/user-attachments/assets/51741bca-4ec0-4d76-995b-3ebddaa4f70a" />



If you like it you can support it by making a donation!
<p>
  <a href="https://www.paypal.me/vprheli/5">
      <img src="https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif" alt="paypal">
  </a>
</p>
