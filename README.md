Infect
======

A game built by /g/, for /g/
![2spooky](http://oi62.tinypic.com/25gz1vo.jpg "Infect")

I always forget to update these, but here goes

### 16/8/2014
###### [Status: Current]
- Added fire; currently does nothing
- Added default speed on unspecified arguments (fast)
- Citizens have a 1% chance to set a wall on fire
- Status bar updated to show healthy population
- Added new version of [gmap](maps/gmap-v2.vrs)
- Moved units into functions (phew)
- Code clean-up/addressing redundancy
- Wood now based on size of map
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
with a 75% chance success rate. They don't stay on the
board after they cast their conversion spell, but this
may change in the future (probably will).
- Added a terminal-friendly default size grid if no arguments
are supplied (20x79)
  - Original idea by [Ilovecock](https://github.com/ilovecock)
- Added a display bar at the bottom which shows you the
amount of citizens, infected, and days passed.

### 12/8/2014
- Source has been posted!
