# Smart Shutter switch with ESPHome
Or how to transform a Tuya noname proprietary (curtain) switch into an esphome (+Home Assistant) open source run device
_____________________________________


<img align="middle" src="pictures/smartswitch.webp" alt="Switch"  width="40%"/>

_____________________________________

For some time now I wanted to automatize my roller shutter so that I could close/open them remotely, all at once or automatically based on date or sun events.

As I already had a Wi-Fi network a simple solution was to use Wi-Fi "smart switches", and you can find some quite cheap ones on aliexpress...
One of my concerns though was the standby power consumption. Enabling the "high power saving" mode of esphome I managed to get from 0.6 to 0.4W. I would have prefered to get down to the 0.1W order but I suppose that another radio tech would need to be used to get there...

Anyway, I went down the apth and ordered a cheap "WiFi Smart Curtain Swtich" on [AliExpress](https://fr.aliexpress.com/item/1005002276767338.html?spm=a2g0o.9042311.0.0.7e1f6c37ZPyPmw)

This is what I received:

<img src="pictures/box1.jpg" alt="Switch Package"  width="40%"/>
<img src="pictures/box2.jpg" alt="Switch Package" width="40%"/>


After quickly installing the Tuya App I was able to connect to the switches and they worked as expected. I guess I could have stoped there, but well if I did I would not had to write this article. My goal was to run open source software on these switches and control it with "my" could (well in fact not even a cloud since I am running Home Assistant on my local network...)



# Hardware

So I opened the switch, the design seemed relatively simple: There is a "high power PCB" that contains the relays and the 5V power supply (**Not isolated from the main power, do not touch or connect anything while the switch is connected to main power (240V) !!**)


**Note**: I ordered 4 switches in total, and interesting out of the 4, 3 switches had different PCB versions! Fortunately it did not change the interface point with the Wi-Fi module so I had nothing specific to do. The only notable point is that on one version there is a blue LED lighting the Wi-Fi logo, on other versions that signal led is wired to the midle button orange LED.


<img src="pictures/high_power_pcb.jpg" align="middle" alt="High Power"  width="40%"/>

The top PCB is the control part: it contains the touch button detection circuitry (an MCU?) and the Wi-Fi module.

<img src="pictures/prepared_for_hotgun.jpg" align="middle" alt="Control Board" width="40%"/>


Looking at that control board realised one bad and one good thing. The bad news was that the Wi-Fi module is based on a proprietary Tuya module that has a non easily modifiable firmware: [WB3S](https://developer.tuya.com/en/docs/iot/wb3s-module-datasheet?id=K9dx20n6hz5n4). However the good news was that this module has the exact same footprint and pinout as the ESP-12E/F and ESP-12S to some extent.
After some investigation I realised that the ESP-12S was sligtly easier as a drop in replacement since it already had the necessary pins pulled up / down to automatically start on power up. Here is some [schematic](https://docs.ai-thinker.com/_media/esp8266/docs/esp-12s_product_specification_en.pdf) I found for that module (not sure if they are fully exact though....)

So I quickly ordered some ESP12 modules on [AliExpress](https://fr.aliexpress.com/item/1005003136626008.html?spm=a2g0o.9042311.0.0.eb5e6c370QfhqQ)

After a thourough investigation I found out that all the control logic is done in the Wi-Fi module, and the other chip is really just used to detect the capacitive touch buttons.
Here are my findings:
* the two PCB board are linked with a 4 wires connectors: GND, 5V, relay1 and relay2 controls (outputs of the control board, input on the power board)
* the 3 buttons have 2 LEDs backlight: green and orange
* on one PCB version there is an additional blue LED on the top left corner (light up the Wi-Fi logo). On the PCB that do not ahve that LED the middle button Orange LED is not controlled/controllable by the Wi-Fi module, instead the Orange LED seems to be hard linked to the touch button output directly.
* the two relays are conencted with the Orange LED of the Up and Down Button

Here is how the Wi-Fi module is connected to the board:

<img src="pictures/esp12-connections.png" align="middle" alt="Pinout"/>

Okey all the investigation work was now done, let's start to actually hack the thing. The first thing to do was to change the WB3S module by the freshly received ESP-12S module. To do this you will need a hot gun. On the above picture you can see that I removed the imediatly close plastic pad on the lower button (gently pull it out), and I added Kapton tape to protect the middle button plastic pad from the heat air.

After a few minutes you should get this

<img src="pictures/top_pcb_with_new_esp.jpg" align="middle" alt="Control Board" width="40%"/>

You just have to clean out the remaining solder on the pad and the baord is ready to receive the ESP-12S module.
**But before** you do that, it's easier to flash the ESP-12S with ESPHome once using the a USB to serial (TTL 3.3V) cable. Even a simple applciation that just connect to Wi-Fi, so the next firmware update can be done over the air.
Note that if you soldered already the module, not a big deal you can flash it in place since the only needed wire are RX/TX (they are not connected on the PCB) and pull down GPIO2 to ground (that ok since it is an input on the PCB).
**However do not attempt this while the switch is connected to the main power.** Instead you can simply power the control board using the GND and 5V pins on the the 4 pins connector of the control board.

Anyway in my case I temporarily soldered the cables directly on the module so I can peacefully flash the ESP module. *Beware* the module power supply is 3.3V only (the control board has a 5V to 3.3V voltage regulator). I found a easy page describing how to wire an ESP-12F module for USB/Serial flashing: [How to wire ESP12 for USB flashing](https://www.sensatio.io/tutorial-how-to-prepare-your-esp8266-esp-12-for-flashing)

It looked like this:

<img src="pictures/ready_to_flash.jpg" align="middle" alt="Control Board" width="40%"/>

Then after plugin my [USB to serial TTL 3.3V dongle](https://fr.aliexpress.com/item/2005100405.html) and connecting the ESP-12 module, simply run the esphome command line to compile and flash the image.
See the software section for more details on ESPHome

Final step: remove the temporray wires, solder the ESP module on the control board, and you ar eready to run!


# Software

## Integration
To generate the image to flash the ESP I simply used [ESPHome](https://esphome.io/). It may look intimidating at first but it is actually *realy* easy to use. Kudos to this project it is trully amazing.

There is actually a simple [getting started guide](https://esphome.io/guides/getting_started_command_line.html) that you can follow to install esphome and then compile your first firmware.
To flash the device, simply type the `esphome run yourproject.yaml` it will compile and then offer you options to flash your device. If it detects a USB to serial dongle it will propose you the wire flashing, otherwise you always have the over air flash method. But it requires to wire-flash esphome once o nyour device with the proper Wi-Fi credentials so that eh device can connect to your local network.

In order to manage this newly create smart switch I simply used [Home Assistant](https://www.home-assistant.io/). This is a bigger peice to chew, I won't go into the details on how to install it or run it, but there is an extremly large amount of tutorials to set it up.
The benefit to using Home Assistant is that it is pre itnegrated with esphome and automatically detect devices, so once set up it becomes trivial to manage your esphome managed devices.
There is also a 'lighter' alternative to use the ESPHome dashboard (simpler tool to manage your ESPHome devices) but I did not try it.

To implement the shutter switch firmware I used this [yaml file](shutterswitch.yaml).
Modify the fiel to add your own passwords and Wi-Fi credentials and then simply run `esphome run shutterswitch.yaml`

Once your device is flashed, booted, attached to the Wi-Fi network, Home Assistant should detect it. You can see/configure it in the Configure/Integration screen

<img src="pictures/HA_integrations.png" align="middle" alt="Home Assistant integration" width="40%"/>

**Note** if you have setup an API password in your esphome yaml file Home Assistant will prompt you for this password first.

Once enabled in Home Assistant, your dashboard should display the new 'cover' widget

<img src="pictures/HA_dashboard.png" align="middle" alt="Home Assistant integration" width="80%"/>



## Automation

The next thing is to automate the opening and closing of the shutter. In my case I wanted to close the shutter every day 20 minutes before sun set, and open them on the morning on either the sun rise or after a fixed hour which ever come last, and only on a weekday.

For this I created two Home Assistant automation: In Home Assistant navigate to Configuration/Automation + Add Automation button.

Here are the two automation I added:

### Shutter close:

```yaml
alias: Shutter Close
description: ''
trigger:
  - platform: sun
    event: sunset
    offset: '-00:20'
condition: []
action:
  - service: cover.close_cover
    target:
      entity_id:
        - cover.volets_ch1
        - cover.volets_ch2
        - cover.volets_ch3
        - cover.volets_sdb
mode: single
```

### Shutter Open

```yaml
alias: Shutter Open
description: ''
trigger:
  - platform: time
    at: '07:30:00'
  - platform: sun
    event: sunrise
condition:
  - condition: sun
    after: sunrise
  - condition: time
    after: '07:30:00'
    weekday:
      - mon
      - tue
      - wed
      - thu
      - fri
action:
  - service: cover.open_cover
    target:
      entity_id:
        - cover.volets_ch1
        - cover.volets_ch2
        - cover.volets_ch3
        - cover.volets_sdb
mode: single
```

You are done, you won't have to run through the house to open and close your shutter anymore, yay!

Do not hesitate to send feedback! (Through GitHub issues, Pull Request, ideas, ...)