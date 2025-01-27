
![VPR-heli_crop](https://github.com/user-attachments/assets/c20f1842-3afb-4ef8-9f90-24fd48db7957)
<HR>
<H1>ETHOS Lua widget scripts</H1>


I am a passionate modeler and programmer, specializing in, among other things, creating Lua scripts for the FrSky ETHOS / OpenTx operating system. My goal is to optimize the experience of using transmitters such as the FrSky Horus X12S and X20 by using custom widgets and tools that provide users with important information, such as battery status or other telemetry data. I enjoy developing intuitive and effective solutions that expand the capabilities of these modern devices. My work combines a passion for model making and programming, while focusing on details that increase user comfort and system reliability.

All my widgets are multilingual. In the current version they support English, German and Czech. The language can be easily added to the code. If you are a native speaker of a language not listed, please translate the texts in the header of the main.lua file and let me know, I will publish them for others.

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
