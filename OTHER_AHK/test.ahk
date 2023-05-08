; Erstelle eine GUI mit einer ComboBox
Gui, Add, ComboBox, vMyComboBox, Option 1|Option 2|Option 3

; Füge das After-Update-Event für die ComboBox hinzu
;GuiControl, +E0x10, MyComboBox


Return
; Definiere die Funktion, die beim After-Update-Event aufgerufen wird
MyComboBox_AfterUpdate:
    ; Hole den ausgewählten Wert aus der ComboBox
    SelectedValue := MyComboBox

    ; Gib den ausgewählten Wert in einer MsgBox aus
    MsgBox, Du hast "%SelectedValue%" ausgewählt!
return

; Zeige die GUI an
Gui, Show
return
