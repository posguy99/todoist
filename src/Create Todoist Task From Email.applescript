#!/usr/bin/osascript
(*
	Create Todoist Task From Email
	Copyright (c) 2014, Marc Wilson (posguy99@gmail.com)
	All rights reserved.
	
	Redistribution and use in source and binary forms, with or without
	modification, are permitted provided that the following conditions are met:

	1. Redistributions of source code must retain the above copyright notice, this
	   list of conditions and the following disclaimer. 
	2. Redistributions in binary form must reproduce the above copyright notice,
	   this list of conditions and the following disclaimer in the documentation
	   and/or other materials provided with the distribution.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
	ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
	WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
	DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
	ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
	(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
	LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
	ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
	(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
	SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

	Originally based on https://github.com/joehooper/todoist-outlook-2011
	(license unknown)

	Encode and decode cribbed from http://www.macosxautomation.com/applescript/sbrt/sbrt-08.html
	Write to a file cribbed from http://www.macosxautomation.com/applescript/sbrt/sbrt-09.html
	List manipulation cribbed from http://www.macosxautomation.com/applescript/sbrt/sbrt-07.html
	(license unknown but assumed to be public domain)
	
	JSON Helper can be found at http://itunes.apple.com/app/json-helper-for-applescript/id453114608?mt=12
	
	Todoist API documentation is at http://todoist.com/API
	
	Notes:
		
	If you use conversations, it will add all messages from the conversation
	as individual tasks unless you explicitly open only one message.
		
	Eventually what I want to do for conversations is have one task created, and the other email(s) be sub-tasks
	under it.

	I crib (copy, steal) shamelessly from other people, which makes the coding style look very... odd.  I'll fix it,
	eventually.
		
	Version history:
		
		0.1 - initial creation (msw 113014)
		0.2 - create token file if not found (msw 113014)
		0.3 - display notification (msw 113014)
		0.4 - save result of API call (msw 120714)
			 add message URL to task title (msw 120714)
			 add message content as a note (msw 120714)
		0.5 - much re-factoring to make easier to understand (msw 120714)
			 added weak dependency on JSON Helper (annoying!) (msw 120714)
			 writes a log file (msw 120714)
			 better error checking (msw 120714)
		0.6 - offer to create a project for email(s) if multiple selected (msw 120714)
			 still more error checking (msw 120714)
			 friendlier dialogs (msw 120714)
		0.7 - Retrieve list of projects to choose from (msw 120814)
			 fix really stupid bug that broke single add in v6 (msw 120814)
			 fix more really stupid logic errors (msw 120814)
		0.8 - enforce JSON Helper Dependency (msw 121414)
			 enforce OS X 10.8 dependency (msw 121414)
			 remove log file write as it is insecure (exposes API token) (msw 121414)
			 add first-run dialog and prompt for API token (msw 121414)
		0.9 - fixed replace_chars() to save/restore the tid's (msw 122814)
			 use OS X defaults system (msw 122814)
			 remove token dot-file if present (msw 122814)
			 keep API token in defaults rather than in a dot-file (msw 122814)
			 removed priority from email in favor of settable default (msw 122814)
			 add control for changing the default due date (msw 122814)
			 add control for whether to add the message URL (msw 122814)
			 add control for whether to add the envelope icon (msw 122814)
			 add control for adding the message body as a note (msw 122814)
			 add control for setting the priority (msw 122814)
			 fixed ordering of first run test (msw 010415)
			 enforce dep on 10.9 for 'display notification' (msw 010415)
		0.10 - fix missing JSHONHelperURL (msw via matthew caine 010915)
		0.11 - fix problem caused by non-English localization of OS X
			   (msw via Karin Rosner and Diego Rosafio 022215)
		0.12 - fix missing variable from v11 fix (msw 022115)

NOTE:  The v11 fix is *not* localization.  It corrects the script assuning buttons are labeled in
English when AS is allowed to use default bvutton titles.


	Defauts:			 
			 todoistCreateTaskRunOnce : boolean
			 (whether or not to display the first run dialog, will be created)
			 
			 todoistCreateTaskAPIToken : string (no default, user defined, no error checking)
			 (this one will be created by the script if it does not exist)
			 
			 todoistCreateTaskDueDate : string (default today)
			 todoistCreateTaskAddURL : boolean (default false)
			 todoistCreateTaskAddIcon : boolean (default false)
			 todoistCreateTaskAddBodyAsNote : boolean (default true)
			 todoistCreateTaskPriority : string (default "0")

iMac $ defaults read me.mwilson.scripts
{
    todoistCreateTaskAPIToken = anexampletokenwouldbehere;
    todoistCreateTaskAddBodyAsNote = 1;
    todoistCreateTaskAddIcon = 0;
    todoistCreateTaskAddURL = 1;
    todoistCreateTaskDueDate = tomorrow;
    todoistCreateTaskFirstRun = 1;
    todoistCreateTaskPriority = 1;
}

*)

property theAppDomain : "me.mwilson.scripts"

global theAppName
global theAppVersion
global addBodyAsNote

-- set some variables

set theAppVersion to "10"
set theAppName to "Create Todoist Task From Email v" & theAppVersion
set JSONHelperURL to "http://itunes.apple.com/app/json-helper-for-applescript/id453114608?mt=12"

-- the envelope character is nice to include, set it in app defaults to turn it on

set theIcon to («data utxt2709» as Unicode text) & " "

-- clean ups
-- we do not return if either were true

my clean_up_log_file()
my clean_up_token_file()

-- check for first run

if (my readDefaultsBoolean(theAppDomain, "todoistCreateTaskFirstRun")) is null then
	my display_first_run()
	my writeDefaultsBoolean(theAppDomain, "todoistCreateTaskFirstRun", "TRUE")
end if

-- test OS version

set _os_version to (second text item of my get_os_version()) as number
if (_os_version < 9) then
	my dialog_error("OS X 10.9 or later (Mavericks) is required." & return & "Please upgrade your OS to use this script.")
end if

-- test for JSON Helper

try
	tell application "Finder" to get application file id "com.vidblishen.jsonhelper"
	set JSONHelperExists to true
on error
	set JSONHelperExists to false
	my dialog_error("JSON Helper is required.  You may install it from" & return & JSONHelperURL)
end try

-- ok, we got here, so OS is at least ML, and JSON Helper is available

-- get the API token

set theToken to my readDefaultsString(theAppDomain, "todoistCreateTaskAPIToken")
if theToken is null then
	set _result to (display dialog "Missing Todoist API token.  Please enter your API token below." buttons {"Ok", "Cancel"} default answer "" default button "Cancel" with icon caution)
	if the button returned of the _result is "Cancel" then
		error number -128
	end if
	set theToken to the text returned of the _result
	my writeDefaultsString(theAppDomain, "todoistCreateTaskAPIToken", theToken)
end if

-- got here, so we have a valid token and all the dependencies are available

-- Are we adding the message URL to the task?
-- the default is no

set addURL to false
set _temp to my readDefaultsBoolean(theAppDomain, "todoistCreateTaskAddURL")
if _temp is not null then
	set addURL to _temp
end if

-- are we adding the icon?
-- the default is no

set addIcon to false
set _temp to my readDefaultsBoolean(theAppDomain, "todoistCreateTaskAddIcon")
if _temp is not null then
	set addIcon to _temp
end if

-- are we adding the body?
-- the default is true

set addBodyAsNote to true
set _temp to my readDefaultsBoolean(theAppDomain, "todoistCreateTaskAddBodyAsNote")
if _temp is not null then
	set addBodyAsNote to _temp
end if

-- get the due date
-- the default is today

set theDate to my readDefaultsString(theAppDomain, "todoistCreateTaskDueDate")
if theDate is null then
	set theDate to "today"
end if

-- get the priority to set
-- the default is 1

set thePriority to my readDefaultsString(theAppDomain, "todoistCreateTaskPriority")
if thePriority is null then
	set thePriority to "1"
end if

-- main loop

tell application "Mail"
	
	-- get the currently selected message or messages
	
	set selectedMessages to selection
	
	-- if there are no messages selected, warn the user and then quit
	
	if selectedMessages is {} then
		my dialog_Info("Please select a message first.")
		return
	end if
	
	-- start out with an empty projectID, which is equivalent to the Inbox
	set theProject to ""
	set _createProject to null
	
	-- _createProject will end up either being null, or the name of the Project to create
	-- JSON Helper is necessary to parse the return from the project creation to get the project_id
	
	if (count of selectedMessages) > 1 then
		set theProjectList to my Todoist_GetAllProjects(theToken)
		set _createProject to (my dialog_Question("There are " & (count of selectedMessages) & " email messages selected." & return & "Do you want to create a Project for them?" & return & return & "Specify the Project name below."))
	end if
	
	if (count of selectedMessages) > 1 then
		-- do we want to add to an existing proect?
		if (_createProject is null) then
			set _projectList to my Todoist_GetAllProjects(theToken)
			set _projectNameList to {}
			repeat with _project in _projectList
				set _projectNameList to _projectNameList & {|name| in _project}
			end repeat
			set _choice to (choose from list _projectNameList with title "Choose A Project!" with prompt "Do you want to add to an existing Project?" & return & return & "Please choose from the list." OK button name "Yes" cancel button name "No")
			if (_choice is not false) then
				-- ok, _choice is the item returned from the list
				-- need to get its index so we can determine the project id
				-- the API allows duplicate project names so this will only find the first instance
				set _index to my list_position(_choice, _projectNameList)
				set theProject to (|id| of item _index of _projectList)
			end if
		end if
		-- fixme: a project name of just spaces?  that would be... bad.  I think.
		if _createProject is not null then
			set theProject to my Todoist_AddProject(theToken, _createProject)
		else
			set theProject to ""
		end if
	end if
	
	-- ok, we now either have a project_id that will be used with Todoist_AddItem()
	-- or it's null
	
	repeat with theMessage in selectedMessages
		
		-- get the information from this message, and store it in variables
		set theURL to ""
		if addURL then
			set theURL to "message://<" & theMessage's message id & ">"
		end if
		
		set theName to the subject of theMessage
		
		set theNote to ""
		if addBodyAsNote then
			set theNote to content of theMessage as rich text
		end if
		
		-- pull the human-readable name out of the sender string
		
		set theSender to (extract name from sender of theMessage)
		
		-- build the task title
		
		if addIcon then
			set theContent to theIcon & theName & " from " & theSender & " " & theURL
		else
			set theContent to theName & " from " & theSender & " " & theURL
		end if
		
		-- create a new task with the information from the message
		
		set theReturn to my Todoist_AddItem(theToken, theContent, thePriority, theDate, theNote, theProject)
		
		-- we can do something nifty with theReturn later, maybe
		
	end repeat
	
	-- display notification to the user
	
	if (count of selectedMessages) > 1 then
		set _notification to ((count of selectedMessages) as string) & " tasks were added."
	else
		set _notification to ((count of selectedMessages) as string) & " task was added."
	end if
	if _createProject is not null then
		set _notification to ("1 project was created." & return & _notification)
	end if
	
	display notification _notification with title "Todoist"
	delay 1
	
end tell

-- call the Todoist API to add an item
-- return a JSON from the API
-- does not return if unsuccessful which is probably a bad idea...

on Todoist_AddItem(_token, _content, _priority, _date, _note, _project)
	
	-- fixme: this produces semi-garbage for MS-Exchange messages due to conditionals in RTF formatting
	-- fixme: it's readable for stuff from work, but...
	
	if addBodyAsNote then
		set _encodedNote to encode_text(_note, true, true)
		set _postToAPI to "curl -X POST -d 'content=" & _content & "' -d 'token=" & _token & "'  -d 'project_id=" & _project & "' -d 'priority=" & _priority & "' -d 'date_string=" & _date & "' -d 'note=" & _encodedNote & "' https://todoist.com/API/additem | sed 's/^.\\(.*\\).$/\\1/' "
	else
		set _postToAPI to "curl -X POST -d 'content=" & _content & "' -d 'token=" & _token & "'  -d 'project_id=" & _project & "' -d 'priority=" & _priority & "' -d 'date_string=" & _date & "' https://todoist.com/API/additem | sed 's/^.\\(.*\\).$/\\1/' "
	end if
	
	-- curl will encode the data in the POST according to MIME-type application/x-www-form-urlencoded so
	-- all the escapes will be done for us
	
	try
		-- fixme: I would really like to get JSON Helper to work here, but it always garbages the task title (the content field), even
		-- fixme: when the note field ends up correctly formatted.  Every on-line example I can find for using it is exactly the same.
		-- fixme:  meanwhile, curl works...
		
		set _temp to do shell script _postToAPI
		
	on error
		-- curl returned a non-zero result, must be bad!
		my dialog_error("Non-zero error return from Todoist API call!")
	end try
	
	if _temp is null then
		my dialog_error("Null response from Todoist API call!")
	end if
	
	set _return to _temp
	
	-- save return from API call if it was non NULL
	-- return an AppleScript property list with the decoded JSON response
	
	-- fixme: aren't we clipping off the braces above and putting them back below so JSON Helper can decode?  silly...
	
	try
		tell application "JSON Helper"
			set _return to read JSON from "{" & _temp & "}"
		end tell
	on error
		my dialog_error("JSON Helper unable to parse result from API call!")
	end try
	
	return _return
	
end Todoist_AddItem

-- call the Todoist API to add a project
-- returns the project_id that was created
-- does NOT check to see if that project already exists and surprisingly enough...
-- NEITHER DOES THE API
-- does not return if unsuccessful which is probably a bad idea...

on Todoist_AddProject(_token, _name)
	
	-- JSON Helper is necessary here (because we need to be able to extract the project_id)
	
	-- curl will encode the data in the POST according to MIME-type application/x-www-form-urlencoded so
	-- all the escapes will be done for us
	
	try
		set _postToAPI to "curl -X POST -d 'name=" & _name & "' -d 'token=" & _token & "' https://todoist.com/API/addproject | sed 's/^.\\(.*\\).$/\\1/' "
		set _temp to do shell script _postToAPI
	on error
		-- curl returned a non-zero result, must be bad!
		my dialog_error("Non-zero error return from Todoist API call!")
	end try
	
	if _temp is null then
		my dialog_error("Null response from Todoist API call!")
	end if
	
	-- save return from API call if it was non NULL
	
	-- fixme: aren't we clipping off the braces above and putting them back below so JSON Helper can decode?  silly...
	
	try
		tell application "JSON Helper"
			set _return to read JSON from "{" & _temp & "}"
		end tell
	on error
		my dialog_error("JSON Helper unable to parse result from API call!")
	end try
	
	set _projectID to (|id| of _return)
	return _projectID
	
end Todoist_AddProject

-- retrieve all project names from the API

on Todoist_GetAllProjects(_token)
	
	try
		tell application "JSON Helper"
			set _URL to "https://todoist.com/API/getProjects?token=" & _token
			set myRecord to fetch JSON from _URL
			set countResults to (count of items of myRecord)
		end tell
	on error
		my dialog_error("JSON Helper unable to parse result from API call!")
	end try
	
	-- ok, myRecord is the JSON result of the query
	-- bomb if we got a null return, which should be impossible, as the Inbox project should always be there
	
	if myRecord is null then
		return null
	end if
	
	-- now build a structure we can actually use
	
	set projectNameList to null
	set projectRecord to {}
	
	repeat with thisProject in myRecord
		set thisProjectName to (|name| in thisProject)
		set thisProjectID to (|id| in thisProject)
		set Project to {|name|:thisProjectName, |id|:thisProjectID}
		set projectRecord to projectRecord & {Project}
	end repeat
	
	-- we return an AppleScript property list, {name : id} for each project
	return projectRecord
	
end Todoist_GetAllProjects

-- stubs for future use

on Todoist_AddNoteToItem()
	-- shim for future
end Todoist_AddNoteToItem

on Todoist_AddSubItem()
	-- shim for future
end Todoist_AddSubItem

-- display informational dialog

on dialog_Info(_message)
	display dialog _message buttons {"Ok"} with title "Information!" default button "Ok" with icon caution
end dialog_Info

-- display error dialog and abort script

on dialog_error(_message)
	display dialog _message buttons {"Cancel"} with title "Error!" default button "Cancel" with icon stop
	error number -128
end dialog_error

-- ask a question
-- "Yes" button returns what the text input was
-- "No" button returns NULL
-- "Cancel" button aborts the script

on dialog_Question(_message)
	set _result to (display dialog _message buttons {"Yes", "No", "Cancel"} with title "Question!" default answer "" default button "No" with icon caution)
	if the button returned of the _result is "Yes" then
		set _input to the text returned of the _result
		return _input
	end if
	if the button returned of the _result is "Cancel" then
		error number -128
	end if
	return null
end dialog_Question

-- replace one character with another

on replace_chars(this_text, search_string, replacement_string)
	set _tid to (AppleScript's text item delimiters)
	set AppleScript's text item delimiters to the search_string
	set the item_list to every text item of this_text
	set AppleScript's text item delimiters to the replacement_string
	set this_text to the item_list as string
	set AppleScript's text item delimiters to _tid
	return this_text
end replace_chars

-- A sub-routine for encoding high-ASCII characters
-- From http://www.macosxautomation.com/applescript/sbrt/sbrt-08.html

on encode_char(this_char)
	set the ASCII_num to (the ASCII number this_char)
	set the hex_list to {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"}
	set x to item ((ASCII_num div 16) + 1) of the hex_list
	set y to item ((ASCII_num mod 16) + 1) of the hex_list
	return ("%" & x & y) as string
end encode_char

-- this sub-routine is used to encode text 
-- From http://www.macosxautomation.com/applescript/sbrt/sbrt-08.html
-- for definitions of encode_URL_A and encode_URL_B see above URL

on encode_text(this_text, encode_URL_A, encode_URL_B)
	set the standard_characters to "abcdefghijklmnopqrstuvwxyz0123456789"
	set the URL_A_chars to "$+!'/?;&@=#%><{}[]\"~`^\\|*"
	set the URL_B_chars to ".-_:"
	set the acceptable_characters to the standard_characters
	if encode_URL_A is false then set the acceptable_characters to the acceptable_characters & the URL_A_chars
	if encode_URL_B is false then set the acceptable_characters to the acceptable_characters & the URL_B_chars
	set the encoded_text to ""
	repeat with this_char in this_text
		if this_char is in the acceptable_characters then
			set the encoded_text to (the encoded_text & this_char)
		else
			set the encoded_text to (the encoded_text & encode_char(this_char)) as string
		end if
	end repeat
	return the encoded_text
end encode_text

-- A sub-routine for decoding a three-character hex string
-- From http://www.macosxautomation.com/applescript/sbrt/sbrt-08.html

on decode_chars(these_chars)
	copy these_chars to {indentifying_char, multiplier_char, remainder_char}
	set the hex_list to "123456789ABCDEF"
	if the multiplier_char is in "ABCDEF" then
		set the multiplier_amt to the offset of the multiplier_char in the hex_list
	else
		set the multiplier_amt to the multiplier_char as integer
	end if
	if the remainder_char is in "ABCDEF" then
		set the remainder_amt to the offset of the remainder_char in the hex_list
	else
		set the remainder_amt to the remainder_char as integer
	end if
	set the ASCII_num to (multiplier_amt * 16) + remainder_amt
	return (ASCII character ASCII_num)
end decode_chars

-- this sub-routine is used to decode text strings 
-- From http://www.macosxautomation.com/applescript/sbrt/sbrt-08.html

on decode_text(this_text)
	set flag_A to false
	set flag_B to false
	set temp_char to ""
	set the character_list to {}
	repeat with this_char in this_text
		set this_char to the contents of this_char
		if this_char is "%" then
			set flag_A to true
		else if flag_A is true then
			set the temp_char to this_char
			set flag_A to false
			set flag_B to true
		else if flag_B is true then
			set the end of the character_list to my decode_chars(("%" & temp_char & this_char) as string)
			set the temp_char to ""
			set flag_A to false
			set flag_B to false
		else
			set the end of the character_list to this_char
		end if
	end repeat
	return the character_list as string
end decode_text

-- A sub-routine for writing data to a file
-- from http://www.macosxautomation.com/applescript/sbrt/sbrt-09.html
-- slightly diddled to use the posix filename

on write_to_file(this_data, target_file, append_data)
	try
		set the target_file to the target_file as string
		set the open_target_file to open for access POSIX file target_file with write permission
		if append_data is false then set eof of the open_target_file to 0
		write this_data to the open_target_file starting at eof
		close access the open_target_file
		return true
	on error
		try
			close access file target_file
		end try
		return false
	end try
end write_to_file

-- return the position of an item in a list
-- From http://www.macosxautomation.com/applescript/sbrt/sbrt-07.html
-- diddled to match on text as the result from the API is text (sorta)

on list_position(this_item, this_list)
	repeat with i from 1 to the count of this_list
		if item i of this_list is (this_item as text) then return i
	end repeat
	return 0
end list_position

-- return the OS version string as a list
-- fixme: does /usr/bin/sw_vers always exist?

on get_os_version()
	set _delim to AppleScript's text item delimiters
	set AppleScript's text item delimiters to "."
	set os_version to (the text items of (do shell script "sw_vers -productVersion"))
	set AppleScript's text item delimiters to _delim
	return os_version
end get_os_version

-- does a file exist?

on FileExists(theFile) -- (String) as Boolean
	tell application "System Events"
		if exists file theFile then
			return true
		else
			return false
		end if
	end tell
end FileExists

-- read from the defaults database
-- return null if the key is not present

on readDefaultsString(_domain, _key)
	set command to "/usr/bin/defaults read " & _domain & space & _key
	try
		set _value to the text of (do shell script command)
	on error
		return null
	end try
	return _value
end readDefaultsString

on writeDefaultsString(_domain, _key, _value)
	set command to "/usr/bin/defaults write " & _domain & space & _key & space & _value
	return the text of (do shell script command)
end writeDefaultsString

on readDefaultsBoolean(_domain, _key)
	set command to "/usr/bin/defaults read " & _domain & space & _key
	try
		set _value to the text of (do shell script command)
	on error
		return null
	end try
	if _value = "1" then
		return true
	else
		return false
	end if
end readDefaultsBoolean

on writeDefaultsBoolean(_domain, _key, _value)
	set command to "/usr/bin/defaults write " & _domain & space & _key & " -bool " & _value
	return the text of (do shell script command)
end writeDefaultsBoolean

-- clean up the security hole from the log file we were creating

on clean_up_log_file()
	set myHome to (path to home folder as text)
	set myLogFile to (POSIX path of (myHome & ".todoist-log"))
	if FileExists(myLogFile) then
		set _warning to "Script versions prior to v8 would create an insecure log file.  That file will now be removed."
		set _warning to _warning & return & return & "Please run the script again."
		display dialog _warning with title "Alert!"
		set _script to "rm -f " & (myLogFile as text)
		do shell script _script
		error number -128
	end if
end clean_up_log_file

-- clean up the security hole from the API file we were creating

on clean_up_token_file()
	set myHome to (path to home folder as text)
	set myTokenFile to (POSIX path of (myHome & ".todoist-token"))
	if FileExists(myTokenFile) then
		set _warning to "Script versions prior to v9 would create a file containing the API key.  That file will now be removed."
		set _warning to _warning & return & return & "Please run the script again."
		display dialog _warning with title "Alert!"
		set _script to "rm -f " & (myTokenFile as text)
		do shell script _script
		error number -128
	end if
end clean_up_token_file

on display_first_run()
	set _message to "Create Todoist Task from Mail.app
Copyright (c) 2014 Marc Wilson <posguy99@gmail.com>


Select a single email and a task will be created in the Inbox.
	
Select multiple email and you will be asked whether to create a Project or to add the email to an existing Project.
	
Email content will become the first Note attached to the created Task or Tasks.

Created Tasks will have a default due date of tomorrow.

"
	my dialog_Info(_message)
	
end display_first_run
