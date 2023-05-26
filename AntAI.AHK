
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






/*
    This is the MAIN AntAi-Script. Its the Starting Point of the AntAi Knowledge Database Tool

    All routines/functions in this file target to serve the implementation of the AntAi Knowledge Data Base Tool
    and are not designed/developped for general usage.
    Author: Thomas Klöckl https://github.com/THEKAEL
*/


#Persistent
#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%

try{

#Include .\OTHER_AHK\TKM_FORMATTING.ahk
#Include .\OTHER_AHK\Class_SQLiteDB.ahk
#Include .\OTHER_AHK\AntAI_functions.ahk


    sqlite_dll_path := A_ScriptDir "\SQLite3.dll"
    user_pattern := "empty"
    knowledge_path := A_ScriptDir "\AntAiKNOWLEDGE.db3"
    config_ini_file := A_ScriptDir "\antai_config.ini"
    sqliteToolPath := A_ScriptDir "\sqlite3.exe"
    html_outputFile := A_ScriptDir "\AntAi_out.html"
    
    ;try catch
    Gosub, PROCESS_INI


    ;try catch 
    my_db3 := New SQLiteDB(sqlite_dll_path)
    if( cfg_inmem == 1) {   
        my_db3.loadToInMem(knowledge_path)
    }
    else {
        my_db3.OpenDB(knowledge_path)
    }

    default_add := "HTML_ADD_ALL_LOOKUP"
    default_run := "HTML_ALL_LOOKUP"


    sql_template_html =
    (
        select  h1, h2, h3, case when trim(info_html)='' then replace( info, char(10),'<BR>') else replace(info_html,char(10),'') end as info_all, output, output_2,
        case when '#XXX#' like fit_to then fit_to else  search_in  end as match_lbl , 
        src_lbl1, src_lbl2, src_lbl3, src_info , search_in, fit_to 
        from T_KNOWLEDGE 
        WHERE 
        ( search_in like '`%#XXX#`%' ESCAPE '\' or
        '#XXX#' like fit_to ) and DATE('now') between show_from and show_to 
        order by h1,h2,h3,info,output ASC
    )

    sql_template_html2 =
    (
        select  h1, h2, h3, case when trim(info_html)='' then replace( info, char(10),'<BR>')  else replace(info_html,char(10),'') end as info_all, output, output_2,
        case when '#XXX#' like fit_to then fit_to else search_in  end as match_lbl , 
        src_lbl1, src_lbl2, src_lbl3, src_info , search_in, fit_to 
        from T_KNOWLEDGE 
        WHERE 
        search_in || '_' || h1 || '_' || h2 || '_' || h3 || '_' || info || '_' || info_html || ' ' || output || ' ' || output_2 like '`%#XXX#`%' ESCAPE '\' or   
        '#XXX#' like fit_to and DATE('now') between show_from and show_to  
        order by h1,h2,h3,info,output ASC
    )

    sql_template_html3 =
    (
        select  h1, h2, h3, case when trim(info_html)='' then replace( info, char(10),'<BR>')  else replace(info_html,char(10),'') end as info_all, output, output_2,
        case when '#XXX#' like fit_to then fit_to else search_in end as match_lbl , 
        src_lbl1, src_lbl2, src_lbl3, src_info , search_in, fit_to 
        from T_KNOWLEDGE 
        WHERE 
        h1 || '_' || h2 || '_' || h3  like '`%#XXX#`%' ESCAPE '\' 
        and DATE('now') between show_from and show_to 
        order by h1,h2,h3,info,output ASC
    )    
    
    prev_qry:=""
    printable_output:=""
    printable_headline :=""
    search_in_all_cols := False
    
    search_in_headers := False
    last_search := ""
    html_alltags :=""

    if(show_all_tags==1) {
        h1_allitems := my_db3.tk_getTableNoHeader("select distinct h1 from T_KNOWLEDGE order by h1 asc")
        h2_allitems := my_db3.tk_getTableNoHeader("select distinct h2 from T_KNOWLEDGE order by h2 asc")
        h3_allitems := my_db3.tk_getTableNoHeader("select distinct h3 from T_KNOWLEDGE order by h3 asc")
        h1_alltags := getOptionTags(h1_allitems,"")
        h2_alltags := getOptionTags(h2_allitems,"")
        h3_alltags := getOptionTags(h3_allitems,"")
        html_alltags =
        (
            <select name='h1a' id='h1a' onInput="copyToTextfield('h1a'); return false;" >
                <option> - </option>
                %h1_alltags%
            </select>
 
    
            <select name='h2a' id='h2a' onInput="copyToTextfield('h2a'); return false;" >
                <option> - </option>
                %h2_alltags%
            </select>

 
            <select name='h3a' id='h3a'  onInput="copyToTextfield('h3a'); return false;" >
                <option> - </option>
                %h3_alltags%
            </select>
        )

    }
    else {
        html_alltags := ""
    }


    OnExit, ExitSub  

return



OpenLogGui:
    ;try catch ohne impact
    Gui, Add, Edit, Readonly x10 y10 w600 h400 vDebug
    Gui, Show, w620 h420, Debug Window
    FormatTime, TimeString, A_Now, yyyy-MM-dd HH:mm:ss ;
    DebugAppend("[" TimeString "] LOGGING GUI CREATED")
return


DebugAppend(Data, useNewline = True, addTime = False)
{
     ;try catch ohne impact
    FormatTime, TimeString, A_Now, HH:mm:ss ;
    GuiControlGet, Debug
    if (useNewline == True) 
        if ( addTime == False)
            GuiControl,,  Debug, %Data%`r`n%Debug%
        else
            GuiControl,,  Debug, [  %TimeString%  ]  %Data%`r`n%Debug%
    else
        GuiControl,,  Debug, %Data%%Debug%
}

closeLogGui:
    ;;; todo als parameter im inif file
    ;sleep 3000
    ;Gui, Destroy
return


;; Hotkey to susped other hotkeys. This is importat in case the user needs the hotkey in some applications like MS Excel
^Escape::
    ;try catch w/o impact
    Suspend, Toggle
    isOn := (A_IsSuspended) ? "OFF" : "ON"
    isPrev := (A_IsSuspended) ? "ON" : "OFF"
    my_user_msg = 
    (
        You have just set the Hotkeys to:
        
        %isOn%

        You can set this value to %isPrev% by typing CTRL+ESCAPE again.
    )
    ;MsgBoxGui( "Hotkey Suspeded", my_user_msg ,4)
    MsgBox, 0, Hotkey suspended, %my_user_msg% , 4
return



PROCESS_INI:
    ; try catch wih error message and script exit ?
    IniRead, sqlite_dll_path, %config_ini_file%, GENERAL, SQLITE_DLL_PATH , %sqlite_dll_path%
    IniRead, knowledge_path, %config_ini_file% , GENERAL, KNOWLEDGE_PATH , %knowledge_path%
    IniRead, sqliteToolPath, %config_ini_file%, GENERAL, SQLITE3TOOL_PATH , %sqliteToolPath%

    IniRead, hk_open_DB, %config_ini_file%, OPTIONAL_HOTKEYS, HK_OPEN_DB , ^F12
    IniRead, hk_help, %config_ini_file%, MANDATORY_HOTKEYS, HK_HELP , #F1

    IniRead, hk_run_default, %config_ini_file%, MANDATORY_HOTKEYS, HK_RUN_DEFAULT , F1
    IniRead, hk_add_default, %config_ini_file%, MANDATORY_HOTKEYS, HK_ADD_DEFAULT , ^F1
    IniRead, hk_change_defaultmode, %config_ini_file%, MANDATORY_HOTKEYS, HK_CHANGE_DEFAULTMODE , !a

    IniRead, hk_run_html, %config_ini_file%, OPTIONAL_HOTKEYS, HK_RUN_TAG , F9
    IniRead, hk_run_html_allcols, %config_ini_file%, MANDATORY_HOTKEYS, HK_RUN_ALLCOLS , F11
    IniRead, hk_run_header, %config_ini_file%, OPTIONAL_HOTKEYS, HK_RUN_HEADER , F10
    IniRead, hk_toy_transparency, %config_ini_file%, OPTIONAL_HOTKEYS, HK_TOY_TRANSPARENCY, X
    
    IniRead, hk_run_add_tag, %config_ini_file%, OPTIONAL_HOTKEYS, HK_RUN_ADD_TAG, +F9
    IniRead, hk_run_add_header, %config_ini_file%, OPTIONAL_HOTKEYS, HK_RUN_ADD_HEADER, +F10
    IniRead, hk_run_add_allcols, %config_ini_file%, MANDATORY_HOTKEYS, HK_RUN_ADD_ALLCOLS, +F11

    IniRead, hk_rebuild_db, %config_ini_file%, OPTIONAL_HOTKEYS, HK_REBUILD_DB, F2
    IniRead, display_row_limit, %config_ini_file%, ETC, DISPLAY_ROW_LIMIT, 1000
    IniRead, qry_row_limit, %config_ini_file%, ETC, QRY_ROW_LIMIT, 5000
    IniRead, show_tags, %config_ini_file% ,ETC, SHOW_TAG_SELECTOR, 0
    IniRead, show_all_tags, %config_ini_file% , ETC, SHOW_ALLTAGS_SELECTOR, 1
    IniRead, exe_clipboard, %config_ini_file%, OPTIONAL_HOTKEYS, HK_EXECUTE_CLIPBOARD, X
    IniRead, html_outputFile, %config_ini_file%, ETC, HTML_BUFFER_FILE , %html_outputFile%
    IniRead, cfg_popupdelay, %config_ini_file%, ETC, POPUP_DELAY_MS, 700
    IniRead, cfg_stdout_browser, %config_ini_file%, RUN_CONFIG_STD , RUN_CONFIG_STDOUT_BROWSER, X
    IniRead, cfg_inmem, %config_ini_file%, ETC, USE_INMEM_DB , 0

    run_config_string := IniGetKeys(config_ini_file,"RUN_CONFIG","|")
    array_run_config := StrSplit( run_config_string , "|" )

    arr_config := Array()
    for index, element in array_run_config
    {
        IniRead, x_temp, %config_ini_file%, RUN_CONFIG, %element%, X
        if(x_temp != "X")
            arr_config.Push(x_temp)
    }

    xls_src_string := IniGetKeys(config_ini_file,"XLS_INPUTS","|")
    array_src_key := StrSplit( xls_src_string , "|" )

    arrayPath := Array()

    for index, element in array_src_key
    {

        IniRead, x_temp, %config_ini_file%, XLS_INPUTS, %element%, X
        if(x_temp != "X")
            arrayPath.Push(x_temp)

    }
    OutputDebug, % arrayPath.Length()


    sqlite_src_string := IniGetKeys(config_ini_file,"SQLITE_INPUTS","|")
    array_sqlite_key := StrSplit( sqlite_src_string , "|" )

    arrayPathSQLite := Array()
    for index, element in array_sqlite_key
    {

        IniRead, x_temp, %config_ini_file%, SQLITE_INPUTS, %element%, X
        if(x_temp != "X")
            arrayPathSQLite.Push(x_temp)

    } 
    OutputDebug, % arrayPathSQLite.Length()

    csv_src_string := IniGetKeys(config_ini_file,"CSV_INPUTS","|")
    array_csv_key := StrSplit( csv_src_string , "|" )

    arrayPathCSV := Array()
    for index, element in array_csv_key
    {

        IniRead, x_temp, %config_ini_file%, CSV_INPUTS , %element%, X
        if(x_temp != "X")
            arrayPathCSV.Push(x_temp)

    } 
    OutputDebug, % arrayPathCSV.Length()



    ;;;; START READIN ADHOC DEFAULTS, SQLITE DB settings and HOTKEYS
    ;;;;
    ;;;;
    ;;;;

    adhocDict := {}
    adhocsqlite_src_string := IniGetKeys(config_ini_file,"ADHOC_SQLITE_INPUTS","|")
    array_adhocsqlite_key := StrSplit( adhocsqlite_src_string , "|" )

    adhocSQLITE_stringlist := ""
    for index, element in array_adhocsqlite_key
    {

        IniRead, x_temp, %config_ini_file%, ADHOC_SQLITE_INPUTS, %element%, X
        if(x_temp != "X"){
            adhocDict[element] := x_temp
            adhocSQLITE_stringlist :=  adhocSQLITE_stringlist "|" x_temp  
        }
    } 

    adhocSQLITE_stringlist := "|||" . adhocSQLITE_stringlist 
    adhocSQLITE_stringlist := StrReplace(adhocSQLITE_stringlist,"||||","")



    src_string := IniGetKeys(config_ini_file,"ADHOC_SQLITE_HOTKEYS","|")
    adhocHK_string := ""
    array_adhocHK_key := StrSplit( src_string , "|" )

    arrayAdhocHK := Array()
    for index, element in array_adhocHK_key
    {

        IniRead, x_temp, %config_ini_file%, ADHOC_SQLITE_HOTKEYS , %element%, X
        if(x_temp != "X"){
            adhocDict[element] := x_temp
            registerHK(x_temp, "RUN_ADHOC_INPUT")
            adhocHK_string := adhocHK_string " | " x_temp
        }

    } 
    adhocHK_string := "|||" . adhocHK_string 
    adhocHK_string := StrReplace(adhocHK_string,"||| | ","")



    src_string := IniGetKeys(config_ini_file,"ADHOC_SQLITE_INPUTS_DEFAULTS","|")
    array_adhocDefaultSQLite_key := StrSplit( src_string , "|" )

    ;arrayAdhocDefaultSQLite := Array()
    for index, element in array_adhocDefaultSQLite_key
    {

        IniRead, x_temp, %config_ini_file%, ADHOC_SQLITE_INPUTS_DEFAULTS , %element%, X
        if(x_temp != "X"){
            adhocDict[element] := x_temp
        }

    } 




    src_string := IniGetKeys(config_ini_file,"ADHOC_SEARCHIN_DEFAULTS","|")
    array_adhocDefaultSEARCHIN_key := StrSplit( src_string , "|" )

    ;arrayAdhocDefaultSEARCHIN := Array()
    for index, element in array_adhocDefaultSEARCHIN_key
    {

        IniRead, x_temp, %config_ini_file%, ADHOC_SEARCHIN_DEFAULTS , %element%, X
        if(x_temp != "X"){
            adhocDict[element] := x_temp
        }

    } 




    src_string := IniGetKeys(config_ini_file,"ADHOC_FITTO_DEFAULTS","|")
    array_adhocDefaultFITTO_key := StrSplit( src_string , "|" )

    ;arrayAdhocDefaultFITTO := Array()
    for index, element in array_adhocDefaultFITTO_key
    {

        IniRead, x_temp, %config_ini_file%, ADHOC_FITTO_DEFAULTS , %element%, X
        if(x_temp != "X"){
            adhocDict[element] := x_temp
        }

    } 
    OutputDebug, % array_adhocDefaultFITTO_key.Length()



    src_string := IniGetKeys(config_ini_file,"ADHOC_H1_DEFAULTS","|")
    array_adhocDefaultH1_key := StrSplit( src_string , "|" )

    ;arrayAdhocDefaultH1 := Array()
    for index, element in array_adhocDefaultH1_key
    {

        IniRead, x_temp, %config_ini_file%, ADHOC_H1_DEFAULTS , %element%, X
        if(x_temp != "X"){
            adhocDict[element] := x_temp
        }

    } 
    OutputDebug, % array_adhocDefaultH1_key.Length()



    src_string := IniGetKeys(config_ini_file,"ADHOC_H2_DEFAULTS","|")
    array_adhocDefaultH2_key := StrSplit( src_string , "|" )

    ;arrayAdhocDefaultH2 := Array()
    for index, element in array_adhocDefaultH2_key
    {

        IniRead, x_temp, %config_ini_file%, ADHOC_H2_DEFAULTS , %element%, X
        if(x_temp != "X"){
            adhocDict[element] := x_temp
        }

    } 
    OutputDebug, % array_adhocDefaultH2_key.Length()



    src_string := IniGetKeys(config_ini_file,"ADHOC_H3_DEFAULTS","|")
    array_adhocDefaultH3_key := StrSplit( src_string , "|" )

    ;arrayAdhocDefaultH3 := Array()
    for index, element in array_adhocDefaultH3_key
    {

        IniRead, x_temp, %config_ini_file%, ADHOC_H3_DEFAULTS , %element%, X
        if(x_temp != "X"){
            adhocDict[element] := x_temp
        }

    } 
    OutputDebug, % array_adhocDefaultH3_key.Length()



    src_string := IniGetKeys(config_ini_file,"ADHOC_INFOHTML_DEFAULTS","|")
    array_adhocDefaultINFOHTML_key := StrSplit( src_string , "|" )

    ;arrayAdhocDefaultINFOHTML := Array()
    for index, element in array_adhocDefaultINFOHTML_key
    {

        IniRead, x_temp, %config_ini_file%, ADHOC_INFOHTML_DEFAULTS , %element%, X
        if(x_temp != "X"){
            adhocDict[element] := x_temp
        }

    } 




    src_string := IniGetKeys(config_ini_file,"ADHOC_OUTPUT1_DEFAULTS","|")
    array_adhocDefaultOUTPUT1_key := StrSplit( src_string , "|" )

    for index, element in array_adhocDefaultOUTPUT1_key
    {

        IniRead, x_temp, %config_ini_file%, ADHOC_OUTPUT1_DEFAULTS , %element%, X
        if(x_temp != "X"){
            adhocDict[element] := x_temp
        }

    } 




    src_string := IniGetKeys(config_ini_file,"ADHOC_OUTPUT2_DEFAULTS","|")
    array_adhocDefaultOUTPUT2_key := StrSplit( src_string , "|" )

    for index, element in array_adhocDefaultOUTPUT2_key
    {

        IniRead, x_temp, %config_ini_file%, ADHOC_OUTPUT2_DEFAULTS , %element%, X
        if(x_temp != "X"){
            adhocDict[element] := x_temp
        }

    } 



    src_string := IniGetKeys(config_ini_file,"ADHOC_SHOWFROM_DEFAULTS","|")
    array_adhocDefaultSHOWFROM_key := StrSplit( src_string , "|" )


    for index, element in array_adhocDefaultSHOWFROM_key
    {

        IniRead, x_temp, %config_ini_file%, ADHOC_SHOWFROM_DEFAULTS , %element%, X
        if(x_temp != "X"){
            adhocDict[element] := x_temp
        }

    } 



    src_string := IniGetKeys(config_ini_file,"ADHOC_SHOWTO_DEFAULTS","|")
    array_adhocDefaultSHOWTO_key := StrSplit( src_string , "|" )

    for index, element in array_adhocDefaultSHOWTO_key
    {

        IniRead, x_temp, %config_ini_file%, ADHOC_SHOWTO_DEFAULTS , %element%, X
        if(x_temp != "X"){
            adhocDict[element] := x_temp
        }

    } 

    ;;;; 
    ;;;;
    ;;;;
    ;;;; START READIN ADHOC DEFAULTS, SQLITE DB settings and HOTKEYS





    ;; register dynamically hotkeys based on ini file formatTable

    registerHK(hk_open_DB, "OPEN_DB")
    registerHK(hk_run_header, "HTML_HEADLINE_LOOKUP")
    registerHK(hk_run_html, "HTML_TAG_LOOKUP")
    registerHK(hk_run_add_tag, "HTML_ADD_TAG_LOOKUP")
    registerHK(hk_run_add_header, "HTML_ADD_HEADLINE_LOOKUP")
    registerHK(hk_rebuild_db, "REBUILD_DB")
    registerHK(exe_clipboard, "FOLLOW_CLIPBOARD")

    registerHK(hk_help, "HELP_HTML")
    registerHK(hk_run_html_allcols, "HTML_ALL_LOOKUP")
    registerHK(hk_run_add_allcols, "HTML_ADD_ALL_LOOKUP")
    registerHK(hk_run_default,"HTML_DEFAULT_LOOKUP")
    registerHK(hk_add_default,"HTML_ADD_DEFAULT_LOOKUP")
    registerHK(hk_change_defaultmode,"CHANGE_DEFAULT_LOOKUP")
    registerHK(hk_toy_transparency,"TOY_TRANSPARENCY")

    
    Gosub, HELP_TEXT


return



CHANGE_DEFAULT_LOOKUP:

    my_message := "NEW DEFAULT MODE: --> "
    if( default_run == "HTML_ALL_LOOKUP"){
        default_add := "HTML_ADD_TAG_LOOKUP"
        default_run := "HTML_TAG_LOOKUP"
        my_message := my_message . "TAG SEARCH"
    } else if (default_run == "HTML_TAG_LOOKUP"){
        default_add := "HTML_ADD_HEADLINE_LOOKUP"
        default_run := "HTML_HEADLINE_LOOKUP"
        my_message := my_message . "HEADLINE SEARCH"
    } else if (default_run == "HTML_HEADLINE_LOOKUP"){
        default_add := "HTML_ADD_ALL_LOOKUP"
        default_run := "HTML_ALL_LOOKUP"
        my_message := my_message . "FULL SEARCH"
    } else {
        default_add := "HTML_ADD_ALL_LOOKUP"
        default_run := "HTML_ALL_LOOKUP"
        my_message := my_message . "FULL SEARCH"
    }

    showPopUp(my_message, cfg_popupdelay)

return

HTML_DEFAULT_LOOKUP:

    Gosub, %default_run%

Return

HTML_ADD_DEFAULT_LOOKUP:

    Gosub, %default_add%

Return




REBUILD_DB:
    Gosub,  OpenLogGui
    DebugAppend("START rebuilding DB: " knowledge_path,True,True)

    my_db3.close() ; close db
    my_db3.loadToInMem(knowledge_path) ; reopen it and load it to memory (RAM)

    buildFromXLS(my_db3, arrayPath,  True)
    buildFromSQLITE(my_db3,arrayPathSQLite, False )
    my_db3.storeto(knowledge_path)  ; save in memory DB to file because we need to have the db in file system for the next setpp

    buildFromCSV(knowledge_path,arrayPathCSV,sqliteToolPath) ; todo: Get CSV config like quotes or sepeators from inif file ??


    flag_deleteEmptyHeader := 1 ; todo: maybe as a config parameter in the ini-file
    if( flag_deleteEmptyHeader == 1) {   
        my_sql := "delete from T_KNOWLEDGE where trim(h1)='' and trim(h2)='' and trim(h3)='' "
        my_db3.Prepare(my_sql, sss)
        sss.Step()
    }
    else {
        ;we do not delete
    }

    if( cfg_inmem == 1) {   
        my_db3.loadToInMem(knowledge_path) ; bring the db back to the RAM for further use and improved performance.
    }
    else {
        ;we do not put it back to the memory and access data directly on the drive
    }
    OutputDebug, % "Load/Refresh of db finished!"
    Gosub, CloseLogGui

return




HELP_HTML:
    Gosub, HELP_TEXT
Return

HELP_TEXT:
    help_text = 
    ( 
    AntAi - Your personal Knowledge DB by Thomas Kloeckl         https://github.com/THEKAEL/010_AntAI

    Hotkey for 
            - HELP                    %hk_help%

        ---- DEFAULT EXECUTION / SEARCH MODE -------
            - SWAP SEARCH MODE        %hk_change_defaultmode%
            - RUN SEARCH              %hk_run_default%         - ADD search condition    %hk_add_default%
            
        ----- DIRECT searches (not recommended)-----
            - RUN TAG SEARCH          %hk_run_html%          - ADD TAG to search       %hk_run_add_tag%
            - RUN HEADER SEARCH       %hk_run_header%          - ADD HEADER to search    %hk_run_add_header%               
            - RUN FULL SEARCH         %hk_run_html_allcols%         - ADD anything to search  %hk_run_add_allcols%
        ---- ADMIN TASKS -----------------------------
            - OPEN DB (db browser)    %hk_open_db%            
            - RE-BUILD DB             %hk_rebuild_db%           
        
        ---- OTHER FEATURES --------------------------
            - Execute Clipboard       %exe_clipboard%
            - Turn Hotkeys (on/off)   ^Escape
            - Knowledge Input-GUI     %adhocHK_string%

    Folder for (ADMIN FEATURES)
            - SQLITE SQLite dll       %sqlite_dll_path%
            - ini file                %config_ini_file%
            - Main Data Base (Sqlite) %knowledge_path%

    Legend HK Shortcuts (AHK Standard syntax / https://www.autohotkey.com/docs/v1/Hotkeys.htm):
            # for Winows Key        ^ for CTRL or STRG key
            ! stands for ALT key    + stands fro Shift key
    
    How to...
        ... for advice how to set up and configure the Tool read detailed wiki: (https://github.com/THEKAEL/010_AntAI/wiki)
        1) Select a search tag/text
            In order to open a HTML-page with your custom help/knowledge you have to:
                - Select a Text or  put text to your clipbord or hover over text with your mouse pointer

        2) Execute Search
            Then you need to press hotkey %hk_run_default%. (Other options see above)
            It will bring up a help page in your standard browser. Note that this should work within almost any application.

        3) Add additional Search to previous search output
            If you run already a search before then you can hit %hk_add_default% to just search within our old output. 
            This might help to bring down the number of results.

        4) You can change the default search mode with %hk_change_defaultmode%
            With the search mode you can define in which column the search should be executed:
                - TAG search: Will search in the tag column SEARCH_IN and FIT_TO
                - HEADER search: Will search in the Header 1-3 columns
                - FULL search: Will search in all columns (header, info, output...)
        More...
            Pressing %exe_clipboard% will try to start the string in your clipboard with the standard application of your machine.
                This might help you to quickly follow a file or folder.

            If a search string contins seperators ";" it will split that string and perform a multiple incremental search.

            You can enter new knowledge via a GUI by copying some text information to your clipboard and pressing 
            the hotkey %adhocHK_string%.
    )
    MsgBoxGui("Help for AntAi Knowledge-DB",help_text)
Return



OPEN_DB:
    Run, %knowledge_path%
Return



;; SUBS
HTML_TAG_LOOKUP:
    Gosub, FETCH_USER_INPUT
        sql_qry := RegExReplace(sql_template_html, "#XXX#",search_array[search_array.MinIndex()],All)
        search_array.RemoveAt(search_array.MinIndex())
        Loop % search_array.Length() {
            xItem := search_array[A_Index]
            sql_qry =
            (
                select * from ( %sql_qry% ) x%A_Index%
                    where  x%A_Index%.search_in like '`%%xItem%`%' ESCAPE '\' or '%xItem%' like x%A_Index%.fit_to
            )
        }
    Gosub, PREPARE_HTML_DATA
    Gosub WRITE_HTML
    Gosub DISPLAY_HTML_DEFAULT

    last_search := user_pattern ; remember in case for repeated call handling
Return


HTML_ADD_TAG_LOOKUP:
    Gosub, FETCH_USER_INPUT

        temp_template = 
        (
            select * from ( %prev_qry% ) xx
                where   xx.search_in like '`%#XXX#`%' ESCAPE '\' or '#XXX#' like xx.fit_to
 
        )
        sql_qry := RegExReplace(temp_template, "#XXX#",search_array[search_array.MinIndex()],All)
        search_array.RemoveAt(search_array.MinIndex())
        Loop % search_array.Length() {
            xItem := search_array[A_Index]
            sql_qry =
            (
                select * from ( %sql_qry% ) x%A_Index%
                    where  x%A_Index%.search_in  like '`%%xItem%`%' ESCAPE '\' or '%xItem%' like x%A_Index%.fit_to
            )
        }

    Gosub, PREPARE_HTML_DATA
    Gosub, WRITE_HTML
    Gosub, DISPLAY_HTML_DEFAULT

    last_search := user_pattern ; remember in case for repeated call handling
Return


HTML_HEADLINE_LOOKUP:
    Gosub, FETCH_USER_INPUT
        sql_qry := RegExReplace(sql_template_html3, "#XXX#",search_array[search_array.MinIndex()],All)
        search_array.RemoveAt(search_array.MinIndex())
        Loop % search_array.Length() {
            xItem := search_array[A_Index]
            sql_qry =
            (
                select * from ( %sql_qry% ) x%A_Index%
                    where  x%A_Index%.h1 || '_' || x%A_Index%.h2 || '_' || x%A_Index%.h3  like '`%%xItem%`%' ESCAPE '\'
            )
        }
    Gosub, PREPARE_HTML_DATA
    Gosub WRITE_HTML
    Gosub DISPLAY_HTML_DEFAULT

    last_search := user_pattern ; remember in case for repeated call handling
Return


HTML_ADD_HEADLINE_LOOKUP:
    Gosub, FETCH_USER_INPUT

        temp_template = 
        (
            select * from ( %prev_qry% ) xx
                where  xx.h1 || '_' || xx.h2 || '_' || 
                xx.h3 like '`%#XXX#`%' ESCAPE '\'
 
        )
        sql_qry := RegExReplace(temp_template, "#XXX#",search_array[search_array.MinIndex()],All)
        search_array.RemoveAt(search_array.MinIndex())
        Loop % search_array.Length() {
            xItem := search_array[A_Index]
            sql_qry =
            (
                select * from ( %sql_qry% ) x%A_Index%
                    where  x%A_Index%.h1 || '_' || x%A_Index%.h2 || '_' || x%A_Index%.h3 like '`%%xItem%`%' ESCAPE '\'
            )
        }
    Gosub, PREPARE_HTML_DATA
    Gosub WRITE_HTML
    Gosub DISPLAY_HTML_DEFAULT

    last_search := user_pattern ; remember in case for repeated call handling
Return


HTML_ALL_LOOKUP:
    Gosub, FETCH_USER_INPUT

        sql_qry := RegExReplace(sql_template_html2, "#XXX#",search_array[search_array.MinIndex()],All)
        search_array.RemoveAt(search_array.MinIndex())
        Loop % search_array.Length() {
            xItem := search_array[A_Index]
            sql_qry =
            (
                select * from ( %sql_qry% ) x%A_Index%
                    where x%A_Index%.search_in || '_' ||  x%A_Index%.h1 || '_' || x%A_Index%.h2 || '_' || x%A_Index%.h3 || '_' || x%A_Index%.info_all || '_' || x%A_Index%.output || '_' || x%A_Index%.output_2 like '`%%xItem%`%' ESCAPE '\' or '`%%xItem%`%' like x%A_Index%.fit_to
            )
        }


    Gosub, PREPARE_HTML_DATA
    Gosub WRITE_HTML
    Gosub DISPLAY_HTML_DEFAULT

    last_search := user_pattern ; remember in case for repeated call handling
Return


HTML_ADD_ALL_LOOKUP:
    Gosub, FETCH_USER_INPUT
        temp_template = 
        (
            select * from ( %prev_qry% ) xx
                where  xx.search_in || '_' || xx.h1 || '_' || xx.h2 || '_' || 
                xx.h3 || '_' || xx.info_all || '_' || xx.output || '_' || 
                xx.output_2 like '`%#XXX#`%' or '#XXX#' like xx.fit_to
 
        )
        sql_qry := RegExReplace(temp_template, "#XXX#",search_array[search_array.MinIndex()],All)
        search_array.RemoveAt(search_array.MinIndex())
        Loop % search_array.Length() {
            xItem := search_array[A_Index]
            sql_qry =
            (
                select * from ( %sql_qry% ) x%A_Index%
                    where  x%A_Index%.search_in || '_' || x%A_Index%.h1 || '_' || x%A_Index%.h2 || '_' || x%A_Index%.h3 || '_' || x%A_Index%.info_all || '_' || x%A_Index%.output || '_' || x%A_Index%.output_2 like '`%%xItem%`%' ESCAPE '\' or '%xItem%' like  x%A_Index%.fit_to
            )
        }
    Gosub, PREPARE_HTML_DATA
    Gosub, WRITE_HTML
    Gosub, DISPLAY_HTML_DEFAULT

    last_search := user_pattern ; remember in case for repeated call handling
Return


FETCH_USER_INPUT:
    send ^c
    Sleep, 100

    user_pattern := trim(Clipboard, omitchars := " `t`r`n")
    if( user_pattern == "" or user_pattern==last_search)  {
        click, 2
        Sleep, 100
        send ^c
        Sleep, 100
        user_pattern := trim(Clipboard, omitchars := " `t`r`n")
    }

    if(user_pattern=="") { 
        Return
    }
    user_pattern_orig := user_pattern
    user_pattern := StrReplace(user_pattern,"_","\_")
    user_pattern := StrReplace(user_pattern,"%","\%")
    search_array := strsplit(user_pattern,";"," `t`r`n")

return

FETCH_USER_INPUT2:
    send ^c
    Sleep, 100

    user_pattern := trim(Clipboard, omitchars := " `t`r`n")
    if( user_pattern == "" )  {
        click, 2
        Sleep, 100
        send ^c
        Sleep, 100
        user_pattern := trim(Clipboard, omitchars := " `t`r`n")
    }

    if(user_pattern="") { 
        Return
    }
    user_pattern_orig := user_pattern
    user_pattern := StrReplace(user_pattern,"_","\_")
    user_pattern := StrReplace(user_pattern,"%","\%")
    search_array := strsplit(user_pattern,";"," `t`r`n")

return

PREPARE_HTML_DATA:
    
    if (show_tags != 0 ) {
        h1_items := my_db3.tk_getTableNoHeader("select distinct h1 from ( " sql_qry " )")
        h2_items := my_db3.tk_getTableNoHeader("select distinct h2 from ( " sql_qry " )")
        h3_items := my_db3.tk_getTableNoHeader("select distinct h3 from ( " sql_qry " )")
        h1_tags := getOptionTags(h1_items,"")
        h2_tags := getOptionTags(h2_items,"")
        h3_tags := getOptionTags(h3_items,"")
    }

    OutputDebug, %sql_qry%
    if(my_db3._Handle == 0) 
        my_db3.openDB(knowledge_path,"W",False)

    limited_sql_qry := sql_qry " LIMIT " qry_row_limit 
    limited_sql_qry := "select  h1, h2, h3, info_all, output, output_2, match_lbl, src_lbl1, src_lbl2, src_lbl3, src_info  from (" . limited_sql_qry . ") TK "
    
    fullTable := my_db3.tk_getTableNoHeader(limited_sql_qry)

    prev_qry := sql_qry ; for later use in case the user would like add a condition / without LIMIT clause

    htmlRowLimit := display_row_limit ; taken from ini-file / see above: display_row_limit
    printable_output := formatTable_html(fullTable,"AntAi Knowledge-DB output for " . user_pattern,False,3,htmlRowLimit, False)

    printable_headline := "Output for:  > "  user_pattern " <  (There are #" min(htmlRowLimit,fullTable.MaxIndex()) " out of " fullTable.MaxIndex() " results shown!)"

Return





WRITE_HTML:
    html_optionstag = 
    (
        <TH class='base grouping'> 
            <button id="increaseBtn" class="hdgimmic indecrease">Incr. Row Height</button> <br>
            <select name='h1' id='h1' class='hdgimmic' onInput="copyToTextfield('h1'); return false;" >
                <option> - </option>
                %h1_tags%
            </select>
        </TH> 
        <TH class='base grouping'  > 
            <button id="decreaseBtn" class="hdgimmic indecrease">Decr. Row Height</button> <BR>
            <select name='h2' id='h2' class='hdgimmic' onInput="copyToTextfield('h2'); return false;" >
                <option> - </option>
                %h2_tags%
            </select>
        </TH> 
        <TH class='base grouping' >  
            <select name='h3' id='h3'  onInput="copyToTextfield('h3'); return false;" >
                <option> - </option>
                %h3_tags%
            </select>
        </TH> 
    )
    if(show_tags==0){
        html_optionstag =
        (
            <TH class='base grouping'><button id="increaseBtn" class="hdgimmic indecrease">Incr. Row Height</button></TH>
            <TH class='base grouping'><button id="decreaseBtn" class="hdgimmic indecrease">Decr. Row Height</button></TH>
            <TH class='base grouping'></TH>
        )
    }

    HTML_page =
    ( 
    <!DOCTYPE html>

        <style>
            table, th.base, td.base, caption {
                border: thin solid #e0e0e0;
            }
            font.lessvisible{
                color: rgb(210,210,210);
            }
            button.hdgimmic, select.hdgimmic{
                width: 100`%;
            }
            button.indecrease{
                font-size: 0.7em;
                font-face: Candara;
            }
            textarea {
                width: 100`%
            }
            table.main {
                border-collapse: collapse;
                border-spacing: 0;
                border-width: thin 0 0 thin;
                margin: 0 0 1em;
                width: 100`%;
            }
            table {
                border-collapse: collapse;
                border-spacing: 0;
                border-width: thin 0 0 thin;
                margin: 0 0 0em;
            }
    
            th.base {
                font-weight: 700;
                background-color: rgb(250,240,240);
                text-align: left;
                padding: 2em 1em 1em 1em;
                white-space:nowrap;
            }
            th.info {
                position: sticky;
                top: 0;
                width: 50`%
                min-width: 45`%;
                max-width: 70`%;
                z-index: 1;
            }
            th.grouping {
                position: sticky;
                top: 0;
                min-width: 5`%;
                z-index: 1;
            }
            th.output1 {
                position: sticky;
                top: 0;
                min-width: 10`%;
                max-widht: 40`%;
                z-index: 1;
            }
            th.output2{
                position: sticky;
                top: 0;
                min-width: 10`%;
                max-widht: 40`%;
                z-index: 1;
            }
            object {
                width: 100`%;
                height:  100`%;
            }
            td.base {
                padding: 1em 1em 1em 1em;
                word-wrap: break-word;
            } 
            td.tblcol_11, td.tblcol_10, td.tblcol_9, td.tblcol_8, td.tblcol_7 {
                font-color: rgb(240,240,240);
                font-weight: normal;
                text-align: left;
                font-size: 0px;
                padding: 0em 0em 0em 0em;
            }        
            div.alldata_4, div.alldata_5, div.alldata_6 {
                overflow-x: hidden;
                overflow-y: auto;
                resize: both;
            }               
			col.tblgrouping {
                background-color: rgb(240,240,255);  
            }
            col.tblsrcinfo {
                background-color: rgb(250,250,250);
                visibility: table-column;
            }
            th.base2 {
                position: sticky;
                z-index: 1;
                top: 0;
                background-color: rgb(240,240,255);
            }
            tr:hover {
                background-color: rgb(250,240,240);
            }

            th.srcinfo {
                position: sticky;
                z-index: 1;
                top: 0;
                padding: 0em 0em 0em 0em;
                width:0.5`%;
            }
            Option, Select {
                font-family: "Candara";
            }

            #sticky-textfield {
                position: sticky;
                top: 0;
                z-index: 2;
                width: 100`%;
                background-color: #f0f0f0;
                padding: 5px;
            }

    </style>


    <script>
        var size_flag = "10px";
        var prev_value = "";

        function CopyToClipboard(id)
        {
            var r = document.createRange();
            r.selectNode(document.getElementById(id));
            window.getSelection().removeAllRanges();
            window.getSelection().addRange(r);
            document.execCommand('copy');
            window.getSelection().removeAllRanges();
        }
        ;
        function copyToTextfield(id){
            document.getElementById("free_text").value = document.getElementById(id).value
            document.getElementById("free_text").focus();
            document.getElementById("free_text").select();
        }
        ;
        function changeColstate()
        {
            const collection2 = document.getElementsByClassName("tblcol_7");
            for (let i = 0; i < collection2.length; i++) {
                collection2[i].style.fontSize = size_flag ;
            }
            const collection3 = document.getElementsByClassName("tblcol_8");
            for (let i = 0; i < collection3.length; i++) {
                collection3[i].style.fontSize = size_flag;
            }
            const collection4 = document.getElementsByClassName("tblcol_9");
            for (let i = 0; i < collection4.length; i++) {
                collection4[i].style.fontSize = size_flag;
            }
            const collection5 = document.getElementsByClassName("tblcol_10");
            for (let i = 0; i < collection5.length; i++) {
                collection5[i].style.fontSize = size_flag;
            }
            const collection6 = document.getElementsByClassName("tblcol_11");
            for (let i = 0; i < collection6.length; i++) {
                collection6[i].style.fontSize = size_flag;
            }
            if(size_flag == "10px")
            {
                size_flag = "0px"
            }
            else
            {
                size_flag = "10px"
            }
        }
        ;
        function selectText(id) {
            const input = document.getElementById(id);
            var curr_value = input.value ;

            if(isNaN(curr_value.charCodeAt(0)) ){
                input.value=""
                prev_value=""
            }
            else {
                input.value = prev_value + curr_value ;
                // alert(curr_value.charCodeAt(0)) ;
                input.focus();
                input.select();
                prev_value = prev_value + curr_value ;
            }
        };

    </script>


    <HTML>
        <HEAD>

        </HEAD>

        <BODY>
            <P title='# is the Windows-Key / ! is the ALT-Key / ^ is CTRL-Key / + is the SHIFT-Key'>
                <div>
                <font color=gray size=4em face='Candara'>
                    HELP: %hk_help% - - RUN (default search): %hk_run_html% - - RUN (search in header1-3) %hk_run_header% - - RUN (search in all Cols): %hk_run_html_allcols% - - ADD TAG to search: %hk_run_add_tag% - - ADD HEADER to search: %hk_run_add_header% - - ADD any Condition: %hk_run_add_allcols%  <BR> || %exe_clipboard% EXECUTE the CLIPBOARD with standard app || # is Windows-Key - - ! is ALT-Key - - ^ is CTRL-Key - - + is SHIFT-Key 
                </font>
                </div>
                <DIV id="sticky-textfield">
                    <textarea name="free_edit_textfield" id="free_text" onInput="selectText('free_text')" autofocus=True ></textarea>
                </DIV>
                    <BR>
                %html_alltags%
                
                </div>
            </P>
            <br>
            <br>

        <font face='Candara' >
        <TABLE id='master_table' class='main'>
            <CAPTION>
                %printable_headline% 
            </CAPTION>
            <COLGROUP>
                <col span=3 class='tblgrouping' >
                <col span=3 class='tblcontent' >
                <col span=5 class='tblsrcinfo' >
            </COLGROUP>            
            <thead>
                <TR style="height: 8em;">
                    %html_optionstag%
                    <TH class='base info'> Info </TH> 
                    <TH class='base output1'> Output </TH> 
                    <TH class='base output2'> Output_2 </TH>
                    <TH class='base2 srcinfo' onClick="changeColstate();return false;">  </TH> 
                    <TH class='base2 srcinfo' onClick="changeColstate();return false;">  </TH>
                    <TH class='base2 srcinfo' onClick="changeColstate();return false;">  </TH>
                    <TH class='base2 srcinfo' onClick="changeColstate();return false;">  </TH>
                    <TH class='base2 srcinfo' onClick="changeColstate();return false;">  </TH>
                </TR>
            </thead>
            <tbody>
                %printable_output%
            </tbody>
        </TABLE>
        </font>

        </BODY>

    <script>
        const elements = document.querySelectorAll("div.alldata_4, div.alldata_5, div.alldata_6");
        const table = document.getElementById("master_table");
        const increaseBtn = document.getElementById("increaseBtn");
        const decreaseBtn = document.getElementById("decreaseBtn");
        increaseBtn.addEventListener("click", function() {
            requestAnimationFrame( function(){
        for (let i = 0; i < table.rows.length; i++) {
            table.rows[i].style.maxHeight = (table.rows[i].offsetHeight + table.rows[i].offsetHeight*0.3) + "px";
            
        }
        elements.forEach(function(element) {
            element.style.maxHeight = (element.offsetHeight + element.offsetHeight*0.3) + "px";
          });
        });
        });
        
        decreaseBtn.addEventListener("click", function() {
        requestAnimationFrame( function(){
        for (let i = 0; i < table.rows.length; i++) {
            table.rows[i].style.maxHeight = (table.rows[i].offsetHeight - table.rows[i].offsetHeight*0.3 ) + "px";
        }
        elements.forEach(function(element) {
            element.style.maxHeight = (element.offsetHeight - element.offsetHeight*0.3) + "px";
          });
        });
    });
    </script>

    </HTML>
    )

    FileDelete, % html_outputFile
    FileAppend, %html_Page%, %html_outputFile%, UTF-8
Return



DISPLAY_HTML_DEFAULT:

    if(cfg_stdout_browser=="X") {
        ;Default based on Sstemsettings is used to execute / open html file
        Run, % html_outputFile
        return
    }


    if ( RegExMatch( cfg_stdout_browser,"\{\{.*\}\}" ) > 0 ) {
        to_execute:=RegExReplace(cfg_stdout_browser, "\{\{.*\}\}" , html_outputFile)
        to_execute:=StrReplace(to_execute,".\", A_ScriptDir "\")
        run, %to_execute%
        Return
    }
    
    try{

        ; If no special handling was found execute the clipboard
        html_outputFile2:=StrReplace(html_outputFile,".\", A_ScriptDir "\")
        Run, %cfg_stdout_browser%  %html_outputFile2%

    } catch Error {
        Run, % html_outputFile
    }


Return



TOY_TRANSPARENCY: ;todo config in ini
    MouseGetPos,,, MouseWin
    WinGet, Transparent, Transparent, ahk_id %MouseWin%
    if(Transparent<90) {
        WinSet, Transparent, 255, ahk_id %MouseWin%
        WinSet, AlwaysOnTop, Off, ahk_id %MouseWin%
    }
    else if(Transparent<180)
    {
        WinSet, Transparent, 5, ahk_id %MouseWin%
        WinSet, AlwaysOnTop, On ,ahk_id %MouseWin%
    }
    else if(Transparent<230)
    {
        WinSet, Transparent, 170, ahk_id %MouseWin%
        WinSet, AlwaysOnTop, On ,ahk_id %MouseWin%
    }
    else 
    {
        WinSet, Transparent, 229, ahk_id %MouseWin%
        WinSet, AlwaysOnTop, On ,ahk_id %MouseWin%
    }
return



FOLLOW_CLIPBOARD:
    
    x := StrLen(trim(Clipboard)) 
    if(x==0){
        ;Clipboard is empty or invalid -> Ther is nothing to do or execute
        return
    }
    my_clip := trim(Clipboard)


    to_execute:=""
    temp_needle:=""
    file_ending := getFileExt(my_clip)
    for index, element in arr_config
    {
        to_execute:=element
        temp_needle := extractToken(element,"{{","}}")
        if ( RegExMatch( file_ending,temp_needle ) > 0 ) {
            to_execute:=RegExReplace(to_execute, "\{\{.*\}\}" , my_clip)
            run, %to_execute%
            Return
        }
    }

    ; If no special handling was found execute the clipboard
    run, %my_clip%
return



ExitSub:
    if A_ExitReason not in Logoff,Shutdown  ; Avoid spaces around the comma in this line.
    {
        MsgBox, 4, , Are you sure you want to exit?
        IfMsgBox, No
            return
    }
    my_db3.Close()
ExitApp 



getFirstKeyByValue(dict, val)
{
    for key, valueX in dict
    {
        if (valueX == val)
            return key
    }
    return ""
}



RUN_ADHOC_INPUT:
    Gui, Destroy
    FormatTime, currDt, %A_Now%, yyyy-MM-dd
    FormatTime, currMonth, %A_Now%, yyyy-MM
    FormatTime, currDt2, %A_Now%, yyyyMMdd

    if RegExMatch(getFirstKeyByValue(adhocDict, A_ThisHotkey), "(\d+)$", match)
        my_idx := match
    else
        my_idx := 1
        
    
    Gosub, FETCH_USER_INPUT2
    my_clip := user_pattern_orig

    ;Set some defaults
   
    zsearchin:= adhocDict["DEFAULT_SEARCHIN_" . my_idx] . "ADHOC_" . currDt "_" . currDt2
    zfitto:=  adhocDict["DEFAULT_FITTO_" . my_idx]
    zh1:= (adhocDict["DEFAULT_H1_" . my_idx] == "") ? "" : adhocDict["DEFAULT_H1_" . my_idx]
    zh2:= (adhocDict["DEFAULT_H2_" . my_idx] == "") ? "" : adhocDict["DEFAULT_H2_" . my_idx]
    zh3:= (adhocDict["DEFAULT_H3_" . my_idx] == "") ? currMonth : adhocDict["DEFAULT_H3_" . my_idx]
    zinfohtml := "This Memo was created on the " . currDt ".`n<BR><BR>`n" .  adhocDict["DEFAULT_INFOHTML_" . my_idx]
    zoutput1 := (adhocDict["DEFAULT_OUTPUT1_" . my_idx] == "" ) ? my_clip : adhocDict["DEFAULT_OUTPUT1_" . my_idx]
    zoutput2 := adhocDict["DEFAULT_OUTPUT2_" . my_idx]
    zvalidfrom := (adhocDict["DEFAULT_SHOWFROM_" . my_idx] == "") ? currdt : adhocDict["DEFAULT_SHOWFROM_" . my_idx] 
    zvalidto := (adhocDict["DEFAULT_SHOWTO_" . my_idx] == "" ) ? "2099-12-31" : adhocDict["DEFAULT_SHOWTO_" . my_idx] 
    zdb3list := adhocSQLITE_stringlist
    zselectedDB := adhocDict["ADHOCSQLITE_" . my_idx]

    showAdhocInputGui(my_db3, sqlite_dll_path, zsearchin  , zfitto , zh1 ,zh2,zh3,zinfohtml , zoutput1 ,zoutput2,zvalidfrom,zvalidto,zdb3list,zselectedDB)
    my_db3.storeto(knowledge_path) 

return




#Include .\OTHER_AHK\AntAiGUI.AHK



}catch error{
    errmsg := error.message
    errfile := error.file
    errline := error.line
    MsgBox, MsgBox Fehlerdetails:`n`nFehlermeldung: %errmsg%`nDatei: %errfile%`nZeile: %errline%

    MsgBox, 4, Error occured somewhere please consider to debug. Restart Script?
    IfMsgBox Yes
    {
        NeustartErforderlich := true
        Reload
    }
}
