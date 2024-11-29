﻿#Requires AutoHotkey v2.0

; Script to Simulate Human-like Behavior in AutoHotkey 2.0 with Color Targeting

; Variable definitions with more human-like values
clickIntervalMin := 400  ; 46 seconds in milliseconds
clickIntervalMax := 620  ; 62 seconds in milliseconds
scrollDelayMin := 80
scrollDelayMax := 200
mouseHoldMin := 70
mouseHoldMax := 150
shortBreakMin := 10  ; 10 seconds in milliseconds
shortBreakMax := 60  ; 60 seconds in milliseconds
mouseMoveStepsMin := 15
mouseMoveStepsMax := 40
clicksBeforeBreakMin := 50
clicksBeforeBreakMax := 100

; Define the target color
TargetColor := "0xFF00E7"

Toggle := false
ClickCount := 0

; Added message to confirm script is loaded
MsgBox("Script loaded. Press F5 to start/stop.")

; Hotkey to toggle the clicking action
F5:: {
    global Toggle, ClickCount
    Toggle := !Toggle
    ClickCount := 0
    if (Toggle) {
        MsgBox("Clicking started")
        ClickRandom()
    } else {
        MsgBox("Clicking stopped")
        SetTimer(ClickRandom, 0)
    }
}

ClickRandom() {
    global scrollDelayMin, scrollDelayMax, mouseHoldMin, mouseHoldMax, clicksBeforeBreakMin, clicksBeforeBreakMax, Toggle, ClickCount, clickIntervalMin, clickIntervalMax
    global TargetColor

    if (!Toggle) {
        return
    }

    ; Search for the target color on the entire screen
    if (PixelSearch(&FoundX, &FoundY, 0, 0, A_ScreenWidth, A_ScreenHeight, TargetColor, 3)) {
        ClickX := FoundX
        ClickY := FoundY
    } else {
        ; If color not found, don't click and wait for next iteration
        if (Toggle) {
            SetTimer(ClickRandom, Random(clickIntervalMin, clickIntervalMax))
        }
        return
    }

    ; Occasionally add unrelated actions
    UnrelatedAction := Random(1, 10)
    if (UnrelatedAction <= 2) {
        ScrollAmount := Random(-5, 5)
        Variance := Random(-30, 30)
        MouseX := ClickX + Variance
        MouseY := ClickY + Variance
        MouseMove(MouseX, MouseY, 10)

        if (ScrollAmount != 0) {
            Loop Abs(ScrollAmount) {
                Send "{Space}"
                Sleep(Random(scrollDelayMin, scrollDelayMax))
            }
        }

        Sleep(Random(800, 2000))
    }

    ; Move to target position with a smooth motion
    MouseMoveBezier(ClickX, ClickY)

    Hesitation()

    ; Decide between single or double click
    ClickType := Random(1, 100)
    if (ClickType <= 90) {
        HoldTime := Random(mouseHoldMin, mouseHoldMax)
        Click("down")
        DragX := Random(-3, 3)
        DragY := Random(-3, 3)
        MouseMove(ClickX + DragX, ClickY + DragY, 5)
        Sleep(HoldTime)
        Click("up")
    } else {
        Click(2)
    }

    ClickCount++
    if (ClickCount >= RandomClicksBeforeBreak()) {
        SleepTime := Random(shortBreakMin, shortBreakMax)
        Sleep(SleepTime)
        ClickCount := 0
    }

    BreakIntervals()

    if (Toggle) {
        SetTimer(ClickRandom, Random(clickIntervalMin, clickIntervalMax))
    }
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

        SleepTime := Random(5, 15)
        Sleep(SleepTime)
    }
    
    FinalMovementJitter(x,y)
}

FinalMovementJitter(x,y) {
   JitterX := Random(-2, 2)
   JitterY := Random(-2, 2)
   MouseMove(x+JitterX, y+JitterY, 10)
   Sleep(Random(20, 70))
   MouseMove(x, y, 0)
}

BezierPoint(t,p0,p1,p2,p3) {
   return (1-t)**3 *p0+3 *(1-t)**2 *t*p1+3 *(1-t)*t**2 *p2+t**3 *p3 
}

EaseInOutQuad(t) {
   return (t<0.5)?2*t*t:-1 +(4-2*t)*t 
}

RandomClicksBeforeBreak() {
   global clicksBeforeBreakMin, clicksBeforeBreakMax 
   return Random(clicksBeforeBreakMin, clicksBeforeBreakMax)
}

BreakIntervals() {
   global shortBreakMin, shortBreakMax 
   BreakChance := Random(1, 100)
   if (BreakChance <= 5) {
      BreakTime := Random(shortBreakMin, shortBreakMax)
      Sleep(BreakTime)
   }
}

Hesitation() {
   HesitationChance := Random(1, 100)
   if (HesitationChance <= 15) {
      HesitationTime := Random(300, 1500)
      Sleep(HesitationTime)
   }
}