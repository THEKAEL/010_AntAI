
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

    This file contains some hepler functions that are used in the main script (AntAi.AHK).
    Mainly you find here import function for csv, xls and sqlite...

    Most functions in this file target to serve the main script and are not designed/developped for general usage.
    Author: Thomas Klöckl https://github.com/THEKAEL
*/

#NoEnv

#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%


/*
    This functions returns a string with all keys that were used in a specific section of the ini-file.
    PARAM:  
        InputFile  (String) -   The Path to the ini-file 
        Section (String)    -   Thee Section of the ini-file
        Delimiter (String)  -   Seperator for the keys used in the returned values
    RETURNS:
        (String)            -   The list of all keys 

*/
IniGetKeys(InputFile, Section , Delimiter="")
{
	;msgbox, OutputVar=%OutputVar% `n InputFile=%InputFile% `n Section=%Section% `n Delimiter=%Delimiter%
	Loop, Read, %InputFile%
	{
		If SectionMatch=1
		{
			If A_LoopReadLine=
				Continue
			StringLeft, SectionCheck , A_LoopReadLine, 1
			If SectionCheck <> [
			{
				StringSplit, KeyArray, A_LoopReadLine , =
				If KEYSlist=
					KEYSlist=%KeyArray1%
				Else
					KEYSlist=%KEYSlist%%Delimiter%%KeyArray1%
			}
			Else
				SectionMatch=
		}
		If A_LoopReadLine=[%Section%]
			SectionMatch=1
	}
	return KEYSlist
}


/*
    This functions import data from SQLite data sources to the knowledge data base.
    PARAM:  
        sqliteDBObject  (Class_SQLiteDB)    -   This is the object of the sqlite AntAi (Main-) Knowledge Database
        sqliteArray (Array of Strings)      -   A list with valid path to valid SQLite data bases
        deleteOldData (Bool)                -   The Main Database table is delete completely !!! In case this parameter is true
    RETURNS:
        nothing
        
*/
buildFromSQLITE(sqliteDBObject, sqliteArray, deleteOldData=False )
{
    DebugAppend("Start Rebuilding Knowledge Database from files.",True,True)

    if(deleteOldData==True) {
        DebugAppend("START: Drop old Tables.", True,True)
        my_sql := "drop table if exists T_KNOWLEDGE"
        my_sql2 := "CREATE TABLE T_KNOWLEDGE( ""search_in"" TEXT,""fit_to"" TEXT,""H1"" TEXT,""H2"" TEXT,""H3"" TEXT,""INFO"" TEXT,""INFO_HTML"" TEXT,""OUTPUT"" TEXT,""OUTPUT_2"" TEXT,""SRC_LBL1"" TEXT,""SRC_LBL2"" TEXT,""SRC_LBL3"" TEXT,""SRC_INFO"" TEXT, ""_insertLBL"" TEXT)"

        sqliteDBObject.Prepare(my_sql, sss)
        sss.Step()
        sqliteDBObject.Prepare(my_sql2, sss)
        sss.Step()

        DebugAppend("END: Drop old Tables.", True, True)
    }

    num_files := sqliteArray.count()
    DebugAppend("INFO: There were SQLITE files found to be loaded: #" num_files, True, True)
    Loop, %num_files%
    {
        sqlite_counter := A_Index+0
        OutputDebug, % sqliteArray[sqlite_counter]
        DebugAppend("")
        DebugAppend("")
        DebugAppend("START processing file " A_Index ": " sqliteArray[sqlite_counter] ,True,True)

        curr_sqlitefile := sqliteArray[sqlite_counter]

        if(FileExist(curr_sqlitefile) == "") {
            DebugAppend("WARNING: File NOT (!) found --> SKIPP import" ,True,True)
            Continue
        }
        else{
            DebugAppend("MSG: File found --> Try import" ,True,True) 
        }

        ; ToDo: Some error handling 
        sqliteDBObject.AttachDB(curr_sqlitefile,"SRC")
        sql_statement = 
        (
            insert into T_KNOWLEDGE ( search_in, fit_to, h1,h2,h3, info,INFO_HTML,output,OUTPUT_2,SHOW_FROM,SHOW_TO,src_lbl1,SRC_LBL2,SRC_LBL3,SRC_INFO,_insertLBL)
            select 
            search_in,
            fit_to,
            h1, h2, h3,
            info, INFO_HTML,
            output, output_2,
            SHOW_FROM, SHOW_TO,
            '%curr_sqlitefile%' src_lbl1,
            'T_KNOWLEDGE' src_lbl2,
            'n/a' src_lbl3,
            'SQLITE' src_info,
            'n/a' _insertLBL
            from SRC.T_KNOWLEDGE
        )
        
        sqliteDBObject.Prepare(sql_statement, sss)
        sss.Step()
        DebugAppend("FINISHED processing file " A_Index ": " sqliteArray[sqlite_counter] ,True,True)
    }
    
    my_sql := "update T_KNOWLEDGE set show_from='1900-01-01' where show_from is null or trim(show_from) ='' "
    sqliteDBObject.Prepare(my_sql, sss)
    sss.Step()
    my_sql := "update T_KNOWLEDGE set show_to='2999-12-31' where show_to is null or trim(show_to) ='' "
    sqliteDBObject.Prepare(my_sql, sss)
    sss.Step()

    my_sql := "delete from T_KNOWLEDGE where trim(h1)='' and trim(h2)='' and trim(h3)=''  and trim(info)='' and trim(info_html)='' and trim(output)='' and trim(output_2)='' "
    sqliteDBObject.Prepare(my_sql, sss)
    sss.Step()
    
    DebugAppend("FINISHED processing SQLITE-files: #" sqliteArray[sqlite_counter] ,True,True)

}

/*
    This functions import data from csv data sources to the knowledge data base.
    PARAM:  
        db_path  (Class_SQLiteDB)    -   This is the object of the sqlite AntAi (Main-) Knowledge Database
        loc_arrayPathCSV (Array of Strings)      -   A list with valid path to valid csv files
        loc_sqliteToolPath (String)                -   The path to the sqlite tool. We use this external tool to import csv data.
        quote4string (String)   - Strings quotes used in the csv file. This parameter will be passed on the to sqlite tool.
        delim - Column seperator used in the csv file. This parameter will be passed on the to sqlite tool.
        mask - Masking special character... not used at the moment
    RETURNS:
        nothing
        
*/
buildFromCSV(db_path,loc_arrayPathCSV,loc_sqliteToolPath,quote4string="""", delim=",", mask=""){

    ;loc_sqliteToolPath := StrReplace(loc_sqliteToolPath, "\" , "\\" )
    num_files := loc_arrayPathCSV.count()

    Loop, %num_files%
    {
        csv_counter := A_Index+0
        OutputDebug, % loc_arrayPathCSV[csv_counter]
        DebugAppend("")
        DebugAppend("")
        DebugAppend("START processing CSV file " A_Index ": " loc_arrayPathCSV[csv_counter] ,True,True)

        curr_csvfile := loc_arrayPathCSV[csv_counter]
        curr_csvfile_bak := curr_csvfile
        if(FileExist(curr_csvfile_bak) == "") {
            DebugAppend("WARNING: File NOT (!) found --> SKIPP import" ,True,True)
            Continue
        }
        else{
            DebugAppend("MSG: File found --> Try import" ,True,True)
        }
        
        curr_csvfile := StrReplace(curr_csvfile, "\" , "\\" )
        OutputDebug, %loc_sqliteToolPath% %db_path% ".mode csv" ".import -skip 1 %curr_csvfile% T_KNOWLEDGE"
        RunWait, %loc_sqliteToolPath% %db_path% ".mode csv" ".import %curr_csvfile% T_KNOWLEDGE", ,  ;hide 
        ;Run, %loc_sqliteToolPath% %db_path% "update T_KNOWLEDGE set src_lbl1='curr_csvfile', src_lbl2='FILE', src_lbl3='n/a', src_info='CSV', _insertLBL='csv_updated' where src_info is NULL", ,
        my_sql := """update T_KNOWLEDGE set src_lbl1='" curr_csvfile_bak "', src_lbl2='FILE', src_lbl3='n/a', src_info='CSV', _insertLBL='csv_updated' where src_info is NULL"""
        OutputDebug, %loc_sqliteToolPath% %db_path%  %my_sql%
        RunWait, %loc_sqliteToolPath% %db_path%  %my_sql%
        my_sql := """delete from T_KNOWLEDGE where upper(h1)='H1' and upper(h2)='H2' and upper(h3)='H3' """
        OutputDebug, %loc_sqliteToolPath% %db_path%  %my_sql%
        RunWait, %loc_sqliteToolPath% %db_path%  %my_sql%

        DebugAppend("END processing CSV file " A_Index ": " loc_arrayPathCSV[csv_counter] ,True,True)

        ;W:\RWE-Trading\MFC\PC_CAO_POWER\MFC_PH\Other\2001_TK\100_Infosrc\DBSRC_PSP.db3
        ;W:\RWE-Trading\MFC\PC_CAO_POWER\MFC_PH\Other\2001_TK\100_Infosrc\T_KNOWLEDGE_PSP.csv
        ;sqlite3 -header -csv mydb.db "SELECT * FROM mytable" > myfile.csv
        ;sqlite3 mydb.db -header -csv "SELECT * FROM mytable" > myfile.csv
    }

    my_sql := """update T_KNOWLEDGE set show_from='1900-01-01' where show_from is null or trim(show_from) ='' """
    ;OutputDebug, %loc_sqliteToolPath% %db_path%  %my_sql%
    RunWait, %loc_sqliteToolPath% %db_path%  %my_sql%

    my_sql := """update T_KNOWLEDGE set show_to='2999-12-31' where show_to is null or trim(show_to) ='' """
    ;OutputDebug, %loc_sqliteToolPath% %db_path%  %my_sql%
    RunWait, %loc_sqliteToolPath% %db_path%  %my_sql%
    DebugAppend("T_KNOWLEDGE cleaned." ,True,True)

}


/*
    This functions import data from xls data sources to the knowledge data base.
    PARAM:  
        sqliteDBObject  (Class_SQLiteDB)    -   This is the object of the sqlite AntAi (Main-) Knowledge Database
        xlsArray (Array of Strings)         -   A list with valid path to valid xls files
        deleteOldData (Bool)                -   The Main Database table is delete completely !!! In case this parameter is true
    RETURNS:
        nothing
        
*/
buildFromXLS(sqliteDBObject, xlsArray, deleteOldData=True )
{
    ; todo: progress bar and logging and user feedback in the calling method
    ; do plausi-checks fo xlsArray and lblArray
    ; check if db is open !

    if (isExcelInstalled() == False )  {
        MsgBox, 48, No Excel Installation Found, We could not create a COM Object based on a valid Excel installation on your computer. Please install Excel or convert your XLS into a vaid CSV format instad. 
        DebugAppend("WARNING: No Excel installation found. Skipp import. ", True,True)
        DebugAppend("MSG: Please install MS Excel or convert XLS files to CSV. ", True,True)
        return
    }
    else {
        DebugAppend("MSG: Valid Excel installation found.", True,True)

    }

    DebugAppend("Start Rebuilding Knowledge Database from files.",True,True)
    if(deleteOldData==True) {
        DebugAppend("START: Drop old Tables.", True,True)
        my_sql := "drop table if exists T_KNOWLEDGE"
        my_sql2 := "CREATE TABLE T_KNOWLEDGE( ""search_in"" TEXT,""fit_to"" TEXT,""H1"" TEXT,""H2"" TEXT,""H3"" TEXT,""INFO"" TEXT,""INFO_HTML"" TEXT,""OUTPUT"" TEXT,""OUTPUT_2"" TEXT, ""SHOW_FROM"" TEXT, ""SHOW_TO"", ""SRC_LBL1"" TEXT,""SRC_LBL2"" TEXT,""SRC_LBL3"" TEXT,""SRC_INFO"" TEXT, ""_insertLBL"" TEXT)"
       sqliteDBObject.Prepare(my_sql, sss)
        sss.Step()
        sqliteDBObject.Prepare(my_sql2, sss)
        sss.Step()
        DebugAppend("END: Drop old Tables.", True, True)
    }

    std_head := ["SEARCH_IN","FIT_TO","H1","H2","H3","INFO","INFO_HTML","OUTPUT","OUTPUT_2","SHOW_FROM","SHOW_TO"]
    std_head_str := "SEARCH_IN" "FIT_TO" "H1" "H2" "H3" "INFO" "INFO_HTML" "OUTPUT" "OUTPUT_2" "SHOW_FROM" "SHOW_TO"

    short_head := ["SEARCH_IN","H1","H2","H3","INFO_HTML","OUTPUT","OUTPUT_2","SHOW_FROM", "SHOW_TO"]
    short_head_str := "SEARCH_IN" "H1" "H2" "H3" "INFO_HTML" "OUTPUT" "OUTPUT_2" "SHOW_FROM" "SHOW_TO"
 
    tiny_head := ["H1", "INFO_HTML", "OUTPUT", "OUTPUT_2","SHOW_TO"]
    tiny_head_str := "H1" "INFO_HTML" "OUTPUT" "OUTPUT_2" "SHOW_TO"


    DebugAppend("START: Create an XLS Application Object.", True, True)
    XL := ComObjCreate("Excel.Application")
    XL.Visible := False

    DebugAppend("END: Create an XLS Application Object.", True, True)
    num_files := xlsArray.count()
    DebugAppend("INFO: There were XLS files found to be loaded: #" num_files, True, True)
    Loop, %num_files%
    {
        Sleep, 4000
        xls_counter := A_Index+0
        OutputDebug, % xlsArray[xls_counter]
        DebugAppend("")
        DebugAppend("")
        DebugAppend("START file " A_Index ": " xlsArray[xls_counter] ,True,True)
        my_xls_to_open := StrReplace(xlsArray[xls_counter], ".\", A_ScriptDir "\")

        ;OutputDebug, % my_xls_to_open
        ;OutputDebug, % FileExist(my_xls_to_open)


        if(FileExist(my_xls_to_open) == "") {
            DebugAppend("WARNING: File NOT (!) found --> SKIPP import" ,True,True)
            Continue
        }
        else{
            DebugAppend("MSG: File found --> Try import" ,True,True)
        }

        XL_WB := XL.Workbooks.Open(my_xls_to_open,False,True) ; no link update + read only
        ; todo: some error handling

        num_tabs := XL_WB.Worksheets.count()

        loop, %num_tabs%
        {
            Sleep, 300
            tab_counter := A_Index+0
            curr_wsname := XL_WB.Worksheets(tab_counter).Name
            XL_WS := XL_WB.Worksheets(tab_counter)
            StringUpper, curr_wsname, curr_wsname
            DebugAppend("PROCESS file " XL_WB.name " - " curr_wsname ,True,True )
            OutputDebug, % curr_wsname
            if ( SubStr(curr_wsname,1,4) == "SRC_" or SubStr(curr_wsname,1,4) == "SCR_" or SubStr(curr_wsname,1,7) == "SOURCE_"  )
            {
                DebugAppend("LOAD Data from SRC TAB  " XL_WB.name " - " curr_wsname ,True,True )
                DebugAppend("." )
                my_head := ""

                lauf1 := 11
                lauf2 := 9
                lauf3 := 5

                sig1 := ""
                sig2 := ""
                sig3 := ""

                Loop, %lauf1%
                {
                    sig1 .=  Trim(XL_WS.Range("A1").Cells(1+0, A_Index+0).value )
                }
                Loop, %lauf2%
                {
                    sig2 .= Trim( XL_WS.Range("A1").Cells(1+0, A_Index+0).value)
                }
                Loop, %lauf3%
                {
                    sig3 .= Trim( XL_WS.Range("A1").Cells(1+0, A_Index+0).value )
                }
                StringUpper, sig1, sig1
                StringUpper, sig2, sig2
                StringUpper, sig3, sig3

                ;Check now the header
                if( sig1 == std_head_str)
                {
                    my_head := std_head
                    head_flag := 1
                }
                if (sig2 == short_head_str)
                {
                    my_head := short_head
                    head_flag := 2

                }
                if (sig3 == tiny_head_str)
                {
                    my_head := tiny_head
                    head_flag := 3
                }

                if (my_head == "" )
                {
                    ;todo: not a valid strucutre message or log
                    ;exit tab / skipp tab
                    Continue
                } 

                ; do loop through all the rows in the used range and create / fire insert statements
                ; todo: drop table somewhere above
                
                num_rangerows := XL_WS.Range("A1").currentRegion().rows.count() - 1
                curr_region := XL_WS.Range("A1") ; .currentRegion()
                sqliteDBObject.Prepare("BEGIN TRANSACTION", sss)
                sss.Step() 
                Loop, %num_rangerows%
                {
                    Sleep, 5
                    x_searchin :=  StrReplace(curr_region.Cells(1+A_Index,1).value, "'","''")
                    x_fitto := StrReplace(curr_region.Cells(1+A_Index,2).value, "'","''")
                    ; x_fittogroup := StrReplace(curr_region.Cells(1+A_Index,3).value, "'","''")
                    x_h1 := StrReplace(curr_region.Cells(1+A_Index,3).value, "'","''")
                    x_h2 :=  StrReplace(curr_region.Cells(1+A_Index,4).value, "'","''")
                    x_h3 :=  StrReplace(curr_region.Cells(1+A_Index,5).value, "'","''")
                    x_info :=  StrReplace(curr_region.Cells(1+A_Index,6).value, "'","''")
                    x_infohtml :=  StrReplace(curr_region.Cells(1+A_Index,7).value, "'","''")
                    x_output :=  StrReplace(curr_region.Cells(1+A_Index,8).value, "'","''")
                    x_output2 :=  StrReplace(curr_region.Cells(1+A_Index,9).value, "'","''")
                    x_sourcelbl1 := xlsArray[xls_counter]
                    x_sourceLbl2 := curr_wsname
                    x_sourcelbl3 := "row: " A_Index
                    x_sourceType := "XLS"
                    x_showfrom :=  StrReplace(curr_region.Cells(1+A_Index,10).value, "'","''")
                    x_showto := StrReplace(curr_region.Cells(1+A_Index,11).value, "'","''")
                    x_insertlbl := "empty"

                    if(head_flag == 1)
                    {
                        ; everything ok no defaults needed
                    }
                    if(head_flag == 2) 
                    {
                        x_searchin :=  StrReplace(curr_region.Cells(1+A_Index,1).value, "'","''")
                        x_output2 := StrReplace(curr_region.Cells(1+A_Index,7).value, "'","''")
                        x_output := StrReplace(curr_region.Cells(1+A_Index,6).value, "'","''")
                        x_infohtml :=  StrReplace(curr_region.Cells(1+A_Index,5).value, "'","''")
                        x_info := ""
                        x_h3 := StrReplace(curr_region.Cells(1+A_Index,4).value, "'","''")
                        x_h2 := StrReplace(curr_region.Cells(1+A_Index,3).value, "'","''")
                        x_h1 := StrReplace(curr_region.Cells(1+A_Index,2).value, "'","''")
                        x_showfrom :=  StrReplace(curr_region.Cells(1+A_Index,8).value, "'","''")
                        x_showto := StrReplace(curr_region.Cells(1+A_Index,9).value, "'","''")
                    }
                    if(head_flag == 3) 
                    {
                        x_output2 := StrReplace(curr_region.Cells(1+A_Index,4).value, "'","''")
                        x_output := StrReplace(curr_region.Cells(1+A_Index,3).value, "'","''")
                        x_infohtml :=  StrReplace(curr_region.Cells(1+A_Index,2).value, "'","''")
                        x_info := ""
                        x_h1 :=  StrReplace(curr_region.Cells(1+A_Index,1).value, "'","''")
                        x_h2 := ""
                        x_h3 := ""
                        x_fittogroup := ""
                        x_fitto := x_output2 
                        x_searchin := x_output "_" x_output2
                        x_showfrom :=  "1900-01-01"
                        x_showto := StrReplace(curr_region.Cells(1+A_Index,5).value, "'","''")
                    }

                    sql_insert = 
                    (
                        insert into T_KNOWLEDGE VALUES 
                        (
                            '%x_searchin%' ,
                            '%x_fitto%' ,
                            '%x_h1%' ,
                            '%x_h2%' ,
                            '%x_h3%',
                            '%x_info%' ,
                            '%x_infohtml%' ,
                            '%x_output%' ,
                            '%x_output2%' ,
                            '%x_showfrom%' ,
                            '%x_showto%' ,
                            '%x_sourcelbl1%' ,
                            '%x_sourcelbl2%' ,
                            '%x_sourcelbl3%' ,
                            '%x_sourceType%',
                            '%x_insertlbl%'
                        `)

                    )
                    if ( mod(A_index,100)!=0 ) {
                        DebugAppend(".",False)
                    }
                    else
                    {
                        DebugAppend("#" A_Index "#",False)
                        OutputDebug, % sql_insert
                    }

                    sqliteDBObject.Prepare(sql_insert, sss)
                    sss.Step() ; execute + commit         
                }
                sqliteDBObject.Prepare("COMMIT", sss)
                sss.Step() 
            }
            else
            {
                DebugAppend("SKIPP TAB (not a source)  " XL_WB.name " - " curr_wsname ,True,True )
                ;skipp
            }
            DebugAppend("FINISHED TAB, rows processed: " num_rangerows ,True,True)
        }
        DebugAppend("CLOSED WB: " XL_WB.name  ,True,True)
        XL_WB.close(False )
        
    }

    my_sql := "update T_KNOWLEDGE set show_from='1900-01-01' where show_from is null or trim(show_from) ='' "
    sqliteDBObject.Prepare(my_sql, sss)
    sss.Step()
    my_sql := "update T_KNOWLEDGE set show_to='2999-12-31' where show_to is null or trim(show_to) ='' "
    sqliteDBObject.Prepare(my_sql, sss)
    sss.Step()

    my_sql := "delete from T_KNOWLEDGE where trim(h1)='' and trim(h2)='' and trim(h3)=''  and trim(info)='' and trim(info_html)='' and trim(output)='' and trim(output_2)='' "
    sqliteDBObject.Prepare(my_sql, sss)
    sss.Step()

    DebugAppend("T_KNOWLEDGE cleaned." ,True,True)


}


/*
    This function shows an easy popup message.
    PARAM:
        message - Message to be shown in the popup gui
        duration - Time until the message disappears automatically
*/
showPopUp(message, duration) {
    Gui +LastFound +AlwaysOnTop -Caption +Border +E0x08000000 +ToolWindow -SysMenu -Owner +Disabled -DPIScale -Theme
    Gui Color, EEEEEE
    Gui Font, s10, Arial
    Gui Add, Text, x10 y10 w300 h60, %message%
    Gui Show, NA
    Sleep, duration
    Gui Destroy
  }
  


/*
    This function gets the file extension
    PARAM:
        str - path or file name including extension
    RETURN:
        String - The file extension, that means everyting after the last dot in the input string.
*/
getFileExt(str){
    dotPos := RegExMatch(str, "(?<=\.)[^.]*$", dot)
    fileExtension := SubStr(str,dotPos) ;(str, StrLen(str) - dotPos)
    return fileExtension
}



/*
    Not needed
*/
extractToken(lookupString, left_token="##", right_token="##"){
    xpos := RegExMatch(lookupString , left_token . "(.*?)" . right_token, prep_pivot_config)
    prep_pivot_config := Trim(StrReplace(StrReplace(prep_pivot_config,left_token,""),right_token) )
    Return prep_pivot_config
} 


/*
    Registers multiple hotkeys
    PARAM:
        hk_string_semikolon (String)    - a list with hotkeys separated by  ; 
    RETURN:
        nothing
*/
registerHK(hk_string_semikolon, mylbl){
    try{
    if(hk_string_semikolon=="X")
        Return

    hk_arr :=  StrSplit( hk_string_semikolon , ";" )
    Loop % hk_arr.Length()
        Hotkey, % hk_arr[A_Index], %mylbl%

    } catch error
    {
        MsgBox, % "Error in Hotkey definition --> " hk_string_semikolon " <--. `n Some HK might not work!!! Please check ini-file and reload script..." 
    }
    return

}


/*
    Checks if Excel is installed
    RETURNS:
        Boolean - True if a Excel installation was found / false if not
*/
isExcelInstalled()
{
    try
    {
        Excel := ComObjCreate("Excel.Application")
        Excel.Quit()
        return true
    }
    catch
    {
        return false
    }
}