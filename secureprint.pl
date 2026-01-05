#!/usr/bin/perl

use CGI;
use File::Path;
use File::Copy;
use DBI;

$|=1;            # Flush immediately.
print "Content-Type: text/plain\n\n";

#get the current logged in user
$netid = Win32::LoginName;

#this code grabs the trailling number off the reference URL
my $q = CGI->new();
my $subDIR = $q->param('a');


my $mainDIR = "E:/fac_printing/";
my $SECUREmainDIR = "E:/fac_printing/HOLDING_SECURE/";

my $secureMOVE = "$SECUREmainDIR$subDIR";
my $MOVE = "$mainDIR$subDIR";

# the perl move file function
move($secureMOVE, $MOVE);

print "Your print should now be releasing to your selected printer. You can close this window!";

exit;


