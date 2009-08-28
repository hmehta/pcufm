#!/usr/bin/perl

use strict;
use Curses;


require ("lib/readconfig.pl");
#require ("lib/filemanager.pl");
#my %config = read_config();

sub redraw_ui {
	my ($uir) = @_;
	my %ui = %{$uir};

	$ui{'main'}{'win'}->move(0,0);	
	# main window (canvas + bottom borders)
	%ui = attr_on(\%ui,"main");
	$ui{'main'}{'win'}->box(0,0);
        %ui = window_size(\%ui,"main");
	%ui = attr_off(\%ui,"main");
	
	# left filemanager (src)
	$ui{'left'}{'win'}->delwin();
	$ui{'left'}{'win'} = newwin($LINES-3,($COLS/2)+1,0,0);
	%ui = attr_on(\%ui,"left","MAIN");
        %ui = window_size(\%ui,"left");
	$ui{'left'}{'win'}->border(get_acs("ACS_VLINE"),get_acs("ACS_VLINE"),get_acs("ACS_HLINE"),get_acs("ACS_HLINE"),get_acs("ACS_ULCORNER"),get_acs("ACS_TTEE"),get_acs("ACS_LTEE"),get_acs("ACS_BTEE"));
	%ui = attr_off(\%ui,"left","MAIN");
	$ui{'left'}{'selection_width'} = (($COLS/2)+1)-4;

	# right filemanager (dest)
	$ui{'right'}{'win'}->delwin();
	$ui{'right'}{'win'} = newwin($LINES-3,($COLS/2),0,$COLS/2);
	%ui = attr_on(\%ui,"right","MAIN");
        %ui = window_size(\%ui,"right");
	$ui{'right'}{'win'}->border(get_acs("ACS_VLINE"),get_acs("ACS_VLINE"),get_acs("ACS_HLINE"),get_acs("ACS_HLINE"),get_acs("ACS_TTEE"),get_acs("ACS_URCORNER"),get_acs("ACS_BTEE"),get_acs("ACS_RTEE"));
	%ui = attr_off(\%ui,"right","MAIN");
	$ui{'right'}{'selection_x'} = ($COLS/2)+2;
	$ui{'right'}{'selection_width'} = ($COLS/2)-4;


	# prompt for commands
	$ui{'prompt'}{'win'}->delwin();
	$ui{'prompt'}{'win'} = newwin(1,$COLS-2,$LINES-2,1);
	%ui = attr_on(\%ui,"prompt","PROMPT");
	for (my $i=0;$i<=$COLS;$i++){
		$ui{'prompt'}{'win'}->addch(0,$i," ");
	}
	$ui{'prompt'}{'win'}->keypad(1);
        %ui = window_size(\%ui,"prompt");

	# status bar
	$ui{'status'}{'win'}->delwin();
	$ui{'status'}{'win'} = newwin(1,$COLS-2,$LINES-3,1);
        %ui = window_size(\%ui,"status");

	# draw filemanagers for the first time
	$ui{'act'} = $ui{'right'};
	%ui = draw_filemanager(\%ui);

	$ui{'act'} = $ui{'left'};
	%ui = draw_filemanager(\%ui);

	%ui = refresh_filemanagers(\%ui);

	return %ui;
}

sub draw_text_window {
	my ($uir,$dir) = @_;
	my %ui = %{$uir};

	%ui = attr_on(\%ui,"main");
	$ui{'main'}{'win'}->box(0,0);
	%ui = attr_off(\%ui,"main");
	$ui{'main'}{'win'}->refresh();
	$ui{'text'}{'win'} = newwin($LINES-2,$COLS-4,1,2);
	%ui = window_size(\%ui,"text");
#	%ui = attr_on(\%ui,"text","MAIN");
#	$ui{'text'}{'win'}->box(0,0);
#	%ui = attr_off(\%ui,"text","MAIN");

	%ui = attr_on(\%ui,"text","LEFT");
	$ui{'text'}{'begin'} = 1 if (!$dir);
	$ui{'text'}{'begin'}-- if ($dir eq "down");
	$ui{'text'}{'begin'}++ if ($dir eq "up");
	$ui{'text'}{'begin'} = 0 if ($ui{'text'}{'begin'} > 0);
	$ui{'text'}{'extrarows'} = 0 if (!$ui{'text'}{'extrarows'});
	my $maxy = $ui{'text'}{'max_y'} - $#{$ui{'text'}{'contents'}} - $ui{'text'}{'extrarows'} - 2;
	debug_log(2,"draw_text_window: maxy: $maxy max_y: $ui{'text'}{'max_y'}\n");
	$ui{'text'}{'begin'} = $maxy if ($ui{'text'}{'begin'} < $maxy);
	$ui{'text'}{'row'} = $ui{'text'}{'begin'};

	foreach (@{$ui{'text'}{'contents'}}){
		chomp $_;
		if (length($_) >= $ui{'text'}{'max_x'}){
			$ui{'text'}{'win'}->addnstr($ui{'text'}{'row'},1,"$_",$ui{'text'}{'max_x'});
			
			my $str = substr($_,$ui{'text'}{'max_x'});
			while (length($str) > $ui{'text'}{'max_x'}){
				$ui{'text'}{'row'}++;
				$ui{'text'}{'extrarows'}++;
				$ui{'text'}{'win'}->addnstr($ui{'text'}{'row'},1,"$str",$ui{'text'}{'max_x'});
				my $str = substr($_,$ui{'text'}{'max_x'});
			}
			$ui{'text'}{'row'}++;	
			$ui{'text'}{'win'}->addnstr($ui{'text'}{'row'},1,"$str",$ui{'text'}{'max_x'});
		}
		else {
			$ui{'text'}{'win'}->addstr($ui{'text'}{'row'},1,"$_");
		}
		$ui{'text'}{'row'}++;
	}	
	%ui = attr_off(\%ui,"text","LEFT");
	$ui{'text'}{'win'}->refresh();

	return %ui;
}

sub refresh_filemanagers {
	my ($uir) = @_;
	my %ui = %{$uir};

	my $act = lc($ui{'act'}{'name'});

	$ui{$act} = $ui{'act'};
	if ($act eq "left"){
		$ui{'act'} = $ui{'right'};
		$act = "right";
	}
	elsif ($act eq "right"){
		$ui{'act'} = $ui{'left'};
		$act = "left";
	}
	%ui = filemanager_chdir(\%ui,$ui{'act'}{'cwd'});
	%ui = draw_filemanager(\%ui,"noreset");

	$ui{$act} = $ui{'act'};
	if ($act eq "left"){
		$ui{'act'} = $ui{'right'};
		$act = "right";
	}
	elsif ($act eq "right"){
		$ui{'act'} = $ui{'left'};
		$act = "left";
	}
	
	%ui = filemanager_chdir(\%ui,$ui{'act'}{'cwd'});
	%ui = draw_filemanager(\%ui,"noreset");

	return %ui;
}

sub status_message {
	my ($uir,$msg,$offset,$pbar) = @_;
	my %ui = %{$uir};

	%ui = attr_on(\%ui,"status","STATUS");
	debug_log(3,"status_message: status greybg: $ui{'conf'}{'COLOR_STATUS_GREYBG'} offset: $offset color_status: $ui{'colors'}{'COLOR_STATUS'}\n");

	if (!$offset){
		debug_log(3,"status_message: clearing to end of line\n");
		for (my $i=0;$i<$ui{'status'}{'max_x'}+2;$i++){
			$ui{'status'}{'win'}->addch(0,$i," ");
		}
		$offset = 0;
	}
	$ui{'status'}{'win'}->refresh();
	my $act_c = substr($ui{'act'}{'name'},0,1);
	my $pbarsize = $ui{'conf'}{'C_PBAR_LENGTH'};
	if (!$pbar){
		$pbar = progress_bar(\%ui,0,100,1);
	}
	debug_log(3,"status_message: pbar: '$pbar'\n");

	my $fileinfo = get_fileinfo(\%ui);
	debug_log(3,"status_message: fileinfo: $fileinfo\n");

	if ($#{$ui{'act'}{'selected'}} >= 0){
		$fileinfo = $#{$ui{'act'}{'selected'}}+1 . " file(s) selected";
	}

#	$fileinfo = "L: $ui{'left'} R: $ui{'right'} A: $ui{'act'}";
#	$fileinfo = "max_n/real cols: $ui{'main'}{'max_x'}/$COLS lines: $ui{'main'}{'max_y'}/$LINES";

	my $status = $ui{'conf'}{'C_STATUS_FORMAT'};
	$status =~ s/_/ /g;
	$status =~ s/ACT/$act_c/g;
	$status =~ s/PBAR/$pbar/g;
	$status =~ s/FILEINFO/$fileinfo/g;
	$msg = "$status $msg";

	debug_log(3,"status_message: adding msg $msg\n");	
	$ui{'status'}{'win'}->addnstr(0,$offset,"$msg",$ui{'status'}{'max_x'}+2);
	$ui{'status'}{'win'}->refresh();
	
	return %ui;
}

sub error_message {
	my ($uir,$msg) = @_;
	my %ui = %{$uir};

	chomp $msg;

	my ($y,$x);
	$ui{'prompt'}{'win'}->getmaxyx($y,$x);
	$ui{'prompt'}{'win'}->move(0,0);
	%ui = attr_on(\%ui,"prompt","ERROR");
	$ui{'prompt'}{'win'}->addnstr("ERROR: $msg",$x);
	for (my $i=length("ERROR: $msg");$i<$x;$i++){
		$ui{'prompt'}{'win'}->addch(0,$i," ");
	}
	%ui = attr_off(\%ui,"prompt","ERROR");
	$ui{'prompt'}{'win'}->refresh();

	return %ui;
}

sub prompt_message {
	my ($uir,$msg) = @_;
	my %ui = %{$uir};

	my ($y,$x);
	$ui{'prompt'}{'win'}->move(0,0);
	%ui = attr_on(\%ui,"prompt","PROMPT");
	$ui{'prompt'}{'win'}->addnstr(0,0,"$msg",$ui{'prompt'}{'max_x'});
	for (my $i=length($msg);$i<$ui{'prompt'}{'max_x'}+2;$i++){
		$ui{'prompt'}{'win'}->addch(0,$i," ");
	}
	$ui{'prompt'}{'win'}->refresh();

	return %ui;
}

sub draw_dirs {
	my ($uir) = @_;
	my %ui = %{$uir};

	# process through as many dirs that can suit the window
	# starting from $ui{'act'}{'scrl'} and stopping at $ui{'act'}{'max_y'}
	#
	# this is to loop all entries in the $ui{'act'}{'win'}
	# => always write entries when draw_filemanager is called
	# prompting the directory is done elsewhere

	my $max;
	if ($ui{'act'}{'max_y'} > ($#{$ui{'act'}{'dirs'}}+1)){
		$max = $#{$ui{'act'}{'dirs'}}+1;
	}
	else {
		$max = $ui{'act'}{'max_y'};
	}
	debug_log(3,"draw_dirs: max: $max / $#{$ui{'act'}{'dirs'}}\n");
	for (my $i=1;$i<=$max;$i++){
		# clear previous entries for proper scrolling
		$ui{'act'}{'win'}->move($i,1);
		%ui = attr_on(\%ui,"act","$ui{'act'}{'name'}");
		for (my $j=1;$j<$ui{'act'}{'max_x'};$j++){
			$ui{'act'}{'win'}->addch($i,$j,' ');
		}
		%ui = attr_off(\%ui,"act","$ui{'act'}{'name'}");
		# directory indicator
		if ($ui{'conf'}{'C_DIR_INDICATOR'}){
			if (-d "$ui{'act'}{'cwd'}/$ui{'act'}{'dirs'}[$ui{'act'}{'scrl'}+$i-1]"){
				%ui = attr_on(\%ui,"act","DIR_IND");
				$ui{'act'}{'win'}->addch($i,1,$ui{'conf'}{'C_DIR_INDICATOR'}) if ($ui{'act'}{'dirs'}[$ui{'act'}{'scrl'}] && "$ui{'act'}{'dirs'}[$ui{'act'}{'scrl'}+$i-1]" ne ".." );
				%ui = attr_off(\%ui,"act","DIR_IND");
			}
		}

		if (inside_ar($ui{'act'}{'selected'},$ui{'act'}{'scrl'}+$i-1)){
			%ui = attr_on(\%ui,"act","SELECTION");
		}
		else {
			%ui = attr_on(\%ui,"act","$ui{'act'}{'name'}");
		}

		# print the entry
		my ($str, $fs) = get_entry(\%ui,$ui{'act'}{'scrl'}+$i-1);
		if (!$fs){
			$ui{'act'}{'win'}->addnstr($i,2,"$str",$ui{'act'}{'max_x'}-2);
		}
		else {
			$ui{'act'}{'win'}->addnstr($i,2,"$str",$ui{'act'}{'max_x'}-9);
			for (my $j=length($str)+2; $j<$ui{'act'}{'max_x'}-6;$j++){
				$ui{'act'}{'win'}->addch($i,$j," ");
			}
			$ui{'act'}{'win'}->addnstr($i,$ui{'act'}{'max_x'}-6,"$fs",6);
		}

		if (inside_ar($ui{'act'}{'selected'},$ui{'act'}{'scrl'}+$i-1)){
			%ui = attr_off(\%ui,"act","SELECTION");
		}
		else {
			%ui = attr_off(\%ui,"act","$ui{'act'}{'name'}");
		}

		# forcily exit the for-hook on boundary
		last if ($i == $ui{'act'}{'max_y'});
	}
	# fill with blanks if window is bigger than directory listing
	if ($max < $ui{'act'}{'max_y'}){
		for (my $i=$max+1;$i<=$ui{'act'}{'max_y'};$i++){
			%ui = attr_on(\%ui,"act","$ui{'act'}{'name'}");

			# clear dir indicators and possible filesizes as well
			# scrollbar is cleaned in draw_scrollbar()
			for (my $j=1;$j<=$ui{'act'}{'max_x'}-1;$j++){
				$ui{'act'}{'win'}->addch($i,$j," ");
			}
			%ui = attr_off(\%ui,"act","$ui{'act'}{'name'}");
		}
	}

	return %ui;
}

sub window_size {
	my ($uir,$win) = @_;

	my %ui = %{$uir};	
	my ($y,$x);
	$ui{$win}{'win'}->getmaxyx($y,$x);
	$ui{$win}{'max_x'} = $x;
	$ui{$win}{'max_y'} = $y;
	#substract borders
	if ($win ne "main"){
		$ui{$win}{'max_x'} -= 2;
		$ui{$win}{'max_y'} -= 2;
	}

	return %ui;
}

sub attr_on {
	my ($uir,$win,$fwin,$obj) = @_;
	my %ui = %{$uir};

	$obj = "win" if (!$obj);

	my $cwin = uc($win);
	if ($fwin){
		$fwin = uc($fwin);
		$ui{$win}{$obj}->attron(get_attr("A_REVERSE")) if ($ui{'conf'}{"COLOR_$fwin\_GREYBG"});
		$ui{$win}{$obj}->attron(COLOR_PAIR($ui{'colors'}{"COLOR_$fwin"})|get_attr($ui{'attributes'}{"COLOR_$fwin"}));
	}
	else {
		$ui{$win}{$obj}->attron(get_attr("A_REVERSE")) if ($ui{'conf'}{"COLOR_$cwin\_GREYBG"});
		$ui{$win}{$obj}->attron(COLOR_PAIR($ui{'colors'}{"COLOR_$cwin"})|get_attr($ui{'attributes'}{"COLOR_$cwin"}));
	}

	return %ui;
}

sub attr_off {
	my ($uir,$win,$fwin,$obj) = @_;
	my %ui = %{$uir};

	$obj = "win" if (!$obj);

	my $cwin = uc($win);
	if ($fwin){
		$fwin = uc($fwin);
		$ui{$win}{$obj}->attroff(get_attr("A_REVERSE")) if ($ui{'conf'}{"COLOR_$fwin\_GREYBG"});
		$ui{$win}{$obj}->attroff(COLOR_PAIR($ui{'colors'}{"COLOR_$fwin"})|get_attr($ui{'attributes'}{"COLOR_$fwin"}));
	}
	else {
		$ui{$win}{$obj}->attroff(get_attr("A_REVERSE")) if ($ui{'conf'}{"COLOR_$cwin\_GREYBG"});
		$ui{$win}{$obj}->attroff(COLOR_PAIR($ui{'colors'}{"COLOR_$cwin"})|get_attr($ui{'attributes'}{"COLOR_$cwin"}));
	}

	return %ui;
}

sub init_ui {
	my (%ui);#,%main,%left,%right,%status,%prompt);
	%{$ui{'conf'}} = read_config();

	# main window (canvas + bottom borders)
	$ui{'main'}{'win'} = init_curses();
	%ui = init_color_pairs(\%ui);
	debug_log(3,"init_ui: main win greybg: $ui{'conf'}{'COLOR_MAIN_GREYBG'}\n");
	%ui = attr_on(\%ui,"main");
	$ui{'main'}{'win'}->box(0,0);
        %ui = window_size(\%ui,"main");
	%ui = attr_off(\%ui,"main");

	# left filemanager (src)
       	$ui{'left'}{'win'} = newwin($LINES-3,($COLS/2)+1,0,0);
	debug_log(3,"init_ui: ".$ui{'colors'}{'COLOR_LEFT'}."\n");
	%ui = attr_on(\%ui,"left","main");
        %ui = window_size(\%ui,"left","main");
	$ui{'left'}{'win'}->border(get_acs("ACS_VLINE"),get_acs("ACS_VLINE"),get_acs("ACS_HLINE"),get_acs("ACS_HLINE"),get_acs("ACS_ULCORNER"),get_acs("ACS_TTEE"),get_acs("ACS_LTEE"),get_acs("ACS_BTEE"));
	%ui = attr_off(\%ui,"left");
	$ui{'left'}{'dirs'} = list_files($ui{'conf'}{'PATH_LEFT'});
	$ui{'left'}{'cwd'} = $ui{'conf'}{'PATH_LEFT'};
	$ui{'left'}{'cwd'} =~ s/\/$//g;
	debug_log(3,"init_ui: left cwd: $ui{'left'}{'cwd'}\n");
	$ui{'left'}{'curpos'} = 1;
	$ui{'left'}{'dirpos'} = 0;
	$ui{'left'}{'selection_x'} = 2;
	$ui{'left'}{'selection_width'} = (($COLS/2)+1)-4;
	$ui{'left'}{'name'} = "LEFT";

	# right filemanager (dest)
	my $stretch = 0;
	if (($COLS/2)%2){
		$stretch = 1;
	}
	$ui{'right'}{'win'} = newwin($LINES-3,($COLS/2)+$stretch,0,$COLS/2);
	%ui = attr_on(\%ui,"right","main");
	#%ui = attr_on(\%ui,"right","MAIN");

	$ui{'right'}{'win'}->border(get_acs("ACS_VLINE"),get_acs("ACS_VLINE"),get_acs("ACS_HLINE"),get_acs("ACS_HLINE"),get_acs("ACS_TTEE"),get_acs("ACS_URCORNER"),get_acs("ACS_BTEE"),get_acs("ACS_RTEE"));
	#%ui = attr_off(\%ui,"right","MAIN");

	%ui = attr_off(\%ui,"right","main");
	$ui{'right'}{'dirs'} = list_files($ui{'conf'}{'PATH_RIGHT'});
	debug_log(3,"init_ui: #ui(right)(dirs): $#{$ui{'right'}{'dirs'}}\n");
	$ui{'right'}{'cwd'} = $ui{'conf'}{'PATH_RIGHT'};
	$ui{'right'}{'cwd'} =~ s/\/$//g;
	$ui{'right'}{'curpos'} = 1;
	$ui{'right'}{'dirpos'} = 0;
	$ui{'right'}{'selection_x'} = ($COLS/2)+2;
	$ui{'right'}{'selection_width'} = ($COLS/2)-4+$stretch;
        %ui = window_size(\%ui,"right");
	$ui{'right'}{'name'} = "RIGHT";


	# prompt for commands
	$ui{'prompt'}{'win'} = newwin(1,$COLS-2,$LINES-2,1);
	%ui = attr_on(\%ui,"prompt");
#	debug_log(3,"init_ui: prompt attr: $ui{'attributes'}{'COLOR_PROMPT'}|get_attr($ui{'attributes'}{'COLOR_PROMPT_REV'})\n");
	for (my $i=0;$i<=$COLS;$i++){
		$ui{'prompt'}{'win'}->addch(0,$i," ");
	}
	$ui{'prompt'}{'win'}->keypad(1);
        %ui = window_size(\%ui,"prompt");

	# status bar
	$ui{'status'}{'win'} = newwin(1,$COLS-2,$LINES-3,1);
        %ui = window_size(\%ui,"status");
	
	%ui = refresh_all(\%ui);
	# draw filemanagers for the first time
	$ui{'act'} = $ui{'right'};
	%ui = filemanager_chdir(\%ui,$ui{'right'}{'cwd'});
	%ui = draw_filemanager(\%ui);

	$ui{'act'} = $ui{'left'};
	%ui = filemanager_chdir(\%ui,$ui{'left'}{'cwd'});
	%ui = draw_filemanager(\%ui);
	
	return %ui;
}

sub draw_scrollbar {
	my ($uir) = @_;
	my %ui = %{$uir};
	
	# draw borders 
	%ui = attr_on(\%ui,"act","MAIN");

	$ui{'act'}{'win'}->addch(0,$ui{'act'}{'max_x'},get_acs("ACS_HLINE"));
	$ui{'act'}{'win'}->addch($ui{'act'}{'max_y'}+1,$ui{'act'}{'max_x'},get_acs("ACS_HLINE"));
	%ui = attr_off(\%ui,"act","MAIN");

	# draw scrollbar
	if ($#{$ui{'act'}{'dirs'}} > $ui{'act'}{'max_y'}) { 
		my $ratio = $#{$ui{'act'}{'dirs'}}/($ui{'act'}{'max_y'});
		# i liek 'em int and round
		my $sby = int(($ui{'act'}{'dirpos'}/$ratio) + 0.5);
		$sby++ if (!$sby);
		debug_log(3,"draw_scrollbar: drawing to sby: $sby on $ratio with scrl $ui{'act'}{'scrl'}\n");
		# up arrow
		if ($ui{'act'}{'dirpos'}>0){
		%ui = attr_on(\%ui,"act","SB_UP");
		$ui{'act'}{'win'}->addch(0,$ui{'act'}{'max_x'},get_acs($ui{'conf'}{'SB_UP'}));
		%ui = attr_off(\%ui,"act","SB_UP");
		}

		# background
		%ui = attr_on(\%ui,"act","SB_BG");

		for (my $i=1;$i<=$ui{'act'}{'max_y'};$i++){
#			debug_log(3,"sb bg is \"$ui{'conf'}{'SB_BG'}\" wat?\n");
			$ui{'act'}{'win'}->addch($i,$ui{'act'}{'max_x'},get_acs("$ui{'conf'}{'SB_BG'}"));
		}
		%ui = attr_off(\%ui,"act","SB_BG");


		# indicator
		%ui = attr_on(\%ui,"act","SB_IND");
		$ui{'conf'}{'SB_INDICATOR'} =~ s/\"//g;
		$ui{'act'}{'win'}->addch($sby,$ui{'act'}{'max_x'},get_acs($ui{'conf'}{'SB_INDICATOR'}));
		%ui = attr_off(\%ui,"act","SB_IND");

		# down arrow
		if($#{$ui{'act'}{'dirs'}} > $ui{'act'}{'max_y'} && $ui{'act'}{'dirpos'} != $#{$ui{'act'}{'dirs'}}) {
			%ui = attr_on(\%ui,"act","SB_DOWN");
			$ui{'act'}{'win'}->addch($ui{'act'}{'max_y'}+1,$ui{'act'}{'max_x'},get_acs($ui{'conf'}{'SB_DOWN'}));
			%ui = attr_off(\%ui,"act","SB_DOWN");
		}
	}
	else {
		#debug_log(3,"draw_scrollbar: my pair = $pair\n");
		%ui = attr_on(\%ui,"act","$ui{'act'}{'name'}");
		for (my $i=1;$i<=$ui{'act'}{'max_y'};$i++){
			$ui{'act'}{'win'}->addch($i,$ui{'act'}{'max_x'}," ");
		}
		%ui = attr_off(\%ui,"act","$ui{'act'}{'name'}");
	}

	return %ui;
}

sub draw_filemanager {
	my ($uir,$direction) = @_;
	my %ui = %{$uir};

	%ui = window_size(\%ui,"act");

	debug_log(4,"--draw_filemanager event--\n");
#	debug_log(4,"act: $direction cp: $ui{'act'}{'curpos'} dp: $ui{'act'}{'dirpos'}/$#{$ui{'act'}{'dirs'}}\n");

	debug_log(4,"chwin: inside d_fm: #ui(right)(dirs): $#{$ui{'right'}{'dirs'}}\n");

	if ($direction eq "up" or $direction eq "down"){
		%ui = move_filemanager(\%ui,$direction);
	}
	elsif ($direction eq "pgup"){
		for (my $i=1;$i<$ui{'act'}{'max_y'};$i++){
			%ui = move_filemanager(\%ui,"up");
		}

	}
	elsif ($direction eq "pgdown"){
		for (my $i=1;$i<$ui{'act'}{'max_y'};$i++){
			%ui = move_filemanager(\%ui,"down");
		}

	}
	elsif ($direction eq "noreset") {
		# boobs
	}
	else {
		$ui{'act'}{'dirpos'} = 0;
		$ui{'act'}{'curpos'} = 1;
	}

	# limit: 0 <= dirpos >= $#{$ui{'act'}{'dirs'}}
	# this is for determining the cell from which to start while listing dir contents
	# sanity check for dirpos boundaries
	$ui{'act'}{'dirpos'} = $#{$ui{'act'}{'dirs'}} if ($ui{'act'}{'dirpos'} > $#{$ui{'act'}{'dirs'}});	
	$ui{'act'}{'dirpos'} = 0 if ($ui{'act'}{'dirpos'} < 0);

#	if ($ui{'act'}{'curpos'} >= $#{$ui{'act'}{'dirs'}}){
#		$ui{'act'}{'curpos'} = $#{$ui{'act'}{'dirs'}};
#		$ui{'act'}{'dirpos'} = $ui{'act'}{'curpos'};
#	}

	debug_log(4,"now: $direction cp: $ui{'act'}{'curpos'} dp: $ui{'act'}{'dirpos'}/$#{$ui{'act'}{'dirs'}}\n");

	# limit: 1 <= curpos >= $LINES-5
	# this is for drawing selection within the filemanager-window
	if ($ui{'act'}{'curpos'} > $ui{'act'}{'max_y'}){
		debug_log(4,"tried to override window-size with $ui{'act'}{'curpos'} > $ui{'act'}{'max_y'}\n");
		$ui{'act'}{'curpos'} = $ui{'act'}{'max_y'};
	}

	# draw caption
	$ui{'act'}{'win'}->move(0,2);
	%ui = attr_on(\%ui,"act","CAPTION");

	$ui{'act'}{'win'}->addnstr(0,2,"$ui{'act'}{'cwd'}",$ui{'act'}{'max_x'});
	%ui = attr_off(\%ui,"act","CAPTION");

#	debug_log(4,"now: $ui{'act'}{'cwd'} length: ".length($ui{'act'}{'cwd'})."\n");

	%ui = attr_on(\%ui,"act","MAIN");

	for (my $i=length($ui{'act'}{'cwd'})+2;$i<$ui{'act'}{'max_x'};$i++){
		$ui{'act'}{'win'}->addch(0,$i,get_acs("ACS_HLINE"));
	}

	%ui = attr_off(\%ui,"act","MAIN");

	debug_log(4,"curpos: $ui{'act'}{'curpos'}\n");
	%ui = draw_dirs(\%ui);
	debug_log(4,"pcufm: after draw_dirs: #ui(right)(dirs): $#{$ui{'right'}{'dirs'}}\n");
	%ui = draw_scrollbar(\%ui);
	$ui{'act'}{'win'}->refresh();
	%ui = draw_selection_bars(\%ui);

	debug_log(4,"--draw_filemanager end_event--\n");

	%ui = status_message(\%ui,"",0,"");
	%ui = refresh_all(\%ui);
	return %ui; 
}

sub draw_selection_bars {
	my ($uir) = @_;
	my %ui = %{$uir};

	if (exists $ui{'left'}{'selection'}){
		$ui{'left'}{'selection'}->delwin();
	}
	if (exists $ui{'right'}{'selection'}){
		$ui{'right'}{'selection'}->delwin();
	}
	if (exists $ui{'act'}{'selection'}){
		$ui{'act'}{'selection'}->delwin();
	}


	debug_log(4,"draw_selection_bars: making newwin 1,$ui{'act'}{'selection_width'},$ui{'act'}{'curpos'},$ui{'act'}{'selection_x'}\n");
	$ui{'act'}{'selection'} = newwin(1,$ui{'act'}{'selection_width'},$ui{'act'}{'curpos'},$ui{'act'}{'selection_x'});

	if ($ui{'act'}{'name'} eq "LEFT"){
		%ui = attr_on(\%ui,"act","SEL_LACT","selection");
		$ui{'right'}{'selection'} = newwin(1,$ui{'right'}{'selection_width'},$ui{'right'}{'curpos'},$ui{'right'}{'selection_x'});
		%ui = attr_on(\%ui,"right","SEL_RIACT","selection");

		$ui{'act'}{'name'} = "RIGHT";
		my ($str, $fs) = get_entry(\%ui,$ui{'right'}{'dirpos'});
		$ui{'act'}{'name'} = "LEFT";
		for (my $i = 0;$i<$ui{'right'}{'selection_width'};$i++){
			$ui{'right'}{'selection'}->addch(0,$i," ");
		}

		$ui{'right'}{'selection'}->addnstr(0,0,"$str",$ui{'right'}{'selection_width'});
		$ui{'right'}{'selection'}->addnstr(0,$ui{'right'}{'max_x'}-8,"$fs",6);
		$ui{'right'}{'selection'}->refresh();
	}
	elsif ($ui{'act'}{'name'} eq "RIGHT") {
		%ui = attr_on(\%ui,"act","SEL_RACT","selection");
		$ui{'left'}{'selection'} = newwin(1,$ui{'left'}{'selection_width'},$ui{'left'}{'curpos'},$ui{'left'}{'selection_x'});
		%ui = attr_on(\%ui,"left","SEL_LIACT","selection");

		$ui{'act'}{'name'} = "LEFT";
		my ($str, $fs) = get_entry(\%ui,$ui{'left'}{'dirpos'});
		$ui{'act'}{'name'} = "RIGHT";
		for (my $i = 0;$i<$ui{'left'}{'selection_width'};$i++){
			$ui{'left'}{'selection'}->addch(0,$i," ");
		}

		$ui{'left'}{'selection'}->addnstr(0,0,"$str",$ui{'left'}{'selection_width'});
		$ui{'left'}{'selection'}->addnstr(0,$ui{'left'}{'max_x'}-8,"$fs",6);
		$ui{'left'}{'selection'}->refresh();
	}
	my $role = $ui{'act'}{'name'};
	$role = substr($role,0,1);

	# fill in bar
	for (my $i = 0;$i<$ui{'act'}{'selection_width'};$i++){
		$ui{'act'}{'selection'}->addch(0,$i," ");
	}

	my ($str, $fs) = get_entry(\%ui,$ui{'act'}{'dirpos'});
	$ui{'act'}{'selection'}->addnstr(0,0,"$str",$ui{'act'}{'selection_width'});
	$ui{'act'}{'selection'}->addnstr(0,$ui{'act'}{'max_x'}-8,"$fs",6);

	$ui{'act'}{'selection'}->refresh();
	return %ui;
}

sub get_entry {
	my ($uir,$pos) = @_;
	my %ui = %{$uir};
#	my @str;

	my $act = lc($ui{'act'}{'name'});
	debug_log(4,"get_entry: ui($act) = $ui{$act}\n");
	%ui = window_size(\%ui,"$act");

	my $str = ${$ui{$act}{'dirs'}}[$pos];

	my ($filesize, $dirlen);
	if ($ui{'conf'}{'C_SHOW_FILESIZE'} eq "TRUE"){
        	$dirlen	= $ui{$act}{'max_x'}-9;	
		if ( -f "$ui{$act}{'cwd'}/@{$ui{$act}{'dirs'}}[$pos]"){
	       		$filesize = get_filesize(\%ui,$pos,$act);
			$filesize = sprintf("%+6s",$filesize);
		}
		else {
			$filesize = "      ";
		}
		$str = substr($str,0,$dirlen);
		$str = "$str";
		return $str,$filesize;
	}
	else {
		$dirlen = $ui{"$act"}{'max_x'}-4;
		$str = sprintf("%-$dirlen\s",$str);
		return $str;
	}
#	debug_log(4,"hash: L: $ui{'left'} R: $ui{'right'} A: $ui{'act'} and dirlen: $dirlen\n");
}

1;
