#!/usr/bin/perl

use strict;
use Curses;


sub refresh_all {
	my ($uiref) = @_;
	my %ui = %{$uiref};

	if ($ui{'main'}{'max_y'} != $LINES){
		debug_log("refresh_all: y-axis modified. attempting resize\n");
		%ui = redraw_ui(\%ui);
	}
	elsif ($ui{'main'}{'max_x'} != $COLS){
		debug_log("refresh_all: x-axis modified. attempting resize\n");
		%ui = redraw_ui(\%ui);
	}
	$ui{'main'}{'win'}->refresh();
	$ui{'status'}{'win'}->refresh();
	$ui{'prompt'}{'win'}->refresh();
	$ui{'left'}{'win'}->refresh();
	$ui{'right'}{'win'}->refresh();

	return %ui;
}

sub exit_curses {	
	debug_log(2,"exit_curses called\n");
	echo();
	curs_set(1);
	endwin();
	return 1;
}

sub init_color_pairs {
	my ($uir) = @_;
	my %ui = %{$uir};


	debug_log(2,"init_color_pair: num of colors $COLORS\n");

	my $i = 0;
	foreach my $k (keys %{$ui{'conf'}}){
		if ($k =~ /^COLOR_/ && $k !~ /_GREYBG$/){
			$i++;
			my @ar = @{$ui{'conf'}{$k}};
			debug_log(2,"init_color_pairs: pair($i) : $ar[0] $ar[1]\n");
			init_pair($i,$ar[0],$ar[1]);
			debug_log(2,"init_color_pairs: ui{colors}{$k} = $i; => ".COLOR_PAIR($i)."\n");
			debug_log(2,"init_color_pairs: ui{attributes}{$k} = $ar[2];\n");
			$ui{'colors'}{$k} = $i;
			$ui{'attributes'}{$k} = $ar[2];
		}		
	}

	return %ui;
}

sub get_attr {
	my ($var) = @_;
	# return A_ variables for conf values
	if ($var eq "A_NORMAL") { return A_NORMAL; }
	elsif ($var eq "A_BOLD") { return A_BOLD; }
	elsif ($var eq "A_REVERSE") { return A_REVERSE; }
	else { return $var; }
}

sub get_acs {
	my ($var) = @_;
	# return ACS_ variables for conf values
	# commented ones aren't supported since of use strict
	# in case you want to use them, just #use strict and
	# uncomment them as you like.
	if ($var eq "ACS_ULCORNER") { return ACS_ULCORNER; }
	elsif ($var eq "ACS_URCORNER") { return ACS_URCORNER; }
	elsif ($var eq "ACS_LLCORNER") { return ACS_LLCORNER; }
	elsif ($var eq "ACS_LRCORNER") { return ACS_LRCORNER; }
	elsif ($var eq "ACS_LTEE") { return ACS_LTEE; }
	elsif ($var eq "ACS_RTEE") { return ACS_RTEE; }
	elsif ($var eq "ACS_BTEE") { return ACS_BTEE; }
	elsif ($var eq "ACS_TTEE") { return ACS_TTEE; }
	elsif ($var eq "ACS_HLINE") { return ACS_HLINE; }
	elsif ($var eq "ACS_VLINE") { return ACS_VLINE; }
	elsif ($var eq "ACS_PLUS") { return ACS_PLUS; }
	elsif ($var eq "ACS_S1") { return ACS_S1; }
	#elsif ($var eq "ACS_S3") { return ACS_S3; }
	#elsif ($var eq "ACS_S7") { return ACS_S7; }
	elsif ($var eq "ACS_S9") { return ACS_S9; }
	elsif ($var eq "ACS_DIAMOND") { return ACS_DIAMOND; }
	elsif ($var eq "ACS_CKBOARD") { return ACS_CKBOARD; }
	elsif ($var eq "ACS_DEGREE") { return ACS_DEGREE; }
	elsif ($var eq "ACS_PLMINUS") { return ACS_PLMINUS; }
	elsif ($var eq "ACS_BULLET") { return ACS_BULLET; }
	elsif ($var eq "ACS_LARROW") { return ACS_LARROW; }
	elsif ($var eq "ACS_RARROW") { return ACS_RARROW; }
	elsif ($var eq "ACS_DARROW") { return ACS_DARROW; }
	elsif ($var eq "ACS_UARROW") { return ACS_UARROW; }
	elsif ($var eq "ACS_BOARD") { return ACS_BOARD; }
	elsif ($var eq "ACS_LANTERN") { return ACS_LANTERN; }
	elsif ($var eq "ACS_BLOCK") { return ACS_BLOCK; }
	#elsif ($var eq "ACS_LEQUAL") { return ACS_LEQUAL; }
	#elsif ($var eq "ACS_GEQUAL") { return ACS_GEQUAL; }
	#elsif ($var eq "ACS_PI") { return ACS_PI; }
	#elsif ($var eq "ACS_NEQUAL") { return ACS_NEQUAL; }
	#elsif ($var eq "ACS_STERLING") { return ACS_STERLING; }
	# this is the case when ppl want char-based ui 
	else { return $var; }
}


sub init_curses {
	my $win = new Curses;

	noecho();
	halfdelay(5);
	$win->keypad(1);
	$win->syncok(1);

	if(!has_colors()){
		exit_curses();
		print "Your terminal does not support colors\n";
		exit;
	}
	start_color();
	curs_set(0);
	leaveok(1);
	
	debug_log(2,"init_curses: curses initialized\n");

	return $win;
}

1;
