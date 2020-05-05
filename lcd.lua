lcd = {}
local _offsets = { [0] = 0x80, 0xC0, 0x90, 0xD0 } -- 16x4

function lcd.clear()
    lcd.sendData(0x01, 0)
    lcd.sendData(0x02, 0)
end

function lcd.sendData(data, mode)
    local bitHigh = bit.band(data, 0xF0) + lcd.ctl + mode
    local bitLow = bit.lshift(bit.band(data, 0x0F), 4) + lcd.ctl + mode
    i2c.start(0)
    i2c.address(0, lcd.address, i2c.TRANSMITTER)
    i2c.write(0, bitHigh + 4, bitHigh, bitLow + 4, bitLow)
    i2c.stop(0)
end

function lcd.display(col, row, data)
    lcd.sendData(col + _offsets[row], 0)
    
    if (type(data) =="number") then
     data = tostring(data)
    end

    for i = 1, #data do
        lcd.sendData(data:byte(i), 1)
    end
end

function lcd.init(SCL, SDA)
    i2c.setup(0, SCL, SDA, i2c.SLOW)
    lcd.address = 0x27
    lcd.ctl = 0x08
    
    lcd.sendData(0x33, 0)
    lcd.sendData(0x32, 0)
    lcd.sendData(0x28, 0)
    lcd.sendData(0x0C, 0)
    lcd.sendData(0x06, 0)
    lcd.sendData(0x01, 0)
    lcd.sendData(0x02, 0)
end

return lcd
