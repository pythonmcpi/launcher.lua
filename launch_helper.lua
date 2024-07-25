-- Launch script

local ffi = require "ffi"

ffi.cdef[[
    int _chdir(const char *dirname);
]]

local homedir = os.getenv("USERPROFILE")

local retval = ffi.C._chdir(homedir .. "\\launcher")

if retval == 0 then
    -- Directory change worked
    dofile "./launcher.lua"
else
    print "Error: Failed to change directory to ~/launcher"
    io.read "*line" -- don't immediately exit
end

