--[[

Format of an entry:

name (string) The name displayed in the ui
cmdline (string) The command line displayed in the ui

spawn (boolean?) If true, executes cmdline when the entry is ran
commandWindow (boolean?) [spawn must be true] When starting cmdline, do it inside a command window

execute (function?) If not nil, called when the entry is ran
]]

return {
    entries = {
        {
            name = "Command Prompt",
            cmdline = "cmd",
            spawn = true,
            commandWindow = true,
        },
        {
            name = "Git Bash",
            cmdline = "\"C:\\Program Files\\Git\\git-bash.exe\"",
            spawn = true,
        },
        {
            name = "Neovide",
            cmdline = "neovide",
            spawn = true,
        },
    },
}

