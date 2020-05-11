-- init.lua
-- Contains the main system logic including MQTT communication

-- Config Variables
BUZZER_PIN = 8
LCD_SDA_PIN = 3
LCD_SCL_PIN = 4
BROKER_IP = "io.adafruit.com"
TOPIC_ROOT = "Danhearn/feeds/"
PROJECT_STATUS_TOPIC = TOPIC_ROOT.."project-status"
VOLUME_TOPIC = TOPIC_ROOT.."volume"
MUTED_TOPIC = TOPIC_ROOT.."muted"
MESSAGE_TOPIC = TOPIC_ROOT.."messages"
BROKER_PORT = 1883
BROKER_USERNAME = "Danhearn"
BROKER_KEY = "test"

-- Map travis build state to a user friendly status string
STATUS_TEXT = {failed = "Failed", started = "Building", passed = "Passed"}

-- State Variables
projects = {}
projectMapping = {}
currentProjectID = 1
projectDisplayID = 1
brokerConnection = nil
lcd = nil
led = nil
buzzer = nil
pingTimer = nil
screenTimer = nil

-- Initialise configuration, WiFi and hardware components
function init()
    print("Initialising")

    -- Initialise buzzer
    buzzer = require("buzzer")
    buzzer.init(BUZZER_PIN)

    -- Initialise screen
    lcd = require("lcd")
    lcd.init(LCD_SCL_PIN, LCD_SDA_PIN)
    lcd.clear()
    lcd.display(0, 1, "Build_Status")
    lcd.display(0, 2, "IP:192.168.4.1")

    -- Initialise LEDs
    led = require("led")
    led.init()

    startWifi()
end


function startWifi()
    -- Setp WiFi config for the end user network
    wifi.setmode(wifi.STATIONAP)
    --wifi.ap.config({ssid="Build_Status", auth=wifi.OPEN})

    -- Start end user module for WiFi connection
    --enduser_setup.manual(true)
    enduser_setup.start(
      function()
        print("Connected to WiFi network")
        local IP = wifi.sta.getip()

        -- Check that connection is valid and start MQTT connection initialisation
        if IP ~= nil then
            print("Connected to WiFi as: "..IP)
            collectgarbage()
            connectToBroker()
        end
      end,
      -- Handle end user errors
      function(error, string)
        print("End user error: #"..error..": "..string)
        lcd.clear()
        lcd.display(0, 1, "WiFi error")

        -- Attempt to reconnect to the WiFi network
        startWifi()
      end
    )
end

function setupIntervals(client)
    -- Update screen with project build status every 5 seconds
    -- Shows each project in order with their ID, name, and last build status
    screenTimer = tmr.create()
    screenTimer:register(5000, tmr.ALARM_AUTO, function()
        lcd.clear()

        -- Check if projects are being tracked
        -- If no projects are tracked then display waiting message
        -- Else show build status while looping through available project IDs
        if(currentProjectID == 1) then
            lcd.display(0, 1, "Waiting for")
            lcd.display(0, 2, "build updates")
        else
            local projectName = projectMapping[projectDisplayID]
            lcd.display(0, 1, projectName)
            lcd.display(0, 2, "ID:"..projectDisplayID..","..STATUS_TEXT[projects[projectName]["status"]])
            if (projectDisplayID < currentProjectID - 1) then
                projectDisplayID = projectDisplayID + 1 
            else
                projectDisplayID = 1
            end
        end
        collectgarbage()
    end)
    screenTimer:start()

    -- Ping MQTT broker every 60 seconds to maintaing connection
    pingTimer = tmr.create()
    pingTimer:register(60000, tmr.ALARM_AUTO, function()
        print("Sending ping")
        client:publish(VOLUME_TOPIC.."/get", 0, 1, 0)
        collectgarbage()
    end)
    pingTimer:start()
end

function onBrokerConnection(client)
    print("Subscribed to feeds")
    lcd.clear()
    lcd.display(0, 1, "Waiting for")
    lcd.display(0, 2, "build updates")
    
    -- Send last value requests to feeds
    -- The /get string is added to the topic as the adafruit broker doesn't support
    -- MQTT retained messages and this is their workaround
    client:publish(VOLUME_TOPIC.."/get", 0, 1, 0)
    client:publish(MUTED_TOPIC.."/get", 0, 1, 0)

    setupIntervals(client)
end

-- Connect to the MQTT broker
function connectToBroker()
    -- Connect to broker
    brokerConnection = mqtt.Client("Client1", 240, BROKER_USERNAME, BROKER_KEY, 1, 10000)
    brokerConnection:lwt("/lwt","Now offline", 1, 0)

    -- On succesfull broker connection subscribe to all fields
    brokerConnection:on("connect", function(client) 
        print("Client connected")
        print("MQTT client connected to "..BROKER_IP)
        client:subscribe({[PROJECT_STATUS_TOPIC]=0, [VOLUME_TOPIC]=1, [MUTED_TOPIC]=2, [MESSAGE_TOPIC]=3}, onBrokerConnection)
    end)
    
    -- On broker disconnect attempt reconnection
    brokerConnection:on("offline",function(client)
        print("Client offline")
        lcd.clear()
        lcd.display(0, 1, "MQTT offline")

        -- Try to reconnect to the broker
        connectToBroker()
    end)

    -- On broker message process message data based on the topic
    brokerConnection:on("message",function(client, topic, data)
        -- Only accept valid data
        if data ~= nil then
            -- Process the message depending on the topic is was sent in
            if topic == PROJECT_STATUS_TOPIC then
                processProjectMessage(data)
            elseif topic == VOLUME_TOPIC then
                processVolumeMessage(data)
            elseif topic == MUTED_TOPIC then
                processMuteMessage(data)
            elseif topic ~= MESSAGE_TOPIC then
                -- Handle messages that don't fit any of the expected topics
                brokerConnection:publish(MESSAGE_TOPIC, "Error: Unexpected message received by ESP: "..data, 0, 0)
            end
        end
        collectgarbage()
    end)

    -- Connect to broker
    brokerConnection:connect(BROKER_IP, BROKER_PORT, false, false, function(conn) end, function(conn,reason)
        print("Fail! Failed reason is: "..reason)

        -- Try to reconnect to the broker
        connectToBroker()
    end)
end

function processVolumeMessage(data)
    local volumeValue = tonumber(data)
    data = nil
    
    -- Validate volume is within the expected range according the MQTT dashboard slider input
    if volumeValue >= 0 and volumeValue <= 100 then
        buzzer.volume = volumeValue*10
        print("New volume: "..tostring(buzzer.volume))
    end
end

function processMuteMessage(data)
    -- Validate muted value is one of the expected two values sent by the MQTT dashboard
    -- switch input
    if data == "YES" then
        buzzer.muted = true
    elseif data == "NO" then
        buzzer.muted = false
    end
    data = nil
    print("New muted: "..tostring(buzzer.muted))
end

function processProjectMessage(data)
    -- Retrieve the required substrings from the project status message
    local nameMatch = string.match(data, '"name":"[%w%d%s_-]*"')
    local stateMatch = string.match(data, '"state":"[%w%d%s_-]*"')
    data = nil
    collectgarbage()
    
    -- Only continue processing if the required strings are found
    if (nameMatch ~= nil and stateMatch ~= nil) then
        
        -- Retrieve values from JSON substrings
        local name = string.sub(nameMatch, 9, string.len(nameMatch)-1)
        nameMatch = nil
        local state = string.sub(stateMatch, 10, string.len(stateMatch)-1)
        stateMatch = nil
        
        if name then
            -- Check if project name already exists in the state
            if projects[name] then
                print("New build status for: "..name..", "..state)
                brokerConnection:publish(MESSAGE_TOPIC, "New build status: "..name..", "..state, 0, 0)
                -- Update project status
                projects[name]["status"] = state
                collectgarbage()

                -- Update LEDs and check if buzzer needed
                showStatus(name)
            else
                if currentProjectID <= 2 then
                    print("New project for: "..name..", "..state)
                    brokerConnection:publish(MESSAGE_TOPIC, "New project being tracked: "..name..", "..state, 0, 0)
                    
                    -- Create new project
                    projects[name] = {name=name, status=state, id=currentProjectID}
                    projectMapping[currentProjectID] = name
                    currentProjectID = currentProjectID + 1
                    collectgarbage()

                    -- Update LEDs and check if buzzer needed
                    showStatus(name)
               else
                    print("Project limit reached")
                    brokerConnection:publish(MESSAGE_TOPIC, "Error: Project limit reached", 0, 0)
               end 
            end
        end

        -- Clear variables to save memory
        name = nil
        state = nil
    else
        -- Handle invalid project status strings that don't match expected structure
        print("Invalid project status string")
        brokerConnection:publish(MESSAGE_TOPIC, "Error: Invalid project status string", 0, 0)
    end
end

function showStatus(name)
    -- Retrieve required values from project
    local project = projects[name]
    local turnBuzzerOn = false
    print("Showing status for ID: "..project["id"]..", "..project["name"].." with status: "..project["status"])

    -- If yellow LED is still flashing then stop and unregister the timer
    if (project["buildingFunction"] ~= nil) then
       projects[project["name"]]["buildingFunction"]:unregister()
       projects[project["name"]]["buildingFunction"] = nil 
    end

    -- Check project status
    if project["status"] == "passed" then
        print(project["name"].." green LED is now on")

        -- Turn green LED on and turn off the yellow and red LEDs
        led.lightProjectLeds(project["id"], {g="on",y="off",r="off"}) 
    elseif project["status"] == "started" then
        print(project["name"].." yellow LED is now on")
        
        -- Turn yellow LED on and turn off the green and red LEDs
        led.lightProjectLeds(project["id"], {g="off",y="on",r="off"}) 

        local buildingActive = false

        -- Start flashing the yellow LED until the project status changes
        projects[project["name"]]["buildingFunction"] = tmr.create()
        projects[project["name"]]["buildingFunction"]:register(1000, tmr.ALARM_AUTO , function()
            if buildingActive == true then
                buildingActive = false
                led.lightProjectLeds(project["id"], {g="off",y="off",r="off"})     
            else
                buildingActive = true
                led.lightProjectLeds(project["id"], {g="off",y="on",r="off"})    
            end
        end)
        projects[project["name"]]["buildingFunction"]:start()
    elseif project["status"] == "failed" then
        print(project["name"].." red LED is now on")
        turnBuzzerOn = true

        -- Turn red LED on and turn off the green and yellow LEDs
        led.lightProjectLeds(project["id"], {g="off",y="off",r="on"})       

        if buzzer.active == false then
            print("Buzzer timer active")

            -- Start buzzer cycle in synchronisation with the red LED
            buzzer.cycle(function()
                led.lightProjectLeds(project["id"], {g="off",y="off",r="on"}) 
            end, function()
                led.lightProjectLeds(project["id"], {g="off",y="off",r="off"}) 
            end, function()
                led.lightProjectLeds(project["id"], {g="off",y="off",r="on"}) 
                turnBuzzerOn = false
            end)
            collectgarbage()
        end
    else
       -- Turn all LEDs on to indicate an error
       led.lightProjectLeds(project["id"], {g="on",y="on",r="on"}) 
        
       brokerConnection:publish(MESSAGE_TOPIC, project["name"].." unexpected project status received", 0, 0)
    end
    collectgarbage()
end

-- Start project status program
init()
