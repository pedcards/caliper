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

MainLoop:
{

}

ExitApp
