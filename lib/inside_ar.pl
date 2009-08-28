#!/usr/bin/perl
# inside_ar

sub inside_key_ar {
	my ($arref, $word) = @_;
	my @ar = @{$arref};
	chomp $word;

	foreach (@ar){
#		debug_log("inside_key_ar: matching '$word' against '$_'\n");
		if ("$word" eq "$_"){
			return 1;
		}
		elsif ($word =~ /^$_$/){
			return 1;
		}
	}
	return 0;
}

sub inside_ar {
	my ($arrayref,$word,$debug) = @_;
	my @ar = @{$arrayref};
	chomp $word;

	foreach (@ar){
		debug_log(2,"inside_ar: '$word' eq '$_'\n") if ($debug);
		if ("$word" eq "$_"){
			return 1;
		}
	}
	return 0;
} # sub inside_ar

1;
