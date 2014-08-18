#!/usr/bin/perl

use warnings; use strict;
use Getopt::Long;

my ($ysize, $xsize, $mapfile,
    $slow, $fast, $fastest,
    $doctors, $nurses, $infected,
    $soldiers, $citizens);

GetOptions ("x=s" => \$xsize,
            "y=s" => \$ysize,
            "d=s" => \$doctors,
            "n=s" => \$nurses,
            "i=s" =>  \$infected,
            "s=s" => \$soldiers,
            "map=s" => \$mapfile,
            "slow" => \$slow,
            "fast" => \$fast,
            "fastest" => \$fastest,
            "h|help" => \&help);
my @grid;

my ($len, $days,  $dead,  $gen,
    $count, $angels,  $ff, $total,
    $fcolor, $walls, $open) = (0,0,0,0,
                               0,0,0,0,
                               1,0,0  );
my $timeout  = 200000;
$SIG{INT}    = \&interrupt;

#No map arguments?
if (!$xsize and !$ysize and !$mapfile) {
    print "No arguments supplied: run default values? [y/n]: ";
    my $choice = <STDIN>;
    if ($choice =~ /^y[es]?/i or $choice eq "\n") {
        $ysize = 79;
        $xsize = 20;
        $fast  =  1 if (!$slow and !$fastest);
        $citizens = $xsize * $ysize;
    } else {
        die "Simulation canceled by user";
    }
}

#No unit arguments?
#Original idea by Ilovecock
if (!$doctors and !$mapfile) {
    $doctors = int(($xsize * $ysize) * 0.001);
    if ($doctors < 1) { $doctors++; }
    $citizens -= $doctors;
} elsif ($doctors and !$mapfile) {
    $citizens -= $doctors;
}

if (!$nurses and !$mapfile) {
    $nurses = int(($xsize * $ysize) * 0.0005);
    if ($nurses < 1) { $nurses++; }
    $citizens -= $nurses;
} elsif ($nurses and !$mapfile) {
    $citizens -= $nurses;
}

if (!$soldiers and !$mapfile) {
    $soldiers = int(($xsize * $ysize) * 0.003);
    if ($soldiers < 1) { $soldiers++;  }
    $citizens -= $soldiers;
} elsif ($soldiers and !$mapfile) {
    $citizens -= $soldiers;
}

if (!$infected and !$mapfile) {
    $infected = int(($xsize * $ysize) * 0.0005);
    if ($infected < 1) { $infected++; }
    $citizens -= $infected;
} elsif ($infected and !$mapfile) {
    $citizens -= $infected;
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
                } elsif ($let eq " ") {
                    $open++;
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
            $grid[$i][$j] = "O";
            $total++;
        }
    }
    #Assign the units to random locations within the array constraints
    #Updated to incorporate Ilovecock's idea
    my ($tdoc, $tinf, $tnur, $tsol) = ($doctors, $infected, $nurses, $soldiers);
    my $units = $tdoc + $tinf + $tnur + $tsol;
    if ($citizens < 1) { $citizens = $ysize * $xsize - $units; }

    if ($units >= $ysize * $xsize) { 
        die "Not enough space to accomodate your units\n";
    }

    while($tdoc) {
        my $i = int(rand($xsize));
        my $j = int(rand($ysize));
        if ($grid[$i][$j] eq "O") {
            $grid[$i][$j] = "D";
            $tdoc--;
        }
    }
    while ($tinf) {
        my $i = int(rand($xsize));
        my $j = int(rand($ysize));
        if ($grid[$i][$j] eq "O") {
            $grid[$i][$j] = "I";
            $tinf--;
        }
    }
    while ($tnur) {
        my $i = int(rand($xsize));
        my $j = int(rand($ysize));
        if ($grid[$i][$j] eq "O") {
            $grid[$i][$j] = "N";
            $tnur--;
        }
    }
    while ($tsol) {
        my $i = int(rand($xsize));
        my $j = int(rand($ysize));
        if ($grid[$i][$j] eq "O") {
            $grid[$i][$j] = "S";
            $tsol--;
        }
    }
    for(my $n=0; $n<$xsize; $n++) {
        for(my $m=0; $m<$ysize; $m++) {
            if ($grid[$n][$m] eq "O" and !$open) {
                $grid[$n][$m] = " ";
                $citizens--; $open++;
                last;
            }
        }
    }
    if (!$open) { die "Too many units on the board\n"; }
}

#Get our dimensions if a map is supplied.
if ($mapfile) {
    $xsize = scalar(@grid);
    $ysize = $len;
}

#clear the screen
print "\x1b[2J\x1b[1;1H";

#amount of wood available based on grid size
my $wood = int($total / 3);


#Let's start
&main;

############
##MAIN LOOP#
############
sub main {
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
    
        #Do action for selected unit
        &action;
    }
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

            #Politely switch spots with the unit, granted it isn't
            #a blank space switching with another blank space,  or
            #infected changing places with a citizen
            if (defined($grid[$ci][$cj])) {
                my $switched = $grid[$ci][$cj];
                my $switchee = $grid[$i][$j];

                if ($switched =~ /[WXF]/) { next; }
                if ($switchee =~ /[WXF]/) { next; }

                if ($switched eq "I" and $switchee eq "O" or
                    $switched eq "O" and $switchee eq "I") { next; }
                if ($switched eq " " and $switchee eq " ") { next; }
                
                $grid[$ci][$cj] = $grid[$i][$j];
                $grid[$i][$j] = $switched;
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
                if ($days % 50 == 0) {
                    $fcolor = 1;
                } elsif ($days % 25 == 0) {
                    $fcolor = 3;
                }
                print "\x1b[3$fcolor" . ";1m" . $grid[$i][$j];
            } else {
                print "\x1b[37;1m" . $grid[$i][$j];
            }
        }
        print"\033[0m|\n";
    }
    if (!$_[0]) {
        my $healthy = $doctors + $nurses + $citizens + $soldiers;
        my $str = "Day: $days - Infected: $infected - Citizens: $citizens" .
                  " - Healthy: ($healthy/" . ($total - $t_init) . ") empty: $open";
        print $str;
        print "=" x (($ysize - length($days)) - length($str) + 2)  . "\r";
    }
}
        
sub win {
    my $result;
    #Was the function told we won? How?
    if ($_[0] == 1) {
        if (!$infected) {
            $result = "for the infection to be eliminated\n";
        } elsif ($infected > $citizens) {
            $result = "for the infected to populate the world\n";
        } else {
            $result = "for the infection to be contained\n";
        }
    } else {
        $result = "for the world to descend into chaos\n";
    }
    print "\033[1;1H\033[2J\033[K";
    printmap("end");
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
    my $step = int(rand(3)); if (!$step) { $step++; }
    if ($dir == 0) {
        $which eq "S" ? $ci += $step : $ci++;
    } elsif ($dir == 1) {
        $which eq "S" ? $cj -= $step : $cj--;
    } elsif ($dir == 2) {
        $which eq "S" ? $ci -= $step : $ci--;
    } elsif ($dir == 3) {
        $which eq "S" ? $cj += $step : $cj++;
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
    die "\n";
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
            if ($grid[$ci][$cj] eq "O" and $chance >= 98) {
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
                if ($schance < 10) {
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
                                                                      
         if ($which eq "N" and $doctor < 4 and $let eq "I") {
             $infected--; $nurses++;
             $grid[$ci][$cj] = "N";
             $count = 0;
         } elsif ($which eq "D" and $doctor < 6) {
             if ($let eq "O") {
                 $citizens--; $nurses++;
                 $grid[$ci][$cj] = "N";
             }
         } elsif ($which eq "D" and $doctor < 54) {
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

    my $cchance = int(rand(10001));
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
        #Is there more than one open space on the map?
        if (defined($grid[$ci][$cj])) {
            if ($grid[$ci][$cj] eq " ") {
                if ($wood >= 25) {
                    if ($days >= 100) {
                        if ($open > 1) {
                            $grid[$ci][$cj] = "W";
                            $wood -= int(rand(24))+1;
                            $walls++; $open--;
                        }
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
            }
        } elsif ($chance <= 74) {
            if ($grid[$ci][$cj] eq "X") {
                $grid[$ci][$cj] = " ";
                $open++;
            } elsif ($grid[$ci][$cj] eq "F") {
                $grid[$ci][$cj] = "W";
            }
        }        
    }
}

sub angels {
    my ($chance, $doctor, $i, $j, $ci, $cj) = @_;
    if ($days % 700 == 0) {
        $grid[$i][$j] = " ";
        $angels--; $open++;
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

sub action {
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
                    while ($try < $xsize * $ysize / 2) {
                        $k = int(rand($xsize));
                        $l = int(rand($ysize));
                        if ($grid[$k][$l] eq " ") {
                            $grid[$k][$l] = "A";
                            $angels++; $open--;
                            $try = $xsize * $ysize;
                        }
                        $try++;
                    }
                }
            }

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
