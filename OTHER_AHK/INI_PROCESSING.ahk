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

isInArray(value, array) {
    StringCaseSense, Off
    for index, item in array {
        if (item = value) {
            return true
        }
    }
    return false
}

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







ReadIniToDictionary(iniFilePath, restrictSection:="") {
    ; Erstellt ein neues AutoHotkey-Objekt, welches als Wörterbuch fungiert
    dict := Object()
  
    ; Liest die Sektionen der INI-Datei
    IniRead, sections , %iniFilePath%
  
    ; Loop durch jede Sektion
    Loop, Parse, sections, `n
    {

        ; Liest die Schlüssel und Werte innerhalb der aktuellen Sektion
        IniRead, keys, %iniFilePath% , %A_LoopField%
        currentSection:=A_LoopField
        if (trim(restrictSection)="" or isInArray(currentSection, restrictSection) ){
            ;continue with the code

        }
        Else
        {
            Continue ; break loop and goto next section
        }
        ; Loop durch jeden Schlüssel in der Sektion
        Loop, Parse, keys, `n
        {
  
  
            ; Der aktuelle Schlüssel
            key := A_LoopField
  
            ; Entfernt den Wertteil von 'key', um nur den Schlüsselnamen zu erhalten
            key := RegExReplace(key, "=.*")
  
            ; Benutze IniRead, um den Wert des Schlüssels zu lesen
            IniRead, value, %iniFilePath%, %currentSection%, %key%
  
            ; Fügt den Schlüssel-Wert-Paar zum Wörterbuch hinzu
            dict[key] := value
        }
    }
  
    ; Gibt das Wörterbuch zurück
    return dict
  }
  


  ReadIniToDictionarySec2(iniFilePath, restrictSection:="") {

    ; Erstellt ein neues AutoHotkey-Objekt, welches als Wörterbuch fungiert
    dict := Object()
    if (restrictSection = "" and !IsObject(restrictSection)) {
        restrictSection := []
    } else if (!IsObject(restrictSection) and restrictSection != "" ){
        restrictSection := [restrictSection]
    }
    
    ; Liest die Sektionen der INI-Datei
    IniRead, sections , %iniFilePath%
  
    ; Loop durch jede Sektion
    Loop, Parse, sections, `n
    {
        ; Liest die Schlüssel und Werte innerhalb der aktuellen Sektion
        IniRead, keys, %iniFilePath% , %A_LoopField%
        currentSection:=A_LoopField
        testme := isInArray(currentSection, restrictSection) 
        testme0 := !IsObject(restrictSection) 
        if !IsObject(restrictSection) or (varT) or isInArray(currentSection, restrictSection) {
            ;continue with the code
        }
        Else
        {
            Continue ; break loop and goto next section
        }
        ; Loop durch jeden Schlüssel in der Sektion
        Loop, Parse, keys, `n
        {
            ; Der aktuelle Schlüssel
            key := A_LoopField
  
            ; Entfernt den Wertteil von 'key', um nur den Schlüsselnamen zu erhalten
            key := RegExReplace(key, "=.*")
  
            ; Benutze IniRead, um den Wert des Schlüssels zu lesen
            IniRead, value, %iniFilePath%, %currentSection%, %key%
            
            key2:= currentSection . "###" . key 
            ; Fügt den Schlüssel-Wert-Paar zum Wörterbuch hinzu
            dict[key2] := [value, currentSection, key]
        }
    }
  
    ; Gibt das Wörterbuch zurück
    return dict
  }



