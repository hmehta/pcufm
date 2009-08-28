#!/usr/bin/perl
#
# this is a software for testing out ncurses
# keymappings with a window with keypad(1).
# inputted keys are printed when inputted.

use Curses;

# init curses
my $win = new Curses;
noecho();
halfdelay(5);
$win->keypad(1);
$win->syncok(1);
curs_set(0);
leaveok(1);

$win->addstr(8,5,"press q to exit");
#$win->addstr(9,5,"ord of ^K: ".ord(\ck));

# the magic between
while (my $c = $win->getch()){
	if ($c eq "q"){
		last;
	}
#	elsif ($c eq BUTTON_CTRL){
#		$win->addstr(10,5,"$c pressed");
#	}
#	elsif ($c eq "\cb"){
#		$win->addstr(10,5,"Ctrl+B pressed!!");
#	}
	elsif ($c != -1) {
		$win->move(5,5);
		$win->clrtoeol();
#		$c =~ s/^./Ctrl+/;
		$win->addstr(5,5,"key: $c length: ".length($c)." hex: ".ord($c));
	}
}

# exit curses
echo();
curs_set(1);
endwin();
exit 1;
