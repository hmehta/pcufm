#!/usr/bin/perl
# configuration reading module for pcufm

use strict;

require("lib/inside_ar.pl");

sub _die {
	my $msg = shift;

	print "$msg\n";
	exit 0;
}

sub debug_level {
	my %debug;
	my $config_file = "cfg/pcufm.cfg";
	open (READ,"<$config_file") or _die("error while reading configuration file");
	while (<READ>){
		next if ($_ =~ /^(#|\n)/);
		$_ =~ s/[\t\s]//g;
		my ($k,$v) = split (/=\>/,$_);
		$v =~ s/"//g;
		if ($k =~ /^LOG/){
			$debug{$k} = "$v";
			last if (exists $debug{'LOGFILE'} and exists $debug{'LOGLEVEL'});
		}
	}
	close (READ);
	if (exists $debug{'LOGFILE'} and exists $debug{'LOGLEVEL'}){
		return %debug;
	}
	else {
		_die("LOGFILE or LOGLEVEL missing, please revise your configuration");
	}
}

sub read_config {
	my %config;
	my @keys;
	my @values;
	my $config_file = "cfg/pcufm.cfg";
	my $row = 0;
	open (READ,"<$config_file") or _die("error while reading configuration file");
	while (<READ>){
		$row++;
		next if ($_ =~ /^(#|\n)/);
		$_ =~ s/[\t\s]//g;
		my ($k,$v) = split (/=\>/,$_);
		_die("no value for key or vice versa, please revise your configuration") if (!$k || !$v);
		$v =~ /^".*"$/ || _die("invalid value $v on row $row, please revise your configuration");
		$v =~ s/"//g;
		$v = " " if (!$v);
		$k =~ /[^A-Z_]/ && _die("invalid key $k on row $row, please revise your configuration");
		
		# use arrayrefs for multivalues, strings for singles
		# use just arrayrefs here
		my @ar;
		@ar = split(/\,/,$v);
		foreach (@ar){
			#print "ar: $_\n";
			if ($k =~ /^COLOR_/){
				$_ =~ s/BLACK/0/;
				$_ =~ s/RED/1/; 
				$_ =~ s/GREEN/2/;
				$_ =~ s/YELLOW/3/; 
				$_ =~ s/BLUE/4/;
				$_ =~ s/MAGENTA/5/; 
				$_ =~ s/CYAN/6/;
				$_ =~ s/WHITE/7/;
				$_ =~ s/GREY/8/;
			}

			if ($k =~ /^KEY_/){
				foreach my $key (keys %config){
					if ($key =~/^KEY_/){
						_die("duplicate binding for $_ on row $row, please revise your configuration") if (inside_ar($config{$key},$_));
			       		}
				}
				debug_log(3,"pushing \"$_\" -> values\n");
				push (@values,$_);
			}
			elsif (!inside_ar(\@values,$_)){
				debug_log(3,"pushing \"$_\" -> values\n");
				push (@values,$_);
			}
		}

		if ($k =~ /^COLOR_/){
			if (inside_ar(\@ar,8)){
				push (@ar,"A_BOLD");
				if ($ar[0] == 8){
					$ar[0] = 0;
				}
				elsif ($ar[1] == 8){
					# swap arrays here in order to use grey as bg, *curses* ;G
					$ar[1] = $ar[0];
					$ar[0] = 0;
					debug_log(3,"read_config: $k\_GREYBG\n");
					$config{"$k\_GREYBG"} = 1;
				}
			}
			else {
				push (@ar,"A_NORMAL");
			}
		}

		if (!inside_ar(\@keys,$k)){
			push (@keys,$k);
		}
		else {
			_die("$k is a duplicate key, please revise your configuration");
		}
		
		# do the specialty, single variables here
		if ($k =~ /^PATH_/ or $k =~ /^(C|CMD)_/ or $k =~ /^SB_/ or $k =~ /^LOG/){
			$ar[0] =~ s/~/$ENV{'HOME'}/;
			if ($k =~ /^PATH_/ && ! -d "$ar[0]"){
				_die("$k is not directory, please revise your configuration");
			}
			$config{$k} = $ar[0];
		}
		else {
			$config{$k} = \@ar;
		}
	}
	close (READ);

	return %config;
}

1;
