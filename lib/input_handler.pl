#!/usr/bin/perl

use strict;


my %KEY = (
	KEY_LEFT => Curses::KEY_LEFT,
	KEY_RIGHT => Curses::KEY_RIGHT,
	KEY_UP => Curses::KEY_UP,
	KEY_DOWN => Curses::KEY_DOWN,
	KEY_ENTER => Curses::KEY_ENTER,
);

sub command_mode {
	my ($uir) = @_;
	my %ui = %{$uir};

	while (my $c = getch($ui{'prompt'}{'win'})){
		debug_log(1,"command_mode: c: '$c' and ord(c): ".ord($c)."\n") if ($c != -1);
		my $ord = ord($c);
		if ($ord == 10){
			$c = "ENTER";
		}
		if ($ord == 32){
			$c = "SPACE";
		}
		if ($ord == 9){
			$c = "TAB";
		}
		if ($ord == 27){
			$c = "ESC";
		}

		if (inside_ar($ui{'conf'}{'KEY_QUIT'},$c)){
			if (exists $ui{'text'}{'win'}){
				$ui{'text'}{'win'}->delwin();
				delete $ui{'text'}{'win'};
				%ui = redraw_ui(\%ui);
			}
			else {
				last;
			}
		}
		elsif ($c eq "p"){
			status_message(\%ui,"woot tracktorz!! longer message brokes this sh*t");
		}
		elsif ($c eq "P"){
			error_message(\%ui,"woot tracktorz!!");
		}

		elsif (inside_ar($ui{'conf'}{'KEY_DOWN'},$c)){
			if (exists $ui{'text'}{'win'}){
				%ui = draw_text_window(\%ui,"down");
			}
			else {
				%ui = draw_filemanager(\%ui,"down");
			}
		}
		elsif (inside_ar($ui{'conf'}{'KEY_UP'},$c)){
			if (exists $ui{'text'}{'win'}){
				%ui = draw_text_window(\%ui,"up");
			}
			else {
				%ui = draw_filemanager(\%ui,"up");
			}
		}
		elsif (inside_ar($ui{'conf'}{'KEY_PGUP'},$c)){
			%ui = draw_filemanager(\%ui,"pgup");
		}
		elsif (inside_key_ar($ui{'conf'}{'KEY_PGDOWN'},$c)){
			%ui = draw_filemanager(\%ui,"pgdown");
		}
		elsif (inside_ar($ui{'conf'}{'KEY_COPY'},$c)){
			%ui = fm_copy(\%ui);
		}
		elsif (inside_ar($ui{'conf'}{'KEY_MOVE'},$c)){
			%ui = fm_move(\%ui,"mv");
		}
		elsif (inside_ar($ui{'conf'}{'KEY_DELETE'},$c)){
			if ($ui{'conf'}{'C_DOUBLE_D_DEL'}){
				prompt_message(\%ui, "press $c again to delete");
				my $error = 0;
				while (my $c = $ui{'prompt'}{'win'}->getch()){
					if ($c != -1){
						if ($c eq "d"){
							%ui = fm_rm(\%ui);
							last;
						}
						$error = 1;
						last;
					}
					usleep($ui{'usleep'});
				}
				prompt_message(\%ui,"deletion aborted by user") if ($error);
				if ($#{$ui{'act'}{'dirs'}} <= $ui{'act'}{'curpos'}){
					%ui = draw_filemanager(\%ui,"noreset");
				}
				else {
					%ui = draw_filemanager(\%ui);
				}
			}
			else {
				prompt_message(\%ui, "press $c again to delete");
			}

		}
		elsif (inside_ar($ui{'conf'}{'KEY_SEARCH'},$c)){
			$ui{'act'}{'dirs'} = list_files($ui{'act'}{'cwd'});
			delete $ui{'act'}{'selected'};
			$ui{'act'}{'curpos'} = 1;
			$ui{'act'}{'dirpos'} = 0;
			%ui = search_dirs(\%ui);
		}
		elsif (inside_ar($ui{'conf'}{'KEY_SELECT'},$c)){
			make_selection(\%ui,$ui{'act'}{'dirpos'});
			%ui = draw_filemanager(\%ui,"noreset");
		}
		elsif (inside_ar($ui{'conf'}{'KEY_SELECT_ALL'},$c)){
			if ($ui{'conf'}{'C_SELECT_ALL'} eq "TRUE"){
				my $sel = $#{$ui{'act'}{'selected'}};
				delete $ui{'act'}{'selected'};
				if ($sel != $#{$ui{'act'}{'dirs'}}-1){
					for (my $i=1;$i<=$#{$ui{'act'}{'dirs'}};$i++){
						push(@{$ui{'act'}{'selected'}},$i);
					}
				}
			}
			else {
				# skip ..
				%ui = make_selection(\%ui,1,$#{$ui{'act'}{'dirs'}});
			}
			%ui = draw_filemanager(\%ui,"noreset");
		}
		elsif (inside_ar($ui{'conf'}{'KEY_CLEAR_SEL'},$c)){
			delete $ui{'act'}{'selected'};
			%ui = draw_filemanager(\%ui,"noreset");
		}
		elsif (inside_ar($ui{'conf'}{'KEY_CHDIR'},$c)){
			%ui = filemanager_chdir(\%ui);
			$ui{'act'}{'curpos'} = 1;
			$ui{'act'}{'dirpos'} = 0;
			$ui{'act'}{'scrl'} = 0;
			%ui = draw_filemanager(\%ui);
			%ui = refresh_filemanagers(\%ui);
		}
		elsif (inside_ar($ui{'conf'}{'KEY_CHWIN'},$c)){
			#$ui{'act'}{'selection'}{'win'}->delwin();
			if ($ui{'act'}{'name'} eq "LEFT") {
				$ui{'act'}{'selected'} = () if ($ui{'conf'}{'C_CLRSEL_CHWIN'} eq "TRUE");
				$ui{'left'} = $ui{'act'};
				$ui{'act'} = $ui{'right'};
				debug_log(2,"command_mode: chwin: L->R #ui(act)(dirs): $#{$ui{'act'}{'dirs'}}\n");
				debug_log(2,"command_mode: chwin: L->R #ui(right)(dirs): $#{$ui{'right'}{'dirs'}}\n");
			}
			elsif ($ui{'act'}{'name'} eq "RIGHT"){
				$ui{'act'}{'selected'} = () if ($ui{'conf'}{'C_CLRSEL_CHWIN'} eq "TRUE");
				$ui{'right'} = $ui{'act'};
				$ui{'act'} = $ui{'left'};
				debug_log(2,"command_mode: chwin: R->L #ui(act)(dirs): $#{$ui{'act'}{'dirs'}}\n");
			}
			%ui = refresh_filemanagers(\%ui);
			debug_log(2,"command_mode: active name: $ui{'act'}{'name'} - a: $ui{'act'} l: $ui{'left'} r: $ui{'right'}\n");
		}
		elsif (inside_ar($ui{'conf'}{'KEY_PROMPT'},$c)){
			%ui = prompt_mode(\%ui);
			debug_log(2,"command_mode: after prompt_mode: $ui{'text'}{'win'}\n");
			if ($ui{'quit'} == 1){
				last;
			}
		}
		elsif ($c != -1) {
			status_message(\%ui,"",0,"");
			error_message(\%ui,"key not bound: $c");
			%ui = refresh_all(\%ui);
		}
		usleep($ui{'usleep'});
	}

}

sub prompt_mode {
	my ($uir) = @_;
	my %ui = %{$uir};

	$ui{'prompt'}{'win'}->move(0,0);
	%ui = window_size(\%ui,"prompt");

	%ui = attr_on(\%ui,"prompt","PROMPT");
	debug_log(2,"prompt_mode: max_x: $ui{'prompt'}{'max_x'}\n");
	for (my $i=0;$i<$ui{'prompt'}{'max_x'}+2;$i++){
		$ui{'prompt'}{'win'}->addch(0,$i," ");
	}
	$ui{'prompt'}{'win'}->addstr(0,0,":");
	# manually print 'em letters
	noecho();
	curs_set(1);

	# get these from config?
	my @commands = qw/c o f r q open mkdir move file rename quit copy chdir cd/;
		
	my $str = "";
	my $str_comp = "preset";
	my $tab_i = 0;
	while (my $c = $ui{'prompt'}{'win'}->getch()){
		if ($c == 263){
			$str_comp = "preset";
			$str = substr($str,0,length($str)-1);
	
			my ($y,$x);
			$ui{'prompt'}{'win'}->getyx($y,$x);
			for (my $i=$x;$i<$ui{'prompt'}{'max_x'};$i++){
				$ui{'prompt'}{'win'}->addch(0,$i," ");
			}
			debug_log(2,"prompt_mode: backspace at x: $x str: $str\n");
			$ui{'prompt'}{'win'}->move(0,$x);
			if ($x == 0) {
				$c = "LAST";
			}
			else {	
				$c = "";
			}
		}
		
		if (ord($c) == 10 or $c eq "LAST"){
			last;
		}
		elsif (ord($c) == 9 || $c == 353) {
			debug_log(2,"prompt_mode: tab with $str_comp and str: $str\n");
			if ($str_comp eq "preset"){
				$str_comp = $str;
				$tab_i = 0;
			}
			$tab_i++ if (ord($c) == 9);
			$tab_i-- if ($c == 353);
			my @tabcommands;
	
			foreach (@commands){
				if ($_ =~ m/^$str_comp/){
					push (@tabcommands, $_);
				}
			}
			if ($tab_i > $#tabcommands){
				$tab_i = 0;
			}
			$str = $tabcommands[$tab_i] if ($tabcommands[$tab_i]);
			for (my $j=0;$j<=$ui{'prompt'}{'max_x'};$j++){
				$ui{'prompt'}{'win'}->addch(0,$j," ");
			}
			$ui{'prompt'}{'win'}->addnstr(0,0,":$str",$ui{'prompt'}{'max_x'});
			$ui{'prompt'}{'win'}->move(0,length(":$str"));
			$ui{'prompt'}{'win'}->refresh();
		}
		elsif ($c != -1){
			$str .= $c;
			if (length($str) >= 55){
				status_message(\%ui,"ERROR: Command too long!",0,"");
				$str = substr($str,0,55);
			}
			$ui{'prompt'}{'win'}->addnstr(0,0,":$str",$ui{'prompt'}{'max_x'});
			$ui{'prompt'}{'win'}->move(0,length(":$str"));

			$ui{'prompt'}{'win'}->refresh();
		}
		usleep($ui{'usleep'});
		echo();
		curs_set(1);
	
	}

	$ui{'prompt'}{'win'}->attroff(COLOR_PAIR($ui{'colors'}{'COLOR_PROMPT'})|$ui{'attributes'}{'COLOR_PROMPT'});

	noecho();
	curs_set(0);
	if ($str){
		chomp $str;
		if ($str =~ s/^(o|open)// || $str =~ s/^(cd|chdir)//){
			if (!$str){
				$str = @{$ui{'act'}{'dirs'}}[$ui{'act'}{'dirpos'}];
			}
			# remove empties ;<
			$str =~ s/^ //g;
			
			# remove double /
			$str =~ s/\/\//\//g;
			%ui = filemanager_chdir(\%ui,$str);
			%ui = refresh_filemanagers(\%ui);
			%ui = draw_filemanager(\%ui);
			return %ui;
		}
		elsif ($str =~ s/^(h|help)//){
			delete $ui{'text'}{'contents'};
			my $help_file = "README";
			open (HELP,"<$help_file");
			while (<HELP>){
				push (@{$ui{'text'}{'contents'}},$_);
			}
			close (HELP);
			%ui = draw_text_window(\%ui);
			debug_log(2,"prompt_mode: $ui{'text'}{'win'}\n");
			return %ui;
#			%ui = draw_filemanager(\%ui,"noreset");
		}
		elsif ($str =~ s/^(mk|mkdir) //){
			if (!$str){
				error_message(\%ui,"usage: mkdir dirname");
			}
			else {
				mkdir "$ui{'act'}{'cwd'}/$str" or debug_log(1,"mkdir $ui{'act'}{'cwd'}/$str failed\n");
				%ui = refresh_filemanagers(\%ui);
#				%ui = draw_filemanager(\%ui,"noreset");
				#%ui = draw_dirs(\%ui);
			}
			return %ui;
		}
		elsif ($str =~ s/^(f|file)$//){
			%ui = fm_output(\%ui,"file","-b");
			return %ui;
		}
		elsif ($str =~ s/^(r|rename) //){
			if (!$str){
				error_message(\%ui,"usage: rename new_name");
			}
			else {
				rename("$ui{'act'}{'cwd'}/@{$ui{'act'}{'dirs'}}[$ui{'act'}{'dirpos'}]","$ui{'act'}{'cwd'}/$str") or debug_log(1,"rename of $ui{'act'}{'cwd'}/@{$ui{'act'}{'dirs'}}[$ui{'act'}{'dirpos'}] -> $ui{'act'}{'cwd'}/$str failed.");
				%ui = refresh_filemanagers(\%ui);
			}
			return %ui;
		}
		elsif ($str =~ s/^(q|quit)$//){
			$ui{'quit'} = 1;
			return %ui;
		}
		else {
			error_message(\%ui,"unknown cmd: $str");
			return %ui;
		}
	}
	else {
		return %ui;
	}
}

1;
