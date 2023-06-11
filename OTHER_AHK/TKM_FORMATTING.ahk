



/*
    Here are some functions that are responsible to formatt matrix arrays (e.g. into a nice html table)
    formatTable_html is used in the main script in order to create a valid html table that is then used
    in the html output file.

    All functions in this file target to serve the main script and are not designed/developped for general usage.
    Author: Thomas Klöckl https://github.com/THEKAEL
*/








#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%




Replicate( Str, Count ) { ; By SKAN / CD: 01-July-2017 | goo.gl/U84K7J
Return StrReplace( Format( "{:0" Count "}", "" ), 0, Str )
}


/*
   Creates a non-html ascii based table based on the given input table object
   PARAM: 
      oTbl  (Class_SQLiteDB.tk_getTableNoHeader() )   - Table object returned by tk_getTableNoHeader()
*/
formatTable(oTbl, my_title="", with_cap=100, rd="`n", cd="`t",emptyRowGap=2) {
;;dev

    Query_Statement := ""
	mysize := []
	Loop % oTbl.MaxIndex()
	{
		oRow := oTbl[ A_Index ]
		first_run := true
		Loop % oRow.MaxIndex() {
			if(first_run == true) {
				mysize[A_Index] = 0
				first_run := false
			}
            oRow[ A_Index ] := StrReplace(StrReplace(oRow[ A_Index ],"`n","" ),"`r","") 
				oRow[ A_Index ] := (StrLen(oRow[ A_Index ]) > with_cap-1 )? substr(oRow[ A_Index ]  ,1,with_cap) . ".." : oRow[ A_Index ]  
            mysize[A_Index] := ( mysize[A_Index] <= StrLen(oRow[ A_Index ] ) ? StrLen(oRow[ A_Index ]) : mysize[A_Index]  )
		}
	}

	Loop % oTbl.MaxIndex()
	{
		oRow := oTbl[ A_Index ]
		Loop % oRow.MaxIndex() {
                
				Query_Statement .= ( A_Index = 1 ? rd : cd ) oRow[ A_Index ]  Replicate(" ", Min(with_cap,mysize[A_Index]-StrLen(oRow[A_Index]  )+1 ))

		}
	}

    
	Query_Statement := SubStr( Query_Statement,  1+StrLen( rd ) )

    return_value :=  my_title . Replicate(rd,emptyRowGap) . Query_Statement

return return_value
}



/*
   Based on a given table object a html table is created.
   PARAM: 
      oTbl  (Class_SQLiteDB.tk_getTableNoHeader() )   - Table object returned by tk_getTableNoHeader()
*/

formatTable_html(oTbl, my_title="", table_frame = False, last_group_col = 3, row_limit=100, noDiv = True) {
;;dev

   if(table_frame == True) {
      output_html := "<table> "
   }

   num_rows := min(row_limit,oTbl.MaxIndex()+0) ; limit the output to row_limit to avoid memory errors or other bad things
   first_row := true
	Loop % num_rows
	{
      output_html .= "<TR>`n"
		oRow := oTbl[ A_Index ]
      rIdx := A_Index
      if( first_row== False){
         prevRow := oTbl[A_Index - 1]
      }

		Loop % oRow.MaxIndex() {
         cIdx := A_Index
			if(first_row == true and table_frame == True ) {
				output_html .= "<TH class='base tblcol_" cIdx "' >" RegExReplace(oRow[ A_Index ], "`n" ,  "<BR>") "</TH>"
			}
         else {
            if(first_row == True) {
               output_html .= "<TD class='base tblcol_" cIdx "'  onclick=""CopyToClipboard('tbl_" rIdx "_" cIdx "');return false;"" > " ((noDiv)? " " : "<div class='alldata_" cIdx "' id='tbl_" rIdx "_" cIdx "'>") RegExReplace(oRow[ A_Index ], "`n" ,  "<BR>")  ( (noDiv)? " " : "</DIV> " ) " </TD>"
            }
            else {
               output_html .= (prevRow[ A_Index ] == oRow[ A_Index] and A_Index <= last_group_col ) ? "<TD class='base' > <font class='lessvisible'> " RegExReplace(oRow[ A_Index ], "`n" ,  "<BR>") " </font></TD> " : "<TD class='base tblcol_" cIdx "' onclick=""CopyToClipboard('tbl_" rIdx "_" cIdx "');return false;"" > " ((noDiv) ? " " : " <div class='alldata_" cIdx "' id='tbl_" rIdx "_" cIdx "'>" ) RegExReplace(oRow[ A_Index ], "`n" ,  "<BR>") ((noDiv)? "  " : "</DIV>" ) "</TD>"
            }
         }
		}
      output_html .= "</TR>`n"
      first_row := False
	}
    
    if(table_frame == true){
      return_value :=  "<H1>"  my_title  "</H1> <br> "  output_html
    }
    else {
       return_value := output_html
    }

return return_value
}

getOptionTags(xTbl, sep= " - " ){
   num_rows := min(200,xTbl.MaxIndex()+0) 
   output_opt := ""
	Loop % num_rows
	{
      xRow := xTbl[ A_Index ]
      xtemp:=""
      Loop % xRow.MaxIndex() {
         ;OutputDebug, % temp
         ;OutputDebug, % sep
         ;OutputDebug % xRow[ A_Index ]
         xtemp := xtemp sep xRow[ A_Index ]
      }
      output_opt:= output_opt "<option value='" xtemp "'>" xtemp "</option> "
   }
   return output_opt
}





/*
   Some GUI taken from AHK forum
*/

MsgBoxGui(Title, Text, Timeout:=0) {
	Gui CustomMSG:Destroy
   global TextBox                       ; This variable can be used to update the text in the MsgBoxGui
   static WhiteBox
   
   static Gap          := 6            ; Spacing above and below text in top area of the Gui
   static LeftMargin   := 12            ; Left Gui margin
   static RightMargin  := 8             ; Space between right side of button and right Gui edge
   static ButtonWidth  := 88            ; Width of OK button
   static ButtonHeight := 26            ; Height of OK button
   static ButtonOffset := 30            ; Offset between the right side of text and right edge of button
   static MinGuiWidth  := 138           ; Minimum width of Gui
 
   BottomGap := LeftMargin                      ; Set the distance between the bottom of the white box and the top of the OK button
   BottomHeight := ButtonHeight+2*BottomGap+3   ; Calculate the height of the bottom section of the Gui
   if !GetMsgBoxFontInfo(FontName,FontSize,FontWeight,IsFontItalic)             ; Get the MsgBox font information
      Return false                                                              ; If there is a problem getting the font information, return false
   GuiOptions := "s" FontSize " w" FontWeight (IsFontItalic ? " italic" : "")   ; Define a string with the Gui options
   Gui, CustomMSG:New, +HwndCustomMSGXHwnd
   Gui, CustomMSG:Font, %GuiOptions%, Courier New ;Consolas ;%FontName%                                          ; Set the font options and name
   Gui, CustomMSG:+LastFound +ToolWindow -MinimizeBox -MaximizeBox                        ; Set the Gui so it doesn't have an icon or the minimize and maximize buttons
   if Text                                                                      ; If the text field is not blank ...
   {  
      Gui, CustomMSG:Add, Edit, x%LeftMargin% y%Gap% ReadOnly BackgroundTrans vTextBox, %Text%  
      GuiControlGet, Size, Pos, TextBox                                         ; Get the position of the text box
      GuiWidth := LeftMargin+SizeW+ButtonOffset+RightMargin+1                   ; Calculate the Gui width
      GuiWidth := GuiWidth < MinGuiWidth ? MinGuiWidth : GuiWidth               ; Make sure that it's not smaller than MinGuiWidth
      WhiteBoxHeight := SizeY+SizeH+Gap                                         ; Calculate the height of the white box
   }
   else                                                                         ; If the text field is blank ...
   {  GuiWidth := MinGuiWidth                                                   ; Set the width of the Gui to MinGuiWidth
      WhiteBoxHeight := 2*Gap+1                                                 ; Set the height of the white box
      BottomGap++                                                               ; Increase the gap above the button by one
      BottomHeight--                                                            ; Decrease the height of the bottom section of the Gui
   }
  ButtonX := GuiWidth-RightMargin-ButtonWidth                 ; Calculate the horizontal position of the button
   ButtonY := WhiteBoxHeight+BottomGap                         ; Calculate the vertical position of the button
   Gui,CustomMSG:Add, Button, gButtonOK x%ButtonX% y%ButtonY% w%ButtonWidth% h%ButtonHeight% Default, OK   ; Add the OK button
   GuiControl, +ReadOnly, TextBox 
   GuiHeight := WhiteBoxHeight+BottomHeight                    ; Calculate the overall height of the Gui
   Gui, CustomMSG:Show, w%GuiWidth% h%GuiHeight%, %Title%                ; Show the Gui
   Gui, CustomMSG:-ToolWindow                                            ; Remove the ToolWindow option so that the Gui has rounded corners and no icon
   GuiControl, Focus, OK                                       ; Sets keyboard focus to the OK button
                                                          ; Trick from http://ahkscript.org/boards/viewtopic.php?p=11519#p11519
   if Timeout                                                  ; If the Timeout parameter has been specified ...
      SetTimer, GuiClose, % -Timeout*1000                      ; Start a timer to destroy the MsgBoxGui after Timeout seconds
   Return true

   ButtonOK:
   GuiClose:
   GuiEscape:
   Gui CustomMSG:Destroy
   Return

 
}

/*



MsgBoxGui(Title, Text, Timeout:=0) {
	Gui Destroy
   global TextBox                       ; This variable can be used to update the text in the MsgBoxGui
   static WhiteBox
   
   static Gap          := 6            ; Spacing above and below text in top area of the Gui
   static LeftMargin   := 12            ; Left Gui margin
   static RightMargin  := 8             ; Space between right side of button and right Gui edge
   static ButtonWidth  := 88            ; Width of OK button
   static ButtonHeight := 26            ; Height of OK button
   static ButtonOffset := 30            ; Offset between the right side of text and right edge of button
   static MinGuiWidth  := 138           ; Minimum width of Gui
 
   BottomGap := LeftMargin                      ; Set the distance between the bottom of the white box and the top of the OK button
   BottomHeight := ButtonHeight+2*BottomGap+3   ; Calculate the height of the bottom section of the Gui
   if !GetMsgBoxFontInfo(FontName,FontSize,FontWeight,IsFontItalic)             ; Get the MsgBox font information
      Return false                                                              ; If there is a problem getting the font information, return false
   GuiOptions := "s" FontSize " w" FontWeight (IsFontItalic ? " italic" : "")   ; Define a string with the Gui options
   Gui, New, +HwndCustomMSGXHwnd
   Gui, Font, %GuiOptions%, Courier New ;Consolas ;%FontName%                                          ; Set the font options and name
   Gui, +LastFound +ToolWindow -MinimizeBox -MaximizeBox                        ; Set the Gui so it doesn't have an icon or the minimize and maximize buttons
   if Text                                                                      ; If the text field is not blank ...
   {  
      Gui, Add, Edit, x%LeftMargin% y%Gap% ReadOnly BackgroundTrans vTextBox, %Text%  
      GuiControlGet, Size, Pos, TextBox                                         ; Get the position of the text box
      GuiWidth := LeftMargin+SizeW+ButtonOffset+RightMargin+1                   ; Calculate the Gui width
      GuiWidth := GuiWidth < MinGuiWidth ? MinGuiWidth : GuiWidth               ; Make sure that it's not smaller than MinGuiWidth
      WhiteBoxHeight := SizeY+SizeH+Gap                                         ; Calculate the height of the white box
   }
   else                                                                         ; If the text field is blank ...
   {  GuiWidth := MinGuiWidth                                                   ; Set the width of the Gui to MinGuiWidth
      WhiteBoxHeight := 2*Gap+1                                                 ; Set the height of the white box
      BottomGap++                                                               ; Increase the gap above the button by one
      BottomHeight--                                                            ; Decrease the height of the bottom section of the Gui
   }
  ButtonX := GuiWidth-RightMargin-ButtonWidth                 ; Calculate the horizontal position of the button
   ButtonY := WhiteBoxHeight+BottomGap                         ; Calculate the vertical position of the button
   Gui,Add, Button, gButtonOK x%ButtonX% y%ButtonY% w%ButtonWidth% h%ButtonHeight% Default, OK   ; Add the OK button
   GuiControl, +ReadOnly, TextBox 
   GuiHeight := WhiteBoxHeight+BottomHeight                    ; Calculate the overall height of the Gui
   Gui, Show, w%GuiWidth% h%GuiHeight%, %Title%                ; Show the Gui
   Gui, -ToolWindow                                            ; Remove the ToolWindow option so that the Gui has rounded corners and no icon
   GuiControl, Focus, OK                                       ; Sets keyboard focus to the OK button
                                                          ; Trick from http://ahkscript.org/boards/viewtopic.php?p=11519#p11519
   if Timeout                                                  ; If the Timeout parameter has been specified ...
      SetTimer, GuiClose, % -Timeout*1000                      ; Start a timer to destroy the MsgBoxGui after Timeout seconds
   Return true

   ButtonOK:
GuiClose:
GuiEscape:
Gui Destroy
Return

 
}

*/

; Reference: http://ahkscript.org/boards/viewtopic.php?f=6&t=9122

GetMsgBoxFontInfo(ByRef Name:="", ByRef Size:=0, ByRef Weight:=0, ByRef IsItalic:=0) {
   ; SystemParametersInfo constant for retrieving the metrics associated with the nonclient area of nonminimized windows
   static SPI_GETNONCLIENTMETRICS := 0x0029
   
   static NCM_Size        := 40 + 5*(A_IsUnicode ? 92 : 60)   ; Size of NONCLIENTMETRICS structure (not including iPaddedBorderWidth)
   static MsgFont_Offset  := 40 + 4*(A_IsUnicode ? 92 : 60)   ; Offset for lfMessageFont in NONCLIENTMETRICS structure
   static Size_Offset     := 0    ; Offset for cbSize in NONCLIENTMETRICS structure
   
   static Height_Offset   := 0    ; Offset for lfHeight in LOGFONT structure
   static Weight_Offset   := 16   ; Offset for lfWeight in LOGFONT structure
   static Italic_Offset   := 20   ; Offset for lfItalic in LOGFONT structure
   static FaceName_Offset := 28   ; Offset for lfFaceName in LOGFONT structure
   static FACESIZE        := 32   ; Size of lfFaceName array in LOGFONT structure
                                  ; Maximum number of characters in font name string
   
   VarSetCapacity(NCM, NCM_Size, 0)              ; Set the size of the NCM structure and initialize it
   NumPut(NCM_Size, &NCM, Size_Offset, "UInt")   ; Set the cbSize element of the NCM structure
   ; Get the system parameters and store them in the NONCLIENTMETRICS structure (NCM)
   if !DllCall("SystemParametersInfo"            ; If the SystemParametersInfo function returns a NULL value ...
             , "UInt", SPI_GETNONCLIENTMETRICS
             , "UInt", NCM_Size
             , "Ptr", &NCM
             , "UInt", 0)                        ; Don't update the user profile
      Return false                               ; Return false
   Name   := StrGet(&NCM + MsgFont_Offset + FaceName_Offset, FACESIZE)          ; Get the font name
   Height := NumGet(&NCM + MsgFont_Offset + Height_Offset, "Int")               ; Get the font height
   Size   := DllCall("MulDiv", "Int", -Height, "Int", 72, "Int", A_ScreenDPI)   ; Convert the font height to the font size in points
   ; Reference: http://stackoverflow.com/questions/2944149/converting-logfont-height-to-font-size-in-points
   Weight   := NumGet(&NCM + MsgFont_Offset + Weight_Offset, "Int")             ; Get the font weight (400 is normal and 700 is bold)
   IsItalic := NumGet(&NCM + MsgFont_Offset + Italic_Offset, "UChar")           ; Get the italic state of the font
   Return true
}



cleanAscii160(dirty_string){
	return StrReplace(dirty_string, Chr(160), Chr(32))
}