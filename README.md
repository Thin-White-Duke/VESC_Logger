# VESC_Logger
iOS Code to enable VESC communication via Adafruit UART Friend.
<br><br>
This project can log real time data from the VESC into a mobile app.  It does not control the VESC, it only reports back on VESC data such as Amps, Battery Voltage, RPM, etc.

<a href="http://www.youtube.com/watch?feature=player_embedded&v=AAa55i9OPH8
" target="_blank"><img src="http://gourmetpixel.com/tests/bens/VESC/VESC_Logger.png" 
alt="VESC Logging App" width="340" height="180" border="10" /></a>

### How??

Grab yourself a VESC - http://www.vedder.se
<br>
Grab yourself an Adafruit UART Friend - https://www.adafruit.com/products/2479
<br>
Find yourself a connector: http://www.watterott.com/en/Jumper-Wire-6-Pin-JST-White
<br>
_Note the 2mm spacing, not standard 0.1"_

Wire these two together:
<br>_Please be careful - this is based on VESC hardware revision 4.7.  Check your VESC hardware_

* VESC Pin 1 (RX) -> Adafruit TX
* VESC Pin 2 (TX) -> Adafruit RX
* VESC Pin 4 (GND) -> Adafruit GND + Adafruit CTS
* VESC Pin 5 (VCC) -> Adafruit vIN

Check http://vedder.se/2015/01/vesc-open-source-esc/ for the VESC UART port info

It's important to make sure you wire your Adafruit CTS to GND otherwise your comms won't work.

### VESC Configuration
Your VESC needs a couple of bits setup in BLDC Tool.  In _App Configuration_ tab choose the _UART_ side tab and set the _Baud Rate_ to _9600_.
<br>
In the _General_ side tab, I have chosen _PPM an UART_ but I don't think you need UART chosen here (to be confirmed)

### Wired up?

With the above wired up, your VESC should now be powering your Adafruit UART friend.  Fire up and see if the Adafruit blinks red.

Now install the iOS code onto your device and run the app.  It will connect to the Adafruit, which should light up a blue LED, and it will try and run a COMM_GET_VALUES on the VESC.

### Using the app

When the app detects a VESC, a Start Recording button will appear.  Tap this and the app will stream VESC data onto a graph.

Long press on the graph to change the VESC variable you want to view.

Drag you finger along the graph to pinpoint values.

Enjoy!

### Credits
Massive thanks to Benjamin Vedder for creating the VESC and open sourcing all his hard work: http://www.vedder.se
<br>
Also thanks to RollingGecko who provided a lot of code that I based this all on: https://github.com/RollingGecko/VescUartControl


