/*  Calipers
    Portable AHK based tool for on-screen measurements.
    "Auto calibration" scans for vertical lines.
    "Auto level" scans for horizontal lines.
    Calculations
    March-out with drag of any line
*/

#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance Force  ; only allow one running instance per user
#MaxMem 128
#Include %A_ScriptDir%\includes
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
CoordMode, Mouse, Screen

SetWorkingDir %A_ScriptDir%
SetTitleMatchMode, 2

GdipOBJ:={X: 0 ,Y: 0 ,W: A_ScreenWidth, H: A_ScreenHeight } 
active_Draw:=0
calArray := {}
scale := ""

Gui, 1: -Caption +E0x80000 +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs
Gui, 1:Show, Maximize
GdipOBJ := Layered_Window_SetUp(4,GdipOBJ.X,GdipOBJ.Y,GdipOBJ.W,GdipOBJ.H,2,"-Caption -DPIScale +Parent1")
GdipOBJ.Pen:=New_Pen("FF0000",,1)

Gui, MainGUI:Add, Button, gCalibrate , Calibrate
Gui, MainGUI:Add, Button, gMarch , March
Gui, MainGUI:Show, x1600 w120, TC Calipers
Gui, MainGUI:+AlwaysOnTop -MaximizeBox -MinimizeBox

startCaliper() {
    global active_Draw
    active_Draw := 1
    SetTimer, drawCaliper,50

    Return
}

calDrop() {
    if (GetKeyState("Ctrl","P")=0) {                                                    ; Key released
        drawCaliper(1)                                                                  ; set caliper
    }
    Return
}

drawCaliper(set:=0) {
    global GdipOBJ, active_Draw, calArray, scale
	MouseGetPos,mx,my

	Gdip_GraphicsClear(GdipOBJ.G)
    num := calArray.length()
    Loop, % num                                                                         ; Draw saved calipers
    {
    	Gdip_DrawLine(GdipOBJ.G, GdipOBJ.Pen, calArray[A_Index].X, GdipOBJ.Y, calArray[A_Index].X, GdipOBJ.H)
    }
    if (num) {
        dx := Abs(calArray[1].X - mx)
        Gdip_DrawLine(GdipOBJ.G, GdipOBJ.Pen, calArray[1].X, my, mx, my)
        ms := round(dx/scale)
        bpm := round(60000/ms)
        ToolTip, % (scale="") ? dx " px" : ms " ms`n" bpm " bpm"
    }
    if (num=2) {
        active_Draw := 0
        SetTimer, calDrop, Off
        SetTimer, drawCaliper, Off
    }

    if (set) {
        SetTimer, calDrop, Off
        calArray.push({X:mx,Y:my})                                                      ; Drop next caliper
    }

	Gdip_DrawLine(GdipOBJ.G, GdipOBJ.Pen, mx, GdipOBJ.Y, mx, GdipOBJ.H)                 ; Draw live caliper
	UpdateLayeredWindow(GdipOBJ.hwnd, GdipOBJ.hdc)                                      ; Refresh viewport

    Return
}

Calibrate() {
    global calArray, scale

    InputBox, ms, Calibration, Enter Calibration (ms), , , , , , , , 1000
    dx := Abs(calArray[1].X - calArray[2].X)
    scale := dx/ms
    Return
}

March() {
    global calArray

    if (calArray.length()<2) {
        Return
    }
    if (calArray[1].X > calArray[2].X) {
        t := calArray.RemoveAt(1)
        calArray.Push(t)
    }
    dx := Abs(calArray[2].X-calArray[1].X)
    Return
}

#If (active_Draw=0) 
Ctrl::
{
    if (calArray.length()) {                                                            ; Calipers present, grab something
        MouseGetPos, mx, my
        ToolTip, Grab this
        calArray.RemoveAt(FindClosest(mx,my))
    }
    startCaliper()
}
Return

#If (active_Draw=1)
Ctrl::
    SetTimer, calDrop, 50
Return

FindClosest(mx,my) {
    threshold := 20
    for key,val in calArray {
        if Abs(val.X-mx) < threshold {
            best := key
        }
    }
    Return best
}

Layered_Window_SetUp(Smoothing,Window_X,Window_Y,Window_W,Window_H,Window_Name:=1,Window_Options:="") {
    Layered:={}
    Layered.W:=Window_W
    Layered.H:=Window_H
    Layered.X:=Window_X
    Layered.Y:=Window_Y
    Layered.Name:=Window_Name
    Layered.Options:=Window_Options
    Layered.Token:=Gdip_Startup()
    Create_Layered_GUI(Layered)
    Layered.hwnd:=winExist()
    Layered.hbm := CreateDIBSection(Window_W,Window_H)
    Layered.hdc := CreateCompatibleDC()
    Layered.obm := SelectObject(Layered.hdc,Layered.hbm)
    Layered.G := Gdip_GraphicsFromHDC(Layered.hdc)
    Gdip_SetSmoothingMode(Layered.G,Smoothing)
    return Layered
}

Create_Layered_GUI(Layered)
{
    Gui,% Layered.Name ": +E0x80000 +LastFound " Layered.Options 
    Gui,% Layered.Name ":Show",% "x" Layered.X " y" Layered.Y " w" Layered.W " h" Layered.H " NA"
}

New_Pen(colour:="000000",Alpha:="FF",Width:= 5) {
    new_colour := "0x" Alpha colour 
    return Gdip_CreatePen(New_Colour,Width)
}


#Include, GDIP_All.ahk
