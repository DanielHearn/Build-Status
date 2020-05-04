buzzer = { }
function buzzer.init(buzzerPin)
    buzzer.pin = buzzerPin
    buzzer.volume = 0
    buzzer.active = false
    pwm.setup(buzzerPin, 1000, buzzer.volume)
    pwm.start(buzzerPin)
end
function buzzer.setVolume (volume)
    buzzer.volume = volume
end
function buzzer.start()
    if (buzzer.muted == false) then
        buzzer.active = true
        pwm.setduty(buzzer.pin, buzzer.volume)
    end
end
function buzzer.stop()
    buzzer.active = false
    pwm.setduty(buzzer.pin, 0) 
end
function buzzer.mute()
    pwm.muted = true
end
function buzzer.unmute()
    pwm.muted = false
end
return buzzer
