#!/usr/bin/perl
#
use strict;

use Curses;
use Time::HiRes qw(usleep);
use POSIX qw(locale_h);
my $locale = setlocale(LC_CTYPE) or die "couldn't figure out locales";
if ($locale =~ /utf8$/){
	use utf8;
}

require("lib/curses.pl");
require("lib/input_handler.pl");
require("lib/ui.pl");
require("lib/filemanager.pl");
require("lib/debug.pl");

# %ui is a hash of hashes
# it contains all the UI elements as hashes, which instead contain
# information about those elements
my %ui = init_ui();
$ui{'usleep'} = 1;

# make initial status message
status_message(\%ui,"",0,"");

# command mode hook
#while (1){
	%ui = command_mode(\%ui);
	usleep(2000);
#}

exit_curses();

sub search_dirs {
	my ($uir) = @_;
	my %ui = %{$uir};
        %ui = draw_dirs(\%ui);
	%ui = refresh_all(\%ui);

	%ui = window_size(\%ui,"prompt");

	$ui{'prompt'}{'win'}->move(0,0);
	$ui{'prompt'}{'win'}->clrtoeol();
	$ui{'prompt'}{'win'}->addstr(0,0,"/");
	echo();
	curs_set(1);
	my @orig_dirs = @{$ui{'act'}{'dirs'}};
	my $search = "";
	my $regexp = 0;
	while (my $c = $ui{'prompt'}{'win'}->getch()){
		delete $ui{'act'}{'dirs'};

		# backspace
		if ($c == 263){
			$search = substr($search,0,length($search)-1);
			#	$ui{'prompt'}{'win'}->clrtoeol();
			my ($y,$x);
			$ui{'prompt'}{'win'}->getyx($y,$x);
			for (my $i=$x;$i<$ui{'prompt'}{'max_x'};$i++){
				$ui{'prompt'}{'win'}->addch(0,$i," ");
			}
			$ui{'prompt'}{'win'}->move(0,$x);

			if ($x == 0){
				$c = "LAST";
			}
			else {
				$c = "";
			}
		}

		if ($c != -1){
			$search .= $c if ($c ne "\n");
	
			foreach my $entry (@orig_dirs){
				my $reg = quotemeta($search);
				$reg =~ s/\\\*/\*/g;
				if ($entry =~ m/^$reg/){
					push (@{$ui{'act'}{'dirs'}},$entry);
				}
			}
			if ($#{$ui{'act'}{'dirs'}} < 0){
				push (@{$ui{'act'}{'dirs'}},"no results");
			}
			%ui = draw_dirs(\%ui);
			%ui = refresh_all(\%ui);
			$ui{'prompt'}{'win'}->refresh();
			if (ord($c) == 10 or $c eq "LAST"){
				last;
			}

		}
		usleep($ui{'usleep'});
		echo();
		curs_set(1);
	}

	%ui = draw_filemanager(\%ui);
	noecho();
	curs_set(0);
	return %ui;
}
