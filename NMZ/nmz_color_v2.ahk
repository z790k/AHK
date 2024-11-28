#Requires AutoHotkey v2.0

; Initialize variables with default values
clickIntervalMin := 342
clickIntervalMax := 620
scrollDelayMin := 80
scrollDelayMax := 200
mouseHoldMin := 70
mouseHoldMax := 150
shortBreakMin := 10
shortBreakMax := 60
mouseMoveStepsMin := 15
mouseMoveStepsMax := 40
clicksBeforeBreakMin := 50
clicksBeforeBreakMax := 100
pixelSearchErrorMargin := 3  ; Adjustable PixelSearch error margin

; Define the target color
TargetColor := "0xFF00E7"

Toggle := false
ClickCount := 0

; Enhanced GUI for AHK v2
Gui, New, , Auto Clicker Configuration
Gui.Add("GroupBox", "x10 y10 w300 h100", "Click Intervals")
Gui.Add("Text", "x20 y40", "Min (ms):")
Gui.Add("Edit", "vClickIntervalMin w50 x100 y40", clickIntervalMin)
Gui.Add("Text", "x170 y40", "Max (ms):")
Gui.Add("Edit", "vClickIntervalMax w50 x250 y40", clickIntervalMax)

Gui.Add("GroupBox", "x10 y120 w300 h100", "Scroll Delay")
Gui.Add("Text", "x20 y150", "Min (ms):")
Gui.Add("Edit", "vScrollDelayMin w50 x100 y150", scrollDelayMin)
Gui.Add("Text", "x170 y150", "Max (ms):")
Gui.Add("Edit", "vScrollDelayMax w50 x250 y150", scrollDelayMax)

Gui.Add("GroupBox", "x10 y230 w300 h100", "Mouse Hold Duration")
Gui.Add("Text", "x20 y260", "Min (ms):")
Gui.Add("Edit", "vMouseHoldMin w50 x100 y260", mouseHoldMin)
Gui.Add("Text", "x170 y260", "Max (ms):")
Gui.Add("Edit", "vMouseHoldMax w50 x250 y260", mouseHoldMax)

Gui.Add("GroupBox", "x10 y340 w300 h100", "Short Breaks")
Gui.Add("Text", "x20 y370", "Min (ms):")
Gui.Add("Edit", "vShortBreakMin w50 x100 y370", shortBreakMin)
Gui.Add("Text", "x170 y370", "Max (ms):")
Gui.Add("Edit", "vShortBreakMax w50 x250 y370", shortBreakMax)

Gui.Add("GroupBox", "x10 y450 w300 h100", "Other Parameters")
Gui.Add("Text", "x20 y480", "PixelSearch Error:")
Gui.Add("Edit", "vPixelSearchErrorMargin w50 x150 y480", pixelSearchErrorMargin)

Gui.Add("Button", "x20 y560 w100 gStartClicking", "Start")
Gui.Add("Button", "x140 y560 w100 gStopClicking", "Stop")
Gui.Add("Button", "x260 y560 w100 gSaveConfig", "Save Config")

Gui.Add("Text", "vStatusIndicator x20 y610", "Status: Idle")
Gui.Show()

; Functions for GUI and core logic
SubmitParameters() {
    global clickIntervalMin, clickIntervalMax, scrollDelayMin, scrollDelayMax
    global mouseHoldMin, mouseHoldMax, shortBreakMin, shortBreakMax, pixelSearchErrorMargin
    Gui.Submit()
}

ValidateParameters() {
    global clickIntervalMin, clickIntervalMax, scrollDelayMin, scrollDelayMax
    global mouseHoldMin, mouseHoldMax, shortBreakMin, shortBreakMax, clicksBeforeBreakMin, clicksBeforeBreakMax

    if (clickIntervalMin > clickIntervalMax
        || scrollDelayMin > scrollDelayMax
        || mouseHoldMin > mouseHoldMax
        || shortBreakMin > shortBreakMax
        || clicksBeforeBreakMin > clicksBeforeBreakMax) {
        MsgBox "Error: Invalid parameter configuration. Ensure Min values are less than Max values."
        return false
    }
    return true
}

StartClicking() {
    if (!ValidateParameters()) return ; Abort if parameters are invalid
    global Toggle
    Toggle := true
    UpdateStatus("Clicking Started")
    ClickRandom()
}

StopClicking() {
    global Toggle
    if (!Toggle) return
    Toggle := false
    UpdateStatus("Idle")
    MsgBox "Clicking has been stopped."
}

UpdateStatus(message) {
    GuiControl.Set("StatusIndicator", "Status: " message)
}

ClickRandom() {
    try {
        global Toggle, TargetColor, pixelSearchErrorMargin, ClickCount
        global clickIntervalMin, clickIntervalMax, scrollDelayMin, scrollDelayMax
        global mouseHoldMin, mouseHoldMax, clicksBeforeBreakMin, clicksBeforeBreakMax
        global shortBreakMin, shortBreakMax

        if (!Toggle) return

        ; Perform PixelSearch
        if (!PixelSearch(&FoundX, &FoundY, 0, 0, A_ScreenWidth, A_ScreenHeight, TargetColor, pixelSearchErrorMargin)) {
            UpdateStatus("Target color not found! Adjust settings.")
            Sleep(Random(500, 1500)) ; Retry after a short delay
            return
        }

        ClickWithImprecision(FoundX, FoundY)

        ; Increment ClickCount and handle breaks
        ClickCount++
        if (ClickCount >= RandomClicksBeforeBreak()) {
            Sleep(Random(shortBreakMin, shortBreakMax))
            ClickCount := 0
        }

        ; Schedule next click with random interval
        SetTimer(ClickRandom, Random(clickIntervalMin, clickIntervalMax))
    } catch Exception {
        LogError(Exception.Message)
    }
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
    FileAppend "Error [" A_Now "]: " message "`n", "error_log.txt"
    UpdateStatus("Error: " message)
}

Random(min, max) {
    return Round(RandomFloat(min, max))
}

RandomFloat(min, max) {
    return min + (max - min) * Rnd()
}

RandomClicksBeforeBreak() {
    global clicksBeforeBreakMin, clicksBeforeBreakMax
    return Random(clicksBeforeBreakMin, clicksBeforeBreakMax)
}