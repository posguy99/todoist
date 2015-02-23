Create Todoist Task From Email
==============================

Copyright &copy; 2014,2015 Marc Wilson <<posguy99@gmail.com>>

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

---

Installation
------------

Copy the script to $HOME/Library/Scripts.

A hotkey can be assigned to the script with a utility such as FastScripts, or turn on the script menu from AppleScript Editor and run it that way.

On the first run of the script, there will be a prompt for your API token.


Configuration
-------------

The script has sensible defaults.  The following settings can be changed:

    defaults write me.mwilson.scripts todoistCreateTaskAddBodyAsNote -bool {TRUE|FALSE}
    defaults write me.mwilson.scripts todoistCreateTaskAddIcon -bool {TRUE|FALSE}
    defaults write me.mwilson.scripts todoistCreateTaskAddURL -bool {TRUE|FALSE}
    defaults write me.mwilson.scripts todoistCreateTaskDueDate "tomorrow"
    defaults write me.mwilson.scripts todoistCreateTaskPriority {1|2|3|4}

Without changes, the defaults are priority low, add the body as a note, add the message URL, and don't add the icon.

The script will store the API key in defaults as todoistCreateTaskAPIToken.


Usage
-----

* Select a single email and a task will be created in the Inbox.
	
* Select multiple email and you will be asked whether to create a Project or to add the email to an existing Project.
	
* Email content will become the first Note attached to the created Task or Tasks.


Notes
------

Adding the message URL will break the iOS Today widget (if you use it).  Clicking the inserted message URL in the Outlook
Add-In will cause the Add-In to crash and require you to restart Outlook.  Apparently unrecognized URL schemes on Windows
are... bad.


