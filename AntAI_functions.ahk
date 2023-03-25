#NoEnv

#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%



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



buildFromSQLITE(sqliteDBObject, sqliteArray, lblArray, deleteOldData=False )
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
        OutputDebug, % xlsArray[sqlite_counter]
        DebugAppend("")
        DebugAppend("")
        DebugAppend("START processing file " A_Index ": " sqliteArray[sqlite_counter] ,True,True)

        curr_sqlitefile := sqliteArray[sqlite_counter]
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

    DebugAppend("FINISHED processing SQLITE-files: #" sqliteArray[sqlite_counter] ,True,True)

}


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
        curr_csvfile := StrReplace(curr_csvfile, "\" , "\\" )
        OutputDebug, %loc_sqliteToolPath% %db_path% ".mode csv" ".import -skip 1 %curr_csvfile% T_KNOWLEDGE"
        RunWait, %loc_sqliteToolPath% %db_path% ".mode csv" ".import %curr_csvfile% T_KNOWLEDGE", ,  ;hide 
        ;Run, %loc_sqliteToolPath% %db_path% "update T_KNOWLEDGE set src_lbl1='curr_csvfile', src_lbl2='FILE', src_lbl3='n/a', src_info='CSV', _insertLBL='csv_updated' where src_info is NULL", ,
        my_sql := """update T_KNOWLEDGE set src_lbl1='" curr_csvfile_bak "', src_lbl2='FILE', src_lbl3='n/a', src_info='CSV', _insertLBL='csv_updated' where src_info is NULL"""
        OutputDebug, %loc_sqliteToolPath% %db_path%  %my_sql%
        RunWait, %loc_sqliteToolPath% %db_path%  %my_sql%
        DebugAppend("END processing CSV file " A_Index ": " loc_arrayPathCSV[csv_counter] ,True,True)

        ;W:\RWE-Trading\MFC\PC_CAO_POWER\MFC_PH\Other\2001_TK\100_Infosrc\DBSRC_PSP.db3
        ;W:\RWE-Trading\MFC\PC_CAO_POWER\MFC_PH\Other\2001_TK\100_Infosrc\T_KNOWLEDGE_PSP.csv
        ;sqlite3 -header -csv mydb.db "SELECT * FROM mytable" > myfile.csv
        ;sqlite3 mydb.db -header -csv "SELECT * FROM mytable" > myfile.csv
    }

    my_sql := "update T_KNOWLEDGE set show_from='1900-01-01' where show_from is null or trim(show_from) ='' "
    sqliteDBObject.Prepare(my_sql, sss)
    sss.Step()
    my_sql := "update T_KNOWLEDGE set show_to='2999-12-31' where show_to is null or trim(show_to) ='' "
    sqliteDBObject.Prepare(my_sql, sss)
    sss.Step()

}

buildFromXLS(sqliteDBObject, xlsArray, deleteOldData=True )
{
    ; todo: progress bar and logging and user feedback in the calling method
    ; do plausi-checks fo xlsArray and lblArray
    ; check if db is open !

    DebugAppend("Start Rebuilding Knowledge Database from files.",True,True)
    if(deleteOldData==True) {
        DebugAppend("START: Drop old Tables.", True,True)
        my_sql := "drop table if exists T_KNOWLEDGE"
        my_sql2 := "CREATE TABLE T_KNOWLEDGE( ""search_in"" TEXT,""fit_to"" TEXT,""H1"" TEXT,""H2"" TEXT,""H3"" TEXT,""INFO"" TEXT,""INFO_HTML"" TEXT,""OUTPUT"" TEXT,""OUTPUT_2"" TEXT, ""SHOW_FROM"" TEXT, ""SHOW_TO"", ""SRC_LBL1"" TEXT,""SRC_LBL2"" TEXT,""SRC_LBL3"" TEXT,""SRC_INFO"" TEXT, ""_insertLBL"" TEXT)"
       sqliteDBObject.Prepare(my_sql, sss)
        sss.Step()
        sqliteDBObject.Prepare(my_sql2, sss)
        sss.Step()
        ;sqliteDBObject.Prepare(my_sql3, sss)
        ;sss.Step()
        ;sqliteDBObject.Prepare(my_sql4, sss)
        ;sss.Step()
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
        xls_counter := A_Index+0
        OutputDebug, % xlsArray[xls_counter]
        DebugAppend("")
        DebugAppend("")
        DebugAppend("START file " A_Index ": " xlsArray[xls_counter] ,True,True)
        XL_WB := XL.Workbooks.Open(xlsArray[xls_counter],False,True) ; no link update + read only
        ; todo: some error handling

        num_tabs := XL_WB.Worksheets.count()

        loop, %num_tabs%
        {
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
        XL_WB.close(False)
        
    }

    my_sql := "update T_KNOWLEDGE set show_from='1900-01-01' where show_from is null or trim(show_from) ='' "
    sqliteDBObject.Prepare(my_sql, sss)
    sss.Step()
    my_sql := "update T_KNOWLEDGE set show_to='2999-12-31' where show_to is null or trim(show_to) ='' "
    sqliteDBObject.Prepare(my_sql, sss)
    sss.Step()

}


