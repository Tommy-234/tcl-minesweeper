# tcl-minesweeper
Minesweeper with smart mine placement &amp; solver

Here I have recreated the classic Windows game, Minesweeper. In the original Windows version, mines are place randomly which results in 
game boards where the user has to guess between two available spaces, where one contains a mine and the other is safe. There is no way to
determine which space is safe, forcing the user to guess. Having played hundreds, even thousdands of games, this started to annoy me.

In this version of minesweeper, the mines are placed randomly but the board is then parsed to look for specific patterns that result in
the user being forced to make a 50:50 guess. This board parser looks for several patterns and successfully fixes the board by randomly
switching one of the troubled mines. Some of these patterns are illustrated in the leading comment in the source code.

This game also includes a solver which will complete as much of the board as it can before it has to guess. About 1 in 5 times the solver
is able to completely solve the board.



I have run this tcl script in tcl 8.4 as well as 8.6. Tcl can be downloaded at ActiveState's website: https://www.activestate.com/products/tcl/downloads/

Follow the install instructions then simply source the file in a tkcon by executing:
  source path/to/file.tcl
Or from the menu in tkcon, do File > Load File and select the tcl script from the file explorer.
