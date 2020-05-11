-- buzzer.lua
-- Control the configuration and state of the TMB12A05 buzzer

buzzer = { }

-- Initialises the buzzer configuration and PWM for the specified pin
function buzzer.init(buzzerPin)
    buzzer.pin = buzzerPin
    buzzer.volume = 0
    buzzer.active = false
    pwm.setup(buzzerPin, 1000, buzzer.volume)
    pwm.start(buzzerPin)
end

-- Sets the buzzer volume
function buzzer.setVolume (volume)
    buzzer.volume = volume
end

-- Starts the buzzer if it isn't muted
function buzzer.start()
    if (buzzer.muted == false) then
        buzzer.active = true
        pwm.setduty(buzzer.pin, buzzer.volume)
    end
end

-- Stops the buzzer
function buzzer.stop()
    buzzer.active = false
    pwm.setduty(buzzer.pin, 0) 
end

-- Mutes the buzzer
function buzzer.mute()
    pwm.muted = true
end

-- Unmutes the buzzer
function buzzer.unmute()
    pwm.muted = false
end

-- Returns the buzzer object back to the main script
return buzzer
