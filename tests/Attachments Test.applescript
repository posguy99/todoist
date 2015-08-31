#!/usr/bin/osascript
(*
    Test attachment saving from mail.app
 *)

    -- The folder to save the attachments in (must already exist)

    set attachmentsFolder to ((path to home folder as text) & "Downloads") as text

    -- Save in a sub-folder

    set subFolder to "todoist"
    tell application "Finder"
       if not (exists folder subFolder of folder attachmentsFolder) then
        try
           display dialog "Directory create"
           make new folder at attachmentsFolder with properties {name:subFolder}
        end try
       end if
    end tell

    -- Process selected messages

    tell application "Mail"
       set selectedMessages to selection
        repeat with theMessage in selectedMessages

            -- Save the attachment

            repeat with theAttachment in theMessage's mail attachments
               set originalName to name of theAttachment
                set savePath to attachmentsFolder & ":" & subFolder & ":" & originalName
                try
                   save theAttachment in savePath
                end try
            end repeat
        end repeat
    end tell

