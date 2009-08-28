#!/usr/bin/perl
use strict;
use Curses;

initscr();

if (ACS_ULCORNER) { printw("Upper left corner           "); addch(ACS_ULCORNER); printw("\n"); }
if (ACS_LLCORNER) { printw("Lower left corner           "); addch(ACS_LLCORNER); printw("\n"); }
if (ACS_LRCORNER) { printw("Lower right corner          "); addch(ACS_LRCORNER); printw("\n"); }
if (ACS_LTEE) { printw("Tee pointing right          "); addch(ACS_LTEE); printw("\n"); }
if (ACS_RTEE) { printw("Tee pointing left           "); addch(ACS_RTEE); printw("\n"); }
if (ACS_BTEE) { printw("Tee pointing up             "); addch(ACS_BTEE); printw("\n"); }
if (ACS_TTEE) { printw("Tee pointing down           "); addch(ACS_TTEE); printw("\n"); }
if (ACS_HLINE) { printw("Horizontal line             "); addch(ACS_HLINE); printw("\n"); }
if (ACS_VLINE) { printw("Vertical line               "); addch(ACS_VLINE); printw("\n"); }
if (ACS_PLUS) { printw("Large Plus or cross over    "); addch(ACS_PLUS); printw("\n"); }
if (ACS_S1) { printw("Scan Line 1                 "); addch(ACS_S1); printw("\n"); }
#if (ACS_S3) { printw("Scan Line 3                 "); addch(ACS_S3); printw("\n"); }
#if (ACS_S7) { printw("Scan Line 7                 "); addch(ACS_S7); printw("\n"); }
if (ACS_S9) { printw("Scan Line 9                 "); addch(ACS_S9); printw("\n"); }
if (ACS_DIAMOND) { printw("Diamond                     "); addch(ACS_DIAMOND); printw("\n"); }
if (ACS_CKBOARD) { printw("Checker board (stipple)     "); addch(ACS_CKBOARD); printw("\n"); }
if (ACS_DEGREE) { printw("Degree Symbol               "); addch(ACS_DEGREE); printw("\n"); }
if (ACS_PLMINUS) { printw("Plus/Minus Symbol           "); addch(ACS_PLMINUS); printw("\n"); }
if (ACS_BULLET) { printw("Bullet                      "); addch(ACS_BULLET); printw("\n"); }
if (ACS_LARROW) { printw("Arrow Pointing Left         "); addch(ACS_LARROW); printw("\n"); }
if (ACS_RARROW) { printw("Arrow Pointing Right        "); addch(ACS_RARROW); printw("\n"); }
if (ACS_DARROW) { printw("Arrow Pointing Down         "); addch(ACS_DARROW); printw("\n"); }
if (ACS_UARROW) { printw("Arrow Pointing Up           "); addch(ACS_UARROW); printw("\n"); }
if (ACS_BOARD) { printw("Board of squares            "); addch(ACS_BOARD); printw("\n"); }
if (ACS_LANTERN) { printw("Lantern Symbol              "); addch(ACS_LANTERN); printw("\n"); }
if (ACS_BLOCK) { printw("Solid Square Block          "); addch(ACS_BLOCK); printw("\n"); }
#if (ACS_LEQUAL) { printw("Less/Equal sign             "); addch(ACS_LEQUAL); printw("\n"); }
#if (ACS_GEQUAL) { printw("Greater/Equal sign          "); addch(ACS_GEQUAL); printw("\n"); }
#if (ACS_PI) { printw("Pi                          "); addch(ACS_PI); printw("\n"); }
#if (ACS_NEQUAL) { printw("Not equal                   "); addch(ACS_NEQUAL); printw("\n"); }
#if (ACS_STERLING) { printw("UK pound sign               "); addch(ACS_STERLING); printw("\n"); }

refresh();
getch();
endwin();

