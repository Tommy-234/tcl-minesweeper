



#		Minesweeper Game
#	Tommy Freethy September 2015
#
# This minesweeper game will parse the game board after generation and look for patterns which result in
# the user guessing between two buttons. This strategy is very effective in generating game boards with
# far fewer "50-50" guesses.
#
#		----Edits----
#
# Jan 10, 2018 - Solver is a little smarter when there are only a few mines left.
# Also, one of the patterns needs debugging
#
# Nov 28, 2017 - I added a minesweeper solver. It solves the entire board maybe 1 in 5 times and gets
# "stuck" all other times. I could add some guessing so the solver would either win or lose every time.
#
# Jun 28, 2017 - I made my code soo pretty. Made sure every line ended in a semi-colon and ensured 
# variable names followed the same protocol. VariableName for local variables and _variable_name
# for member variables.
# Also added a couple more patterns to look for
#
# Mar 1, 2017 - added new fields to the scores file (best_5_times, last_25, and total_win_time).
# With these new fields I made an adjustment to the Scores prompt. I added stats on the last 25 games,
# I added top 5 times, I removed the fixed game boards stats, and I use total_win_time for an average
# win time.
#
# Feb 23, 2017 - changed when check_for_patterns is called. Was after generate_mines but before 
# fix_first_click. Now it's after fix_first_click to prevent mines being placed into patterns.

#		----To Do----
# -	Some adjustments to the scores prompt:
#		- have different tabs for different difficulties
# - Add in a help menu explaining the game and rules


#		----Done-----
# -	Parse the board to look for specific patterns which result in a guess...Half-ass done
# -	Fix the mine image, looks like ass.....kinda fixed -I just made the background red

# -	Look to make the algorithms faster, some lag when board is created, also during a big move
# -	Give the numbers their own colours like in real minesweeper, 1=blue, 2=green, 3=red, etc.
# -	New game bug. when new game button is invoked, the time increments faster
# -	Make the first click safe with no surrounding mines
# -	If the scores prompt is exited and the new game button is pressed we get an error
# -	Some adjustments to the score prompt:
#		- popup in a more convenient spot
#		- have the scores come up from the menu
#		- better spacing
#		- Add an "s" to the best time value
#		- fix some background colours
#		- maybe a bit bigger
#		- Display the score for the current value of $_difficulty
#		- do something about the buttons at the bottom, they look like shit
#		- give a local grab to the toplevel prompt
# - Bug with changing difficulties
# -	Strange bug has happened twice now where I win the game but the program does not recognize the win.
# -	Sometimes when updating the scores file it writes garbage
# - Bug with longest win/lose streak
# -	Ability to reset the scores file
# -	Comment everything
# - Still a couple glitches with the scores
# -	Have the time start on the first click
# -	The exclamation points on the flagged squares are not always black
# - Clean up some code, the setup proc is kinda pointless
# - Theres a bug with the _remaining_mines variable. The game is ending early in some cases and not
#	ending in other cases.
# -	The parser is only half done for the first pass
# -	Account for resizing: 
#		- Have the buttons "-fill both" in a particular frame 
#		- Minimum size for window
# - I fucked something up pretty bad. The time or remaining mines are not updating
# - Probably will need to make adjustment with the scores file when the application is run by an exe,
#	if the file does not exist, then create the file with the default scores. Plus I need to change the
# 	_scores_path variable to a relative path instead of hard-coding the path to my scores file
# - An error occurs with the time when the game ends with a 0 square
# - Make an exe file so people can play my kickass game

# ------------------------------------------------------------------------------------

#Some patterns to look for when parsing the board

#These three are the patterns which I have seen the most, there are definitely more
#Each board shows a couple different variations of the same pattern, 
#they differ slightly when against a wall. X indicates a mine, O indicates a safe spot

	# # # # # # # # # # # #
	# O X X  			  #
	# O	O X				  #    
	#			      X X #
	#				  O O #
	#				  O	X <---------Needs debugging, on left wall as well
	#			      X X #
	#					  #
	#					  #
	#					  #
	#		X O	O X 	  #
	#		X O	X X 	  #
	# # # # # # # # # # # #

	# # # # # # # # # # # #
	# O O X  			  #
	# O	X X				  #    
	# O O X				  #
	#					  #
	#					  #
	#					  #
	#					  #
	#		X O	O X		  #
	#		X O	X X <------------Needs implementation
	#		X O	O X 	  #
	#					  #
	# # # # # # # # # # # #

	# # # # # # # # # # # #
	# O X   			  #
	# X	O 				  #    
	#	  X				  #
	#			X     X	  #
	#			  X O	  #
	#			  O	X   <--------Needs implementation
	#			X	  X	  #
	#					  #
	#		X	  X		  #
	#		  X	O   	  #
	#		  O	X   	  #
	# # # # # # # # # # # #

# As of March 2017 the parser is looking for most of these patterns. The ones I am missing include:
#	- The "X" pattern in the middle of the board
#	- Two parallel, 3 mine rows/columns, spaced 3 apart, with one mine in the middle. (2nd pattern, not against wall)
# I'm going to guess that I detect a good 80% of the bad boards. These 2 remaining patterns appear quite 
# infrequent and are probably too expensive to look for.

namespace eval minesweeper {
	variable _rows 10;
	variable _columns 10;
	variable _mines 10;
	variable _mine_indexes "";
	variable _remaining_mines "";
	variable _remaining_squares "";
	variable _every;
	variable _time 0;
	variable _scores_path "C:/Users/Temp/Documents/tests/minesweeper/scores.txt";
	# variable _scores_path "";
	variable _game_over 0;
	variable _first_click 1;
	variable _difficulty "easy";
	variable _fixed_board 0;
	
	variable _active_squares "";
	
#main
#
#main proc of the program, calls the required procs to set up the first game board
	
	proc main {} {
		variable _mine_indexes;
		variable _remaining_mines "";
		variable _remaining_squares "";
		variable _rows 10;
		variable _columns 10;
		variable _mines 10;
		variable _scores_path;
		
		
		# set _scores_path [file join scores.txt];
		if {[file exists $_scores_path] == 0} {
			set File [open $_scores_path "w"];
			foreach Difficulty {easy medium hard} {
				puts $File "$Difficulty games_played 0";
				puts $File "$Difficulty games_won 0";
				puts $File "$Difficulty best_time -";
				puts $File "$Difficulty longest_win 0";
				puts $File "$Difficulty longest_lose 0";
				puts $File "$Difficulty current 0";
				puts $File "$Difficulty board_fixes 0";
				puts $File "$Difficulty board_fix_wins 0";
				
				puts $File "$Difficulty best_5_times -";
				puts $File "$Difficulty total_win_time 0";
				puts $File "$Difficulty last_25 -";
			}
			close $File;
		}
		
		create_board;
		create_menu;
		generate_mines;
		# set _mine_indexes {8_2 9_4 10_3 8_5 9_8 8_10 7_9 6_8 1_10 2_10};
		# set _remaining_squares [expr {$_rows * $_columns - $_mines}];
		# set _remaining_mines $_mines;
	}
	
#every
#
#This proc controls the _time variable. "every 1000 [list incr _time]" when called like that, _time is
#incremented every 1000ms or every 1s. The timer can be cancelled by using "cancel" instead of a ms value
	
	proc every {MS Body} {
		variable _time;
		variable _every;
		
		if {$MS eq "cancel"} {
			after cancel $_every($Body);
			unset _every($Body);
			return;
		}
		set _every($Body) [info level 0];
		eval $Body;
		after $MS [info level 0];
		.outer_frame.progress_frame.timer configure -text $_time;
	}

#create_board
#
#This proc sets up a game board with the necessary bindings .
#To get a handle on a specific button, the path is .outer_frame.game_board.row_column
	
	proc create_board {} {
		variable _rows;
		variable _columns;
		variable _mines;
		variable _active_squares;
		
		set _active_squares "";
		
		pack [frame .outer_frame];
		pack [frame .outer_frame.game_board] -fill both -expand true;
		
		for {set i 1} {$i <= $_rows} {incr i} {
			for {set j 1} {$j <= $_columns} {incr j} {
				set Button [button .outer_frame.game_board.${i}_${j} -command \
					[subst -nocommands {::minesweeper::button_press ${i}_${j}}] \
					-width 3 -bg blue -font "-size 9 -weight bold"\
				];
				grid configure $Button -row $i -column $j -sticky nesw;
			}
		}
		pack [frame .outer_frame.progress_frame];
		pack [label .outer_frame.progress_frame.remaining_mines_text -text "Remaining: "] -side left;
		pack [label .outer_frame.progress_frame.remaining_mines -text $_mines] -side left;
		
		pack [button .outer_frame.progress_frame.solve -text "Solve" -command minesweeper::solve_board] -side right -padx 5;
		pack [button .outer_frame.progress_frame.reset -text "New Game" -command minesweeper::reset_board] -side right -padx 5;
		
		pack [label .outer_frame.progress_frame.timer -text 0] -side right;
		pack [label .outer_frame.progress_frame.timer_text -text "Time: "] -side right;

		bind . <ButtonPress-3> [list minesweeper::set_flag %W];
		bind . <ButtonPress-2> [list minesweeper::click_surrounding %W];
		bind . <Double-ButtonPress-1> [list minesweeper::click_surrounding %W];
		
		#The following is turning off both width and height resizing for the toplevel window "." 
		wm resizable . 0 0;
	}
	
#create_menu
#
#This proc creates the menu
	
	proc create_menu {} {
		menu .menu -tearoff 0 -type menubar;
		menu .menu.game -tearoff 0;
		menu .menu.game.diff -tearoff 0;
		
		.menu.game add command -label "New Game" -command {minesweeper::reset_board;};
		.menu.game add separator;
		
		.menu.game add cascade -menu .menu.game.diff -label Difficulty -underline 0;
		.menu.game.diff add command -label "Easy" -command [list minesweeper::set_difficulty easy];
		.menu.game.diff add command -label "Medium" -command [list minesweeper::set_difficulty medium];
		.menu.game.diff add command -label "Hard" -command [list minesweeper::set_difficulty hard];
		
		.menu.game add command -label "Scores" -command [list minesweeper::display_game_over scores];
		.menu.game add separator;
		.menu.game add command -label "Quit" -command exit;
		
		.menu add cascade -menu .menu.game -label Game -underline 0;
		
		. configure -menu .menu;
		wm title . "Minesweeper";
	}

#generate_mines
#
#This proc generates random mines by creating a list of all button indexes (row_column) and scramble the 
#order. Then generate a random index and select $_mines from the list at the random index.
#This ensures a set of random mines
	
	proc generate_mines {} {
		variable _rows;
		variable _columns;
		variable _mines;
		variable _mine_indexes "";
		variable _remaining_mines;
		variable _remaining_squares;
		
		set TotalButtons [expr {$_rows * $_columns - 1}];
		
		for {set i 1} {$i <= $_rows} {incr i} {
			for {set j 1} {$j <= $_columns} {incr j} {
				lappend AllButtons "${i}_${j}";
			}
		}
		for {set i 0} {$i <= $TotalButtons} {incr i} {
			set j [expr {int(rand() * $TotalButtons)}];
			set Temp [lindex $AllButtons $j];
			set AllButtons [lreplace $AllButtons $j $j [lindex $AllButtons $i]];
			set AllButtons [lreplace $AllButtons $i $i $Temp];
		}
		
		set StartIndex [expr {int(rand() * $TotalButtons)}];
		if {[expr {$StartIndex + $_mines}] > $TotalButtons} {
			set EndIndex $StartIndex;
			set StartIndex [expr {$StartIndex - $_mines + 1}];
		} else {
			set EndIndex [expr {$StartIndex + $_mines - 1}];
		}
		set _mine_indexes [lrange $AllButtons $StartIndex $EndIndex];
		set _remaining_squares [expr {$_rows * $_columns - $_mines}];
		set _remaining_mines $_mines;
	}

#button_press
#
#This proc is called when any of the buttons are invoked on the game board. if its the first click we 
#fix the board so it results in a "big move"
	
	proc button_press {Index} {
		variable _mine_indexes;
		variable _game_over;
		variable _first_click;
		
		if {$_game_over} {
			return;
		}
		
		if {$_first_click == 1} {
			minesweeper::every 1000 [list incr _time];
			fix_first_click $Index;
			safe_button_press $Index;
			set _first_click 0;
			return;
		}
			
		if {[lsearch $_mine_indexes $Index] == -1} {
			safe_button_press $Index;
		} else {
			set _game_over 1;
			game_lost $Index;
		}
		update;
	}
	
#fix_first_click
#
#The first click of the game will always be a big move (no surrounding mines). This proc gets the first click
#index and its surrounding mines and makes sure none of those are mines.
	
	proc fix_first_click {Index} {
		variable _rows;
		variable _columns;
		variable _mine_indexes;
		
		set SurroundingSquares [minesweeper::get_surrounding_sqaures $Index];
		lappend SurroundingSquares $Index;
		
		foreach Square $SurroundingSquares {
			if {[lsearch $_mine_indexes $Square] >= 0} {
				switch_mine $Square $SurroundingSquares;
			}
		}
		check_for_patterns $SurroundingSquares;
	}

#safe_button_press
#
#This proc counts the mines in the surround sqaures and paints that number on the button, while disabling
#the button. If there are 0 surrounding mines safe_button_press is called recursively on all surrounding
#squares. This is how a big move is generated.
	
	proc safe_button_press {Index} {
		variable _mine_indexes;
		variable _remaining_squares;
		variable _game_over;
		variable _active_squares;
		
		set SurroundingMines 0;
		set SurroundingSquares [minesweeper::get_surrounding_sqaures $Index];
		
		
		foreach Square $SurroundingSquares {
			if {[lsearch $_mine_indexes $Square] >= 0} {
				incr SurroundingMines;
			}
		}
		if {[.outer_frame.game_board.$Index cget -text] ne ""} {
			return;
		}
		switch $SurroundingMines {
			0 {
				incr _remaining_squares -1;
				.outer_frame.game_board.$Index configure -background white -text $SurroundingMines \
					-state disabled -disabledforeground black;
				foreach Square $SurroundingSquares {
					if {[.outer_frame.game_board.$Square cget -text] eq ""} {
						safe_button_press $Square;
					}
				}
				if {$_remaining_squares == 0 && $_game_over == 0} {
					game_won;
				}
				return;
			}
			1 {
				.outer_frame.game_board.$Index configure -disabledforeground "royal blue" -text \
					$SurroundingMines -state disabled -background white;
			}
			2 {
				.outer_frame.game_board.$Index configure -disabledforeground "lime green" -text \
					$SurroundingMines -state disabled -background white;
			}
			3 {
				.outer_frame.game_board.$Index configure -disabledforeground red -text \
					$SurroundingMines -state disabled -background white;
			}
			4 {
				.outer_frame.game_board.$Index configure -disabledforeground "midnight blue" -text \
					$SurroundingMines -state disabled -background white;
			}
			5 {
				.outer_frame.game_board.$Index configure -disabledforeground "firebrick" -text \
					$SurroundingMines -state disabled -background white;
			}
			6 {
				.outer_frame.game_board.$Index configure -disabledforeground "cyan" -text \
					$SurroundingMines -state disabled -background white;
			}
			7 {
				.outer_frame.game_board.$Index configure -disabledforeground magenta -text \
					$SurroundingMines -state disabled -background white;
			}
			8 {
				.outer_frame.game_board.$Index configure -disabledforeground "light slate gray" -text \
					$SurroundingMines -state disabled -background white;
			}
		}
		lappend _active_squares $Index;
		incr _remaining_squares -1;
		if {$_remaining_squares == 0} {
			game_won;
		}
	}

#get_surrounding_sqaures
#
#This proc is used quite frequently. It takes an index and returns the surrounding sqaures. If the index
#is a cornner or on a side it will only return the valid surrounding sqaures.
#A middle square has 8 surrounding squares, a side square has 5 and a corner has 3
	
	proc get_surrounding_sqaures {Index} {
		variable _rows;
		variable _columns;
		
		set SurroundingSquares "";
		
		set ClickRow [lindex [split $Index "_"] 0];
		set ClickRowMinus [expr {$ClickRow - 1}];
		set ClickRowPlus [expr {$ClickRow + 1}];
		
		set ClickColumn [lindex [split $Index "_"] 1];
		set ClickColumnMinus [expr {$ClickColumn - 1}];
		set ClickColumnPlus [expr {$ClickColumn + 1}];

		if {$ClickRow == $_rows} {
			if {$ClickColumn == $_columns} {
				lappend SurroundingSquares $ClickRowMinus\_$ClickColumnMinus;
				lappend SurroundingSquares $ClickRowMinus\_$ClickColumn;

				lappend SurroundingSquares $ClickRow\_$ClickColumnMinus;
			} else {
				if {$ClickColumnMinus == 0} {
					lappend SurroundingSquares $ClickRowMinus\_$ClickColumn;
					lappend SurroundingSquares $ClickRowMinus\_$ClickColumnPlus;
					
					lappend SurroundingSquares $ClickRow\_$ClickColumnPlus;
				} else {
					lappend SurroundingSquares $ClickRowMinus\_$ClickColumnMinus;
					lappend SurroundingSquares $ClickRowMinus\_$ClickColumn;
					lappend SurroundingSquares $ClickRowMinus\_$ClickColumnPlus;
					
					lappend SurroundingSquares $ClickRow\_$ClickColumnMinus;
					lappend SurroundingSquares $ClickRow\_$ClickColumnPlus;
				}
			}
		} else {
			if {$ClickRowMinus == 0} {
				if {$ClickColumn == $_columns} {
					lappend SurroundingSquares $ClickRow\_$ClickColumnMinus;

					lappend SurroundingSquares $ClickRowPlus\_$ClickColumnMinus;
					lappend SurroundingSquares $ClickRowPlus\_$ClickColumn;
				} else {
					if {$ClickColumnMinus == 0} {
						lappend SurroundingSquares $ClickRow\_$ClickColumnPlus;

						lappend SurroundingSquares $ClickRowPlus\_$ClickColumn;
						lappend SurroundingSquares $ClickRowPlus\_$ClickColumnPlus;
					} else {
						lappend SurroundingSquares $ClickRow\_$ClickColumnMinus;
						lappend SurroundingSquares $ClickRow\_$ClickColumnPlus;
						
						lappend SurroundingSquares $ClickRowPlus\_$ClickColumnMinus;
						lappend SurroundingSquares $ClickRowPlus\_$ClickColumn;
						lappend SurroundingSquares $ClickRowPlus\_$ClickColumnPlus;
					}
				}
			} else {
				if {$ClickColumn == $_columns} {
					lappend SurroundingSquares $ClickRowMinus\_$ClickColumnMinus;
					lappend SurroundingSquares $ClickRowMinus\_$ClickColumn;

					lappend SurroundingSquares $ClickRow\_$ClickColumnMinus;

					lappend SurroundingSquares $ClickRowPlus\_$ClickColumnMinus;
					lappend SurroundingSquares $ClickRowPlus\_$ClickColumn;
				} else {
					if {$ClickColumnMinus == 0} {
						lappend SurroundingSquares $ClickRowMinus\_$ClickColumn;
						lappend SurroundingSquares $ClickRowMinus\_$ClickColumnPlus;

						lappend SurroundingSquares $ClickRow\_$ClickColumnPlus;

						lappend SurroundingSquares $ClickRowPlus\_$ClickColumn;
						lappend SurroundingSquares $ClickRowPlus\_$ClickColumnPlus;
					} else {
						lappend SurroundingSquares $ClickRowMinus\_$ClickColumnMinus;
						lappend SurroundingSquares $ClickRowMinus\_$ClickColumn;
						lappend SurroundingSquares $ClickRowMinus\_$ClickColumnPlus;
						
						lappend SurroundingSquares $ClickRow\_$ClickColumnMinus;
						lappend SurroundingSquares $ClickRow\_$ClickColumnPlus;
						
						lappend SurroundingSquares $ClickRowPlus\_$ClickColumnMinus;
						lappend SurroundingSquares $ClickRowPlus\_$ClickColumn;
						lappend SurroundingSquares $ClickRowPlus\_$ClickColumnPlus;
					}
				}
			}
		}
		return $SurroundingSquares;
	}

#set_flag
#
#When the right mouse button is pressed over an active square, the button is turned yellow and the text
#is changed to "!". This indicates a mine. _remaining_mines is also decremented	
	
	proc set_flag {Widget} {
		variable _remaining_mines;
		
		if {[winfo class $Widget] ne "Button"} {
			return;
		}
		switch [$Widget cget -background] {
			"yellow" {
				$Widget configure -background blue -text "" -state normal;
				incr _remaining_mines;
			}
			"blue" {
				$Widget configure -background yellow -text "!" -state disabled -disabledforeground black;
				incr _remaining_mines -1;
			}
		}
		.outer_frame.progress_frame.remaining_mines configure -text $_remaining_mines;
		update;
	}
	
#click_surrounding
#
#This proc is called when a mouse wheel click or double click occurs on a disabled sqaure. If the number
#on the button equals the surrounding flags (yellow !), a button_press will be called on each active 
#surrounding square.
	
	proc click_surrounding {Widget} {
		variable _active_squares;
		
		if {[winfo class $Widget] ne "Button"} {
			return;
		}
		
		set PathElements [split $Widget "."];
		set Index [lindex $PathElements end];
		if {[string first "_" $Index] == -1} {
			return;
		}
		
		set SurroundingSquares [minesweeper::get_surrounding_sqaures $Index];
		set SurroundingMines 0;
		
		foreach Square $SurroundingSquares {
			if {[.outer_frame.game_board.$Square cget -background] eq "yellow"} {
				incr SurroundingMines;
			}
		}
		if {$SurroundingMines != [$Widget cget -text]} {
			return;
		}
		
		set ListIndex [lsearch $_active_squares $Index];
		if {$ListIndex != -1} {
			set _active_squares [lreplace $_active_squares $ListIndex $ListIndex];
		}
		
		foreach Square $SurroundingSquares {
			if {[.outer_frame.game_board.$Square cget -text] eq ""} {
				button_press $Square;
			}
		}
	}
	
#game_lost
#
#stops the time, updates the score file and display the scores prompt
	
	proc game_lost {Index} {
		variable _difficulty;
		variable _mine_indexes;
		
		puts "Your stupid bot just lost by clicking $Index";
		
		minesweeper::every cancel [list incr _time];
		.outer_frame.game_board.$Index configure -background red;
		update_scores lose;
		
		foreach Mine $_mine_indexes {
			if {[.outer_frame.game_board.$Mine cget -background] == "blue"} {
				.outer_frame.game_board.$Mine configure -background red;
			}
		}
		after 500 [list minesweeper::display_game_over lose];
	}
	
#game_won
#
#stops the time, updates the score file and display the scores promp

	proc game_won {} {
		variable _game_over;
		variable _difficulty;
		
		minesweeper::every cancel [list incr _time];
		set _game_over 1;
		update_scores win;
		after 500 [list minesweeper::display_game_over win];
	}
	
#display_game_over
#
#This proc is called whenever we want to see the scores. This is displayed after every game and can
#also be accessed by the menu.
#The scores this prompt is displaying is saved in a text file
	proc display_game_over {WinLose} {
		variable _time;
		variable _difficulty;
		
		set X "";
		set Y "";
		if {[winfo exists .game_over]} {
			if {[winfo ismapped .game_over]} {
				set X [winfo rootx .game_over];
				set Y [winfo rooty .game_over];
			}
		} 
		if {$X eq ""} {
			set Height [winfo height .outer_frame];
			set Width [winfo width .outer_frame];
			
			set X [expr {[winfo rootx .outer_frame] + ($Width / 2)}];
			set Y [expr {$Height / 2}];
		}
		
		array set Scores [read_scores $_difficulty];
		set Percent 0;
		set AverageWinTime 0;
		set Last25Games 0;
		set Last25Wins 0;
		if {$Scores(games_played) != 0} {
			set Percent [expr {$Scores(games_won) * 100 / $Scores(games_played)}];
			if {$Scores(games_won) > 0} {
				set AverageWinTime [expr {$Scores(total_win_time) / $Scores(games_won)}];
			}
			
			foreach Char [split $Scores(last_25) ""] {
				incr Last25Games;
				if {$Char eq "w"} {
					incr Last25Wins;
				}
			}
		}
		if {![winfo exists .game_over]} {
			toplevel .game_over -background white;
			pack [label .game_over.label -font "-size 12 -weight bold" -background white] -fill x -pady 5 -side top;

			
			pack [frame .game_over.top -background white] -side top;
			pack [frame .game_over.top.left -background white] -side left -fill y;
			pack [frame .game_over.top.right -background white] -side right -fill y;
			
# ------------------------Games--------------------------------
			pack [labelframe .game_over.top.left.games -text "Games" -foreground blue -background white] -pady 3 -padx 7 -fill x;
			
			pack [frame .game_over.top.left.games.left -background white] -side left;
			pack [label .game_over.top.left.games.left.games -text "Games Played: " -background white] -anchor w -pady 2;
			pack [label .game_over.top.left.games.left.wins -text "Games Won: " -background white] -anchor w -pady 2;
			pack [label .game_over.top.left.games.left.percent -text "Win Percent: " -background white] -anchor w -pady 2;
			
			pack [frame .game_over.top.left.games.right -background white] -side right;
			pack [label .game_over.top.left.games.right.games -text $Scores(games_played) -background white] -anchor e -pady 2;
			pack [label .game_over.top.left.games.right.wins -text $Scores(games_won) -background white] -anchor e -pady 2;
			pack [label .game_over.top.left.games.right.percent -text "$Percent%" -background white] -anchor e -pady 2;
			
# ------------------------Times-------------------------------
			pack [labelframe .game_over.top.right.times -text "Times" -foreground blue -background white] -pady 3 -padx 7 -fill both;
			
			pack [frame .game_over.top.right.times.top -background white] -side top;
			pack [frame .game_over.top.right.times.top.left -background white] -side left;
			pack [label .game_over.top.right.times.top.left.time -text "Time: " -background white] -anchor w -pady 2;
			pack [label .game_over.top.right.times.top.left.average -text "Average Win Time: " -background white] -anchor w -pady 2;
			
			pack [frame .game_over.top.right.times.top.right -background white] -side right;
			pack [label .game_over.top.right.times.top.right.time -text "${_time}s" -background white] -anchor e -pady 2;
			pack [label .game_over.top.right.times.top.right.average -text "${AverageWinTime}s" -background white] -anchor e -pady 2;
			
			pack [frame .game_over.top.right.times.bottom -background white] -side bottom;
			pack [label .game_over.top.right.times.bottom.best -font "-size 10 -weight bold -underline 1" -background white -text "Best Times"] -fill x -pady 4;
			set Counter 1;
			foreach Time $Scores(best_5_times) {
				if {$Time eq "-"} {continue;}
				pack [label .game_over.top.right.times.bottom.time$Counter -text "$Counter:  ${Time}s" -background white] -pady 2;
				incr Counter;
			}

# ------------------------Streaks-----------------------------
			pack [labelframe .game_over.top.left.streak -text "Streaks" -foreground blue -background white] -pady 3 -padx 7 -fill x;
			
			pack [frame .game_over.top.left.streak.left -background white] -side left;
			pack [label .game_over.top.left.streak.left.win -text "Longest Win Streak: " -background white] -anchor w -pady 2;
			pack [label .game_over.top.left.streak.left.lose -text "Longest Losing Streak: " -background white] -anchor w -pady 2;
			pack [label .game_over.top.left.streak.left.current -text "Current Streak: " -background white] -anchor w -pady 2;
			
			pack [frame .game_over.top.left.streak.right -background white] -side right;
			pack [label .game_over.top.left.streak.right.win -text $Scores(longest_win) -background white] -anchor e -pady 2;
			pack [label .game_over.top.left.streak.right.lose -text $Scores(longest_lose) -background white] -anchor e -pady 2;
			pack [label .game_over.top.left.streak.right.current -text $Scores(current) -background white] -anchor e -pady 2;

# ------------------------Last 25 Games-----------------------------
			pack [labelframe .game_over.top.left.last25 -text "Last 25 Games" -foreground blue -background white] -pady 3 -padx 7 -fill x;
			
			pack [frame .game_over.top.left.last25.left -background white] -side left;
			pack [label .game_over.top.left.last25.left.games -text "Games: " -background white] -anchor w -pady 2;
			pack [label .game_over.top.left.last25.left.wins -text "Wins: " -background white] -anchor w -pady 2;
			
			pack [frame .game_over.top.left.last25.right -background white] -side right;
			pack [label .game_over.top.left.last25.right.games -text $Last25Games -background white] -anchor e -pady 2;
			pack [label .game_over.top.left.last25.right.wins -text $Last25Wins -background white] -anchor e -pady 2;
			
# ------------------------Buttons-----------------------------
			set Script {
				wm withdraw .game_over;
				minesweeper::reset_board;
			}
			pack [frame .game_over.button_frame -background white] -pady 3 -padx 3 -side bottom;
			pack [button .game_over.button_frame.close -text "New Game" -command $Script -background white] -side left;
			
			set ResetScript [subst -nocommands {
				minesweeper::update_scores reset;
				minesweeper::display_game_over scores;
			}];
			pack [button .game_over.button_frame.reset -text "Reset Scores" -command $ResetScript -background white] -padx 5 -side left;
			
			pack [button .game_over.button_frame.exit -text "Close" -command [list wm withdraw .game_over] -background white] -side left;
			wm geometry .game_over +$X+$Y;
		} else {
			.game_over.top.left.games.right.games configure -text $Scores(games_played);
			.game_over.top.left.games.right.wins configure -text $Scores(games_won);
			.game_over.top.left.games.right.percent configure -text "$Percent%";
			
			.game_over.top.right.times.top.right.time configure -text "$_time\s";
			.game_over.top.right.times.top.right.average configure -text "${AverageWinTime}s";
			set Counter 1;
			foreach Time $Scores(best_5_times) {
				if {$Time eq "-"} {continue}
				if {[winfo exists .game_over.top.right.times.bottom.time$Counter]} {
					.game_over.top.right.times.bottom.time$Counter configure -text "$Counter:  ${Time}s";
				} else {
					pack [label .game_over.top.right.times.bottom.time$Counter -text "$Counter:  ${Time}s" -background white] -pady 2;
				}
				incr Counter;
			}
			
			.game_over.top.left.streak.right.win configure -text $Scores(longest_win);
			.game_over.top.left.streak.right.lose configure -text $Scores(longest_lose);
			.game_over.top.left.streak.right.current configure -text $Scores(current);
			
			.game_over.top.left.last25.right.games configure -text $Last25Games;
			.game_over.top.left.last25.right.wins configure -text $Last25Wins;
			
			wm geometry .game_over +$X+$Y
		}
		switch $WinLose {
			"win" {
				wm title .game_over "Game Won";
				.game_over.label configure -text "Game Won!";
			}
			"lose" {
				wm title .game_over "Game Lost";
				.game_over.label configure -text "Game Lost!";
			}
			"scores" {
				wm title .game_over "Scores";
				.game_over.label configure -text "Scores";
				pack forget .game_over.close;
			}
		}
		wm deiconify .game_over;
		#grab set .game_over;
	}
	
#read_scores
#
#The scores file keeps scores for all three difficulties. This proc is called with a difficulty and
#returns the scores for that difficulty
	
	proc read_scores {TargetDifficulty} {
		variable _scores_path;
		
		array set ReturnArray ""
		set File [open $_scores_path "r"]
		foreach Line [split [read $File] "\n"] {
			foreach {Difficulty Field Value} $Line {
				set Difficulty [string trim $Difficulty "\{"];
				if {$Difficulty ne "$TargetDifficulty"} {
					continue;
				}
				set ReturnArray($Field) $Value;
			}
		}
		close $File;
		return [array get ReturnArray];
	}
	
#update_scores
#
#This proc is used to update the scores file. When we write to the file it stomps the contents of the 
#previous file. Therefore we need to rewrite all the contents of the score file, not just the difficulty
#we want.

#Edit March 1 2017. I added a few new fields to the scores file and I cleaned up this proc a little.
#I had to get cute with the syntax in here. I couldn't find a way to get a value out of an array when 
#the array name has a variable substitution. Looks something like this: $Scores${_difficulty}(field). 
#The problem is ${_difficulty} needs to be substituted first, before $Scores...
#My solution was to use "set" as a "get". [set Scores${_difficulty}(field)] will return the value of 
#field in the Scores$_difficulty array.
	
	proc update_scores {WinLose} {
		variable _scores_path;
		variable _time;
		variable _difficulty;
		variable _fixed_board;
		
		foreach Difficulty {easy medium hard} {
			array set Scores$Difficulty [read_scores $Difficulty];
		}
		set Scores${_difficulty}(games_played) [expr {[set Scores${_difficulty}(games_played)] + 1}];
		switch $WinLose {
			"win" {
				set Scores${_difficulty}(games_won) [expr {[set Scores${_difficulty}(games_won)] + 1}];
				
				set LastHundred [set Scores${_difficulty}(last_25)];
				if {$LastHundred eq "-"} {set LastHundred "";}
				append LastHundred "w";
				if {[string length $LastHundred] > 25} {
					set LastHundred [string replace $LastHundred 0 0];
				}
				set Scores${_difficulty}(last_25) $LastHundred;
				
				
				if {[set Scores${_difficulty}(current)] >= 0} {
					set Scores${_difficulty}(current) [expr {[set Scores${_difficulty}(current)] + 1}];
				} else {
					set Scores${_difficulty}(current) 1;
				}
				
				if {[set Scores${_difficulty}(best_time)] eq "-" || [set Scores${_difficulty}(best_time)] > $_time} {
					set Scores${_difficulty}(best_time) $_time;
				}
				
				set BestTimes [string trim [set Scores${_difficulty}(best_5_times)] "-"];
				lappend BestTimes $_time;
				set Scores${_difficulty}(best_5_times) "\{[lrange [lsort -integer $BestTimes] 0 4]\}";
				
				set Scores${_difficulty}(total_win_time) [expr {[set Scores${_difficulty}(total_win_time)] + $_time}];
				
				
				if {[set Scores${_difficulty}(current)] > [set Scores${_difficulty}(longest_win)]} {
					set Scores${_difficulty}(longest_win) [set Scores${_difficulty}(current)];
				}
				
				if {$_fixed_board == 1} {
					set Scores${_difficulty}(board_fixes) [expr {[set Scores${_difficulty}(board_fixes)] + 1}];
					set Scores${_difficulty}(board_fix_wins) [expr {[set Scores${_difficulty}(board_fix_wins)] + 1}];
				}
			}
			"lose" {
				set LastHundred [set Scores${_difficulty}(last_25)];
				if {$LastHundred eq "-"} {set LastHundred "";}
				append LastHundred "l";
				if {[string length $LastHundred] > 25} {
					set LastHundred [string replace $LastHundred 0 0];
				}
				set Scores${_difficulty}(last_25) $LastHundred;
				
				if {[set Scores${_difficulty}(current)] <= 0} {
					set Scores${_difficulty}(current) [expr {[set Scores${_difficulty}(current)] - 1}];
				} else {
					set Scores${_difficulty}(current) -1;
				}
				
				if {[set Scores${_difficulty}(current)] < [set Scores${_difficulty}(longest_lose)]} {
					set Scores${_difficulty}(longest_lose) [set Scores${_difficulty}(current)];
				}
				
				if {$_fixed_board == 1} {
					set Scores${_difficulty}(board_fixes) [expr {[set Scores${_difficulty}(board_fixes)] + 1}];
				}
				
				set Scores${_difficulty}(best_5_times) "\{[set Scores${_difficulty}(best_5_times)]\}";
			}
			"reset" {
				set Scores${_difficulty}(games_played) 0;
				set Scores${_difficulty}(games_won) 0;
				set Scores${_difficulty}(longest_win) 0;
				set Scores${_difficulty}(longest_lose) 0;
				set Scores${_difficulty}(best_time) "-";
				set Scores${_difficulty}(current) 0;
				set Scores${_difficulty}(board_fixes) 0;
				set Scores${_difficulty}(board_fix_wins) 0;
				
				set counter 1;
				foreach Time [set Scores${_difficulty}(best_5_times)] {
					if {$Time eq "-"} {continue;}
					.game_over.top.right.times.bottom.time$counter configure -text "";
					incr counter;
				}
				set Scores${_difficulty}(best_5_times) -;
				set Scores${_difficulty}(total_win_time) 0;
				set Scores${_difficulty}(last_25) -;
				
				set _time 0;
			}
		}
		set File [open $_scores_path "w"];
		foreach Difficulty {easy medium hard} {
			foreach {Field Value} [array get Scores$Difficulty] {
				if {$Field eq "" || $Value eq ""} {
					continue;
				}
				puts $File "$Difficulty $Field $Value";
			}
		}
		close $File;
	}
	
#reset_board
#
#This proc is called when we want to start a new game. Fix all the buttons, recalc the remaining squares
#and mines, and regenerate mines
	
	proc reset_board {} {
		variable _rows;
		variable _columns;
		variable _time 0;
		variable _remaining_mines;
		variable _remaining_squares;
		variable _game_over;
		variable _mines;
		variable _first_click;
		variable _fixed_board;
		variable _active_squares;
		
		set _active_squares "";
		
		if {$_game_over == 1} {
			set _game_over 0;
			.outer_frame.progress_frame.timer configure -text 0;
			.outer_frame.progress_frame.remaining_mines configure -text $_mines;
		} else {
			if {$_first_click == 0} {
				minesweeper::every cancel [list incr _time];
				.outer_frame.progress_frame.timer configure -text 0;
				.outer_frame.progress_frame.remaining_mines configure -text $_mines;
			}
		}
		
		for {set i 1} {$i <= $_rows} {incr i} {
			for {set j 1} {$j <= $_columns} {incr j} {
				.outer_frame.game_board.${i}_${j} configure -bg blue -text "" -state normal -image "";
			}
		}
		set _fixed_board 0;
		set _first_click 1;
		set _remaining_squares [expr {$_rows * $_columns - $_mines}];
		set _remaining_mines $_mines;

		generate_mines;
	}
	
#set_difficulty
#
#This proc is called from the menu when the user is switching difficulties. All we are doing is setting
#the size of the board and number of mines, then we generate a board and populate it with mines.
	
	proc set_difficulty {Difficulty} {
		variable _rows;
		variable _columns;
		variable _mines;
		variable _remaining_mines;
		variable _remaining_squares;
		variable _game_over;
		variable _time 0;
		variable _first_click;
		variable _difficulty;
		
		destroy .outer_frame;
		
		if {$_game_over == 1} {
			set _game_over 0;
		} else {
			if {$_first_click == 0} {
				minesweeper::every cancel [list incr _time];
			}
		}
		
		switch $Difficulty {
			"easy" {
				set _rows 10;
				set _columns 10;
				set _remaining_mines 10;
				set _mines 10;
				set _difficulty "easy";
			}
			"medium" {
				set _rows 16;
				set _columns 16;
				set _remaining_mines 40;
				set _mines 40;
				set _difficulty "medium";
			}
			"hard" {
				set _rows 16;
				set _columns 30;
				set _remaining_mines 99;
				set _mines 99;
				set _difficulty "hard";
			}
		}
		set _first_click 1;
		set _remaining_squares [expr {$_rows * $_columns - $_mines}];
		set _remaining_mines $_mines;
		create_board;
		generate_mines;
	}
	
# check_for_patterns
#
#This proc parses the board and looks for specific patterns which will result in a guess.
#At the top of this file I have drawn out these patterns. As of now this proc is only searching for all
#three patterns but only against walls. These patterns are the most common so this fix alone should
#catch at least half of the game_boards which requires a 50-50 guess. 
#Below this proc are the helper procs for this routine
#
#Big change Feb 23, 2017. After thousands of games I'm fucking tired of fix_first_click placing mines
#into these patterns. Instead of checking for patterns after generating the mines, I now check after the 
#first click. The argument FirstClickSquares contains the first click square as well as the (up to) 8 
#surrounding squares, this ensures mines are not being placed into the first move.
	
	proc check_for_patterns {FirstClickSquares} {
		variable _mine_indexes;
		variable _rows;
		variable _columns;
		
		set ColsMinusTwo [expr {$_columns -2}];
		set RowsMinusTwo [expr {$_rows -2}];
		set SwitchMine 0;
		
#I had to do something fancy when switching on $Col. One of the cases requires variable substitution
#and I could not use subst because some of the variables in the switch have not been set yet. To get around
#this, leave off the braces for the switch and use \ at the end of each case. 
		
		foreach Mine $_mine_indexes {
			set Row [lindex [split $Mine "_"] 0];
			set Col [lindex [split $Mine "_"] 1];
			switch $Col \
				1 {
					# Feb 2017. This algorithm was not looking for this pattern in corners until now.
					# Changed the implementation in this case and the $_columns case to inspect the corners.
					# No change needed when we switch on $Row, since we do not need to look in the same corner
					# twice.
					if {[lsearch $_mine_indexes "[expr {$Row - 1}]_[expr {$Col + 1}]"] >= 0} {
						if {([lsearch $_mine_indexes "[expr {$Row - 2}]_[expr {$Col + 2}]"] >= 0) && \
							([lsearch $_mine_indexes "[expr {$Row + 1}]_[expr {$Col + 2}]"] >= 0 || \
							$Row == $_rows) \
						} {
							set SwitchMine 1;
						}
						if {[lsearch $_mine_indexes "[expr {$Row + 1}]_[expr {$Col + 2}]"] >= 0 && \
							$Row == 2 \
						} {
							set SwitchMine 1;
						}
					}
					if {[lsearch $_mine_indexes "[expr {$Row + 1}]_[expr {$Col + 1}]"] >= 0} {
						if {([lsearch $_mine_indexes "[expr {$Row + 2}]_[expr {$Col + 2}]"] >= 0) && \
							([lsearch $_mine_indexes "[expr {$Row - 1}]_[expr {$Col + 2}]"] >= 0 || \
							$Row == 1) \
						} {
							set SwitchMine 1;
						}
						if {[lsearch $_mine_indexes "[expr {$Row - 1}]_[expr {$Col + 2}]"] >= 0 && \
							[expr {$Row + 1}] == $_rows \
						} {
							set SwitchMine 1;
						}
					}
					if {[lsearch $_mine_indexes "${Row}_[expr {$Col + 1}]"] >= 0} {
						if {[lsearch $_mine_indexes "[expr {$Row - 3}]_$Col"] >= 0 && \
							[lsearch $_mine_indexes "[expr {$Row - 3}]_[expr {$Col + 1}]"] >= 0 \
						} {
							if {[lsearch $_mine_indexes "[expr {$Row - 1}]_$Col]"] >= 0 || \
								[lsearch $_mine_indexes "[expr {$Row - 2}]_$Col"] >= 0 \
							} {
								set SwitchMine 1;
							}
						}
					}
				} \
				$_columns {
					if {[lsearch $_mine_indexes "[expr {$Row - 1}]_[expr {$Col - 1}]"] >= 0} {
						if {([lsearch $_mine_indexes "[expr {$Row - 2}]_[expr {$Col - 2}]"] >= 0) && \
							([lsearch $_mine_indexes "[expr {$Row + 1}]_[expr {$Col - 2}]"] >= 0 || \
							$Row == $_rows) \
						} {
							set SwitchMine 1;
						}
						if {[lsearch $_mine_indexes "[expr {$Row + 1}]_[expr {$Col - 2}]"] >= 0 && \
							$Row == 2 \
						} {
							set SwitchMine 1;
						}
					}
					if {[lsearch $_mine_indexes "[expr {$Row + 1}]_[expr {$Col - 1}]"] >= 0} {
						if {([lsearch $_mine_indexes "[expr {$Row + 2}]_[expr {$Col - 2}]"] >= 0) && \
							([lsearch $_mine_indexes "[expr {$Row - 1}]_[expr {$Col - 2}]"] >= 0 || \
							$Row == 1) \
						} {
							set SwitchMine 1;
						}
						if {[lsearch $_mine_indexes "[expr {$Row - 1}]_[expr {$Col - 2}]"] >= 0 && \
							[expr {$Row + 1}] == $_rows \
						} {
							set SwitchMine 1;
						}
					}
					if {[lsearch $_mine_indexes "${Row}_[expr {$Col - 1}]"] >= 0} {
						if {[lsearch $_mine_indexes "[expr {$Row - 3}]_$Col"] >= 0 && \
							[lsearch $_mine_indexes "[expr {$Row - 3}]_[expr {$Col - 1}]"] >= 0 \
						} {
							if {[lsearch $_mine_indexes "[expr {$Row - 1}]_$Col]"] >= 0 || \
								[lsearch $_mine_indexes "[expr {$Row - 2}]_$Col"] >= 0 \
							} {
								set SwitchMine 1;
							}
						}
					}
				} \
				3 - \
				$ColsMinusTwo {
					set condition 1;
					set SurroundingVertical [minesweeper::get_sqaures $Mine vertical];
					foreach Surrounding $SurroundingVertical {
						if {[lsearch $_mine_indexes $Surrounding] == -1} {
							set condition 0;
							break;
						}
					}
					if {$condition} {
						switch $Col [subst {
							3 {
								if {[lsearch $_mine_indexes "$Row\_[expr {$Col - 1}]"] >= 0 || \
									[lsearch $_mine_indexes "$Row\_[expr {$Col - 2}]"] >= 0
								} {
									set SwitchMine 1;
								}
							}
							$ColsMinusTwo {
								if {[lsearch $_mine_indexes "$Row\_[expr {$Col + 1}]"] >= 0 || \
									[lsearch $_mine_indexes "$Row\_[expr {$Col + 2}]"] >= 0
								} {
									set SwitchMine 1;
								}
							}
						}]
					}
				} \
			;
			if {$SwitchMine} {
				switch_mine $Mine $FirstClickSquares;
				check_for_patterns $FirstClickSquares;
				break;
			}
			switch $Row \
				1 {
					if {[lsearch $_mine_indexes "[expr {$Row + 1}]_[expr {$Col - 1}]"] >= 0} {
						if {[lsearch $_mine_indexes "[expr {$Row + 2}]_[expr {$Col - 2}]"] >= 0 && \
							[lsearch $_mine_indexes "[expr {$Row + 2}]_[expr {$Col + 1}]"] >= 0 \
						} {
							set SwitchMine 1;
						}
					}
					if {[lsearch $_mine_indexes "[expr {$Row + 1}]_[expr {$Col + 1}]"] >= 0} {
						if {[lsearch $_mine_indexes "[expr {$Row + 2}]_[expr {$Col + 2}]"] >= 0 && \
							[lsearch $_mine_indexes "[expr {$Row + 2}]_[expr {$Col - 1}]"] >= 0 \
						} {
							set SwitchMine 1;
						}
					}
					if {[lsearch $_mine_indexes "[expr {$Row + 1}]_$Col"] >= 0} {
						if {[lsearch $_mine_indexes "${Row}_[expr {$Col - 3}]"] >= 0 && \
							[lsearch $_mine_indexes "[expr {$Row + 1}]_[expr {$Col - 3}]"] >= 0 \
						} {
							if {[lsearch $_mine_indexes "${Row}_[expr {$Col - 1}]"] >= 0 || \
								[lsearch $_mine_indexes "${Row}_[expr {$Col - 2}]"] >= 0 \
							} {
								set SwitchMine 1;
							}
						}
					}
				} \
				$_rows {
					if {[lsearch $_mine_indexes "[expr {$Row - 1}]_[expr {$Col - 1}]"] >= 0} {
						if {[lsearch $_mine_indexes "[expr {$Row - 2}]_[expr {$Col - 2}]"] >= 0 && \
							[lsearch $_mine_indexes "[expr {$Row - 2}]_[expr {$Col + 1}]"] >= 0 \
						} {
							set SwitchMine 1;
						}
					}
					if {[lsearch $_mine_indexes "[expr {$Row - 1}]_[expr {$Col + 1}]"] >= 0} {
						if {[lsearch $_mine_indexes "[expr {$Row - 2}]_[expr {$Col + 2}]"] >= 0 && \
							[lsearch $_mine_indexes "[expr {$Row - 2}]_[expr {$Col - 1}]"] >= 0 \
						} {
							set SwitchMine 1;
						}
					}
					if {[lsearch $_mine_indexes "[expr {$Row - 1}]_$Col"] >= 0} {
						if {[lsearch $_mine_indexes "${Row}_[expr {$Col - 3}]"] >= 0 && \
							[lsearch $_mine_indexes "[expr {$Row - 1}]_[expr {$Col - 3}]"] >= 0 \
						} {
							if {[lsearch $_mine_indexes "${Row}_[expr {$Col - 1}]"] >= 0 || \
								[lsearch $_mine_indexes "${Row}_[expr {$Col - 2}]"] >= 0 \
							} {
								set SwitchMine 1;
							}
						}
					}
				} \
				3 - \
				$RowsMinusTwo {
					set condition 1;
					set SurroundingHorizontal [minesweeper::get_sqaures $Mine horizontal];
					foreach Surrounding $SurroundingHorizontal {
						if {[lsearch $_mine_indexes $Surrounding] == -1} {
							set condition 0;
							break;
						}
					}
					if {$condition} {
						switch $Row [subst {
							3 {
								if {[lsearch $_mine_indexes "[expr {$Row - 1}]_$Col"] >= 0 || \
									[lsearch $_mine_indexes "[expr {$Row - 2}]_$Col"] >= 0
								} {
									set SwitchMine 1;
								}
							}
							$RowsMinusTwo {
								if {[lsearch $_mine_indexes "[expr {$Row + 1}]_$Col"] >= 0 || \
									[lsearch $_mine_indexes "[expr {$Row + 2}]_$Col"] >= 0
								} {
									set SwitchMine 1;
								}
							}
						}]
					}
				} \
			;
			if {$SwitchMine} {
				switch_mine $Mine $FirstClickSquares;
				check_for_patterns $FirstClickSquares;
				break;
			}
		}
	}
	
# switch_mine
#
#This proc is used by check_for_patterns, when a pattern is found this proc is used to switch one of 
#the mines to eliminate the pattern. Also want to make sure the mine is not place into the first move.

	proc switch_mine {MineIndex FirstClickSquares} {
		variable _mines;
		variable _mine_indexes;
		variable _rows;
		variable _columns;
		variable _fixed_board;
		
		set _fixed_board 1;
		while {true} {
			set Row [expr {int(rand() * $_rows) + 1}];
			set Column [expr {int(rand() * $_columns) + 1}];
			set NewSquare "$Row\_$Column";
			if {[lsearch $_mine_indexes $NewSquare] == -1 &&\
				[lsearch $FirstClickSquares $NewSquare] == -1 \
			} {
				set ListIndex [lsearch $_mine_indexes $MineIndex];
				lappend _mine_indexes $NewSquare;
				set _mine_indexes [lreplace $_mine_indexes $ListIndex $ListIndex];
				break;
			}
		}
	}
	
# get_sqaures
#
#This method is also used by check_for_patterns. It returns either the vertical or horizontal
#surrounding squares.
	
	proc get_sqaures {Index Surrounding} {
		variable _rows;
		variable _columns;
		
		set SurroundingSquares "";
		set Row [lindex [split $Index "_"] 0];
		set RowMinus [expr {$Row - 1}];
		set RowPlus [expr {$Row + 1}];
		set Column [lindex [split $Index "_"] 1];
		set ColumnMinus [expr {$Column - 1}];
		set ColumnPlus [expr {$Column + 1}];
		
		switch $Surrounding {
			"vertical" {
				switch $Row [subst {
					1 {
						lappend SurroundingSquares $RowPlus\_$Column;
					}
					$_rows {
						lappend SurroundingSquares $RowMinus\_$Column;
					}
					default {
						lappend SurroundingSquares $RowPlus\_$Column;
						lappend SurroundingSquares $RowMinus\_$Column;
					}
				}]
			}
			"horizontal" {
				switch $Column [subst {
					1 {
						lappend SurroundingSquares $Row\_$ColumnPlus;
					}
					$_columns {
						lappend SurroundingSquares $Row\_$ColumnMinus;
					}
					default {
						lappend SurroundingSquares $Row\_$ColumnPlus;
						lappend SurroundingSquares $Row\_$ColumnMinus;
					}
				}]
			}
		}
		return $SurroundingSquares;
	}
	
# ================================================================================
# -------------------------------- SOLVER ----------------------------------------
# ================================================================================
	
	proc solve_board {} {
		variable _rows;
		variable _columns;
		variable _remaining_squares;
		variable _remaining_mines;
		variable _active_squares;
		variable _game_over;
		
		set FirstIndex "[expr $_rows / 2]_[expr $_columns / 2]";
		if {[.outer_frame.game_board.$FirstIndex cget -background] eq "blue"} {
			button_press $FirstIndex;
		}
		while {1} {
			set RemainingSquaresTemp $_remaining_squares;
			solve_flag_mines;
			if {$RemainingSquaresTemp == $_remaining_squares} {
				set ActiveSquaresTemp $_active_squares;
				set RemainingMinesTemp $_remaining_mines;
				solve_advanced_click;
				if {$ActiveSquaresTemp == $_active_squares &&\
					$RemainingMinesTemp == $_remaining_mines \
				} {
					break;
				}
			}
			if {$_game_over} {
				break;
			}
			if {$_remaining_mines == 0} {
				solve_click_remaining "";#This somehow does not get executed
			}
		}
	}
	proc solve_flag_mines {} {
		variable _active_squares;
		
		foreach ActiveIndex $_active_squares {
			set AdjacentMines [.outer_frame.game_board.$ActiveIndex cget -text]
			set AdjacentSquares 0;
			
			set Surrounding [get_surrounding_sqaures $ActiveIndex];
			foreach SurroundingIndex $Surrounding {
				if {[.outer_frame.game_board.$SurroundingIndex cget -background] ne "white"} {
					incr AdjacentSquares;
				}
			}
			if {$AdjacentSquares == $AdjacentMines} {
				set ListIndex [lsearch $_active_squares $ActiveIndex];
				set _active_squares [lreplace $_active_squares $ListIndex $ListIndex];
				
				foreach SurroundingIndex $Surrounding {
					if {[.outer_frame.game_board.$SurroundingIndex cget -background] eq "blue"} {
						set_flag ".outer_frame.game_board.$SurroundingIndex";
					}
				}
			}
		}
		foreach ActiveIndex $_active_squares {
			click_surrounding ".outer_frame.game_board.$ActiveIndex";
		}
	}
	proc solve_advanced_click {} {
		variable _active_squares;
		
		# puts "======================================="
		foreach ActiveIndex $_active_squares {
			array set ActiveResult [solve_advanced_get_index_info $ActiveIndex];
			if {[array get ActiveResult] eq ""} {
				continue;
			}
			
			# puts "solve_advanced_click...ActiveIndex=$ActiveIndex";
			foreach {name value} [array get ActiveResult] {
				# puts "solve_advanced_click...$name=$value";
			}
			# puts "--------------------------------------------"
			
			foreach WhiteAdjacentIndex $ActiveResult(white_indexes) {
				array set WhiteAdjacentResult [solve_advanced_get_index_info $WhiteAdjacentIndex];
				if {[array get WhiteAdjacentResult] eq ""} {
					continue;
				}
				
				set Union "";
				set UniqueActive "";
				set UniqueWhiteAdjacent "";
				foreach Element $ActiveResult(blue_indexes) {
					if {[lsearch $WhiteAdjacentResult(blue_indexes) $Element] ne -1} {
						lappend Union $Element;
					} else {
						lappend UniqueActive $Element;
					}
				}
				foreach Element $WhiteAdjacentResult(blue_indexes) {
					if {[lsearch $ActiveResult(blue_indexes) $Element] eq -1} {
						lappend UniqueWhiteAdjacent $Element;
					}
				}
				
				if {$ActiveResult(remaining) == $WhiteAdjacentResult(remaining)} {
					if {[llength $UniqueActive] == 0} {
						foreach Index $UniqueWhiteAdjacent {
							button_press $Index;
						}
						continue;
					}
				}
				if {[expr {$ActiveResult(remaining) - $WhiteAdjacentResult(remaining)}] == [llength $UniqueActive]} {
					foreach Unique $UniqueActive {
						if {[.outer_frame.game_board.$Unique cget -background] eq "blue"} {
							set_flag ".outer_frame.game_board.$Unique";
						}
					}
					continue;
				}
				# puts "------------------------------------------";
				# puts "WhiteAdjacentIndex=$WhiteAdjacentIndex, ActiveIndex=$ActiveIndex";
				# puts "if special...[llength $UniqueActive], $WhiteAdjacentResult(remaining), $ActiveResult(remaining)"
				if {[llength $UniqueActive] == 0 && $WhiteAdjacentResult(remaining) > $ActiveResult(remaining)} {
					foreach NestedWhiteAdjacentIndex $WhiteAdjacentResult(white_indexes) {
						array set NestedWhiteAdjacentResult [solve_advanced_get_index_info $NestedWhiteAdjacentIndex];
						
						set Found 0;
						set NestedWhiteSuroundingBlue "";
						# puts "(blue_indexes)=$NestedWhiteAdjacentResult(blue_indexes)"
						foreach Index $NestedWhiteAdjacentResult(blue_indexes) {
							lappend NestedWhiteSuroundingBlue $Index
							if {[lsearch $ActiveResult(blue_indexes) $Index] > -1} {
								# puts "Found $Index from $NestedWhiteAdjacentIndex blue indexes, in $ActiveIndex blue indexes"
								set Found 1;
								break;
							}
						}
						if {!$Found} {
							# puts "Not Found...WhiteAdjacentIndex=$WhiteAdjacentIndex, NestedWhiteAdjacentIndex=$NestedWhiteAdjacentIndex";
							set NewWhiteAdjacentRemaining [expr {$WhiteAdjacentResult(remaining) - $ActiveResult(remaining)}];
							
							set NestedUnion "";
							set NestedUniqueNested "";
							set NestedUniqueWhite "";
							foreach Element $NestedWhiteAdjacentResult(blue_indexes) {
								if {[lsearch $WhiteAdjacentResult(blue_indexes) $Element] ne -1} {
									lappend NestedUnion $Element;
								} else {
									lappend NestedUniqueNested $Element;
								}
							}
							foreach Element $WhiteAdjacentResult(blue_indexes) {
								if {[lsearch $NestedWhiteAdjacentResult(blue_indexes) $Element] eq -1} {
									if {[lsearch $ActiveResult(blue_indexes) $Element] eq -1} {
										lappend NestedUniqueWhite $Element;
									}
								}
							}
							
							# puts "WHITE...unique length=[llength NestedUniqueWhite], remaining=$NewWhiteAdjacentRemaining"
							# puts "NESTED...unique length=[llength NestedUniqueNested], remaining=$NestedWhiteAdjacentResult(remaining)"
							
							if {$NestedWhiteAdjacentResult(remaining) == $NewWhiteAdjacentRemaining} {
								if {[llength $NestedUniqueWhite] == 0} {
									foreach Index $NestedUniqueNested {
										button_press $Index;
									}
								}
								if {[llength $NestedUniqueNested] == 0} {
									foreach Index $NestedUniqueWhite {
										button_press $Index;
									}
								}
								continue;
							}
							
							if {[expr {$NestedWhiteAdjacentResult(remaining) - $NewWhiteAdjacentRemaining}] == [llength $NestedUniqueNested]} {
								foreach Unique $NestedUniqueNested {
									if {[.outer_frame.game_board.$Unique cget -background] eq "blue"} {
										set_flag ".outer_frame.game_board.$Unique";
									}
								}
								continue;
							}
							if {[expr {$NewWhiteAdjacentRemaining - $NestedWhiteAdjacentResult(remaining)}] == [llength $NestedUniqueWhite]} {
								foreach Unique $NestedUniqueWhite {
									if {[.outer_frame.game_board.$Unique cget -background] eq "blue"} {
										set_flag ".outer_frame.game_board.$Unique";
									}
								}
								continue;
							}
						}
					}
					continue
				}
			}
		}
	}
	proc solve_advanced_get_index_info {Index} {
		variable _active_squares;
		variable _remaining_mines;
		variable _remaining_squares;
		
		set RemainingMines [.outer_frame.game_board.$Index cget -text];
		
		if {![string is integer $RemainingMines]} {
			set ListIndex [lsearch $_active_squares $Index];
			if {$ListIndex != -1} {
				set _active_squares [lreplace $_active_squares $ListIndex $ListIndex];
			}
			return "";
		}
		
		set RemainingMoveIndexes "";
		set SurroundingWhite "";
		
		set Surrounding [get_surrounding_sqaures $Index];
		foreach SurroundingIndex $Surrounding {
			switch [.outer_frame.game_board.$SurroundingIndex cget -background] {
				"white" {
					if {[lsearch $_active_squares $SurroundingIndex] != -1} {
						lappend SurroundingWhite $SurroundingIndex;
					}
				}
				"blue" {
					lappend RemainingMoveIndexes $SurroundingIndex;
					set NestedSurrounding [get_surrounding_sqaures $SurroundingIndex];
					foreach NestedSurroundingIndex $NestedSurrounding {
						if {$NestedSurroundingIndex eq $Index} {
							continue;
						}
						if {[.outer_frame.game_board.$NestedSurroundingIndex cget -background] eq "white"} {
							if {[lsearch $_active_squares $NestedSurroundingIndex] != -1} {
								lappend SurroundingWhite $NestedSurroundingIndex;
							}
						}
					}
				}
				"yellow" {
					incr RemainingMines -1;
				}
			}
		}
		if {$RemainingMines == $_remaining_mines} {
			solve_click_remaining $RemainingMoveIndexes;
			return "";
		}
		set Result(white_indexes) [lsort -unique $SurroundingWhite];
		set Result(blue_indexes) $RemainingMoveIndexes;
		set Result(remaining) $RemainingMines;
		
		return [array get Result];
	}
	proc solve_click_remaining {NoClickSquares} {
		variable _rows;
		variable _columns;
		
		for {set i 1} {$i <= $_rows} {incr i} {
			for {set j 1} {$j <= $_columns} {incr j} {
				set Index ${i}_${j};
				if {[.outer_frame.game_board.$Index cget -background] eq "blue"} {
					if {[lsearch $NoClickSquares $Index] == -1} {
						button_press $Index;
					}
				}
			}
		}
	}
}
minesweeper::main;
focus .;






