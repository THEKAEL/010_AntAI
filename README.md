# Current Status
- The Tool is usable.
- I will focus on an updated and imroved documentation
- I am currently fixing bugs and implement some missing features
- Check this side frequently in order to have the latest version downloaded.
- I consider the database structure and the datasource structure as fixed (csv, xls and sqlite files). Hence these will be compatible with future versions!
  

# 010_AntAI

__Thias is the first Version of my Knowledge Database AntAI based on AHK__

AntAi is a knowledge database. The database is shipped empty with some examples and needs to be filled and maintained by the users. 
By using a hotkey or simple gui, the user can trigger AutoHotkey (AHK) scripts that search for 
a phrase in the database and display it in the browser via an HTML file.

## Documentation
There is a wiki available for the AntAi Tool:
https://github.com/THEKAEL/010_AntAI/wiki

Usually the current documentation/wiki does not refere to the latest features.

## Project
This is a part time one man project. I do this during my free time in the evening and use it in real world 
to support my daily tasks in financial controlling. 

## Use cases
As I mentioned I use it for various things. I organize data in Excel or CSV files and make them available to the AntAI-Tool.
Here some real work examples:
  - Memos
  - Process Description (daily, monthly, quarterly tasks)
  - Favourites: Network Path, Weblinks...
  - Interesting Information form ChatGPT or Google
  - Mappings (e.g. Portfolio_ID vs Portfolio_Name)

Some ohter use cases:
  - Reminders
  - Mappings like
    - Postal Code
    - Customer basis data
    - SAP account numbers vs account name
  - Hints on a specific topic
  - Birthday Lists

## Security
 - The tool does not need any internet connection
 - As long as you provide/prepare the data on your own you have control over the output
 - The code is open. Please check on your own!
 - In case you include data sources from other people (collegues, internet friends...) there is the following problem:
   - The data are displayed on a local html file. This means that the information provider could inject harmfull HTML/Javascript/... code since the information can be html code.
   - As long as you use and maintain your own data ther is no HTML incection issue IMO.
 - Check the information sources (Excel-Sheets, CSV, SQLite Databases) from external sources for harmfull html content.

   If you have an additional remarks on security please mention them in the issue section.

   

