



Gui, Add, ComboBox, vMyComboBox, Item1|Item2|Item3|Item4
Gui, Show, , Mein Fenster
return

GuiClose:
ExitApp

^j:: ; Wenn Sie Strg+J drücken
Gui, Submit, NoHide
MyComboBox := "Item3" ; Setzt 'Item3' als den ausgewählten Wert in der ComboBox
GuiControl,, MyComboBox, %MyComboBox%
return


