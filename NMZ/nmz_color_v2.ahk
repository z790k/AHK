#Requires AutoHotkey v2.0

; Initialize variables with default values
clickIntervalMin := 20
clickIntervalMax := 20
scrollDelayMin := 20
scrollDelayMax := 20
mouseHoldMin := 20
mouseHoldMax := 20
shortBreakMin := 20
shortBreakMax := 20
mouseMoveStepsMin := 20
mouseMoveStepsMax := 20
clicksBeforeBreakMin := 20
clicksBeforeBreakMax := 20
pixelSearchErrorMargin := 20  ; Adjustable PixelSearch error margin

; Define the target color
TargetColor := "0xff00e7"

Toggle := false
ClickCount := 0

; Enhanced GUI for AHK v2
#Requires AutoHotkey v2.0

MyGui := Gui()
MyGui.Title := "Auto Clicker Configuration"

MyGui.Add("GroupBox", "x10 y10 w300 h100", "Click Intervals")
MyGui.Add("Text", "x20 y40", "Min (ms):")
MyGui.Add("Edit", "vClickIntervalMin w50 x100 y40", clickIntervalMin)
MyGui.Add("Text", "x170 y40", "Max (ms):")
MyGui.Add("Edit", "vClickIntervalMax w50 x250 y40", clickIntervalMax)

MyGui.Add("GroupBox", "x10 y120 w300 h100", "Scroll Delay")
MyGui.Add("Text", "x20 y150", "Min (ms):")
MyGui.Add("Edit", "vScrollDelayMin w50 x100 y150", scrollDelayMin)
MyGui.Add("Text", "x170 y150", "Max (ms):")
MyGui.Add("Edit", "vScrollDelayMax w50 x250 y150", scrollDelayMax)

MyGui.Add("GroupBox", "x10 y230 w300 h100", "Mouse Hold Duration")
MyGui.Add("Text", "x20 y260", "Min (ms):")
MyGui.Add("Edit", "vMouseHoldMin w50 x100 y260", mouseHoldMin)
MyGui.Add("Text", "x170 y260", "Max (ms):")
MyGui.Add("Edit", "vMouseHoldMax w50 x250 y260", mouseHoldMax)

MyGui.Add("GroupBox", "x10 y340 w300 h100", "Short Breaks")
MyGui.Add("Text", "x20 y370", "Min (ms):")
MyGui.Add("Edit", "vShortBreakMin w50 x100 y370", shortBreakMin)
MyGui.Add("Text", "x170 y370", "Max (ms):")
MyGui.Add("Edit", "vShortBreakMax w50 x250 y370", shortBreakMax)

MyGui.Add("GroupBox", "x10 y450 w300 h100", "Other Parameters")
MyGui.Add("Text", "x20 y480", "PixelSearch Error:")
MyGui.Add("Edit", "vPixelSearchErrorMargin w50 x150 y480", pixelSearchErrorMargin)

MyGui.Add("Button", "x20 y560 w100", "Start").OnEvent("Click", StartClicking)
MyGui.Add("Button", "x140 y560 w100", "Stop").OnEvent("Click", StopClicking)
MyGui.Add("Button", "x260 y560 w100", "Save Config").OnEvent("Click", SaveConfig)

StatusIndicator := MyGui.Add("Text", "x20 y610", "Status: Idle")

MyGui.Show()

; Functions
SubmitParameters(*) {
    SavedValues := MyGui.Submit(false)
    clickIntervalMin := SavedValues.ClickIntervalMin
    clickIntervalMax := SavedValues.ClickIntervalMax
    scrollDelayMin := SavedValues.ScrollDelayMin
    scrollDelayMax := SavedValues.ScrollDelayMax
    mouseHoldMin := SavedValues.MouseHoldMin
    mouseHoldMax := SavedValues.MouseHoldMax
    shortBreakMin := SavedValues.ShortBreakMin
    shortBreakMax := SavedValues.ShortBreakMax
    pixelSearchErrorMargin := SavedValues.PixelSearchErrorMargin
}

StartClicking(*) {
    global Toggle
    SubmitParameters()
    Toggle := true
    UpdateStatus("Running")
    SetTimer(ClickRandom, 100)
}

StopClicking(*) {
    UpdateStatus("Stopped")
    Toggle := false
    SetTimer(ClickRandom, 0)
}

SaveConfig(*) {
    SubmitParameters()
    ; Implement config saving logic here
}

UpdateStatus(message) {
    global StatusIndicator
    StatusIndicator.Value := "Status: " . message
    StatusIndicator.Redraw()
    ; Force a GUI update
    SetTimer(() => MyGui.Opt("+AlwaysOnTop"), -1)
    SetTimer(() => MyGui.Opt("-AlwaysOnTop"), -50)
}

global lastMissed := false
global recentAreas := []

ClickRandom() {
    global Toggle, A_ScreenWidth, A_ScreenHeight, TargetColor, pixelSearchErrorMargin, ClickCount, lastMissed, recentAreas

    if (!Toggle) {
        SetTimer(ClickRandom, 0)
        return
    }

    try {
        ; Decide whether to do a full screen search (10% chance)
        if (Random(1, 100) <= 10) {
            searchX := 0
            searchY := 0
            searchWidth := A_ScreenWidth
            searchHeight := A_ScreenHeight
        } else {
            ; Dynamic area selection with central bias
            loop {
                cellWidth := A_ScreenWidth // Random(4, 6)
                cellHeight := A_ScreenHeight // Random(4, 6)
                
                ; Bias towards center by adjusting random range
                cellX := Random(cellWidth // 2, A_ScreenWidth - cellWidth) // cellWidth * cellWidth
                cellY := Random(cellHeight // 2, A_ScreenHeight - cellHeight) // cellHeight * cellHeight
            
                searchX := cellX + Random(-cellWidth/8, cellWidth/8)
                searchY := cellY + Random(-cellHeight/8, cellHeight/8)
                searchWidth := cellWidth + Random(-cellWidth/8, cellWidth/8)
                searchHeight := cellHeight + Random(-cellHeight/8, cellHeight/8)
            
                searchX := Max(0, Min(searchX, A_ScreenWidth - searchWidth))
                searchY := Max(0, Min(searchY, A_ScreenHeight - searchHeight))
            
                areaKey := searchX . "," . searchY . "," . searchWidth . "," . searchHeight
            
                if (!HasValue(recentAreas, areaKey))
                    break
            }
            ; Add to recent areas and remove oldest if more than 5
            recentAreas.Push(areaKey)
            if (recentAreas.Length > 5)
                recentAreas.RemoveAt(1)
        }

        UpdateStatus("Searching in area: " . searchX . "," . searchY)

        if (PixelSearch(&FoundX, &FoundY, searchX, searchY, searchX + searchWidth, searchY + searchHeight, TargetColor, pixelSearchErrorMargin)) {
            UpdateStatus("Color found at " . FoundX . ", " . FoundY)
            
            if (lastMissed || Random(1, 100) > 10) {
                ; Click accurately
                ClickWithImprecision(FoundX, FoundY)
                UpdateStatus("Clicked accurately at " . FoundX . ", " . FoundY)
                lastMissed := false
            } else {
                ; Intentionally miss
                UpdateStatus("Intentionally missed click")
                lastMissed := true
            }

            ClickCount++
            if (ClickCount >= RandomClicksBeforeBreak()) {
                UpdateStatus("Taking a short break...")
                Sleep(Random(shortBreakMin, shortBreakMax))
                ClickCount := 0
            }
        } else {
            UpdateStatus("Color not found in this area, trying again...")
        }
    } catch as e {
        LogError("Error in ClickRandom: " . e.Message)
    }

    if (Toggle) {
        nextInterval := Random(clickIntervalMin, clickIntervalMax)
        UpdateStatus("Next search in " . nextInterval . "ms")
        SetTimer(ClickRandom, -nextInterval)
    }
}

; Helper function to check if a value exists in an array
HasValue(haystack, needle) {
    for index, value in haystack
        if (value = needle)
            return true
    return false
}

ClickWithImprecision(x, y) {
    ImpreciseX := x + Random(-3, 3)
    ImpreciseY := y + Random(-3, 3)
    MouseMoveBezierWithOvershoot(ImpreciseX, ImpreciseY)
    ClickWithPressure()
}

ClickWithPressure() {
    global mouseHoldMin, mouseHoldMax
    Click("Down")
    Sleep(Random(mouseHoldMin, mouseHoldMax))
    Click("Up")
}

MouseMoveBezierWithOvershoot(x, y) {
    global mouseMoveStepsMin, mouseMoveStepsMax
    MouseGetPos(&CurrentX, &CurrentY)

    OvershootX := x + Random(-10, 10)
    OvershootY := y + Random(-10, 10)

    MouseMoveBezier(OvershootX, OvershootY)
    Sleep(Random(50, 150)) ; Pause at overshoot point
    MouseMoveBezier(x, y)
}

MouseMoveBezier(x, y) {
    global mouseMoveStepsMin, mouseMoveStepsMax
    MouseGetPos(&CurrentX, &CurrentY)

    ControlX1 := Random(0, A_ScreenWidth)
    ControlY1 := Random(0, A_ScreenHeight)
    ControlX2 := Random(0, A_ScreenWidth)
    ControlY2 := Random(0, A_ScreenHeight)

    Steps := Max(Random(mouseMoveStepsMin, mouseMoveStepsMax), mouseMoveStepsMin)

    Loop Steps {
        t := A_Index / Steps
        easedT := EaseInOutQuad(t)

        CurrentX := BezierPoint(easedT, CurrentX, ControlX1, ControlX2, x)
        CurrentY := BezierPoint(easedT, CurrentY, ControlY1, ControlY2, y)
        MouseMove(Round(CurrentX), Round(CurrentY), 0)
        Sleep(Random(5, 15))
    }
}

EaseInOutQuad(t) {
    return (t < 0.5) ? 2 * t * t : -1 + (4 - 2 * t) * t
}

BezierPoint(t, p0, p1, p2, p3) {
    return (1 - t)**3 * p0 + 3 * (1 - t)**2 * t * p1 + 3 * (1 - t) * t**2 * p2 + t**3 * p3
}

LogError(message) {
    FileAppend("Error [" . A_Now . "]: " . message . "`n", "error_log.txt")
    UpdateStatus("Error: " . message)
}



RandomFloat(min, max) {
    return min + (max - min) * Random(0.0, 1.0)
}




RandomClicksBeforeBreak() {
    global clicksBeforeBreakMin, clicksBeforeBreakMax
    return Random(clicksBeforeBreakMin, clicksBeforeBreakMax)
}

Esc::
{
    global Toggle
    Toggle := false
    SetTimer(ClickRandom, 0)
    UpdateStatus("Emergency Stop - Exiting")
    Sleep(500)  ; Give a moment for the status to update
    ExitApp  ; This will completely terminate the script
}
