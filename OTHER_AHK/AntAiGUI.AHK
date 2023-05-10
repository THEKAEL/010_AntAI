#NoEnv

#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%


; global vars that feed the gui


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




INIT_ADHOCGUI:



; Erstelle die GUI
Gui, Add, Text, x5, Search In:
Gui, Add, Edit, vFeld1 w800 x5, %xxsearchin%
Gui, Add, Button, gClearFeld1 x+5, CLEAR

Gui, Add, Text, x5, (and/or) fit to:
Gui, Add, Edit, vFeld2 w800 x5, %xxfitto%
Gui, Add, Button, gClearFeld2 x+5, CLEAR

Gui, Add, Text, x5, Header H1:
Gui, Add, Edit, vFeld3 w800 x5, %xxh1%
Gui, Add, Button, gClearFeld3 x+5, CLEAR

Gui, Add, Text, x5, Header H2:
Gui, Add, Edit, vFeld4 w800 x5, %xxh2%
Gui, Add, Button, gClearFeld4 x+5, CLEAR

Gui, Add, Text, x5 , Header H3:
Gui, Add, Edit, vFeld5 x5 w800, %xxh3%
Gui, Add, Button, gClearFeld5 x+5, CLEAR

Gui, Add, Text, x5 , Info-HTML:
Gui, Add, Edit, vFeld6 w800 h100 x5, %xxinfohtml%
Gui, Add, Button, gClearFeld6 x+5, CLEAR

Gui, Add, Text, x5 , OUTPUT1:
Gui, Add, Edit, vFeld7 w800 h200 x5, %xxoutput1%
Gui, Add, Button, gClearFeld7 x+5, CLEAR

Gui, Add, Text, x5 , OUTPUT2:
Gui, Add, Edit, vFeld8 w800 h100 x5, %xxoutput2%
Gui, Add, Button, gClearFeld8 x+5, CLEAR

Gui, Add, Text, x5 , Valid From / Valid To:
Gui, Add, Edit, vFeld9 w395  x5, %xxvalidFrom%
Gui, Add, Edit, vFeld10 w395  x+10, %xxvalidTo%
Gui, Add, Button, gClearFeld9 x+5, CLEAR

; Erstelle die Dropdown-Box
Gui, Add, Text, x5 , Dropdown:
Gui, Add, ComboBox, vDropdown w395 x5  , %xxdb3list% ;alternativ ComboBox um Freitexte zuzulassen.
GuiControl, Text, Dropdown, %xxpreselectedDB%

struct_sql := "SELECT group_concat(my_col, '|') FROM (select distinct h1 || ';' || h2 as my_col from T_Knowledge order by 1 asc)  "
headerstructure_list := xxmy_db3.tk_get1stValue(struct_sql)
Gui, Add, ComboBox, vMyCombo x+5 w400 , %headerstructure_list% 
Gui, Add, Button, gTakeField001 x+5, GET

; Erstelle die Buttons
Gui, Add, Button, gxCommitButton x0,  COMMIT
Gui, Add, Button, gxCancelButton x+5 , CANCEL

; Zeige die GUI
Gui, Show, , Add a new Knowledge Item to an ADHOC Database (source)
return

; Button-Events
xCommitButton:
    
    Gui, Submit, NoHide
    ; MsgBox, Die Daten wurden gespeichert:`nFeld1: %Feld1%`nFeld2: %Feld2%`nFeld3: %Feld3%`nFeld4: %Feld4%`nFeld5: %Feld5%`nFeld6: %Feld6%`nDropdown: %Dropdown%

    selectedDB := Dropdown
    Global xxsearchin := Feld1
    Global xxfitto := Feld2
    Global xxh1 := Feld3
    Global xxh2 := Feld4
    Global xxh3 := Feld5
    Global xxinfohtml := Feld6
    Global xxoutput1 := Feld7
    Global xxoutput2 := Feld8
    Global xxvalidfrom := Feld9
    Global xxvalidto := Feld10

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
Gui, Destroy
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
Gui, Submit, NoHide
arr := StrSplit(MyCombo, ";")
selectedValue1 := arr[1]
selectedValue2 := arr[2]
GuiControl, Text, Feld3, %selectedValue1%
GuiControl, Text, Feld4, %selectedValue2%
Return


StrSplit(selectedValue, ";")

