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

SetWorkingDir %A_ScriptDir%
SetTitleMatchMode, 2

global MyGui := {W: A_ScreenWidth ,H: A_ScreenHeight }
global GdipOBJ:={X: 0 ,Y: 0 ,W: A_ScreenWidth, H: A_ScreenHeight } ; W: MyGui.W ,H: MyGui.H }
global active_Draw:=0

Pixels := 96
NumUnits := 1
Units := "Inches"
scaleFactor := NumUnits/Pixels ; .568 ;your calibration factor to convert pixels to units

Gui, 1: -Caption +E0x80000 +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs
Gui, 1:Show, Maximize ; % "w" MyGui.W " h" MyGui.H
GdipOBJ := Layered_Window_SetUp(4,GdipOBJ.X,GdipOBJ.Y,GdipOBJ.W,GdipOBJ.H,2,"-Caption -DPIScale +Parent1")
; UpdateLayeredWindow(GdipOBJ.hwnd, GdipOBJ.hdc, GdipOBJ.X, GdipOBJ.Y, GdipOBJ.W, GdipOBJ.H)
MyPen:=New_Pen("FF0000",,5)

MainLoop:
{

}

ExitApp

updatePos() {
	mouseGetPos,x,y
	dx := x-sx
	dy := sy-y
	dist := round(  ((dx)**2 + (dy)**2) **.5  ,3)
	distCalibrated := round(dist * scaleFactor,3)
	tooltip [%dx%:%dy%]`n%dist% px`n%distCalibrated% %units%
    
    Return
}

DrawStuff:
	Gdip_GraphicsClear(GdipOBJ.G)
	MouseGetPos,ex,ey
	Gdip_DrawLine(GdipOBJ.G, myPen, sx, sy, ex, ey)
	UpdateLayeredWindow(GdipOBJ.hwnd, GdipOBJ.hdc)
	if(GETKEYSTATE("Shift")){
		active_Draw:=0
		setTimer updatePos, off
		SetTimer,DrawStuff,off
		tooltip Distance measured is : %distCalibrated% %units%  
		clipboard := distCalibrated
;		Gdip_DeletePen(myPen)
	}
	if(GETKEYSTATE("Alt")){
		active_Draw:=0
		setTimer updatePos, off
		SetTimer,DrawStuff,off
		ToolTip
		Gdip_GraphicsClear(GdipOBJ.G)
		UpdateLayeredWindow(GdipOBJ.hwnd, GdipOBJ.hdc)
		clipboard := distCalibrated
		GuiControl, Calibrate:, Pixels, %dist%
	    Gui, Calibrate:Show, , Scale Calibration
	}
Return

#If (active_Draw=0)
{
    ^LButton::
    {
        active_Draw := 1
        MouseGetPos,sx,sy ; start position for measurement
        SetTimer, updatePos,50
        SetTimer, DrawStuff,50

        Return
    }
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
    ;~ static Hellbent_Pen:=[]
    new_colour := "0x" Alpha colour 
    ;~ Hellbent_Pen[Hellbent_Pen.Length()+1]:=Gdip_CreatePen(New_Colour,Width)
    return Gdip_CreatePen(New_Colour,Width)
}


#Include, GDIP_All.ahk
