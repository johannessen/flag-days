Flag Days
=========

A script to calculate official flag days. It tackles three issues:

- Determination of the dates of flag days in the Gregorian calendar.
  
  Some of these days have fixed dates, while others are defined based
  on the Easter date or other variable criteria.

- Presentation of flag days in a useful way.
  
  Generally, the next 12 months after today's date are of interest.
  However, in order to give a more useful picture of how the sun's path
  varies by time of year, the last flag day occasion in the resulting
  list should be shown for the past. When fixed and variable dates are
  mixed here, this can get somewhat tricky though.

- Determination of the times the flag is supposed to be hoisted and
  lowered.
  
  Generally this is based upon actual sunrise and sunset, taking into
  account mountains that rise above the ideal horizon. However, it is
  customary to observe certain limits, e. g. to not hoist the flag
  earlier than 08:00 even if sunrise happens earlier.

This software has pre-release quality.
There is little documentation and no schedule for further development.

Todo
----

- separate behaviour from presentation
- remove hard-coded data
- convert into Perl module
- improve kludges
- release to CPAN
- pie-in-the-sky goal: automatic calculation of the appropriate
  elevation angle based on a horizon analysis from DEM data
  (though this project may not be worth that kind of time investment)
