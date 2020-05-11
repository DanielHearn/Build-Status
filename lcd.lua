-- lcd.lua
-- Controls the state and configuration of the LCD1602 screen

lcd = {}

-- Screen Codes
local ADDRESS = 0x27
local BACKLIGHT_ON = 0x08
local FIRST_ROW = 0x80
local SECOND_ROW = 0xC0
local FOUR_BIT_MODE = 0x28
local CLEAR_DISPLAY = 0x01
local RETURN_HOME = 0x02
local DISPLAY_ON = 0x0C
local CGRAM_ADDRESS = 0x06

-- Offset values for each row
local ROW_OFFSET = {FIRST_ROW, SECOND_ROW}

-- Clear both rows of the screen
function lcd.clear()
    lcd.sendData(CLEAR_DISPLAY, 0)
    lcd.sendData(RETURN_HOME, 0)
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
    lcd.sendData(col + ROW_OFFSET[row], 0)

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
    -- Start i2c connection
    i2c.setup(0, SCL, SDA, i2c.SLOW)
    lcd.address = ADDRESS
    lcd.backlight = BACKLIGHT_ON

    -- Start screen
    lcd.sendData(0x33, 0)
    lcd.sendData(0x32, 0)
    lcd.sendData(FOUR_BIT_MODE, 0)
    lcd.sendData(DISPLAY_ON, 0)
    lcd.sendData(CGRAM_ADDRESS, 0)
    lcd.sendData(CLEAR_DISPLAY, 0)
    lcd.sendData(RETURN_HOME, 0)
    lcd.clear()
end

-- Returns the lcd screen object back to the main script
return lcd
