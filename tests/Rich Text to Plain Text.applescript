try
	set the clipboard to string of (the clipboard as record)
on error errMsg
	display dialog errMsg
end try
