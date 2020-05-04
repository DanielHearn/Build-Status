led = { }
local ledPins = {{green = 0, yellow = 1, red = 2}, {green = 5, yellow = 6, red = 7}}
local ledValueMapping = {on=gpio.HIGH, off=gpio.LOW}
function led.init()
    -- Load GPIO output for LED pins
    for k, v in pairs(ledPins) do
        gpio.mode(v.green, gpio.OUTPUT)
        gpio.write(v.green, gpio.LOW)
        gpio.mode(v.yellow, gpio.OUTPUT)
        gpio.write(v.yellow, gpio.LOW)
        gpio.mode(v.red, gpio.OUTPUT)
        gpio.write(v.red, gpio.LOW)
    end
end
function led.lightProjectLeds(id, values)
    local pins = ledPins[id]
    gpio.write(pins.green, ledValueMapping[values.g])
    gpio.write(pins.yellow, ledValueMapping[values.y])   
    gpio.write(pins.red, ledValueMapping[values.r])
end
return led