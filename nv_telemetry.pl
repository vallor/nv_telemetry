#!/usr/bin/perl

my $default = 'EliteDangerous64.exe';
#my $default = 'starwars';
#my $default = 'Xorg';

my $resolution = 5; # every time() % $resolution, print a line

my $Blurb = "nv_telemetry.pl - record timestamp and video memory usage
Usage: $0 \[searchstring\]
Prints timestamp:vmem of a program by running
nvidia-smi.  vmem is in MiB.  Timestamp is
seconds since the Unix epoch, synched to every
second evenly divisible by $resolution.

Default search string is '$default'
";

use strict;

use Time::HiRes(qw/nanosleep/);

$|=1; # set output to line-oriented

my $searchstring = shift || $default;

# see if they asked for help
if($searchstring =~ m#^\-h# || $searchstring =~ m#\-\-h#)
    {
    select STDERR;
    print $Blurb;
    exit 0;
    }

#warn "\$searchstring is $searchstring\n";

our ($now, $lastnow);

while(1) # loop on this forever
{
    # synchronize on an even 5-second mark
    TIMELOOP:
    while(1)
        {
        nanosleep(500000000); # sleep 0.5 seconds
        $now = time;
        if($now == $lastnow)
            {
            # already wrote telemetry for
            # this second, so wait for the
            # next 5-second mark
            next TIMELOOP;
            }

        if($now % $resolution == 0)
            {
            # time to write a line
            $lastnow=$now; last TIMELOOP;
            }
        }
        
    # end of the time loop, time to write telemetry

    open(N,"nvidia-smi|") || die "couldn't run nvdia-smi:$!";

    # now we read the output of nvidia-smi
    NVLOOP:
    while(<N>)
        {
        # we're looking for $searchstring in a line
        # that looks like:
        # ...EliteDangerous64.exe      10748MiB |
        next unless (/$searchstring\s+(\d+)\S+ \|/);
        my $vmem=$1;
        print "$now:$vmem\n";
        last NVLOOP; # done with nvidia-smi
        }
    close(N); # stops nvidia-smi
} # let's do it again
