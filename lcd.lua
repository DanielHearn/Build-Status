-- lcd.lua
-- Controls the state and configuration of the LCD1602 screen

lcd = {}

-- Offset values for each row
local rowOffset = {0x80, 0xC0}

-- Clear both rows of the screen
function lcd.clear()
    lcd.sendData(0x01, 0)
    lcd.sendData(0x02, 0)
end

-- Send data to the screen via i2c
function lcd.sendData(data, mode)
    -- Calculate bit values from specified data and mode
    local offset = 4
    local bitHigh = bit.band(data, 0xF0) + lcd.backlight + mode
    local bitLow = bit.lshift(bit.band(data, 0x0F), offset) + lcd.backlight + mode

    -- Write data to screen
    i2c.start(0)
    i2c.address(0, lcd.address, i2c.TRANSMITTER)
    i2c.write(0, bitHigh + offset, bitHigh, bitLow + offset, bitLow)
    i2c.stop(0)
end

-- Display text on the screen according the specified column and row
function lcd.display(col, row, data)
    -- Select screen column and row with screen cursor
    lcd.sendData(col + rowOffset[row], 0)

    -- Convert numbers to string
    if (type(data) =="number") then
     data = tostring(data)
    end

    -- Send each character individually to the screen
    for i = 1, #data do
        lcd.sendData(data:byte(i), 1)
    end
end

-- Initialise the screen
function lcd.init(SCL, SDA)
    i2c.setup(0, SCL, SDA, i2c.SLOW)
    lcd.address = 0x27
    lcd.backlight = 0x08

    lcd.sendData(0x33, 0)
    lcd.sendData(0x32, 0)
    lcd.sendData(0x28, 0)
    lcd.sendData(0x0C, 0)
    lcd.sendData(0x06, 0)
    lcd.sendData(0x01, 0)
    lcd.sendData(0x02, 0)
end

-- Returns the lcd screen object back to the main script
return lcd
