# launcher.lua

A simple and lightweight program launcher.
Currently windows-only, but pull requests are accepted.

## Requirements

- Terminal with color and unicode support
- Other dependencies listed in a comment in `launcher.lua`. (TODO: Move those here.)

## Configuration

`config.lua` holds the list of launcher entries. The format is documented in a comment.
Colors and unicode characters are not easily customizable at the moment.

## Usage

Type to narrow down program options. Arrow keys can be used to select a specific entry.
Pressing enter will execute that entry. If no entry was selected using arrow keys, the first entry is used.

Prefixing the query with `:` allows you to launch an unlisted program.
By default, this program is launched with a console window.
You can prefix the query with `;` instead to launch it without a console.

Prefixing the query with `::` brings up a list of utilities used for developing this project.
These may change at any time and are meant only for development use.

## launch_helper.lua

A helper script for starting launcher.lua from Window's Run box (accessed with Windows+R).
This script assumes that the launcher.lua repository is cloned to ~/launcher.
You would type the following into the Run box: `luajit.exe launcher/launch_helper.lua`

