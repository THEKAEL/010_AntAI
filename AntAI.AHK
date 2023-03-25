#Persistent
#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%

#Include .\OTHER_AHK\TKM_FORMATTING.ahk
#Include .\OTHER_AHK\Class_SQLiteDB.ahk
#Include AntAI_functions.ahk
    
    sqlite_dll_path := A_ScriptDir "\SQLite3.dll"
    user_pattern := "empty"
    knowledge_path := A_ScriptDir "\KNOWLEDGE.db3"
    config_ini_file := A_ScriptDir "\wisdom_config.ini"
    sqliteToolPath := A_ScriptDir "\sqlite3.exe"
    html_outputFile := A_ScriptDir "\AntAi_out.html"
    
    Gosub PROCESS_INI

    my_db3 := New SQLiteDB(sqlite_dll_path)
    my_db3.loadToInMem(knowledge_path)



    sql_template =
    (
        select  h1, h2, h3, info, output, output_2,
        case when '#XXX#' like fit_to then fit_to else search_in end as match_lbl , 
        src_lbl1, src_lbl2, src_lbl3, src_info, search_in, fit_to 
        from T_KNOWLEDGE 
        WHERE 
        search_in like '`%#XXX#`%' ESCAPE '\' or
        '#XXX#' like fit_to
        order by h1,h2,h3,info,output ASC
    )

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
    Gui, Add, Edit, Readonly x10 y10 w600 h400 vDebug
    Gui, Show, w620 h420, Debug Window
    FormatTime, TimeString, A_Now, yyyy-MM-dd HH:mm:ss ;
    DebugAppend("[" TimeString "] LOGGING GUI CREATED")
return


DebugAppend(Data, useNewline = True, addTime = False)
{
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
    sleep 3000
    Gui, Destroy
return


;; Hotkey to susped other hotkeys. This is importat in case the user needs the hotkey in some applications like MS Excel
^Escape::
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

    IniRead, sqlite_dll_path, %config_ini_file%, GENERAL, SQLITE_DLL_PATH , %sqlite_dll_path%
    IniRead, knowledge_path, %config_ini_file% , GENERAL, KNOWLEDGE_PATH , %knowledge_path%
    IniRead, sqliteToolPath, %config_ini_file%, GENERAL, SQLITE3TOOL_PATH , %sqliteToolPath%

    IniRead, hk_open_DB, %config_ini_file%, GENERAL, HK_OPEN_DB , ^F12
    IniRead, hk_help, %config_ini_file%, GENERAL, HK_HELP , #F1

    IniRead, hk_run_html, %config_ini_file%, GENERAL, HK_RUN_TAG , F9
    IniRead, hk_run_html_allcols, %config_ini_file%, GENERAL, HK_RUN_ALLCOLS , F11
    IniRead, hk_run_header, %config_ini_file%, GENERAL, HK_RUN_HEADER , F10
    
    IniRead, hk_run_add_tag, %config_ini_file%, GENERAL, HK_RUN_ADD_TAG, +F9
    IniRead, hk_run_add_header, %config_ini_file%, GENERAL, HK_RUN_ADD_HEADER, +F10
    IniRead, hk_run_add_allcols, %config_ini_file%, GENERAL, HK_RUN_ADD_ALLCOLS, +F11

    IniRead, hk_rebuild_db, %config_ini_file%, GENERAL, HK_REBUILD_DB, F2
    IniRead, display_row_limit, %config_ini_file%, ETC, DISPLAY_ROW_LIMIT, 1000
    IniRead, qry_row_limit, %config_ini_file%, ETC, QRY_ROW_LIMIT, 5000
    IniRead, show_tags, %config_ini_file% ,ETC, SHOW_TAG_SELECTOR, 0
    IniRead, show_all_tags, %config_ini_file% , ETC, SHOW_ALLTAGS_SELECTOR, 1
    IniRead, exe_clipboard, %config_ini_file%, GENERAL, HK_EXECUTE_CLIPBOARD, X
    IniRead, html_outputFile, %config_ini_file%, ETC, HTML_BUFFER_FILE , %html_outputFile%

    ; XLS_INPUTS
    ;IniRead, src_xls_1, %config_ini_file%, XLS_INPUTS, XLS_1 , X
    ;IniRead, xls_src_list, %config_ini_file% , XLS_INPUTS
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

    ;; register dynamically hotkeys based on ini file formatTable

    registerHK(hk_open_DB, "OPEN_DB")
    registerHK(hk_help, "HELP_HTML")
    registerHK(hk_run_header, "HTML_HEADLINE_LOOKUP")
    registerHK(hk_run_html_allcols, "HTML_ALL_LOOKUP")
    registerHK(hk_run_html, "HTML_TAG_LOOKUP")
    ;Hotkey, %hk_run_html% , HTML_TAG_LOOKUP
    registerHK(hk_run_add_tag, "HTML_ADDTAG_LOOKUP")
    registerHK(hk_run_add_header, "HTML_ADD_HEADLINE_LOOKUP")
    registerHK(hk_run_add_allcols, "HTML_ADD_ALL_LOOKUP")
    registerHK(hk_rebuild_db, "REBUILD_DB")
    registerHK(exe_clipboard, "FOLLOW_CLIPBOARD")




    Gosub, HELP_TEXT


return


#F11::
; Test 

Gui +LastFound +AlwaysOnTop -Caption +Border +E0x08000000 +ToolWindow -SysMenu -Owner +Disabled -DPIScale -Theme
Gui Color, EEEEEE
Gui Font, s10, Arial
Gui Add, Text, x10 y10 w200 h20, This is a sample GUI.
Gui Show, NA

   ; Gosub, PROCESS_INI
return

REBUILD_DB:
    Gosub,  OpenLogGui
    DebugAppend("START rebuilding DB: " knowledge_path,True,True)

    my_db3.close() ; close db
    my_db3.loadToInMem(knowledge_path) ; reopen it and load it to memory (RAM)

    buildFromXLS(my_db3, arrayPath,  True)
    buildFromSQLITE(my_db3,arrayPathSQLite, array_sqlite_key, False )
    my_db3.storeto(knowledge_path)  ; save in memory DB to file because we need to have the db in file system for the next setpp

    buildFromCSV(knowledge_path,arrayPathCSV,sqliteToolPath) ; todo: Get CSV config like quotes or sepeators from inif file ??
    my_db3.loadToInMem(knowledge_path) ; bring the db back to the RAM for further use and improved performance.

    OutputDebug, % "Load/Refresh of db finished!"
    Gosub, CloseLogGui

return


HELP_HTML:
    Gosub, HELP_TEXT
Return

HELP_TEXT:
    help_text = 
    ( 
    Your personal Knowledge DB by (c) Thomas Kloeckl
    Hotkey for 
            - HELP                    %hk_help%

            - RUN TAG SEARCH          %hk_run_html%
            - RUN HEADER SEARCH       %hk_run_header%  
            - RUN FULL SEARCH         %hk_run_html_allcols%

            - ADD TAG to search       %hk_run_add_tag%
            - ADD HEADER to search    %hk_run_add_header%
            - ADD anything to search  %hk_run_add_allcols%

            - OPEN DB (db browser)    %hk_open_db%            
            - RE-BUILD DB             %hk_rebuild_db%

            - Execute Clipboard       %exe_clipboard%
            - Turn Hotkeys (on/off)   ^Escape

    Folder for
            - SQLITE SQLite dll       %sqlite_dll_path%
            - ini file 0              %config_ini_file%
            - Main Data Base (Sqlite) %knowledge_path%

    Others / HK Shortcuts:
            # stands for Winows Key
            ^ stands for CTRL or STRG key
            ! stands for ALT key
            + stands fro Shift key
    
    How to...
            In order to open a webpage with your custom help/info you have to:
            - Select a Text or
            - Put text to your clipbord or
            - hover over text with your mouse pointer
            Then you need to press one of the following hotkeys: %hk_run_html%, %hk_run_html_allcols% or %hk_run_header%. 
            It will bring up a help page in your standard browser. Note that this should work within any MS Windows application.

            If you run already a search then you can hit %hk_run_add_tag%, %hk_run_add_header% or %hk_run_add_allcols% to just search within our old output. 
            This might help to bring down the number of results.

            Pressing %exe_clipboard% will try to start the string in your clipboard with the standard application of your machine.
                This might help you to quickly follow a file or folder.

            If a search string contins seperators ";" it will split that string and perform a multiple incremental search.
    )
    MsgBoxGui("Help for Wisdom-DB",help_text)
Return



OPEN_DB:
    Run, %knowledge_path%
Return



FOLLOW_CLIPBOARD:
    run, %Clipboard%
return



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


HTML_ADDTAG_LOOKUP:
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
    printable_output := formatTable_html(fullTable,"KNOWLEDGE DB output for " . user_pattern,False,3,htmlRowLimit, False)

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
            }
            th.grouping {
                position: sticky;
                top: 0;
                min-width: 5`%;
            }
            th.output1 {
                position: sticky;
                top: 0;
                min-width: 10`%;
                max-widht: 40`%;
            }
            th.output2{
                position: sticky;
                top: 0;
                min-width: 10`%;
                max-widht: 40`%;
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
                top: 0;
                background-color: rgb(240,240,255);
            }
            tr:hover {
                background-color: rgb(250,240,240);
            }

            th.srcinfo {
                position: sticky;
                top: 0;
                padding: 0em 0em 0em 0em;
                width:0.5`%;
            }
            Option, Select {
                font-family: "Candara";
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
                    <textarea name="free_edit_textfield" id="free_text" onInput="selectText('free_text')" autofocus=True ></textarea>
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
                <TR>
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
    Run, % html_outputFile
Return



^RButton:: ;todo config in ini
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



ExitSub:
    if A_ExitReason not in Logoff,Shutdown  ; Avoid spaces around the comma in this line.
    {
        MsgBox, 4, , Are you sure you want to exit?
        IfMsgBox, No
            return
    }
    my_db3.Close()
ExitApp 



registerHK(hk_string_semikolon, mylbl){
    if(hk_string_semikolon=="X")
        Return

    hk_arr :=  StrSplit( hk_string_semikolon , ";" )
    Loop % hk_arr.Length()
        Hotkey, % hk_arr[A_Index], %mylbl%

    return

}
