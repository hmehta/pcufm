#!/usr/bin/perl

use strict;
use warnings;

my %debug = debug_level();

sub debug_log {
	my ($lvl,$msg) = @_;
	
	if ($debug{'LOGLEVEL'} <= 0){
		return 1;
	}

	if ($debug{'LOGLEVEL'} < $lvl){
		$msg = "";
	}

	if ($msg) {
		open (WRITE,">>$debug{'LOGFILE'}");
		print WRITE "$msg";
		close (WRITE);
	}

	return 1;
}

sub debug_hash {
	my ($href) = @_;
	my %hash = %{$href};
	
	debug_log("__DEBUG_HASH_\n");
	foreach (keys %hash){
		debug_log("key: $_ value: $hash{$_}\n");
	}
	debug_log("__END_HASH_\n");
}

1;
