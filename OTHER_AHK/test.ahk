#SingleInstance Force
#Persistent





Gui, Add, Button, vMyButton x50 y50 w100 h50 gButtonClicked, Zeige Text
Gui, Show, x100 y100 h150 w200, Text Anzeigen



SetTimer, CheckMouse, 150
return

CheckMouse:
    MouseGetPos, mX, mY, mWin, mControl
    GuiControlGet, MyButtonPos,, MyButton
    ;OutputDebug, %mControl%

    if (mControl = "Button1")
    {
        ; Speichern Sie den aktuell markierten Text in die Zwischenablage
        Send ^c
        Sleep 100  ; Ein kurzes Delay, um sicherzustellen, dass der Text kopiert wurde

        ; Den Inhalt der Zwischenablage in eine Variable speichern
        ClipText := Clipboard

        ; Den Inhalt der Zwischenablage in einer MessageBox anzeigen
    ; MsgBox, %ClipText%
    }
return


ButtonClicked:

    ; Den Inhalt der Zwischenablage in einer MessageBox anzeigen
    MsgBox, %ClipText%
return