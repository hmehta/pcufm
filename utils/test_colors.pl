#!/usr/bin/perl
use strict;
use Curses;

initscr();
start_color();

# change in order to NOT print entrys on grey BG
my $grey_bg = 1;

printw("terminal supports $COLORS colors and $COLOR_PAIRS color_pairs\n");
printw("terminal size: $LINES x $COLS\n");
printw("printing grey backgrounds as well..\n") if ($grey_bg);
printw("legend: N = normal B = bold G = grey background\n");

# init color pairs for basic colors 1-8
for (my $i=1;$i<9;$i++){
	init_pair($i,0,$i-1);
}

# print it out
for (my $i=1;$i<9;$i++){
	attron(COLOR_PAIR($i));
	printw("N ");
	attroff(COLOR_PAIR($i));
	printw(" ");
	attron(COLOR_PAIR($i)|A_BOLD);
	printw("B ");
	attroff(COLOR_PAIR($i)|A_BOLD);
	if ($grey_bg){
		printw(" ");
		attron(COLOR_PAIR($i)|A_BOLD|A_REVERSE);
		printw("G ");
		attroff(COLOR_PAIR($i)|A_BOLD|A_REVERSE);
	}
}

printw ("\nall possible color combos with basic colors printed. press any key to exit\n");

refresh();
getch();
endwin();

