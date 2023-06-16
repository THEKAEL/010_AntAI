

/*

    MIT License

    Copyright (c) 2023 Thomas Klöckl https://github.com/THEKAEL/010_AntAI

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.

    The original/latest version of this code can be found under https://github.com/THEKAEL/010_AntAI
    Contributions to my projects are highly appreciated.

*/



;#NoEnv
#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%


#Include .\OTHER_AHK\INI_PROCESSING.ahk

iniFile := ".\antai_config2.ini"

sections := "" ; [ "MANDATORY_HOTKEYS","OPTIONAL_HOTKEYS"] ; Ersetzen oder erweitern Sie diese Liste nach Bedarf
;isInArray("MANDATORY_Hotkeys",sections)
OutputDebug, % sections.MaxIndex()


maxH := 0
stdW := 0
rowH := 0
rowGap := rowH
leftGap := 0
iniFile := ".\antai_config2.ini"

showEditIniGui(iniFile, sections)

return

showEditIniGui(xiniFile, sectionsArray, xmaxH=800, xstdW:=500, xrowH:=25, xrowGap:=25, xleftGap:=15){
     global maxH := xmaxH
     global stdW := xstdW
     global rowH := xrowH
     global rowGap := xrowGap
     global leftGap := xleftGap
     global iniFile := xiniFile
     global sections := sectionsArray
    Gosub, REBUILD_GUI_INI
}



REBUILD_GUI_INI:
currentCol:=1
; INIT the GUI
if(sections = "" and !IsObject(sections)){
    IniRead, sections , %iniFile%
    sections := StrSplit(sections, "`n")
}
Gui, INIEDIT:Destroy
Gui, INIEDIT:New, +HwndINIEDITHwnd
Gui, INIEDIT:Add, Button, x20 y20 w100 h20 gOKButtonINI, Write Back
Gui, INIEDIT:Add, Button, x120 y20 w100 h20 gCancelButtonINI, Cancel
Gui, INIEDIT:Add, Button, x240 y20 w80 h20 gChooseIni, Select INI

yPos := 60
myW:=stdW*0.9
Gui, INIEDIT:Add, Text, x%leftGap% y%yPos% w%myW% h%rowH% vCurrentIni , Current INI: %iniFile%

yPos := yPos +25
startY := yPos

rememberGuiEditElement := []
rememberRelatedSection := []
rememberRelatedOrigVal := []
rememberRelatedIniKey := []

currIdx := 0
for index, section in sections {
    inidict := ReadIniToDictionarySec2(iniFile,section)
    overFlowShift := Max(0,currentCol-1) * stdW + leftGap * currentCol ; Min(1,currentCol-1) 
    Gui, INIEDIT:Font, Bold
    tempXshfit := overFlowShift + leftGap/2
    Gui, INIEDIT:Add, Text, x%tempXshfit% y%yPos%, %section%
    Gui, INIEDIT:Font
    yPos += rowGap -5
    for key, valueArray in inidict {
        overFlowShift := Max(0,currentCol-1) * stdW + leftGap * currentCol ; Min(1,currentCol-1) 
        valVal := valueArray[1]
        valSec := valueArray[2]
        valKey := valueArray[3]

        rememberGuiEditElement[currIdx] := Key
        rememberRelatedSection[currIdx] := valSec
        rememberRelatedOrigVal[currIdx] := valVal
        rememberRelatedIniKey[currIdx] := valKey
        currIdx := currIdx + 1
        tempXshfit := overFlowShift + leftGap
        Gui, INIEDIT:Add, Text, x%tempXshfit% y%yPos%, %valKey%
        tempXshfit := overFlowShift + leftGap +stdW*0.4
        tempW := stdW*0.55
        Gui, INIEDIT:Add, Edit, x%tempXshfit% y%yPos% w%tempW% v%key%, %valVal%
        yPos += rowGap
        if(yPos >= maxH - rowH-rowGap ) {
            currentCol += 1
            yPos := startY
        }
    }
}
Gui, INIEDIT:+LastFound +ToolWindow -MinimizeBox -MaximizeBox 
Gui, INIEDIT:Show,  , Edit the INI-File. Restart script to apply changes.

return


OKButtonINI:
    
    Gui, INIEDIT:Submit

    for index, val in rememberGuiEditElement
    {
        GuiControlGet, value,, %val% 
        xsection := rememberRelatedSection[index]
        xkey:= rememberRelatedIniKey[index]
        OutputDebug, % value
        IniWrite, %value%, %iniFile%, %xsection%, %xkey%

    }

    MsgBox, 4, , Do you want to apply changes and restart the Script? If you have changed the data source you will need to rebuild the database after restart!

    IfMsgBox, Yes
        Reload
    Else
        MsgBox, Sie haben Nein gedrückt, das Skript wird nicht neu gestartet.

    return

    Gui, INIEDIT:Destroy
return


CancelButtonINI:
    Gui, INIEDIT:Destroy
return


ChooseIni:
FileSelectFile, selectedFilePath
    if (selectedFilePath != "") {
        MsgBox % "Sie haben die Datei " selectedFilePath " ausgewählt."
    }

    iniFile:=selectedFilePath
    sections := ""

    Gosub, REBUILD_GUI_INI

return
