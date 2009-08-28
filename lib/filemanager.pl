#!/usr/bin/perl

use strict;
# for stat
use Fcntl ':mode';
use threads;
use threads::shared;
use File::Copy;
use File::Copy::Recursive qw(rcopy);
use File::Find;
use File::Path;

sub move_filemanager {
	my ($uir,$dir) = @_;
	my %ui = %{$uir};

	%ui = window_size(\%ui,"act");

	if ($dir eq "up"){
		if ($ui{'act'}{'curpos'} > 1){
			$ui{'act'}{'curpos'}--;
		}

		if ($ui{'act'}{'dirpos'} > 0){
			$ui{'act'}{'dirpos'}--;
		}
		# scrolling happens on direction "up" when curpos == 1 and dirpos > 0
		debug_log(3,"move_filemanager: $ui{'act'}{'curpos'} == 1 & $ui{'act'}{'dirpos'} >= 0\n");
		if ($ui{'act'}{'curpos'} == 1 && $ui{'act'}{'dirpos'} >= 0){
			$ui{'act'}{'scrl'} = $ui{'act'}{'dirpos'};
		}
	}
	elsif ($dir eq "down"){
		$ui{'act'}{'curpos'}++ if (($ui{'act'}{'curpos'} < $ui{'act'}{'max_y'}) && ($ui{'act'}{'curpos'} <= $#{$ui{'act'}{'dirs'}}));
		$ui{'act'}{'dirpos'}++ if ($ui{'act'}{'dirpos'} < $#{$ui{'act'}{'dirs'}});

		# scrolling happens on direction "down" when curpos >= y (hasn't been changed yet :)) and dirpos < $#dirs
		debug_log(3,"move_filemanager: $ui{'act'}{'curpos'} >= $ui{'act'}{'max_y'} & $ui{'act'}{'dirpos'} > $ui{'act'}{'max_y'} & $ui{'act'}{'dirpos'} < $#{$ui{'act'}{'dirs'}}\n");
 		if ($ui{'act'}{'curpos'} >= $ui{'act'}{'max_y'} && $ui{'act'}{'dirpos'} > $ui{'act'}{'max_y'}-1 && $ui{'act'}{'dirpos'} <= $#{$ui{'act'}{'dirs'}}){
			$ui{'act'}{'scrl'} = $ui{'act'}{'dirpos'}-$ui{'act'}{'max_y'}+1;
		}
	}

	return %ui;
}

sub make_selection {
	my ($uir,$pos,$pos2) = @_;
	my %ui = %{$uir};

	$pos2 = $pos if (!$pos2);
	for (my $i=$pos;$i<=$pos2;$i++){
		if (inside_ar($ui{'act'}{'selected'},$i)){
			my @ar;
			for (my $j=0;$j<=$#{$ui{'act'}{'selected'}};$j++){
				if (@{$ui{'act'}{'selected'}}[$j] == $i){
					next;
				}
				else {
					push (@ar,@{$ui{'act'}{'selected'}}[$j]);
				}
			}
			$ui{'act'}{'selected'} = \@ar;
		}
		else {
			push(@{$ui{'act'}{'selected'}},$i);
		}
	}	

	return %ui;
}

sub filemanager_chdir {
	my ($uir,$var) = @_;
	my %ui = %{$uir};

	$ui{'act'}{'cwd'} =~ s/\/$//g;
	debug_log(3,"filemanager_chdir: cwd: $ui{'act'}{'cwd'}\n");
	my $new_cwd = $ui{'act'}{'cwd'}."/".@{$ui{'act'}{'dirs'}}[$ui{'act'}{'dirpos'}];
	$new_cwd = $var if ($var);
	if ($new_cwd =~ /~/){
		if ($ENV{'HOME'}){
			$new_cwd =~ s/~/$ENV{'HOME'}/;
		}
		else {
			# guess it..
			debug_log(3,"filemanager_chdir: had to guess $ENV{'USER'} home\n");
			$new_cwd =~ s/~/\/home\/$ENV{'USER'}/;
		}
	}
	
	if ($new_cwd !~ /^\//){
		$new_cwd = "$ui{'act'}{'cwd'}/$new_cwd";
		debug_log(3,"filemanager_chdir: new_cwd had no ^/, now $new_cwd\n");
	}
	
	debug_log(3,"filemanager_chdir: newcwd: $new_cwd\n");
	if ($new_cwd =~ s/[.]+$//g){
		debug_log(3,"filemanager_chdir: removed .. \n");
		my @cwd = split (/\//,$new_cwd);
		debug_log(3,"filemanager_chdir: cwd length $#cwd ");
		$new_cwd = "";
		for (my $i=0;$i<$#cwd;$i++){
			$new_cwd .= "/".$cwd[$i] if ($cwd[$i]);
		}
		$new_cwd = "/" if (!$new_cwd);
	}

	if (-d $new_cwd) {
		$ui{'act'}{'cwd'} = $new_cwd;
		$ui{'act'}{'dirs'} = list_files($ui{'act'}{'cwd'});
	}
	else {
		%ui = fm_output(\%ui,"feh","");
	}
	debug_log(3,"cwd2: $ui{'act'}{'cwd'}\n");

	return %ui;
}

sub progress_bar {
	my ($uir, $done, $total, $ret) = @_;
	my %ui = %{$uir};

	my %bar = (
		'length'	=> $ui{'conf'}{'C_PBAR_LENGTH'},
		# bar decos
		'start_c'	=> $ui{'conf'}{'C_PBAR_PROG_STR'},
		'end_c' 	=> $ui{'conf'}{'C_PBAR_PROG_END'},
		'prog_c' 	=> $ui{'conf'}{'C_PBAR_PROG_IND'},
		'prog_b' 	=> $ui{'conf'}{'C_PBAR_PROG_BAR'},
		'prog_a' 	=> $ui{'conf'}{'C_PBAR_PROG_EMP'},
	);

	my $ratio = $total/($bar{'length'});
	my $percentage = int(($done/$total)*100);
	$total = int($total / $ratio);
	$done = int($done / $ratio);

	my $retbar = $bar{'start_c'};
	for (my $i=0; $i<$done; $i++){
		if ($i == $done-1){
			#print $bar{'prog_c'};
			$retbar .= $bar{'prog_c'};
		}
		else {
			#print $bar{'prog_b'};
			$retbar .= $bar{'prog_b'};
		}
	}
	for (my $i=$done; $i<$total; $i++){
		$retbar .= $bar{'prog_a'};
	}
	if ($ui{'conf'}{'C_PBAR_PERCENTS'} eq "TRUE"){
		$retbar .= $bar{'end_c'};
		$retbar .= $percentage."%";
	}
	else {
		$retbar .= $bar{'end_c'};
	}
	status_message(\%ui,"",0,$retbar);

	return %ui if (!$ret);
	return $retbar;
}

sub get_fileinfo {
	my ($uir,$i) = @_;
	my %ui = %{$uir};

	my $filename;
	if (!$i){
		$filename = "$ui{'act'}{'cwd'}/@{$ui{'act'}{'dirs'}}[$ui{'act'}{'dirpos'}]";
	}
	else {
		$filename = "$ui{'act'}{'cwd'}/@{$ui{'act'}{'dirs'}}[$i]";
	}

	if ( my($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = lstat($filename)) {
		my $user = getpwuid($uid);
		my $group = getgrgid($gid);
			
		my $permissions = sprintf("%04o", S_IMODE($mode));

		my $filesize = get_filesize(\%ui);

		# get rid of cwd
		$filename =~ s/^.*\///g;
		my $ret = $ui{'conf'}{'C_FILEINFO'};
		$ret =~ s/_/ /g;
		$ret =~ s/PERMS/$permissions/g;
	        $ret =~ s/USER/$user/g;
		$ret =~ s/GROUP/$group/g;
		$ret =~ s/FILENAME/$filename/g;
	        $ret =~ s/FILESIZE/$filesize/g;
		return $ret;
	} else {
		return 0;
	}
}

sub get_filesize {
	my ($uir,$i,$act) = @_;
	my %ui = %{$uir};

	if (!$act){
		$act = "act";
	}

	my $filesize;
        if ($i){
		return "directory" if (-d "$ui{$act}{'cwd'}/@{$ui{$act}{'dirs'}}[$i]");
		$filesize = -s "$ui{$act}{'cwd'}/@{$ui{$act}{'dirs'}}[$i]";
	}
	else {
		return "directory" if (-d "$ui{$act}{'cwd'}/@{$ui{$act}{'dirs'}}[$ui{$act}{'dirpos'}]");
		$filesize = -s "$ui{$act}{'cwd'}/@{$ui{$act}{'dirs'}}[$ui{$act}{'dirpos'}]";
	}

	return "" if (!$filesize);

	# change this if you like 10^3 more ..
	my $k = 1024;

	my $unit = 0;
	while ($filesize >= 100){
		$filesize = $filesize/$k;
		$unit++;
	}
	my %units = (
		0 => "b",
		1 => "Kb",
		2 => "Mb",
		3 => "Gb",
		4 => "Tb", # geez dude.. :>
	);
	# trim the floating number a bit :)
	if (length($filesize) >= 3){
		$filesize = substr($filesize,0,4);
	}

#	debug_log(3,"get_filesize: got size $filesize$units{$unit}\n");
	$filesize .= $units{$unit};
	my $ret = sprintf "%+5s",$filesize;
	return $ret;
}

sub list_files {
	my ($dir) = @_;

	my $err;
	opendir (DIR, "$dir") or $err = $!;
	my @dirs;
	if ($err){ 
		push (@dirs,"$err");
	}
	else {
		@dirs = readdir(DIR);
		closedir(DIR);
	}

	sort (@dirs);
	chomp @dirs;

	my @c_dir;
	foreach (sort @dirs){
		next if ($_ =~ s/^(\.|\.\.)//g);
		push (@c_dir,$_);
	}
	unshift (@c_dir, "..");

	return \@c_dir if ($#c_dir >= 0);
}

sub fm_output {
	my ($uir, $cmd, $args) = @_;
	my %ui = %{$uir};

	my $file = "$ui{'act'}{'cwd'}/@{$ui{'act'}{'dirs'}}[$ui{'act'}{'dirpos'}]";
	if ( -f "$file"){
		my $outp = `$cmd $args "$file"`;
		prompt_message(\%ui,$outp);
		sleep 2;
	}
	return %ui;
}

sub validate_filename {
	my ($filename) = @_;

	if ($filename =~ m/\.\.$/){
		return 0;
	}
	return 1;
}	

sub fm_rm {
	my ($uir) = @_;
	my %ui = %{$uir};

	my @src;
	if ($#{$ui{'act'}{'selected'}} > -1){
		debug_log(2,"fm_rm: got $ui{'act'}{'selected'}\n");
		foreach (@{$ui{'act'}{'selected'}}){
			push (@src, "$ui{'act'}{'cwd'}/@{$ui{'act'}{'dirs'}}[$_]");
		}
	}
	else {
		push (@src, "$ui{'act'}{'cwd'}/@{$ui{'act'}{'dirs'}}[$ui{'act'}{'dirpos'}]");
	}

	debug_log(2,"fm_rm: for array size $#src\n");

	foreach (@src){
		my $error = 0;
		if ($_ =~ m/\.\.$/ && $ui{'conf'}{'C_PROTECT_DOTS'} eq "TRUE"){
			error_message(\%ui,"protected selection ..");
			next; 
		}

		if ($ui{'conf'}{'C_RMTREE'} eq "TRUE") {
			debug_log(2,"fm_rm: rmtree $_\n");
			rmtree("$_", {error => \my $err});
			for my $diag (@$err){
				my ($file, $message) = each %$diag;
				debug_log(1,"fm_rm: rmtree failed for $file: $message\n");
				# capture first error
				$error = $message if (!$error);
			}
		}
		else {
			if (-f "$_"){
				debug_log(2,"fm_rm: unlink $_\n");
				unlink("$_") or debug_log(1,"fm_rm: unlink($_) failed $!\n") and $error = $_;
			}
			elsif (-d "$_"){
				debug_log(2,"fm_rm: rmdir $_\n");
				rmdir("$_") or debug_log(1,"fm_rm: rmdir($_) failed $!\n") and $error = $_;
			}
		}

		if (!$error) {
			prompt_message(\%ui, "deleted $_");
		}
		else {
			error_message(\%ui,"$error: $_");
		}
		usleep($ui{'usleep'});
	}

	delete $ui{'act'}{'selected'};
	%ui = refresh_filemanagers(\%ui);

	return %ui;
}

sub real_filesize {
	my ($filename) = @_;
	my $filesize = 0;
	find(sub{ $filesize += -s if $_ }, "$filename");
	return $filesize;
}

sub fm_copy {
	my ($uir) = @_;
	my %ui = %{$uir};

	my ($dest,$act,@src);
	
	if ($#{$ui{'act'}{'selected'}} > -1){
		debug_log(2,"fm_copy: got $ui{'act'}{'selected'}\n");
		foreach (@{$ui{'act'}{'selected'}}){
			push (@src, "$ui{'act'}{'cwd'}/@{$ui{'act'}{'dirs'}}[$_]");
		}
	}
	else {
		push (@src, "$ui{'act'}{'cwd'}/@{$ui{'act'}{'dirs'}}[$ui{'act'}{'dirpos'}]");
	}

	if ($ui{'act'}{'name'} eq "LEFT"){
		$dest = "$ui{'right'}{'cwd'}/";   
		$act = "left";
	}	
	elsif ($ui{'act'}{'name'} eq "RIGHT"){
		$dest = "$ui{'left'}{'cwd'}/";
		$act = "right";
	}
	debug_log(2,"fm_copy: making copy: for array size $#src -> $dest\n");

	foreach (@src){
		if ($_ =~ m/\.\.$/ && $ui{'conf'}{'C_PROTECT_DOTS'} eq "TRUE"){
			error_message(\%ui,"protected selection ..");
			next; 
		}

		my $destfile = $_;
		$destfile =~ s/^.*\///;
		$destfile = $dest.$destfile;

		debug_log(2,"fm_copy: $_ -> $destfile\n");
		my $tot = real_filesize("$_");

		my $thr = threads->create(sub {
			rcopy("$_","$destfile") or debug_log(1,"fm_copy: failed $!\n") && error_message(\%ui,"copy failed: $!");
			return $!;
		});
		my $thr2 = threads->create(sub {
			my $done = 0;
			while ($done != $tot){
				usleep(5000);
				$done = real_filesize("$destfile");
#				debug_log(2,"fm_copy: $done/$tot\n");
				%ui = progress_bar(\%ui,"$done","$tot",0);
				if (!$thr->is_running()){
					last;
				}
			}
		});
		
		my $var = $thr->join();
		$thr2->join();

		if (!$var){
			prompt_message(\%ui,"copied $_");
		}

		debug_log(2,"fm_copy: copying done\n");
	}

	%ui = refresh_filemanagers(\%ui);
	return %ui;
}

sub fm_move {
	my ($uir) = @_;
	my %ui = %{$uir};

	my ($dest,$act,@src);
	
	if ($#{$ui{'act'}{'selected'}} > -1){
		debug_log(2,"fm_move: got $ui{'act'}{'selected'}\n");
		foreach (@{$ui{'act'}{'selected'}}){
			push (@src, "$ui{'act'}{'cwd'}/@{$ui{'act'}{'dirs'}}[$_]");
		}
	}
	else {
		push (@src, "$ui{'act'}{'cwd'}/@{$ui{'act'}{'dirs'}}[$ui{'act'}{'dirpos'}]");
	}

	if ($ui{'act'}{'name'} eq "LEFT"){
		$dest = "$ui{'right'}{'cwd'}/";   
		$act = "left";
	}	
	elsif ($ui{'act'}{'name'} eq "RIGHT"){
		$dest = "$ui{'left'}{'cwd'}/";
		$act = "right";
	}
	debug_log(2,"fm_move: making move: for array size $#src -> $dest\n");

	foreach (@src){
		if ($_ =~ m/\.\.$/ && $ui{'conf'}{'C_PROTECT_DOTS'} eq "TRUE"){
			error_message(\%ui,"protected selection ..");
			next; 
		}

		my $destfile = $_;
		$destfile =~ s/^.*\///;
		$destfile = $dest.$destfile;

		my $err;
		move("$_","$destfile") or $err = $!;
		if (!$err){
			debug_log(2,"fm_move: move $_ -> $dest succesful\n");
			prompt_message(\%ui,"moved $_");
		}
		else {
			debug_log(1,"fm_move: move $_ $destfile failed: $!\n");
		       	error_message(\%ui,"move failed: $!");
		}
	}

	%ui = refresh_filemanagers(\%ui);
	return %ui;
}

1;
