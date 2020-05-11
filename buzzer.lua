-- buzzer.lua
-- Control the configuration and state of the TMB12A05 buzzer

buzzer = { }

-- Initialises the buzzer configuration and PWM for the specified pin
function buzzer.init(buzzerPin)
    buzzer.pin = buzzerPin
    buzzer.volume = 0
    buzzer.active = false
    buzzer.buzzerCycles = 11

    -- Initialise PWM
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

-- Cycle buzzer with callbacks so that the main program can control the red LED
function buzzer.cycle(highCallback, lowCallback, finishedCallback)
    buzzerHigh = true
    buzzerCyclesUsed = 1

    -- Create timer for buzzer that turns it on and off
    buzzerCycleTimer = tmr.create()
    buzzerCycleTimer:register(1000, tmr.ALARM_SEMI , function()
        -- Toggle red LED and buzzer depending on current state
        if buzzerHigh == true then
            buzzerHigh = false
            buzzer.stop()
            lowCallback()
        else
            buzzerHigh = true
            buzzer.start()
            highCallback()
        end
    
        -- Repeat buzzer if not all cycles have been used otherwise disable buzzer
        if buzzerCyclesUsed < buzzer.buzzerCycles then
            buzzerCyclesUsed = buzzerCyclesUsed + 1
            buzzerCycleTimer:start()
        else
            print("Buzzer timer disabled")
            buzzer.stop()
            finishedCallback()
            buzzerHigh = true
        end
    end)
    buzzerCycleTimer:start()
end

-- Returns the buzzer object back to the main script
return buzzer
