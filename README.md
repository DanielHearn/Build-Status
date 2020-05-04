# Travis CI Build Status IoT System
 
This repository is for internet-of-things coursework submission by UP801685.
The code runs on an ESP8266 and uses a TMB12A05 buzzer, 2 green LEDs, 2 yellow LEDs, 2 red LEDs, and a LCD1602 screen.

The code consists of the following files:
- init.lua: Handle WiFi and MQTT connection, create instances of led, lcd, and buzzer files and control them to produce outputs
- buzzer.lua: Handle state and configuration of the TMB12A05 by using PWM to control the buzzer sound.
- led.lua: Handle state and configuration of the LEDs by using GPIO.
- lcd.lua: Handle state and configuration of the LCD1602 screen to display the project name, ID and status.

The code is currently configured to track 1 or 2 Travis CI projects, but can be modified to support more projects if more LEDs are connected and added into the led.lua ledPins table.

The following modules are used in the ESP8266:
- bit
- enduser_setup
- file
- gpio
- http
- i2c
- mqtt
- net
- node
- pwm
- tmr
- uart
- wifi
