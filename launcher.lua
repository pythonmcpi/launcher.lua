--[[

A simple program launcher.

Usage: luajit.exe launcher.lua

Requires:
- [luajit](https://luajit.org/)
  - [pdcurses.dll](https://github.com/wmcbrine/PDCurses) on system PATH
- [winapi.dll](https://github.com/stevedonovan/winapi) in the same directory as luajit.exe

]]

local base_path = string.match(arg[0], '^(.-)[^/\\]*$')

local ffi = require "ffi"
local bit = require "bit" -- bit operations provided by luajit
local winapi = require "winapi"
local curses = require ".\\curses"

local keycodes = require "keycodes"

local config = require "config"

-- Try to switch to the user's home directory
ffi.cdef[[
    int _chdir(const char *dirname);
]]

local homedir = os.getenv("USERPROFILE")
local retval = ffi.C._chdir(homedir)

if retval ~= 0 then
    print "Warn: Failed to change directory to ~"
    print "Programs may be launched from the wrong directory"
end

local modifiers = {
    right_line = bit.lshift(1, 17),
    left_line = bit.lshift(1, 18),
    -- not sure what 19 does
    underline = bit.lshift(1, 20),
    reverse = bit.lshift(1, 21),
    bold = bit.lshift(1, 23),
}

local boxdraw = {
    h = "─", -- horizontal
    v = "│", -- vertical
    x = "┼", -- cross
    vr = "├", -- vertical right
    vl = "┤", -- vertical left
    hu = "┴", -- horizontal up
    hd = "┬", -- horizontal down
    tl = "┌", -- top left
    tr = "┐", -- top right
    bl = "└", -- bottom left
    br = "┘", -- bottom right
}

-- #define PDC_COLOR_SHIFT 24
-- #define A_COLOR (chtype)0xff000000
-- #define COLOR_PAIR(n)      (((chtype)(n) << PDC_COLOR_SHIFT) & A_COLOR)

local PDF_COLOR_SHIFT = 24
local A_COLOR = 0xff000000

local function COLOR_PAIR(n)
    return bit.band(bit.lshift(n, PDF_COLOR_SHIFT), A_COLOR)
end

local function getch()
    while true do
        local key = curses.wgetch(curses.stdscr)

        if key ~= keycodes.resize then
            return key
        end

        curses.resize_term(0, 0)
        curses.refresh()
    end
end

local function setup_colors()
    -- 0 is default and cannot be changed
    curses.init_pair(1, 38, 0)
    curses.init_pair(2, 0, 45)
    curses.init_pair(3, 7, 0)
end

local function colorTest()
    curses.clear()
    curses.move(0, 0)

    for i=1,255 do
        curses.init_pair(i, 0, i)
        curses.attrset(COLOR_PAIR(i))

        local s = tostring(i)
        if string.len(s) == 1 then
            s = "  " .. s
        elseif string.len(s) == 2 then
            s = " " .. s
        end

        curses.addstr(s)

        curses.attrset(COLOR_PAIR(0))
        if (i+1) % 16 == 0 then
            curses.addstr("\n")
        end
    end

    curses.addstr("\n")
    local possibleColorPalette = {11, 31, 33, 39, 45, 51, 75, 87, 123, 159}

    for i=1,#possibleColorPalette do
        curses.attrset(COLOR_PAIR(possibleColorPalette[i]))
        curses.addstr("ABC")
    end

    curses.refresh()
    getch()

    setup_colors() -- restore color pairs
end

local function centerText(text, width)
    width = width or curses.getmaxx(curses.stdscr)

    local tLen = string.len(text)
    local padLen = width - tLen
    local padStart = math.floor(padLen / 2)
    local padEnd = math.ceil(padLen / 2)

    return string.rep(" ", padStart) .. text .. string.rep(" ", padEnd)
end

local function draw_border(box_sep, count_box_width)
    if color == nil then color = 0 end

    local maxX = curses.getmaxx(curses.stdscr)
    local maxY = curses.getmaxy(curses.stdscr)

    -- Top line
    curses.move(1, 1)
    curses.addstr(boxdraw.tl .. string.rep(boxdraw.h, maxX - 5) .. boxdraw.tr)

    -- Bottom line
    curses.move(maxY - 2, 1)
    curses.addstr(boxdraw.bl .. string.rep(boxdraw.h, maxX - 5) .. boxdraw.br)

    -- Right line
    for y=2, (maxY-3) do
        curses.move(y, 1)
        curses.addstr(boxdraw.v)
    end

    -- Left line
    for y=2, (maxY-3) do
        curses.move(y, maxX-3)
        curses.addstr(boxdraw.v)
    end

    -- Search box separator (overwrites some of the existing lines)
    if box_sep then
        curses.move(3, 1)
        curses.addstr(boxdraw.vr .. string.rep(boxdraw.h, maxX - 5) .. boxdraw.vl)

        -- Seperator between search and count
        if count_box_width then
            local x = maxX - 4 - count_box_width

            curses.move(1, x)
            curses.addstr(boxdraw.hd)

            curses.move(2, x)
            curses.addstr(boxdraw.v)

            curses.move(3, x)
            curses.addstr(boxdraw.hu)
        end
    end
end

local function main()
    -- Terminal flags
    curses.cbreak()
    curses.noecho()
    curses.keypad(curses.stdscr, true) -- enable arrow keys

    if curses.has_colors() == 0 then
        curses.printw "This terminal is missing color support.\n"
        curses.printw "Press enter to dismiss this message.\n"

        curses.refresh()
        getch()

        return
    end

    -- Set up colors
    curses.start_color()
    curses.use_default_colors()

    setup_colors()

    curses.PDC_set_title("launcher.lua")

    local query = ""
    local sortedEntries = {}
    for i,v in ipairs(config.entries) do
        table.insert(sortedEntries, v)
    end

    table.sort(sortedEntries, function (a, b)
        return a.name:upper() < b.name:upper()
    end)

    local selection = 0

    while true do
        curses.clear()

        -- Draw current query
        curses.move(2, 2)
        curses.attrset(bit.bor(COLOR_PAIR(0), modifiers.bold))
        curses.addstr(query)

        -- Filter options
        local optionSource = sortedEntries
        local sourceCount = #sortedEntries
        local filteredOptions = {}
        local cmdlineWidth = 0
        local useDefaultSort = query:sub(1,1) ~= ":" and query:sub(1,1) ~= ";"
        local useQuery = query:lower()

        if query:sub(1, 2) == "::" then
            optionSource = {
                {
                    name = "Debug: Color Test",
                    cmdline = "::colortest",
                    execute = colorTest,
                },
            }
            useDefaultSort = true
            useQuery = query:sub(3, -1)
            sourceCount = #optionSource
        end

        if useDefaultSort then
            for i, v in ipairs(optionSource) do
                if string.find(v.name:lower(), useQuery, nil, true) or string.find(v.cmdline:lower(), useQuery, nil, true) then
                    table.insert(filteredOptions, v)

                    if string.len(v.cmdline) > cmdlineWidth then
                        cmdlineWidth = string.len(v.cmdline)
                    end
                end
            end
        else
            table.insert(filteredOptions, {
                name = "Run Command Directly",
                cmdline = query:sub(2, -1),
                spawn = true,
                commandWindow = query:sub(1,1) == ":",
            })
            sourceCount = #filteredOptions
            cmdlineWidth = string.len(filteredOptions[1].cmdline)
        end

        -- Draw options
        local maxX = curses.getmaxx(curses.stdscr)
        local maxY = curses.getmaxy(curses.stdscr) - 6
        local loopMax

        if maxY > #filteredOptions then
            loopMax = #filteredOptions
        else
            loopMax = maxY
        end

        for i=1,loopMax do
            curses.move(3 + i, 2)

            if i == selection then
                curses.attrset(COLOR_PAIR(2))
            else
                curses.attrset(bit.bor(COLOR_PAIR(0), modifiers.bold))
            end

            local leftAlign = " " .. filteredOptions[i].name

            local padLen = maxX - 7 - cmdlineWidth - string.len(leftAlign)

            curses.addstr(leftAlign)
            curses.addstr(string.rep(" ", padLen))

            if i == selection then
                curses.attrset(bit.bor(COLOR_PAIR(2), modifiers.bold))
            else
                curses.attrset(COLOR_PAIR(0))
            end

            curses.addstr(filteredOptions[i].cmdline)
        end

        -- Draw count
        curses.attrset(COLOR_PAIR(0))
        local count_width = string.len(tostring(sourceCount)) * 2 + 1
        local count_str = #filteredOptions .. "/" .. sourceCount
        count_str = string.rep(" ", count_width - #count_str) .. count_str
        curses.move(2, maxX - 4 - count_width)
        curses.addstr(count_str)

        -- Draw border
        curses.attrset(COLOR_PAIR(1))
        draw_border(true, count_width + 2)

        curses.move(2, 2+string.len(query))

        curses.refresh()
        local char = getch()

        local ok, sc = pcall(string.char, char)

        if char == keycodes.backspace or char == 8 then
            -- backspace
            query = query:sub(1, -2) -- remove last character
            selection = 0
        elseif char == keycodes.up then
            if selection > 0 then
                selection = selection - 1
            end
        elseif char == keycodes.down then
            if selection < loopMax then
                selection = selection + 1
            end
        elseif char == keycodes.right or char == keycodes.left then
            -- ignore, we don't support editing
        elseif char == keycodes.esc then
            if query == "" then
                return
            end
            query = ""
            selection = 0
        elseif ok then
            if sc == "\n" then
                if #filteredOptions > 0 then
                    if selection == 0 then selection = 1 end

                    local sentry = filteredOptions[selection]

                    if sentry.spawn then
                        if sentry.commandWindow then
                            os.execute("start " .. sentry.cmdline)
                        else
                            winapi.spawn_process(sentry.cmdline)
                        end
                    end

                    local shouldreturn = true

                    if sentry.execute then
                        shouldreturn = sentry.execute()
                    end

                    if shouldreturn then return end
                end
            else
                query = query .. sc
                selection = 0
            end
        end
    end
end

-- Setup/teardown code
curses.initscr()
local ok, err = pcall(main)

-- Reset terminal flags
curses.echo()
curses.nocbreak()
curses.noraw()

curses.endwin()

-- Print error if there was one
if not ok then
    print(err)
end

