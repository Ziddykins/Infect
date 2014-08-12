#!/usr/bin/perl

use warnings; use strict;
use Getopt::Long;

my ($ysize, $xsize, $mapfile,
	$slow, $fast, $fastest,
	$doctors, $infected, $soldiers, $nurses,
	$wood, $help, $quiet);

GetOptions ("x=s" => \$xsize,
			"y=s" => \$ysize,
			"map=s" => \$mapfile,
			"d=s" => \$doctors,
			"i=s" => \$infected,
			"s=s" => \$soldiers,
			"n=s" => \$nurses,
			"w=s" => \$wood,
			"slow" => \$slow,
			"fast" => \$fast,
			"fastest" => \$fastest,
			"h" => \$help,
			"help" => \$help,
			"q" => \$quiet,
			"quiet" => \$quiet);

#display help
if ($help) { &help; }

#No map arguments? use default values
if (!$xsize and !$ysize and !$mapfile) { 
	$xsize = 50;
	$ysize = 100;
}


my @grid;
my $len;
my $days	= 0;
my $dead	= 0;
my $gen		= 0;
my $count	= 0;
my $disp	= 1;
my $ff		= 0;
my $total	= 0;
my $timeout	= 200000;

if (!$wood and !$mapfile) {
	$wood = int($xsize * $ysize * 0.5);
}
#if not defined, set initial value for doctors, infected, soldiers and nurses
if (!$doctors and !$mapfile) {
	$doctors  = int($xsize * $ysize * 0.01)+1;
}
if (!$infected and !$mapfile) {
	$infected = int($xsize * $ysize * 0.01)+1;
}
if (!$soldiers and !$mapfile) {
	$soldiers = int($xsize * $ysize * 0.02)+1;
}
if (!$nurses and !$mapfile) {
	$nurses = int($xsize * $ysize * 0.05)+1;
}


my $citizens = 0;
$SIG{INT}    = \&interrupt;


#User tries to supply map and map size?
if ($mapfile and $ysize or $mapfile and $xsize) {
    die "Can't specify size and map\n";
}

#Forgot x or y?
if ($xsize and !$ysize or $ysize and !$xsize) {
    die "Missing pair coordinate\n";
}

#Multiple speeds set?
if ($slow and $fast or $slow and $fastest) { die "Select one speed\n"; }
if ($fast and $slow or $fast and $fastest) { die "Select one speed\n"; }
if ($fastest and $slow or $fastest and $fast) { die "Select one speed\n"; }

#If no speed is set, only show results at the end
if (!$slow and !$fast and !$fastest and !$quiet) {
    print "No speed selected, only displaying results\n";
}

#Load the map and check for characters we don't recognize
if ($mapfile) {
    open(my $fh, '<', $mapfile) or die "Can't open file $mapfile for reading\n";
    $citizens = 0; $infected = 0; $doctors = 0; $nurses = 0; $soldiers = 0;
    while (my $line = <$fh>) {
        chomp($line);
        $len = length($line);
        my @temp = split(//, $line);
        foreach my $let (@temp) {
            if ($let !~ /[IOWDNXS ]/) {
                die "Invalid characters in map file\n";
            } else {
                if ($let eq "I") {
                    $infected++;
                } elsif ($let eq "D") {
                    $doctors++;
                } elsif ($let eq "S") {
                    $soldiers++;
                } elsif ($let eq "O") {
                    $citizens++;
                }
                $total++;
            }
        }
        push @grid, [ split(//, $line) ];
    }
}

#Generate the grid
if ($xsize and $ysize) {
	for(my $i=0; $i<$xsize; $i++) {
		for(my $j=0; $j<$ysize; $j++) {
			$grid[$i][$j] = "O"; $citizens++;
			$total++;
		}
	}
	my $tmpinfected = $infected;
	while ($tmpinfected > 0){
		my $x = int(rand(scalar(@grid)-1));
		my $y = int(rand(scalar(@grid)*2-1));
		if($grid[$x][$y] eq "O"){
			$grid[$x][$y] = "I";
			$tmpinfected--;
			$citizens--;
		}
	}
	my $tmpdoctors = $doctors;
	while ($tmpdoctors > 0){
		my $x = int(rand(scalar(@grid)-1));
		my $y = int(rand(scalar(@grid)*2-1));
		if($grid[$x][$y] eq "O"){
			$grid[$x][$y] = "D";
			$tmpdoctors--;
			$citizens--;
		}
	}
	my $tmpnurses = $nurses;
	while ($tmpnurses > 0){
		my $x = int(rand(scalar(@grid)-1));
		my $y = int(rand(scalar(@grid)*2-1));
		if($grid[$x][$y] eq "O"){
			$grid[$x][$y] = "N";
			$tmpnurses--;
			$citizens--;
		}
	}
	my $tmpsoldiers = $soldiers;
	while ($tmpsoldiers > 0){
		my $x = int(rand(scalar(@grid)-1));
		my $y = int(rand(scalar(@grid)*2-1));
		if($grid[$x][$y] eq "O"){
			$grid[$x][$y] = "S";
			$tmpsoldiers--;
			$citizens--;
		}
	}
}


#Uncomment and comment above to manually set locations.
#maybe command line arguments like a normal person? hint hint
#$grid[7][0] = "D";
#$grid[8][0] = "D";
#$grid[2][0] = "D";
#$grid[3][0] = "D";
#$grid[8][1] = "D";
#$grid[9][1] = "D";
#$grid[0][1] = "D";
#$grid[1][1] = "D";
#$grid[2][1] = "D";
#$grid[0][2] = "D";
#$grid[9][0] = "I";
#$grid[0][0] = "I";
#$grid[1][0] = "I";

#Get our dimensions if a map is supplied.
if ($mapfile) {
    $xsize = scalar(@grid)-1;
    $ysize = $len-1;
    $wood = int($xsize * $ysize * 0.5);
}

while (1) {
	$days++; 
	#If there's no infected, y'dun winned
	$total = 0;
	$infected = 0;
	$doctors = 0;
	$soldiers = 0;
	$nurses = 0;
	$citizens = 0;
	for(my $n=0; $n<$xsize; $n++) {
		for(my $m=0; $m<$ysize; $m++) {
			if ($grid[$n][$m] eq "I") {
				$infected++;
			} elsif ($grid[$n][$m] eq "N") {
				$nurses++;
				$total++;
			} elsif ($grid[$n][$m] eq "D") {
				$doctors++;
				$total++;
			} elsif ($grid[$n][$m] eq "O") {
				$citizens++;
				$total++;
			} elsif ($grid[$n][$m] eq "S") {
				$soldiers++;
				$total++;
			}
		}
	}
	if ($infected >= ($citizens + $nurses + $doctors + $soldiers)*3) { win(0); }
	if ($soldiers >= ($citizens + $nurses + $doctors)*1.5 and $soldiers >= $infected) { win(3); } 
	if ($count >= $timeout) { win(1); }
	if ($infected == 0) {
		win(2);
	}
	
	#Just keep iterating through the entire grid one by one
	for(my $i=0; $i<$xsize; $i++) {
		for(my $j=0; $j<$ysize; $j++) {
			my $chance = int(rand(101));
			my $doctor = int(rand(101));
			$count++;
			if ($grid[$i][$j] eq "W") { next; 
			
			#1% chance for dead bodies to decay spontaneously
			} elsif ($grid[$i][$j] eq "X") {
				if($chance == 1) {
					$grid[$i][$j] = " ";
				}
			#doctors and nurses move
			} elsif ($grid[$i][$j] eq "D" or $grid[$i][$j] eq "N") {
				medical($i, $j, $chance, $doctor);
			#citizens move
			} elsif ($grid[$i][$j] eq "O") {
				citizen($i, $j, $chance, $doctor);
			#infected move
			} elsif ($grid[$i][$j] eq "I") {
				infected($i, $j, $chance, $doctor);				
			#soldiers move
			} elsif ($grid[$i][$j] eq "S") {
				soldier($i,$j, $chance, $doctor);
			}
			if ($slow) { &printmap; }
		}
		if ($fast) { &printmap; }
	}
	&move;
	if ($fastest) { &printmap; }
}
sub medical {
	my ($i, $j, $chance, $doctor) = @_;
	my $ci = $i;
	my $cj = $j;
	my $dir	= int(rand(4));
	($ci, $cj) = sdir($ci, $cj, $dir);
	my $let	= $grid[$ci][$cj];
	my $which  = $grid[$i][$j];
	if (defined($let)) {
		#Miraculous revival
		if ($doctor == 0 and $let eq "X") {
			$grid[$ci][$cj] = "O";
			$dead--; $citizens++;
			$count = 0;
		}
		#nurse heals infected
		elsif ($which eq "N" and $doctor <= 20 and $let eq "I") {
			$infected--; $citizens++;
			$grid[$ci][$cj] = "O";
		#doctor teaches	
		} elsif ($which eq "D" and $doctor <= 20) {
			if ($let eq "O") {
				$citizens--; $nurses++;
				$grid[$ci][$cj] = "N";
			}
			if ($let eq "N" and int(rand(2)) == 1) {
				$nurses--; $doctors++;
				$grid[$ci][$cj] = "D";
			}
		#doctor heals infected
		} elsif ($doctor <= 25) {
			if ($let eq "I") {
				$infected--; $citizens++;
				$grid[$ci][$cj] = "O";
			}
		}
		$count = 0;
	}
}

sub citizen {
	my ($i, $j, $chance, $doctor) = @_;
	my $ci = $i;
	my $cj = $j;
	#Citizen's turn
	if ($chance <= 15) {
		my $dir = int(rand(4));
		($ci, $cj) = sdir($ci, $cj, $dir);
		#Can we build here? Do we have enough resources?
		#Has enough time passed to take up carpentry?
		if (defined($grid[$ci][$cj])) {
			if ($grid[$ci][$cj] eq " ") {
				if ($wood >= 25) {
					if ($days >= 100) {
						$grid[$ci][$cj] = "W";
						$wood -= int(rand(24))+1;
						$count = 0;
					}
				}
			}
		}
	#Citizens joins the militia
	} elsif ($chance == 100) {
		$citizens--; $soldiers++;
		$grid[$i][$j] = "S";
	}			
}

sub infected {
	my ($i, $j, $chance, $doctor) = @_;
	my $ci = $i;
	my $cj = $j;
	#infections can happen in all directions around the infected
	for( my $dir = 0; $dir < 4; $dir++) {
		if ($chance > 95) {
			($ci, $cj) = sdir($ci, $cj, $dir);
			if (defined($grid[$ci][$cj])) {
				#infect citizens
				if ($grid[$ci][$cj] eq "O") {
					#citizen becomes infected
					$grid[$ci][$cj] =  "I";
					$infected++; $citizens--;
				#infected can break down walls
				} elsif ($grid[$ci][$cj] eq "W" and $doctor < 5) {
					$grid[$ci][$cj] = " ";
					$wood+=int(rand(24))+1;
				#infect doctors or nurses
				} elsif ($grid[$ci][$cj] eq "D" or $grid[$ci][$cj] eq "N") {
					my $which = $grid[$ci][$cj];
					if ($doctor <= 25) {
						#doctor dies
						$grid[$ci][$cj] = "X";
						$dead++;
						if ($which eq "D") {
							$doctors--;
						} elsif ($which eq "N") {
							$nurses--;
						}
					} elsif ($doctor <= 30) {
						#infected dies
						$grid[$i][$j] = "X";
						$dead++; $infected--;
					} elsif ($doctor <= 60) {
						#doctor/nurse converted into infected
						$grid[$ci][$cj] = "I";
						$infected++;
						if ($which eq "D") {
							$doctors--;
						} elsif ($which eq "N") {
							$nurses--;
						}
					} elsif ($doctor <= 70) {
						#infected healed to citizen
						$grid[$i][$j] = "O";
						$infected--; $citizens++;
					} elsif ($doctor <= 100) {
						#both doctor/nurse and infected die
						$grid[$i][$j]   = "X";
						$grid[$ci][$cj] = "X";
						$infected--;
						$dead += 2;
						if ($which eq "D") {
							$doctors--;
						} elsif ($which eq "N") {
							$nurses--;
						}
					}
				#infect soldiers
				} elsif ($grid[$ci][$cj] eq "S"){
					#soldier manages to kill infected before becoming infected
					if ($doctor < 10) {
						$grid[$i][$j] = "X";
						$infected--; $dead++;
					#soldier kills the infected but becomes infected himself
					} elsif ($doctor < 60) {
						$grid[$i][$j] = "X";
						$grid[$ci][$cj] = "I";
						$soldiers--; $dead++;
					#soldier gets infected
					} elsif ($doctor < 90) {
						$grid[$ci][$cj] = "I";
						$soldiers--; $infected++;
					#soldier kills himself before becoming infected
					} else {
						$grid[$ci][$cj] = "X";
						$soldiers--; $dead++;
					}
				}
				$count = 0;
			}
		}
	}
}

sub soldier {
	my ($i, $j, $chance, $doctor) = @_;
	#Murderous Soldier's turn
	my $r1 = int(rand(2));
	my $r2 = int(rand(3));
	my $p1 = int(rand(2));
	my $p2 = int(rand(2));
	my $ci = $i;
	my $cj = $j;
	my $rchance = int(rand(101));
	if ($p1) { $ci += $r1; } else { $ci -= $r1; }
	if ($p2) { $cj += $r2; } else { $cj -= $r2; }
	if(defined($grid[$ci][$cj])) {
		my $which = $grid[$ci][$cj];
		if ($which =~ /[D|N]/ and $rchance <= 1) {
			$rchance = int(rand(101));
		}
		if ($rchance <= 80) {
			#If a citizen is in our radius of 2x3, don't shoot
			#Doctors are fine though, who likes going to 
			#the doctor's anyway, they're scary.
			my $fail = 0;
			my $inf  = 1;
			for(my $k=$i-2; $k<$i+3; $k++) {
				for(my $l=$j-3; $l<$j+4; $l++) {
					my $which = $grid[$k][$l];
					if (defined($which)) {
						if ($which eq "O") {
							$fail = 1;
						}
						if ($which eq "I") {
							$inf = 1;
						}
					}
				}
			}
			if ($fail) { ; }
			elsif (!$inf) { ; }
			elsif ($which eq "I") {
				$grid[$ci][$cj] = "X";
				$infected--; $dead++;
				$count = 0;
			} elsif ($which eq "O") {
				if ($rchance >= 20) {
					$grid[$ci][$cj] = "S";
					$citizens--; $soldiers++;
					$count = 0;
				}
			#Doctor or nurse is a victim of friendly 
			#fire amidst the chaos
			} elsif ($grid[$ci][$cj] eq "D" or $grid[$ci][$cj] eq "N") {
				if ($rchance <= 1) {
					$grid[$ci][$cj] = "X";
					$dead++; $ff++;
					if ($which eq "D") {
						$doctors--;
					} elsif ($which eq "N") {
						$nurses--;
					}
					$count = 0;
				}
			#We train our soldiers to kill, then clean up that mess
			} elsif ($grid[$ci][$cj] eq "X") {
				$grid[$ci][$cj] = " ";
			}
		}
	}
}

sub move {
    for(my $i=0; $i<$xsize; $i++) {
        for(my $j=0; $j<$ysize; $j++) {
            #Each unit excluding walls and bodies move in a random direction
            #after they've completed their action (N/W/S/E)
            #Except for that one time when I forgot to include bodies.
            #I bet that was horrific for citizens.
            if ($grid[$i][$j] =~ /[W|X|\s]/) { next; }
            my $dir = int(rand(4));
            my $ci = $i;
            my $cj = $j;
            ($ci, $cj) = sdir($ci, $cj, $dir);
			#Politely switch spots with non-wall, non-dead space
			if (defined($grid[$ci][$cj])) {
				my $tmp = $grid[$ci][$cj];
				if ($tmp eq "W" or $tmp eq "X") {
					next;
				} elsif (int(rand(10))<3) {
					$grid[$ci][$cj] = $grid[$i][$j];
					$grid[$i][$j] = $tmp;
				}
			}
        }
    }
}

sub printmap {
	$disp  = 0;
	print"\033[1;1H";
	for(my $i=0; $i<$xsize; $i++) {
	   for(my $j=0; $j<$ysize; $j++) {
		if ($grid[$i][$j] eq "O") {
		     print "\x1b[32;1m" . $grid[$i][$j];
		} elsif ($grid[$i][$j] eq "I") {
		    print "\x1b[31;1m" . $grid[$i][$j];
		} elsif ($grid[$i][$j] eq "D") {
		     print "\x1b[36;1m" . $grid[$i][$j];
		} elsif ($grid[$i][$j] eq "S") {
		     print "\x1b[35;1m" . $grid[$i][$j];
		} elsif ($grid[$i][$j] eq " ") {
		     print "\x1b[37;1m" . $grid[$i][$j];
		} elsif ($grid[$i][$j] eq "N") {
		     print "\x1b[33;1m" . $grid[$i][$j];
		} elsif ($grid[$i][$j] eq "W") {
		     print "\x1b[32;1m\x1b[42;1m" . $grid[$i][$j] . "\x1b[0m";
		} else {
		    print "\x1b[37;1m" . $grid[$i][$j];
		}
	    }
	    print "\x1b[0m\n";
	}
	print "=" x $ysize . "\n";
	print "Doctors: $doctors - Infected: $infected - Citizens: $citizens          \n" .
	  "Nurses: $nurses - Soldiers: $soldiers - Dead: $dead (Friendly Fire: " .
	  " $ff) - Day: $days       \n";
}

sub win {
    if(!$quiet){
	    my $result;
	    #Was the function told we won? How?
	    if ($_[0] == 2) {
			$result = "for the infection to be eliminated\n";
		} elsif ($_[0] == 1) {
			$result = "for the infection to be contained\n";
	    } elsif ($_[0] == 3) {
			$result = "for a military dictatorship to be established\n";
		} else {
		$result = "for the world to descend into chaos\n";
	    }
	    print "\033[2J\033[1;1H";
	    &printmap;
	    print "It only took " . $days . " days $result";
	    print "Doctors: $doctors - Infected: $infected - Citizens: $citizens\n" .
		  "Nurses: $nurses - Soldiers: $soldiers - Dead: $dead (Friendly Fire: " .
		  " $ff) - Day: $days\n";
	    print "Enter to end... ";
	    my $bye = <STDIN>;
	    print "Simulation ended\n";
	    exit(0);
    } else {
	if ($_[0] == 1 || $_[0] == 2){
		print "citizens win\n";
	} elsif ($_[0] == 3) {
		print "military wins\n";
	} else {
		print "virus wins\n";
	}
	exit(0);
    }
}

sub sdir {
    my ($ci, $cj, $dir) = @_;
    if ($dir == 0) {
        $ci++;
    } elsif ($dir == 1) {
        $cj--;
    } elsif ($dir == 2) {
        $ci--;
    } elsif ($dir == 3) {
        $cj++;
    }
    return ($ci, $cj);
}

sub help {
    print "--map <str>\t\tSpecify a file to read from containing a map\n";
    print "--x <int>\t\tUse in conjunction with --y <int> to specify dimensions of auto-generated map\n";
    print "--y <int>\t\tSee above\n";
    print "--slow\t\t\tRun the simulation with slow speed. Very slow.\n";
    print "--fast\t\t\tRun the simulation with fast speed. Almost real-time!\n";
    print "--fastest\t\tRun the simulation at fastest speed.\n";
    print "--d <int>\t\tSpecify the initial number of doctors\n";
	print "--i <int>\t\tSpecify the initial number of infected\n";
    print "--n <int>\t\tSpecify the initial number of nurses\n";
    print "--s <int>\t\tSpecify the initial number of soldiers\n";
    print "--w <int>\t\tSpecify initially available wood\n";
    print "--h or --help\t\tDisplay this message\n";
    exit(0);
}
sub interrupt {
    print "\033[2J\033[1;1H\n";
    die "Simulation interrupted by user";
}
