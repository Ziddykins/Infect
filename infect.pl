#!/usr/bin/perl

use warnings; use strict;
use Getopt::Long;

my ($ysize, $xsize, $mapfile,
    $slow, $fast, $fastest);

GetOptions ("x=s" => \$xsize,
            "y=s" => \$ysize,
            "map=s" => \$mapfile,
            "slow" => \$slow,
            "fast" => \$fast,
            "fastest" => \$fastest);
my @grid;

my ($len, $days, $doctors, $infected, $dead,
    $citizens, $gen, $count, $angels, $soldiers,
    $nurses, $ff, $total, $fcolor, $walls) = (0,0,0,0,0,
                                              0,0,0,0,0,
                                              0,0,0,1,0);
my $timeout  = 200000;
$SIG{INT}    = \&interrupt;

#No map arguments?
if (!$xsize and !$ysize and !$mapfile) {
    &help;
    print "No arguments supplied: run default values? [y/n]: ";
    my $choice = <STDIN>;
    if ($choice =~ /^y[es]?/i or $choice eq "\n") {
        $ysize = 79;
        $xsize = 20;
        $fast  =  1 if (!$slow and !$fastest);
    } else {
        die "Simulation canceled";
    }
}

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
if (!$slow and !$fast and !$fastest) {
    print "No speed selected, only displaying results\n";
}

#Load the map and check for characters we don't recognize
if ($mapfile) {
    open(my $fh, '<', "$mapfile") or die "Can't open file $mapfile for reading\n";
    while (my $line = <$fh>) {
        chomp($line);
        $len = length($line);
        my @temp = split(//, $line);
        foreach my $let (@temp) {
            if ($let !~ /[IOAWDNFXS ]/) {
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
                } elsif ($let eq "X") {
                    $dead++;
                } elsif ($let eq "N") {
                    $nurses++;
                } elsif ($let eq "W") {
                    $walls++;
                }
                $total++;
            }
        }
        push @grid, [ split(//, $line) ];
    }
}

my $t_init = $walls;

#Generate the grid
if (!$mapfile) {
    for(my $i=0; $i<$xsize; $i++) {
        for(my $j=0; $j<$ysize; $j++) {
            $grid[$i][$j] = "O"; $citizens++;
            $total++;
        }
    }
    #Assign the units to random locations within the array constraints
    $grid[int(rand(scalar(@grid)-1))][int(rand(scalar(@grid)*2-1))] = "I";
    $grid[int(rand(scalar(@grid)-1))][int(rand(scalar(@grid)*2-1))] = "I";
    $grid[int(rand(scalar(@grid)-1))][int(rand(scalar(@grid)*2-1))] = "I";
    $grid[int(rand(scalar(@grid)-1))][int(rand(scalar(@grid)*2-1))] = "D";
    $grid[int(rand(scalar(@grid)-1))][int(rand(scalar(@grid)*2-1))] = "D";
    $grid[int(rand(scalar(@grid)-1))][int(rand(scalar(@grid)*2-1))] = "D";
    $grid[int(rand(scalar(@grid)-1))][int(rand(scalar(@grid)*2-1))] = "D";
    $grid[int(rand(scalar(@grid)-1))][int(rand(scalar(@grid)*2-1))] = "D";
    $grid[int(rand(scalar(@grid)-1))][int(rand(scalar(@grid)*2-1))] = "D";
    $grid[int(rand(scalar(@grid)-1))][int(rand(scalar(@grid)*2-1))] = "D";
    $grid[int(rand(scalar(@grid)-1))][int(rand(scalar(@grid)*2-1))] = "D";
    $grid[int(rand(scalar(@grid)-1))][int(rand(scalar(@grid)*2-1))] = "D";
    $grid[int(rand(scalar(@grid)-1))][int(rand(scalar(@grid)*2-1))] = "D";
    $grid[int(rand(scalar(@grid)-1))][int(rand(scalar(@grid)*2-1))] = "S";
    $citizens -= 14; $infected += 3; $soldiers += 1; $doctors += 10;
}

#Get our dimensions if a map is supplied.
if ($mapfile) {
    $xsize = scalar(@grid);
    $ysize = $len;
}

#clear the screen
print "\x1b[2J\x1b[1;1H";

#amount of wood available based on grid size
my $wood = $total * 0.5;

while (1) {
    $days++;
    if ($infected >= ($total * 0.75)) { win(0); }
    if ($count >= $timeout) { win(1); }

    #If there's no infected, y'dun winned
    my $noin = 0;
    for(my $n=0; $n<$xsize; $n++) {
        for(my $m=0; $m<$ysize; $m++) {
            if (!grep(/I/, $grid[$n][$m])) {
                $noin++;
            }
        }
    }
    if ($noin >= $total) {
        win(1);
    }

    #Just keep iterating through the entire grid one by one
    for(my $i=0; $i<$xsize; $i++) {
        for(my $j=0; $j<$ysize; $j++) {
            my $chance = int(rand(101));
            my $doctor = int(rand(101));
            $count++;
            my $ci = $i;
            my $cj = $j;
            if ($days % 200 == 0) {
                my $k   = int(rand($xsize));
                my $l   = int(rand($ysize));
                my $try = 0;
                unless ($angels) {
                    while ($try < $xsize * $ysize) {
                        $k = int(rand($xsize));
                        $l = int(rand($ysize));
                        if ($grid[$k][$l] eq " ") {
                            $grid[$k][$l] = "A";
                            $angels++;
                            $try = $xsize * $ysize;
                        }
                        $try++;
                    }
                }
            }
            #Who's turn is it?
            if ($grid[$i][$j] eq "I") {
                infected($chance, $doctor, $i, $j, $ci, $cj);
            } elsif ($grid[$i][$j] eq "D" or $grid[$i][$j] eq "N") {
                doctors($chance, $doctor, $i, $j, $ci, $cj);
            } elsif ($grid[$i][$j] eq "O") {
                citizens($chance, $doctor, $i, $j, $ci, $cj);
            } elsif ($grid[$i][$j] eq "S") {
                soldiers($chance, $doctor, $i, $j, $ci, $cj);
            } elsif ($grid[$i][$j] eq "A") {
                angels($chance, $doctor, $i, $j, $ci, $cj);
            }
            if ($slow) { &printmap; }            
        }
        if ($fast) { &printmap; }
    }
    &move;
    if ($fastest) { &printmap; }
}

sub move {
    for(my $i=0; $i<$xsize; $i++) {
        for(my $j=0; $j<$ysize; $j++) {
            my $which = $grid[$i][$j];
            #Each unit excluding WXF and open move in a random direction
            #after they've completed their action
            #Except for that one time when I forgot to include bodies.
            #I bet that was horrific for citizens.
            if ($which =~ /[WXF ]/) { next; }
            my $dir;
            if ($which eq "A") {
                $dir = int(rand(8));
            } else {
                $dir = int(rand(4));
            }

            my $ci = $i;
            my $cj = $j;
            ($ci, $cj) = sdir($ci, $cj, $dir, $which);
            #Politely switch Spots with the open space
            if (defined($grid[$ci][$cj])) {
                if ($grid[$ci][$cj] eq " ") {
                    $grid[$ci][$cj] = $grid[$i][$j];
                    $grid[$i][$j] = " ";
                }
            }
        }
    }
}

sub printmap {
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
            } elsif ($grid[$i][$j] eq "A") {
                print "\x1b[31;1m\x1b[43;1m" . $grid[$i][$j] . "\x1b[0m";
            } elsif ($grid[$i][$j] eq "F") {
                my $prev = $fcolor;
                if ($days % 100 == 0) {
                    $fcolor = 1;
                } elsif ($days % 50 == 0) {
                    $fcolor = 3;
                }
                print "\x1b[3$fcolor" . ";1m" . $grid[$i][$j];
            } else {
                print "\x1b[37;1m" . $grid[$i][$j];
            }
        }
        print "\x1b[0m|\n";
    }
    my $healthy = $doctors + $nurses + $citizens + $soldiers;
    my $str = "Day: $days - Infected: $infected - Citizens: $citizens" .
              " - Healthy: ($healthy/" . ($total - $t_init) . ")";
    print $str;
    print "=" x (($ysize - length($days)) - length($str) + 2)  . "\r";
}
        
sub win {
    my $result;
    #Was the function told we won? How?
    if ($_[0] == 1) {
        if (!$infected) {
            $result = "for the infection to be eliminated\n";
        } else {
            $result = "for the infection to be contained\n";
        }
    } else {
        $result = "for the world to descend into chaos\n";
    }
    print "\x1b[2J\x1b[1;1H";
    &printmap;
    print "It only took " . $days . " days $result";
    print "Doctors: $doctors - Infected: $infected - Citizens: $citizens\n" .
          "Nurses: $nurses - Soldiers: $soldiers - Dead: $dead (Friendly Fire: " .
          " $ff) - Day: $days\n";
    print "Press any key to end... ";
    my $bye = <STDIN>;
    die "End of simulation";
}

sub sdir {
    my ($ci, $cj, $dir, $which) = @_;
    if ($dir == 0) {
        $which eq "S" ? $ci += 2 : $ci++;
    } elsif ($dir == 1) {
        $which eq "S" ? $cj -= 2 : $cj--;
    } elsif ($dir == 2) {
        $which eq "S" ? $ci -= 2 : $ci--;
    } elsif ($dir == 3) {
        $which eq "S" ? $cj += 2 : $cj++;
    } elsif ($dir == 4) {
        $cj++; $ci++;
    } elsif ($dir == 5) {
        $cj--; $ci--;
    } elsif ($dir == 6) {
        $cj++; $ci--;
    } elsif ($dir == 7) {
        $cj--; $ci++;
    }
    return ($ci, $cj);
}

sub help {
    print "--map <str>\t\tSpecify a file to read from containing a map\n";
    print "--x <int>\t\tUse in conjunction with --y <int> to specify dimensions\n" .
          "\t\t\tof auto-generated map\n";
    print "--y <int>\t\tSee above\n";
    print "--slow\t\t\tRun the simulation with slow speed. Very slow.\n";
    print "--fast\t\t\tRun the simulation with fast speed. Almost real-time!\n";
    print "--fastest\t\tRun the simulation at fastest speed.\n";
}

sub interrupt {
    print "\033[2J\033[1;1H\n";
    my $fn = 0;
    $fn++ while -e "save$fn.vrs";
    open(my $fh, '>', "save$fn.vrs");
    for(my $i=0; $i<$xsize; $i++) {
        for(my $j=0; $j<$ysize; $j++) {
            print $fh $grid[$i][$j];
        }
        print $fh "\n";
    }
    die "Simulation interrupted by user, simulation saved in save$fn.vrs";
}

sub infected {
    my ($chance, $doctor, $i, $j, $ci, $cj) = @_;

    if ($chance >= 75) {
        my $dir = int(rand(4));
        ($ci, $cj) = sdir($ci, $cj, $dir, 0);
        if (defined($grid[$ci][$cj])) {
            if ($grid[$ci][$cj] eq "O" and $chance >= 93) {
                #citizen becomes infected
                $grid[$ci][$cj] = "I";
                $infected++; $citizens--;
                $count = 0;
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
                    $count = 0;
                } elsif ($doctor <= 50) {
                    #infected dies
                    $grid[$i][$j] = "X";
                    $dead++; $infected--;
                    $count = 0;
                } elsif ($doctor <= 55) {
                    #infected converted into nurse
                    $grid[$i][$j] = "N";
                    $nurses++; $infected--;
                    $count = 0;
                } elsif ($doctor <= 80) {
                    #doctor/nurse converted into infected
                    $grid[$ci][$cj] = "I";
                    $infected++;
                    if ($which eq "D") {
                        $doctors--;
                    } elsif ($which eq "N") {
                        $nurses--;
                    }
                    $count = 0;
                } elsif ($doctor <= 85) {
                    #infected healed to citizen
                    $grid[$i][$j] = "O";
                    $infected--; $citizens++;
                    $count = 0;
                } elsif ($doctor <= 90) {
                    #infected healed to soldier
                    $grid[$i][$j] = "S";
                    $infected--;
                    $soldiers++;
                    $count = 0;
                } elsif ($doctor <= 100) {
                    #both doctor/nurse and infected die
                    $grid[$i][$j]   = "X";
                    $grid[$ci][$cj] = "X";
                    $dead += 2;
                    $infected--;
                    $count = 0;
                    if ($which eq "D") {
                        $doctors--;
                    } elsif ($which eq "N") {
                        $nurses--;
                    }
                }
             } elsif ($grid[$ci][$cj] eq "S") {
                my $schance = int(rand(101));
                if ($schance > 55) {
                    $dead++; $soldiers--;
                    $grid[$ci][$cj] = "X";
                    $count = 0; 
                }
            }
        }
    }
}

sub doctors {
    my ($chance, $doctor, $i, $j, $ci, $cj) = @_;
    my $dir    = int(rand(4));
    ($ci, $cj) = sdir($ci, $cj, $dir, 0);
    my $let    = $grid[$ci][$cj];
    my $which  = $grid[$i][$j];

    if (defined($let)) {
         #Miraculous revival
         if ($doctor == 0 and $let eq "X") {
             $grid[$ci][$cj] = "O";
             $dead--; $citizens++;
             return;
         }

         #Our medics don't do anything for these doomed souls/saviors
         if ($let =~ /[XDSNWAF ]/) { return; }
                                                                      
         if ($which eq "N" and $doctor <= 3 and $let eq "I") {
             $infected--; $nurses++;
             $grid[$ci][$cj] = "N";
             $count = 0;
         } elsif ($which eq "D" and $doctor <= 7) {
             if ($let eq "I") { 
                 $infected--; $nurses++;
                 $grid[$ci][$cj] = "N";
                 $count = 0;
             }
             if ($let eq "O") {
                 $citizens--; $nurses++;
                 $grid[$ci][$cj] = "N";
             }
         } elsif ($doctor <= 17) {
             if ($let eq "I") {
                 $infected--; $citizens++;
                 $grid[$ci][$cj] = "O";
                 $count = 0;
             }
        }
    }
}
    
sub citizens {
    my ($chance, $doctor, $i, $j, $ci, $cj) = @_;
    my $dir = int(rand(4));
    ($ci, $cj) = sdir($ci, $cj, $dir, 0);

    my $cchance = int(rand(1001));
    #0.1% chance of becoming a doctor or catching airborne infection
    if ($cchance == 0) {
        $grid[$i][$j] = "D";
        $doctors++; $citizens--;
    } elsif ($cchance == 1) {
        $grid[$i][$j] = "I";
        $citizens--; $infected++;
        $count = 0;
    } elsif ($cchance == 2) {
        if (defined($grid[$ci][$cj])) {
            if ($grid[$ci][$cj] eq "I") {
                $grid[$ci][$cj] = "X";
                $infected--; $dead++;
            }
        }
    }

    if ($chance > 1 and $chance <= 16) {
        #Can we build here? Do we have enough resources?
        #Has enough time passed to take up carpentry?
        if (defined($grid[$ci][$cj])) {
            if ($grid[$ci][$cj] eq " ") {
                if ($wood >= 25) {
                    if ($days >= 100) {
                        $grid[$ci][$cj] = "W";
                        $wood -= int(rand(24))+1;
                        $walls++;
                    }
                }
            }
        }
    } elsif ($chance == 17) {
        #We don't need no water
        #Citizen sets fire to wall
        if (defined($grid[$ci][$cj])) {
            if ($grid[$ci][$cj] eq "W") {
                if ($days >= 100) {
                    $grid[$ci][$cj] = "F";
                }
            }
        }
    }
}

sub soldiers {
    my ($chance, $doctor, $i, $j, $ci, $cj) = @_;

    #Murderous Soldier's turn
    my $r1 = int(rand(2));
    my $r2 = int(rand(3));
    my $p1 = int(rand(2));
    my $p2 = int(rand(2));
    my $rchance = int(rand(101));
    if ($p1) { $ci += $r1; } else { $ci -= $r1; }
    if ($p2) { $cj += $r2; } else { $cj -= $r2; }
    if(defined($grid[$ci][$cj])) {
        my $which = $grid[$ci][$cj];
        if ($which =~ /[D|N]/ and $rchance <= 1) {
            $rchance = int(rand(101));
        }
        if ($rchance <= 24) {
            #If a citizen is in our radius of 2x3, don't shoot
            #Doctors are fine though, who likes going to 
            #the doctor's anyway, they're scary.
            my $fail = 0;
            my $inf  = 0;
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
            if ($fail) { return; }
            if (!$inf) { return; }
            if ($which eq "I") {
                $grid[$ci][$cj] = "X";
                $infected--; $dead++;
                $count = 0;
            } elsif ($which eq "O") {
                if ($rchance >= 20) {
                    $grid[$ci][$cj] = "S";
                    $citizens--; $soldiers++;
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
                }
            #We train our soldiers to kill, then clean up that mess
            } elsif ($grid[$ci][$cj] eq "X") {
                $grid[$ci][$cj] = " ";
            }
        }
    }
}

sub angels {
    my ($chance, $doctor, $i, $j, $ci, $cj) = @_;

    if ($days % 700 == 0) {
        $grid[$i][$j] = " ";
        $angels--;
    }
    if ($chance > 75) {
        if ($days % 200 == 0) {
            for(my $k=$i-3; $k<$i+4; $k++) {
                for(my $l=$j-5; $l<$j+6; $l++) {
                    my $which = $grid[$k][$l];
                    if (defined($grid[$k][$l])) {
                        if ($which eq "I" or $which eq "X") {
                            $grid[$k][$l] = "O";
                            if ($which eq "I") {
                                $citizens++; $infected--;
                            } else {
                                $citizens++; $dead--;
                            }
                        }
                    }
                }
            }
        }
    }
}
