set myHome to (path to home folder as text)
set myLogFile to (POSIX path of (myHome & ".todoist-log"))
set _script to "rm -f " & myLogFile
FileExists(myLogFile)
-- do shell script _script

on FileExists(theFile) -- (String) as Boolean
	tell application "System Events"
		if exists file theFile then
			return true
		else
			return false
		end if
	end tell
end FileExists
