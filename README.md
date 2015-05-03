Create Todoist Task From Email
==============================

Copyright &copy; 2014,2015 Marc Wilson <<posguy99@gmail.com>>

---


Installation
------------

Copy the script to $HOME/Library/Scripts.

I suggest using [FastScripts](http://www.red-sweater.com/fastscripts/) to generate context-sensitive hotkeys for scripts.  It is free for up to ten shortcuts.

A good reference for creating hotkeys for scripts using Automator can be found at
[veritrope.com](http://veritrope.com/the-basics-using-keyboard-shortcuts-with-applescripts/).

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


