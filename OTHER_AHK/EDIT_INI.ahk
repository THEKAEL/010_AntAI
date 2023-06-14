#NoEnv
#SingleInstance, Force
SendMode, Input
SetBatchLines, -1
SetWorkingDir, %A_ScriptDir%

#Include, Y:\DEV\GIT\010_AntAI\OTHER_AHK\INI_PROCESSING.ahk

iniFile := "Y:\DEV\GIT\010_AntAI\antai_config2.ini"

sections := "" ;["XLS_INPUTS", "MANDATORY_HOTKEYS"] ; Ersetzen oder erweitern Sie diese Liste nach Bedarf
;isInArray("MANDATORY_Hotkeys",sections)

if(sections = "" and !IsObject(sections)){
    IniRead, sections , %iniFile%
    sections := StrSplit(sections, "`n")
}
Gui, Add, Button, x50 y20 w100 h30 gOKButton, OK
Gui, Add, Button, x150 y20 w100 h30 gCancelButton, Cancel

yPos := 60
for index, section in sections {
    inidict := ReadIniToDictionarySec2(iniFile,section)
    Gui, Font, Bold
    Gui, Add, Text, x5 y%yPos%, %section%
    Gui, Font
    yPos += 20
    for key, valueArray in inidict {
        valVal := valueArray[1]
        valSec := valueArray[2]
        valKey := valueArray[3]

        Gui, Add, Text, x20 y%yPos%, %valKey%
 
        Gui, Add, Edit, x200 y%yPos% w300 v%key%, %valVal%
        yPos += 25
    }
}

Gui, Show, , TestGUI
return

OKButton:
Gui, Submit


Gui, Destroy
return

CancelButton:
Gui, Destroy
return

GuiClose:
ExitApp
return
