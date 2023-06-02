#SingleInstance Force

; Register the hotstring dynamically during runtime
Hotstring(":X:xxrun","A")

Return

; Your subroutine A
A:
    MsgBox, Subroutine A executed!
return

