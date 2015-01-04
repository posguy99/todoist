set sysinfo to system info
set osver to system version of sysinfo

set _delim to AppleScript's text item delimiters
set AppleScript's text item delimiters to "."
set os_version to (the text items of (do shell script "sw_vers -productVersion"))
set test to (the second text item of os_version)

