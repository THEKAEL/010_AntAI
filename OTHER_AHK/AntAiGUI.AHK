
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





#NoEnv
#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%

#Include .\OTHER_AHK\EDIT_INI.AHK

/*
    This script reasizes the GUI functionality to offer an interactive way to the user to add new knowledge data
    to one of the sqlite data bases scpecified in the ini file.
    Author: Thomas Klöckl https://github.com/THEKAEL
*/


/*
    global vars that feed the gui / some default values for the GUI
*/

xxsearchin:="default search in"
xxfitto := ""
xxh1:=   "ADHOC"
xxh2:=   "MEMO"
xxh3:=   "NONE"
xxinfohtml:= "no info available"
xxoutput1:=  "n/a"
xxoutput2:=  "n/a"

FormatTime, currentDate, %A_Now%, yyyy-MM-dd
xxvalidFrom := currentDate
xxvalidto := "2099-12-31"

xxdb3list := "Eintrag1|Eintrag2|Eintrag3|Eintrag4"
xxSQLiteDLL := A_ScriptDir "\SQLite3.dll"
xxmy_db3 := "" 
xxpreselectedDB := ""

global val_checkTag := "Checked"
global val_checkHeader := "Checked"
global val_checkInfoOut := "Checked"



/*
    Function to start up the GUI
*/
showAdhocInputGui( basisDB, SQLiteDLL, searchin:="ADHOC",fitto:="ADHOC",h1:= "ADHOC",h2:= "ADHOC",h3:="ADHOC",infohtml := "n/a" ,output1 := "n/a" ,output2 := "n/a",validfrom="",validto="",db3list:="./ADHOC.db3",preselectedDB := ""){

    Global xxsearchin := searchin
    Global xxfitto := fitto
    Global xxh1 := h1
    Global xxh2 := h2
    Global xxh3 := h3
    Global xxinfohtml := infohtml
    Global xxoutput1 := output1
    Global xxoutput2 := output2
    Global xxvalidfrom := validfrom
    Global xxvalidto := validto
    Global xxdb3list := db3list
    Global xxSQLiteDLL := SQLiteDLL
    Global xxmy_db3 := basisDB
    Global xxpreselectedDB := preselectedDB
    Gosub, INIT_ADHOCGUI
    
    return

}



/*
    The GUI is created with global labels and variables in order to realize events
    This GUI shows inputs fields and buttons that allow the user to add a new knowledge item to one of the sqlite source databases
*/


INIT_ADHOCGUI:

    Gui, MyGuiX:New, +HwndMyGuiXHwnd
    ; Erstelle die GUI
    Gui, MyGuiX:Add, Text, x5, Search In:
    Gui, MyGuiX:Add, Edit, vFeld1 w800 x5, %xxsearchin%
    Gui, MyGuiX:Add, Button, gClearFeld1 x+5, CLEAR

    Gui, MyGuiX:Add, Text, x5, (and/or) fit to:
    Gui, MyGuiX:Add, Edit, vFeld2 w800 x5, %xxfitto%
    Gui, MyGuiX:Add, Button, gClearFeld2 x+5, CLEAR

    Gui, MyGuiX:Add, Text, x5, Header H1:
    Gui, MyGuiX:Add, Edit, vFeld3 w800 x5, %xxh1%
    Gui, MyGuiX:Add, Button, gClearFeld3 x+5, CLEAR

    Gui, MyGuiX:Add, Text, x5, Header H2:
    Gui, MyGuiX:Add, Edit, vFeld4 w800 x5, %xxh2%
    Gui, MyGuiX:Add, Button, gClearFeld4 x+5, CLEAR

    Gui, MyGuiX:Add, Text, x5 , Header H3:
    Gui, MyGuiX:Add, Edit, vFeld5 x5 w800, %xxh3%
    Gui, MyGuiX:Add, Button, gClearFeld5 x+5, CLEAR

    Gui, MyGuiX:Add, Text, x5 , Info-HTML:
    Gui, MyGuiX:Add, Edit, vFeld6 w800 h100 x5, %xxinfohtml%
    Gui, MyGuiX:Add, Button, gClearFeld6 x+5, CLEAR

    Gui, MyGuiX:Add, Text, x5 , OUTPUT1:
    Gui, MyGuiX:Add, Edit, vFeld7 w800 h200 x5, %xxoutput1%
    Gui, MyGuiX:Add, Button, gClearFeld7 x+5, CLEAR

    Gui, MyGuiX:Add, Text, x5 , OUTPUT2:
    Gui, MyGuiX:Add, Edit, vFeld8 w800 h100 x5, %xxoutput2%
    Gui, MyGuiX:Add, Button, gClearFeld8 x+5, CLEAR

    Gui, MyGuiX:Add, Text, x5 , Valid From / Valid To:
    Gui, MyGuiX:Add, Edit, vFeld9 w395  x5, %xxvalidFrom%
    Gui, MyGuiX:Add, Edit, vFeld10 w395  x+10, %xxvalidTo%
    Gui, MyGuiX:Add, Button, gClearFeld9 x+5, CLEAR

    ; Erstelle die Dropdown-Box
    Gui, MyGuiX:Add, Text, x5 , Dropdown:
    Gui, MyGuiX:Add, ComboBox, vDropdown w395 x5  , %xxdb3list% ;alternativ ComboBox um Freitexte zuzulassen.
    GuiControl, Text, Dropdown, %xxpreselectedDB%

    struct_sql := "SELECT group_concat(my_col, '|') FROM (select distinct h1 || ';' || h2 as my_col from T_Knowledge order by 1 asc)  "
    headerstructure_list := xxmy_db3.tk_get1stValue(struct_sql)
    Gui, MyGuiX:Add, ComboBox, vMyCombo x+5 w400 , %headerstructure_list% 
    Gui, MyGuiX:Add, Button, gTakeField001 x+5, GET

    ; Erstelle die Buttons
    Gui, MyGuiX:Add, Button, gxCommitButton x0,  COMMIT
    Gui, MyGuiX:Add, Button, gxCancelButton x+5 , CANCEL

    ; Zeige die GUI
    Gui, MyGuiX:Show, , Add a new Knowledge Item to an ADHOC Database (source)
return

; Button-Events
xCommitButton:
    
    Gui, MyGuiX:Submit, NoHide
    ; MsgBox, Die Daten wurden gespeichert:`nFeld1: %Feld1%`nFeld2: %Feld2%`nFeld3: %Feld3%`nFeld4: %Feld4%`nFeld5: %Feld5%`nFeld6: %Feld6%`nDropdown: %Dropdown%

    ; TODO: Mask Strings to make them insertable sql_statement below
    selectedDB := Dropdown
    Global xxsearchin := sqlMask(Feld1)
    Global xxfitto := sqlMask(Feld2)
    Global xxh1 := sqlMask(Feld3)
    Global xxh2 := sqlMask(Feld4)
    Global xxh3 := sqlMask(Feld5)
    Global xxinfohtml := sqlMask(Feld6)
    Global xxoutput1 := sqlMask(Feld7)
    Global xxoutput2 := sqlMask(Feld8)
    Global xxvalidfrom := sqlMask(Feld9)
    Global xxvalidto := sqlMask(Feld10)

    xxsqliteDBObject := New SQLiteDB(sqlite_dll_path)
    xxsqliteDBObject.OpenDB(selectedDB)



    DebugAppend("START: INSERT adhoc DATASET .", True,True)
    my_sql2 := "CREATE TABLE if not exists T_KNOWLEDGE( ""search_in"" TEXT,""fit_to"" TEXT,""H1"" TEXT,""H2"" TEXT,""H3"" TEXT,""INFO"" TEXT,""INFO_HTML"" TEXT,""OUTPUT"" TEXT,""OUTPUT_2"" TEXT, ""SHOW_FROM"" TEXT, ""SHOW_TO"" TEXT, ""SRC_LBL1"" TEXT,""SRC_LBL2"" TEXT,""SRC_LBL3"" TEXT,""SRC_INFO"" TEXT, ""_insertLBL"" TEXT)"

    xxsqliteDBObject.Prepare(my_sql2, sss)
    sss.Step()

    FormatTime, xxcurrentDateTime, %A_Now%, yyyy-MM-dd HH:mm:ss

    sql_statement = 
    (
        insert into T_KNOWLEDGE ( search_in, fit_to, h1,h2,h3, info,INFO_HTML,output,OUTPUT_2,SHOW_FROM,SHOW_TO,src_lbl1,SRC_LBL2,SRC_LBL3,SRC_INFO,_insertLBL)
         VALUES `( 
        '%xxsearchin%',
        '%xxfitto%',
        '%xxh1%', '%xxh2%', '%xxh3%',
        '', '%xxinfohtml%',
        '%xxoutput1%', '%xxoutput2%',
        '%xxvalidfrom%', '%xxvalidto%',
        'ADHOC' ,
        '%xxcurrentDateTime%' ,
        'ADHOC' ,
        'ADHOC' ,
        'ADHOC' 
        `)
    )

    ;execute in the ADHOC Database. Data can be reviewed and edited in this Database. Furtherore they are imported in case user triggers a rebuild
    xxsqliteDBObject.Prepare(sql_statement, sss)
    sss.Step()

    ;to avoid that the user needs to rebuid the database right away we insert the data into the main knowledge database as well (inmem)
    xxmy_db3.Prepare(sql_statement, sss)
    sss.Step()

    ;TODO: Manage properly the appending to the main database in AntAi
    
return


xCancelButton:
    Gui, MyGuiX:Destroy
return

; CLEAR-Button-Events
ClearFeld1:
    GuiControl,, Feld1,
return

ClearFeld2:
    GuiControl,, Feld2,
return

ClearFeld3:
    GuiControl,, Feld3,
return

ClearFeld4:
    GuiControl,, Feld4,
return

ClearFeld5:
    GuiControl,, Feld5,
return

ClearFeld6:
    GuiControl,, Feld6,
return

ClearFeld7:
    GuiControl,, Feld7,
return

ClearFeld8:
    GuiControl,, Feld8,
return

ClearFeld9:
    GuiControl,, Feld9,
    GuiControl,, Feld10,
return

TakeField001:
    FormatTime, CurrentDateTime,, yyyy-MM-dd
    FormatTime, CurrentDateTime2,, yyyyMMdd
    Gui, Submit, NoHide
    arr := StrSplit(MyCombo, ";")
    selectedValue1 := arr[1]
    selectedValue2 := arr[2]
    GuiControl, Text, Feld3, %selectedValue1%
    GuiControl, Text, Feld4, %selectedValue2%
    GuiControl, Text, Feld1, ADHOC_%selectedValue1%_%selectedValue2%_%CurrentDateTime%_%CurrentDateTime2%
Return


;StrSplit(selectedValue, ";")




processedAction := False
edit_config_ini_file := config_ini_file

openQuickAccessGUI(configINI, version:=2){
    Global edit_config_ini_file := configINI

    loc_check1 := global val_checkTag
    loc_check2 := global val_checkHeader
    loc_check3 := global val_checkInfoOut


    if (loc_check1 != "" and loc_check1 != "Checked"){
        global val_checkTag := "Checked"
    }

    if (loc_check2 != "" and loc_check2 != "Checked"){
        global val_checkHeader := "Checked"
    }

    if( loc_check3 != "" and loc_check3 != "Checked"){
        global val_checkInfoOut := "Checked"
    }

    if (loc_check1 = "" and loc_check2 = ""  and loc_check3 = "" ) {
        global val_checkTag := "Checked"
        global val_checkInfoOut := "Checked"
        global val_checkHeader := "Checked"
    }

    if (version=1 ) {
        Gosub, OPEN_QUICK_ACCESS_GUI
    }
    else if (version=2) {
        Gosub, OPEN_QUICK_ACCESS_GUI2
    }
    else if (version=3) {
        Gosub, OPEN_QUICK_ACCESS_GUI3
    }
    else if (version=4) {
        Gosub, OPEN_QUICK_ACCESS_GUI4
    }
    else if (version=5) {
        Gosub, OPEN_QUICK_ACCESS_GUI5
    }
    Else{
        Gosub, OPEN_QUICK_ACCESS_GUI
    }

}


OPEN_QUICK_ACCESS_GUI:


    my_width:=70
    my_smallwidth:=20
    my_height:=20
    my_midWidth := my_smallwidth*2+5
    next_gui_mode := 2

    Gui, MyGui:New, +AlwaysOnTop -Caption +ToolWindow +LastFound +HwndMyGuiHwnd
    Gui, MyGui:Font, Bold s6, Verdana
    Gui, MyGui:Add, Button, gButton1LOOKALL x5 Default  w%my_width% h%my_height% , FIND
    Gui, MyGui:Font
    Gui, MyGui:Font, s6, Verdana
    Gui, MyGui:Add, Button, gButtonHELP x+5  w%my_smallwidth% h%my_height% , ?
    Gui, MyGui:Add, Button, gButton_Exit x+5 w%my_smallwidth% h%my_height% CLEAR, X
    Gui, MyGui:Add, Button, gButton2LOOKADD x5 w%my_width% h%my_height%, + FIND  
    Gui, MyGui:Add, Button, gButton_INIADMIN x+5 w%my_smallwidth% h%my_height% , *
    Gui, MyGui:Add, Button, gButton_INIDS x+5 w%my_smallwidth% h%my_height% CLEAR , DS
    Gui, MyGui:Add, Button, gButton3 x5 w%my_width% h%my_height%, + INFO    
    Gui, MyGui:Add, Button, gButton_GETSEARCH x+5 w%my_smallwidth% h%my_height% , <-
    Gui, MyGui:Add, Button, gButton_INIHK x+5 w%my_smallwidth% h%my_height% CLEAR , HK

    Gui, MyGui:Add, Text,  x+5 w5 h%my_height% CLEAR, 

    ; Gui, MyGui:Add, Text,  x5 w%my_width% h%my_height% , 
    Gui, MyGui:Add, Edit, x5 vMinieditor w%my_width% h%my_height% , %xxinfohtml%

    Gui, MyGui:Add, Button, gButton4Rebuild x+5 w%my_midWidth% h%my_height% CLEAR, Build DB
    Gui, MyGui:Add, CheckBox, vCheckbox1Tag gCheckboxSetting1 x5 %val_checkTag%, Tag
    Gui, MyGui:Add, CheckBox, vCheckbox2Header gCheckboxSetting2 x+1 %val_checkHeader% , Head
    Gui, MyGui:Add, CheckBox, vCheckbox3InfoOut gCheckboxSetting3 x+1 %val_checkInfoOut% , Info/Out
   ; Gui, MyGui:Add, CheckBox, vCheckbox4 x+1, Out

    Gui, MyGui:+SysMenu
    offsetY:=A_ScreenHeight-140
    offsetX:=A_ScreenWidth/2

    GuiControl, +BackgroundFF0000, Button1
    GuiControl, +BackgroundFF0000, Button2

    OnMessage(0x201, "WM_LBUTTONDOWN")
    OnMessage(0x200, "WM_MOUSEMOVE")

    Gui, MyGui:Show,   x%offsetX% y%offsetY%, My Gui
    guiID := MyGuiHwnd ; defined above


    WinGet, Transparent, Transparent, ahk_id %guiID%
    WinSet, Transparent, 180, ahk_id %guiID%


    SetTimer, CheckMouse, 1000

Return


OPEN_QUICK_ACCESS_GUI2:


    my_width:=50
    my_width2:=50*2
    my_smallwidth:=20
    my_height:=20
    my_smallheight:=my_height/1.7
    my_midWidth := my_smallwidth*2+5
    next_gui_mode := 3

    Gui, MyGui:New, +AlwaysOnTop -Caption +ToolWindow +LastFound +HwndMyGuiHwnd

    Gui, MyGui:Font
    Gui, MyGui:Font, s6, Verdana
    Gui, MyGui:Add, Button,  gButton_Exit x+3 w%my_smallwidth% h%my_height% , X
    Gui, MyGui:Add, Button, gButtonHELP x+3  w%my_smallwidth% h%my_height% , ?

    Gui, MyGui:Font, Bold s6, Verdana
    Gui, MyGui:Add, Button, gButton1LOOKALL x+10 Default  w%my_width% h%my_height% , FIND
    Gui, MyGui:Add, Button, gButton2LOOKADD x+3 w%my_width% h%my_height%, + FIND  
    Gui, MyGui:Add, Button, gButton3 x+3 w%my_width% h%my_height%, + INFO    

    Gui, MyGui:Font
    Gui, MyGui:Font, s6, Verdana



    Gui, MyGui:Add, Button, gButton_INIADMIN x+10 w%my_smallwidth% h%my_height% , *
    Gui, MyGui:Add, Button, gButton_INIHK x+3 w%my_smallwidth% h%my_height% , HK
    Gui, MyGui:Add, Button, gButton_INIDS x+3 w%my_smallwidth% h%my_height% , DS
   
    Gui, MyGui:Add, Text,  x+3 w5 h%my_height% , 

    ; Gui, MyGui:Add, Text,  x5 w%my_width% h%my_height% , 
    Gui, MyGui:Add, Edit, x+10 vMinieditor w%my_width2% h%my_height% , %xxinfohtml%
    Gui, MyGui:Add, Button, gButton_GETSEARCH x+3 w%my_smallwidth% h%my_height% , <-

    ;Gui, MyGui:Add, Button, gButton4Rebuild x+10 w%my_midWidth% h%my_height% , Build DB
    Gui, MyGui:Add, Button, gButton4Rebuild x+10 w%my_width% h%my_height% , Full Build
    Gui, MyGui:Add, Button, gButton4UpdateBuild x+10 w%my_Width% h%my_height% , Partial Build

    Gui, MyGui:Add, CheckBox, vCheckbox1Tag gCheckboxSetting1 x+5 y8 h%my_smallheight% %val_checkTag%, Tag
    Gui, MyGui:Add, CheckBox, vCheckbox2Header gCheckboxSetting2 x+1 h%my_smallheight%  %val_checkHeader%, Head
    Gui, MyGui:Add, CheckBox, vCheckbox3InfoOut gCheckboxSetting3 x+1 h%my_smallheight%  %val_checkInfoOut%, Info/Out
   ; Gui, MyGui:Add, CheckBox, vCheckbox4 x+1, Out

    Gui, MyGui:+SysMenu
    offsetY:=A_ScreenHeight-100
    offsetX:=A_ScreenWidth/2

    GuiControl, +BackgroundFF0000, Button1
    GuiControl, +BackgroundFF0000, Button2

    OnMessage(0x201, "WM_LBUTTONDOWN")
    OnMessage(0x200, "WM_MOUSEMOVE")

    Gui, MyGui:Show,   x%offsetX% y%offsetY%, My Gui
    guiID := MyGuiHwnd ; defined above

    WinGet, Transparent, Transparent, ahk_id %guiID%
    WinSet, Transparent, 180, ahk_id %guiID%

    SetTimer, CheckMouse, 1000

Return


OPEN_QUICK_ACCESS_GUI3:


    my_width:=50
    my_width2:=50*4
    my_smallwidth:=20
    my_height:=20
    my_midWidth := my_smallwidth*2+5
    next_gui_mode := 4

    Gui, MyGui:New, +AlwaysOnTop -Caption +ToolWindow +LastFound +HwndMyGuiHwnd
    Gui, MyGui:Font, s6, Verdana
    Gui, MyGui:Add, Button,  gButton_Exit x+3 w%my_smallwidth% h%my_height% , X
    Gui, MyGui:Font, Bold s6, Verdana
    Gui, MyGui:Add, Button, gButton1LOOKALL x+10 Default  w%my_width% h%my_height% , FIND
    Gui, MyGui:Add, Button, gButton2LOOKADD x+3 w%my_width% h%my_height%, + FIND  
    Gui, MyGui:Add, Button, gButton3 x+3 w%my_width% h%my_height%, + INFO    

    Gui, MyGui:Font
    Gui, MyGui:Font, s6, Verdana

    ;Gui, MyGui:Add, Button, gButtonHELP x+10  w%my_smallwidth% h%my_height% , ?
    ;Gui, MyGui:Add, Button,  gButton_Exit x+3 w%my_smallwidth% h%my_height% , X

    ;Gui, MyGui:Add, Button, gButton_INIADMIN x+10 w%my_smallwidth% h%my_height% , *
    ;Gui, MyGui:Add, Button, gButton_INIHK x+3 w%my_smallwidth% h%my_height% , HK
    ;Gui, MyGui:Add, Button, gButton_INIDS x+3 w%my_smallwidth% h%my_height% , DS
   
    Gui, MyGui:Add, Text,  x+3 w5 h%my_height% , 

    ; Gui, MyGui:Add, Text,  x5 w%my_width% h%my_height% , 
    Gui, MyGui:Add, Edit, x+10 vMinieditor w%my_width2% h%my_height% , %xxinfohtml%
    Gui, MyGui:Add, Button, gButton_GETSEARCH x+3 w%my_smallwidth% h%my_height% , <-

    Gui, MyGui:Add, CheckBox, gCheckboxSetting1 vCheckbox1Tag x+5 y8 h%my_smallheight% %val_checkTag%, Tag
    Gui, MyGui:Add, CheckBox, gCheckboxSetting2 vCheckbox2Header x+1 h%my_smallheight% %val_checkHeader%, Head
    Gui, MyGui:Add, CheckBox, gCheckboxSetting3 vCheckbox3InfoOut x+1 h%my_smallheight% %val_checkInfoOut%, Info/Out
   ; Gui, MyGui:Add, CheckBox, vCheckbox4 x+1, Out

    ;Gui, MyGui:Add, Button, gButton4Rebuild x+10 w%my_midWidth% h%my_height% , Build DB

    Gui, MyGui:+SysMenu
    offsetY:=A_ScreenHeight-100
    offsetX:=A_ScreenWidth/2

    GuiControl, +BackgroundFF0000, Button1
    GuiControl, +BackgroundFF0000, Button2

    ;GuiControl, +TabRight, MyGui:Button1
    ;GuiControl, +TabRight, MyGui:Button2
    ;GuiControl, +TabRight, MyGui:Minieditor
    ;GuiControl, +TabRight, MyGui:Button_Exit
    

    OnMessage(0x201, "WM_LBUTTONDOWN")
    OnMessage(0x200, "WM_MOUSEMOVE")

    Gui, MyGui:Show,   x%offsetX% y%offsetY%, My Gui
    guiID := MyGuiHwnd ; defined above

    WinGet, Transparent, Transparent, ahk_id %guiID%
    WinSet, Transparent, 180, ahk_id %guiID%

    SetTimer, CheckMouse, 1000

Return


OPEN_QUICK_ACCESS_GUI4:


    my_width:=50
    my_width2:=50*4
    my_width3:=80
    my_smallwidth:=20
    my_height:=20
    my_midWidth := my_smallwidth*2+5
    next_gui_mode := 5

    Gui, MyGui:New, +AlwaysOnTop -Caption +ToolWindow +LastFound +HwndMyGuiHwnd
    ;Gui, MyGui:Font, Bold s6, Verdana
    ;Gui, MyGui:Add, Button, gButton1LOOKALL x5 Default  w%my_width% h%my_height% , FIND
    ;Gui, MyGui:Add, Button, gButton2LOOKADD x+3 w%my_width% h%my_height%, + FIND  
    ;Gui, MyGui:Add, Button, gButton3 x+3 w%my_width% h%my_height%, + INFO    

    Gui, MyGui:Font
    Gui, MyGui:Font, s6, Verdana
    ;Gui, MyGui:Add, Text,  x+3 w%my_smallwidth% h%my_height% , Config
    ;Gui, MyGui:Add, Button, gButtonHELP x+10  w%my_smallwidth% h%my_height% , ?
    Gui, MyGui:Add, Button,  gButton_Exit x+3 w%my_smallwidth% h%my_height% , X
    Gui, MyGui:Font, s6, Verdana
    Gui, MyGui:Add, Button, gButton_INIADMIN x+10 w%my_smallwidth% h%my_height% , *
    Gui, MyGui:Add, Button, gButton_INIHK x+3 w%my_smallwidth% h%my_height% , HK
    Gui, MyGui:Add, Button, gButton_INIDS x+3 w%my_smallwidth% h%my_height% , DS
    
    ;Gui, MyGui:Add, Text,  x+3 w%my_width% h%my_height% , AntAI

    ;Gui, MyGui:Add, Text,  x5 w%my_width% h%my_height% , 
    ;Gui, MyGui:Add, Edit, x+10 vMinieditor w%my_width2% h%my_height% , %xxinfohtml%
    ;Gui, MyGui:Add, Button, gButton_GETSEARCH x+3 w%my_smallwidth% h%my_height% , <-

    Gui, MyGui:Add, Button, gButton4Rebuild x+10 w%my_width3% h%my_height% , Full Build
    Gui, MyGui:Add, Button, gButton4UpdateBuild x+10 w%my_Width3% h%my_height% , Update DB

    Gui, MyGui:+SysMenu
    offsetY:=A_ScreenHeight-100
    offsetX:=A_ScreenWidth/2

    ;GuiControl, +BackgroundFF0000, Button1
    ;GuiControl, +BackgroundFF0000, Button2

    ;OnMessage(0x201, "WM_LBUTTONDOWN")
    ;OnMessage(0x200, "WM_MOUSEMOVE")

    Gui, MyGui:Show,   x%offsetX% y%offsetY%, My Gui
    guiID := MyGuiHwnd ; defined above

    WinGet, Transparent, Transparent, ahk_id %guiID%
    WinSet, Transparent, 180, ahk_id %guiID%

    SetTimer, CheckMouse, 1000

Return


OPEN_QUICK_ACCESS_GUI5:

    my_width:=50
    my_width2:=50*4
    my_width3:=80
    my_smallwidth:=20
    my_height:=20
    my_midWidth := my_smallwidth*2+5
    next_gui_mode := 2

    Gui, MyGui:New, +AlwaysOnTop -Caption +ToolWindow +LastFound +HwndMyGuiHwnd

    Gui, MyGui:Font
    Gui, MyGui:Font, s6, Verdana
    ;Gui, MyGui:Add, Text,  x+3 y9 w%my_smallwidth% h%my_height% , AntAI
    Gui, MyGui:Add, Button,  gButton_Exit x+3 w%my_smallwidth% h%my_height% , X
    Gui, MyGui:Add, Button, gButtonHELP x+10  w%my_smallwidth% h%my_height% , ?
   

    Gui, MyGui:+SysMenu
    offsetY:=A_ScreenHeight-100
    offsetX:=A_ScreenWidth/2

    ;GuiControl, +BackgroundFF0000, Button1
    ;GuiControl, +BackgroundFF0000, Button2

    ;OnMessage(0x201, "WM_LBUTTONDOWN")
    ;OnMessage(0x200, "WM_MOUSEMOVE")

    Gui, MyGui:Show,   x%offsetX% y%offsetY%, My Gui
    guiID := MyGuiHwnd ; defined above

    WinGet, Transparent, Transparent, ahk_id %guiID%
    WinSet, Transparent, 180, ahk_id %guiID%

    SetTimer, CheckMouse, 1000

Return


CheckboxSetting1:

    if (val_checkTag = "Checked")
        global val_checkTag := ""
    else    
        global val_checkTag := "Checked"

return


CheckboxSetting2:

    if (val_checkHeader = "Checked")
        global val_checkHeader := ""
    else
        global val_checkHeader := "Checked"

return


CheckboxSetting3:

    if (val_checkInfoOut = "Checked")
        global val_checkInfoOut := ""
    else
        global val_checkInfoOut := "Checked"

return


Button1LOOKALL:
    GuiControlGet, userInputNew,, Minieditor
    if( userInputNew=""){
        ; We ignor the Mini edit field
    } 
    else {
        ; we put the value from the user input field into Clipboard
        Clipboard := userInputNew
    }
 
    setSearchSettings(val_checkTag=="Checked", val_checkHeader=="Checked", val_checkInfoOut=="Checked",val_checkInfoOut=="Checked",False)
    Gosub, HTML_DYN_LOOKUP
    GuiControl, MyGui:Text, Minieditor, 
    Sleep, 1000
    Gui, MyGui:Show
    GuiControl, MyGui:Focus, Minieditor,
return

ButtonHELP:
    Gosub, HELP_TEXT
return

Button2LOOKADD:
    GuiControlGet, userInputNew,, Minieditor
    if( userInputNew=""){
        ; We ignor the Mini edit field
    } 
    else {
        ; we put the value from the user input field into Clipboard
        Clipboard := userInputNew
    }
    setSearchSettings(val_checkTag=="Checked", val_checkHeader=="Checked", val_checkInfoOut=="Checked",val_checkInfoOut=="Checked",False)
    Gosub, HTML_ADD_DYN_LOOKUP
    GuiControl, MyGui:Text, Minieditor, 
    Sleep, 1000
    Gui, MyGui:Show
    GuiControl, MyGui:Focus, Minieditor,
return

Button_INIADMIN:
    sections :="" ; shows everything in the Ini-File
    showEditIniGui(config_ini_file, sections, xmaxH:=850, xstdW:=500, xrowH:=25, xrowGap:=25, xleftGap:=15)
return

Button_INIDS:
    sections :=["XLS_INPUTS","CSV_INPUTS" ,"SQLITE_INPUTS"] ;shows everything related to data sources
    showEditIniGui(config_ini_file, sections, xmaxH:=850, xstdW:=900, xrowH:=25, xrowGap:=25, xleftGap:=15)
return

Button_INIHK:
    sections := ["MANDATORY_HOTKEYS","OPTIONAL_HOTKEYS"]    ;shows everything related to hotkeys
    showEditIniGui(config_ini_file, sections, xmaxH:=850, xstdW:=500, xrowH:=25, xrowGap:=25, xleftGap:=15)
return

Button_GETSEARCH:
    GuiControl, MyGui:Text, Minieditor, %current_search_pattern%
Return

Button_Exit:
    Gui, MyGui:Destroy
    openQuickAccessGUI(edit_config_ini_file,next_gui_mode)
    ; MsgBox, Info,  Please note that the Script and the HOTKEYS are still active. To exit script use the (hidden) icon menue in your windows toolbar.
Return

Button3:
    Gosub, RUN_ADHOC_INPUT
return

Button4Rebuild:
; Full rebuild of the whole knowledge db importing all specified data sources
    Gosub, REBUILD_DB
return

Button4UpdateBuild:
; Updating/refreshing the knowledge database only of those data sources that are supposingly new or have changed (based on the file property attributes)
    Gosub, REFRESH_DB
return

WM_LBUTTONDOWN()
{
    PostMessage, 0xA1, 2
}

WM_MOUSEMOVE()
{
    PostMessage, 0xA1, 2
}


return

CheckMouse:
    MouseGetPos, mX, mY, mWin, mControl
    GuiControlGet, MyButtonPos,, MyButton
    ;OutputDebug, %mControl%

    GuiControlGet, buttonText,, %mControl%

    ;if (mControl = "Button1")
    if (guiID=mWin and processedAction=False)
    {
        ; Speichern Sie den aktuell markierten Text in die Zwischenablage
        Send ^c
        Sleep 300  ; Ein kurzes Delay, um sicherzustellen, dass der Text kopiert wurde

        ; Den Inhalt der Zwischenablage in eine Variable speichern
        ClipText := Clipboard
        processedAction:=True
    }
    else if (guiID!=mWin) {
        processedAction:=False
    }
return

sqlMask(str){
    maskStr := StrReplace(str,"'","''")
    return maskStr
}
