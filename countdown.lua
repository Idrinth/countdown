Countdown = {
    Settings= {},
}
local accumulated = 0;
local grace = 0;
local window = "Countdown"
local label = "CountdownTimer"
local header = "CountdownLabel"
local localTimer = 0
local colors = {
    white={r=255, g=255, b=255},
    gold={r=218, g=165, b=32},
    bronze={r=205, g=127 , b=50},
}
local function log(message)
    TextLogAddEntry("Chat", SystemData.ChatLogFilters.SCENARIO, towstring(message))
end
local function slash(input)
    if input == "end" then
        Countdown.Settings.finish = not Countdown.Settings.finish
        log("End enabled? "..tostring(Countdown.Settings.finish))
    elseif input == "start" then
        Countdown.Settings.start = not Countdown.Settings.start
        log("Start enabled? "..tostring(Countdown.Settings.start))
    elseif input == "header" then
        Countdown.Settings.header = not Countdown.Settings.header
        log("Header enabled? "..tostring(Countdown.Settings.header))
    else
        local command, number = input:match("^([a-z:]+) ([0-9]+)$")
        number = tonumber(number)
        if command then
            if command == "size:max" then
                if number < 100 or number > 500 then
                    log("Percentage for size:max must be between 100 and 500")
                else
                    Countdown.Settings.sizeMax = number;
                    log("size:max="..tostring(number).."%")
                end
            elseif command == "size:exponent" then
                if number < 1 or number > 16 then
                    log("Exponent for size:exponent must be between 1 and 16")
                else
                    Countdown.Settings.sizeExponent = number
                    log("size:exponent="..tostring(number))
                end
            elseif command == "grace" then
                if number < 0 or number > 10 then
                    log("Grace period must be between 0 and 10 seconds")
                else
                    Countdown.Settings.grace = number
                    log("grace="..tostring(number))
                end  
            end
        else
            local time = input:match("^([0-9]+)$")
            Countdown.start(tonumber(time))
        end
    end
end
function Countdown.OnInitialize()
    CreateWindow(window, true)
    if WindowGetAnchorCount(window) == 0 then
        WindowAddAnchor(window, "bottom", "Root", "center", 0, 0)
    end
    LabelSetFont(label, ChatSettings.Fonts[4].fontName, WindowUtils.FONT_DEFAULT_TEXT_LINESPACING) -- Age of Reckoning Large
    LabelSetFont(header, ChatSettings.Fonts[4].fontName, WindowUtils.FONT_DEFAULT_TEXT_LINESPACING) -- Age of Reckoning Large
    LayoutEditor.RegisterWindow(window, L"Countdown",L"Countdown for Scenarios and City Sieges", true, true, true, nil, nil, false, 1, nil, nil )
    if LibSlash ~= nil and LibSlash.RegisterSlashCmd ~= nil then --optional dependency
        LibSlash.RegisterSlashCmd("countdown", slash)
        LibSlash.RegisterSlashCmd("icd", slash)
    end
    if Countdown.Settings == nil then
        Countdown.Settings = {}
    end
    if Countdown.Settings.start == nil then
        Countdown.Settings.start = true
    end
    if Countdown.Settings.finish == nil then
        Countdown.Settings.finish = true
    end
    if Countdown.Settings.header == nil then
        Countdown.Settings.header = true
    end
    if Countdown.Settings.sizeMax == nil then
        Countdown.Settings.sizeMax = 500
    end
    if Countdown.Settings.sizeExponent == nil then
        Countdown.Settings.sizeExponent = 8
    end
    if Countdown.Settings.grace == nil then
        Countdown.Settings.grace = 2
    end
end

local function setLabelColor(color)
    LabelSetTextColor(header, color.r, color.g, color.b)
    LabelSetTextColor(label, color.r, color.g, color.b)
end
local function getScale(time)
    local scale = 1 + (Countdown.Settings.sizeMax/100 - 1) * (1 - time/1000) ^ Countdown.Settings.sizeExponent
    if scale > 5 then
        return 5
    elseif scale < 1 then
        return 1
    end
    return scale
end
local function getTimer(time, hideHeader, endText)
    local timer = math.floor(time);
    if time >= timer + 0.5 then
        timer = math.ceil(time)
    end
    timer = tostring(timer)
    if timer == "0" then
        timer = endText
        grace = Countdown.Settings.grace
        WindowSetShowing(header, false)
    else
        WindowSetShowing(header, true and not hideHeader)
    end
    return towstring(timer)
end
local function displayCountdown(time, hideHeader, endText)
    local timer = getTimer(time, hideHeader, endText)
    if time >= 30 then
        setLabelColor(colors.white)
    elseif time >= 10 then
        setLabelColor(colors.gold)
    else
        setLabelColor(colors.bronze)
    end
    WindowSetShowing(window, true)
    if timer ~= LabelGetText(label) then
        WindowSetScale(label, getScale(time) * WindowGetScale(window))
        LabelSetText(label, timer)
        WindowStartAlphaAnimation(label, Window.AnimationType.EASE_OUT, 1, 0, 1+math.max(grace, 0), true, 0, 0)
    end
end

function Countdown.OnUpdate(elapsed)
    accumulated = accumulated + elapsed
    localTimer = localTimer - elapsed
    grace = grace - elapsed
    if accumulated < 0.1 then
        return
    end
    accumulated = 0
    WindowSetShowing(window, grace > 0)
    if GameData.Player.isInScenario then
        if Countdown.Settings.start and GameData.ScenarioData.mode == GameData.ScenarioMode.PRE_MODE then
            LabelSetText(header, L"Starting in")
            displayCountdown(GameData.ScenarioData.timeLeft, not Countdown.Settings.header, "START");
            localTimer = 0
            return
        elseif Countdown.Settings.finish and GameData.ScenarioData.mode == GameData.ScenarioMode.RUNNING and GameData.ScenarioData.timeLeft <= 60 then
            LabelSetText(header, L"Ending in")
            displayCountdown(GameData.ScenarioData.timeLeft, not Countdown.Settings.header, "END");
            localTimer = 0
            return
        end
    end
    if GameData.Player.isInSiege then
        for objectiveIndex = 1, EA_Window_CityTracker.NUM_OBJECTIVES do
            for questIndex = 1, EA_Window_CityTracker.NUM_QUESTS do
                if (DataUtils.activeObjectivesData[objectiveIndex] ~= nil)
                then
                    if DataUtils.activeObjectivesData[objectiveIndex].Quest[questIndex] ~= nil then
                        local quest = DataUtils.activeObjectivesData[objectiveIndex].Quest[questIndex]
                        if quest.timerState ~= GameData.PQTimerState.FROZEN then
                            LabelSetText(header, L"Starting in")
                            displayCountdown(quest.timerValue, not Countdown.Settings.header, "START");
                            localTimer = 0
                            return
                        elseif quest.timerState ~= GameData.PQTimerState.RUNNING and GameData.ScenarioData.timeLeft <= 60 then
                            LabelSetText(header, L"Ending in")
                            displayCountdown(quest.timerValue, not Countdown.Settings.header, "END");
                            localTimer = 0
                            return
                        end
                    end
                end
           end
        end
    end
    if localTimer >= 0 then
        displayCountdown(localTimer, true, "NOW");
    end
end

function Countdown.start(time)
    if time ~= nil and time > 0 then
        localTimer = time
    else
        localTimer = 30
    end
end