
tell application "JSON Helper"
	set myRecord to fetch JSON from "https://todoist.com/API/getProjects?token=e3e9074ef60cce6e6dbb7b0e506c1d2b11ccb09c"
	set countResults to (count of items of myRecord)
end tell

-- ok, there are #countResults projects in the list
-- fetch each name and create the list of projects for the dialog to use

set projectNameList to {}
set projectRecord to {}

repeat with thisProject in myRecord
	set thisProjectName to (|name| in thisProject)
	set thisProjectID to (|id| in thisProject)
	
	set projectNameList to projectNameList & {thisProjectName}
	
	set Project to {|name|:thisProjectName, |id|:thisProjectID}
	
	set projectRecord to projectRecord & {Project}
end repeat

set _choice to choose from list projectNameList ¬
	with title "Choose from the list" with prompt "Please make your selection"

-- ok, _choice is the item from the list
-- need to index into projectRecord to find that project's ID

set _position to my list_position(_choice, projectNameList)
set _projectID to (|id| of item _position of projectRecord)

say (_choice as text) & " is eyetem " & _position & " in the list and has a project ID of " & (_projectID as text)


-- return the position of an item in a list

on list_position(this_item, this_list)
	repeat with i from 1 to the count of this_list
		if item i of this_list is (this_item as text) then return i
	end repeat
	return 0
end list_position

