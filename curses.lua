local ffi = require "ffi"

ffi.cdef[[
    typedef unsigned long chtype;
    typedef chtype attr_t;

    typedef struct _win       /* definition of a window */
    {
        int   _cury;          /* current pseudo-cursor */
        int   _curx;
        int   _maxy;          /* max window coordinates */
        int   _maxx;
        int   _begy;          /* origin on screen */
        int   _begx;
        int   _flags;         /* window properties */
        chtype _attrs;        /* standard attributes and colors */
        chtype _bkgd;         /* background, normally blank */
        bool  _clear;         /* causes clear at next refresh */
        bool  _leaveit;       /* leaves cursor where it is */
        bool  _scroll;        /* allows window scrolling */
        bool  _nodelay;       /* input character wait flag */
        bool  _immed;         /* immediate update flag */
        bool  _sync;          /* synchronise window ancestors */
        bool  _use_keypad;    /* flags keypad key mode active */
        chtype **_y;          /* pointer to line pointer array */
        int   *_firstch;      /* first changed character in line */
        int   *_lastch;       /* last changed character in line */
        int   _tmarg;         /* top of scrolling region */
        int   _bmarg;         /* bottom of scrolling region */
        int   _delayms;       /* milliseconds of delay for getch() */
        int   _parx, _pary;   /* coords relative to parent (0,0) */
        struct _win *_parent; /* subwin's pointer to parent win */

        /* these are used only if this is a pad */
        struct pdat
        {
            int _pad_y;
            int _pad_x;
            int _pad_top;
            int _pad_left;
            int _pad_bottom;
            int _pad_right;
        } _pad;               /* Pad-properties structure */
    } WINDOW;

    /* Core */
    WINDOW* initscr(void);
    int refresh(void);
    int endwin(void);

    int move(int, int);
    int resize_term(int, int);

    /* getmaxyx is implemented as a macro */
    int getmaxx(WINDOW *);
    int getmaxy(WINDOW *);

    void PDC_set_title(const char *);

    /* Text display */
    int printw(const char*, ...);
    int addch(const chtype);
    int addstr(const char *);

    int clear(void);

    /* Input */
    int wgetch(WINDOW*);

    /* Color */
    int has_colors(void);
    int start_color(void);
    int use_default_colors(void);
    int init_pair(short, short, short);

    /* Formatting */
    int attron(chtype);
    int attroff(chtype);
    int attrset(chtype);

    /* Terminal flags */
    int raw(void);
    int noraw(void);
    int echo(void);
    int noecho(void);
    int cbreak(void);
    int nocbreak(void);
    int keypad(WINDOW *, bool);

    WINDOW *stdscr;
    int COLORS;
]]

local curses = ffi.load "pdcurses"

return curses

