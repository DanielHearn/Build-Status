-- led.lua
-- Controls the state and configuration of the LEDs used to display build statuses

led = { }

-- The GPIO pins for the connected LEDs
-- The number of nested tables must equal the number of connected LED groups
local LED_PINS = {{green = 0, yellow = 1, red = 2}, {green = 5, yellow = 6, red = 7}}

local LED_VALUES = {on=gpio.HIGH, off=gpio.LOW}

-- Initialise LEDs
function led.init()
    -- Set GPIO output and low signal to LED pins for each LED group
    for k, v in pairs(LED_PINS) do
        gpio.mode(v.green, gpio.OUTPUT)
        gpio.write(v.green, gpio.LOW)
        gpio.mode(v.yellow, gpio.OUTPUT)
        gpio.write(v.yellow, gpio.LOW)
        gpio.mode(v.red, gpio.OUTPUT)
        gpio.write(v.red, gpio.LOW)
    end
end

-- Light the LEDs for a project based on the specified LED table
-- e.g. led.lightProjectLeds(1, {g="on",y="off",r="off"})
function led.lightProjectLeds(id, values)
    local pins = LED_PINS[id]
    gpio.write(pins.green, LED_VALUES[values.g])
    gpio.write(pins.yellow, LED_VALUES[values.y])   
    gpio.write(pins.red, LED_VALUES[values.r])
end

-- Returns the led object back to the main script
return led
