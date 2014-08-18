Infect
======

A game built by /g/, for /g/
![2spooky](http://oi62.tinypic.com/25gz1vo.jpg "Infect")

### 18/8/2014
###### [Status: Current]
- Incorporated [Ilovecock](https://github.com/ilovecock)'s unit assigning to avoid duplicate initial placement
- Units now switch places with each other; infected and citizens can not switch
- Nurse's and doctor's citizen->nurse conversion reduced to 2%
- Doctors no longer convert infected to nurses
- Doctor's infected->citizen conversion increased to 60%
- Airborne rate for infection and spontaneous doctor change from 0.1% to 0.01%
- Always leave room for an angel; this means citizens will not build 
  walls if there is only one open space. This eliminates hang-time when an angel
  placement is stuck in a while-loop.
- Infection spread rate reduced to 3% chance to infect citizen
- Soldier now moves one OR two spaces instead of only two
- Fire "animation" doubled in speed
- Game will not start if supplied units outnumber amount of spots on the board minus 1
- Added end result of infected populating the world (2nd timeout method)
- Unit display SEEMS to be working properly now... Shouldn't have any more negative values.
- Soldiers now only have a 10% chance to be killed by the infected
- Soldiers now have a 75% chance to put out fire, which still does nothing
- Iteration and unit-calls moved to their own function
- Main loop no longer runs globally

### 16/8/2014
###### [Status: Outdated]
- Added fire; currently does nothing
- Added default speed on unspecified arguments (fast)
- Citizens have a 1% chance to set a wall on fire
- Status bar updated to show healthy population
- Added new version of [gmap](maps/gmap-v2.vrs)
- Moved units into functions (phew)
- Code clean-up/addressing redundancy
- Wood now based on size of map (x*y/3)
- Citizens now only have a 0.1% chance instead of a 1%
  chance to randomly become a doctor or catching the
  airborne infection. This also makes it much easier to see
  the infected actually spreading from their original hosts
- Citizens now have a 0.1% chance to kill an infected in the direction of their action
- Fixed soldier bug where they wouldn't kill infected
- Angels now revive the dead to citizens


### 13/8/2014
###### [Status: Outdated]
- Soldiers now move 2 spaces at once. This cuts down on
infected surviving in corners and behind walls/bodies.
- Introduction of a new unit, the Angel. The Angel comes
every 200 turns and lands in a random, free space. They
have a radius of 3x5 and heal all infected in that radius
with a 25% chance success rate. They don't stay on the
board after they cast their conversion spell, but this
may change in the future (probably will).
- Added a terminal-friendly default size grid if no arguments
are supplied (20x79)
  - Original idea by [Ilovecock](https://github.com/ilovecock)
- Added a display bar at the bottom which shows you the
amount of citizens, infected, and days passed.

### 12/8/2014
- Source has been posted!
