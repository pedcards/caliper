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
active_Move:=0
active_March:=0
calArray := {}
mLast := {}
scale := ""

GuiTitle := "TC Calipers"
Gui, 1: -Caption +E0x80000 +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs
Gui, 1:Show, Maximize
GdipOBJ := Layered_Window_SetUp(4,GdipOBJ.X,GdipOBJ.Y,GdipOBJ.W,GdipOBJ.H,2,"-Caption -DPIScale +Parent1")
GdipOBJ.Pen:=New_Pen("FF0000",,1)

Gui, MainGUI:Add, Button, gclickCaliper , New caliper
Gui, MainGUI:Add, Button, gCalibrate , Calibrate
Gui, MainGUI:Add, Button, vactive_March gToggleMarch, % "  March  "
Gui, MainGUI:Show, x1600 w120, % GuiTitle
Gui, MainGUI:+AlwaysOnTop -MaximizeBox -MinimizeBox

WinWaitClose, % GuiTitle
ExitApp

/*;	====================================================================================================================
*/
clickCaliper() {
/*	Start drawing new caliper line based on lines present
		0: Start first line (X1)
		1: Start second line
		2+: Both lines present, grab something
*/
	global calArray, active_Draw, active_Move, mLast
	
	if (calArray.length()=2) {															; Both calipers present, grab something
		MouseGetPos, mx, my
		mLast := {X:mx,Y:my}
		best:=FindClosest(mx,my)
		Switch best
		{
			Case 1:
				active_Move := 1
				SetTimer, moveCaliper, 50
				Return
			Case 2:
				calArray.RemoveAt(best)													; Release this position, makes live

			Default:
				Return																	; Not close, ignore
		}
	}

	active_Draw := 1
	SetTimer, makeCaliper,50

	Return
}

dropCaliper() {
/*	Plunk new caliper line at last mouse position
*/
	global calArray, mLast
	calArray.push(mLast)
	Return
}

makeCaliper() {
/*	Make caliper lines based on prev lines and new position
	Hline if more than one line on the field
*/
	global GdipOBJ, active_Draw, active_March, calArray, mLast, scale

	MouseGetPos,mx,my
	mLast := {X:mx,Y:my}

	if (active_March) {
		calMarch()
	}

	drawCalipers()

	num := calArray.length()
	if (num) {																			; Draw Hline when first line dropped
		dx := Abs(calArray[1].X - mx)
		drawHline(calArray[1].x,mx,my)
		scaleTooltip(dx)
	}
	if (num=2) {																		; Done when second line drops
		active_Draw := 0
		SetTimer, makeCaliper, Off
		reorderCalipers()
	}

	drawVline(mx)																		; Draw live caliper
	UpdateLayeredWindow(GdipOBJ.hwnd, GdipOBJ.hdc)										; Refresh viewport

	Return
}

moveCaliper() {
/*	Have grabbed X1 from dropped caliper
*/
	global GdipOBJ, calArray, mLast, scale

	MouseGetPos,mx,my
	dx := mx-mLast.X
	dy := my-mLast.Y
	mLast := {X:mx,Y:my}

	for key in calArray
	{
		calArray[key].X += dx
		calArray[key].Y += dy
	}

	scaleTooltip(calArray[2].X-calArray[1].X)
	drawCalipers()
	drawHline(calArray[1].x,calArray[2].x,my)
	UpdateLayeredWindow(GdipOBJ.hwnd, GdipOBJ.hdc)

	Return
}

moveRelease() {
/*	Drop the set of calipers being moved
*/
	global active_Move
	active_Move=0
	SetTimer, moveCaliper, Off
	ToolTip
	Return
}

drawCalipers() {
/*	Draw all caliper lines from calArray
*/
	global GdipOBJ, calArray

	Gdip_GraphicsClear(GdipOBJ.G)
	Loop, % calArray.length()															; Draw saved calipers
	{
		drawVline(calArray[A_Index].X)
	}
	Return
}

drawVline(X) {
/*	Draw vertical line at X
*/
	global GdipOBJ

	Gdip_DrawLine(GdipOBJ.G, GdipOBJ.Pen, X, GdipOBJ.Y, X, GdipOBJ.H)
	Return
}

drawHline(x1,x2,y) {
/*	Draw horizontal line
*/
	global GdipOBJ
	
	Gdip_DrawLine(GdipOBJ.G, GdipOBJ.Pen, x1, y, x2, y)
	Return
}

reorderCalipers() {
/*	Make sure that X1 always smaller than X2
*/
	global calArray

	if (calArray[1].X > calArray[2].X) {
		t := calArray[1]
		calArray[1] := calArray[2]
		calArray[2] := t
	}
	Return
}

scaleTooltip(dx) {
	global scale
	ms := round(dx/scale)
	bpm := round(60000/ms,1)
	ToolTip, % (scale="") ? dx " px" : ms " ms`n" bpm " bpm"
	Return
}
Calibrate() {
/*	Calibration window to calculate scale
*/
	global calArray, scale

	Gui, cWin:Add, Text, w200 Center, Select calibration measurement
	Gui, cWin:Add, Button, w200 gc1000, 1000 ms
	Gui, cWin:Add, Button, w200 gc2000, 2000 ms
	Gui, cWin:Add, Button, w200 gc3000, 3000 ms
	Gui, cWin:Add, Button, w200 gcOther, Other
	Gui, cWin:Show, , Calibrate
	Gui, cWin:+AlwaysOnTop -MaximizeBox -MinimizeBox

	WinWaitClose, Calibrate
	dx := Abs(calArray[1].X - calArray[2].X)
	scale := dx/ms
	Return
	
	c1000:
	{
		ms:=1000
		Gui, cWin:Cancel
		Return
	}
	c2000:
	{
		ms:=2000
		Gui, cWin:Cancel
		Return
	}
	c3000:
	{
		ms:=3000
		Gui, cWin:Cancel
		Return
	}
	cOther:
	{
		Return
	}
}

toggleMarch() {
/*	Toggle between "March" and "Meausre" button
*/
	global active_March, MainGUI
	active_March := !active_March
	GuiControl, MainGUI:Text, active_March
		, % (active_March) ? "Measure" : "March"
	Return
}

calMarch() {
/*	March out caliper lines relative to X1
*/
	global calArray, GdipOBJ, active_March, mLast
	grip:=2

	if (calArray.length()<2) {
		Return
	}
	lastX := mLast.X																	; last known position
	fullX := lastX-calArray[1].X														; distance from X1
	steps := grip-1																		; divisor
	dx := fullX/steps																	; dx between each caliper

	calArray.RemoveAt(2, calArray.length())												; clear everything above X1

	while (lastX < GdipOBJ.W) {															; add calipers to the right
		lastX += dx
		calArray.Push({X:lastX})
	}
	lastX := calArray[1].X																; add calipers to the left
	while (lastX > GdipOBJ.X) {
		lastX -= dx
		calArray.Push({X:lastX})
	}

	Return
}

FindClosest(mx,my) {
/*	Check if any caliper lines within threshold distance
	Return key num for match
*/
	global calArray
	threshold := 3
	
	for key,val in calArray {
		if Abs(val.X-mx) < threshold {
			Return key																	; Return early if hit
		}
	}
	Return
}

#If (active_Draw=0) 
^LButton::
{
	clickCaliper()
	Return
}

#If, (active_Move=1)
LButton Up::
^LButton Up::
{
	moveRelease()
	Return
}

#If (active_Draw=1)
LButton Up::
^LButton Up::
{
	dropCaliper()
	Return
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
