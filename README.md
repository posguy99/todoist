Create Todoist Task From Email
==============================
Copyright &copy; 2014 Marc Wilson <<posguy99@gmail.com>>

---
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

---

Installation
------------

Copy the script to $HOME/Library/Scripts.

A hotkey can be assigned to the script with a utility such as FastScripts, or turn on the script menu from AppleScript Editor and run it that way.

On the first run  of the script, there will be a prompt for your API token.


Usage
-----
* Select a single email and a task will be created in the Inbox.
	
* Select multiple email and you will be asked whether to create a Project or to add the email to an existing Project.
	
* Email content will become the first Note attached to the created Task or Tasks.

* Created Tasks will have a default due date of today.

* The email priority will become the Task Priority.
