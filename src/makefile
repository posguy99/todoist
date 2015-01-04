# compile all scripts

OSAC=/usr/bin/osacompile

all: createtask

createtask: Create\ Todoist\ Task\ From\ Email.scpt

Create\ Todoist\ Task\ From\ Email.scpt : Create\ Todoist\ Task\ From\ Email.applescript
	/usr/bin/osacompile -o "Create Todoist Task From Email.scpt" "Create Todoist Task From Email.applescript"

clean:
	rm *.scpt
    
