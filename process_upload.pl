#!/usr/bin/perl

use CGI;
use File::Path;
use File::Copy;
use DBI;
#use warnings;

#use Image::Magick;

#get the current logged in user
#$netid = Win32::LoginName;

#$|=1;            # Flush immediately.
#print "Content-Type: text/plain\n\n";

#get the current logged in user
$netid = Win32::LoginName;

#get variables from the html form
$query = new CGI;
$file = $query->param("file");
$printer = $query->param("printer");
$papersize = $query->param("papersize");
$duplex = $query->param("duplex");
$secure = $query->param("secure");
$fit = $query->param("fit");
$pages = $query->param("pages");
$copies = $query->param("copies");
$idnumber = $query->param("idnumber");
#my $fit = "original";

#time calculation
@months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
@weekDays = qw(Sun Mon Tue Wed Thu Fri Sat Sun);
($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = localtime();
$year = 1900 + $yearOffset;
$theTime = "$months[$month] $dayOfMonth, $year - $weekDays[$dayOfWeek] $hour:$minute";

$Fmonth = ($month + 1);

my $upload_filehandle = $query->upload("file");

my $pagerange = "-pagerange='";
my $pagerangeend = "'";



#if ($pages = ''){
if ($pages !~/[0-9]/){
	$pagerange = '';
}

#if ($pages = ''){
if ($pages !~/[0-9]/){

	$pagerangeend = '';
}

my $copiesword = "-copies=";

#if ($copies = ''){
if ($copies !~/[0-9]/){
	$copiesword = '';
}

my $mainDIR = "E:/stu_printing";
my $riso = "";
#my $fileextention = $file;
my ($fileextention) = $file =~ /(\.[^.]+)$/;
my $subDIR = "$printer/$duplex/$papersize/$fit/$netid$hour$minute$copiesword$copies$pagerange$pages$pagerangeend$fileextention";

if ($printer eq "RISO"){
$subDIR = "$printer/single/11_17/$fit/$netid$hour$minute$copiesword$copies$pagerange$pages$pagerangeend$fileextention";
}


# Match a dot, followed by any number of non-dots until the
# end of the line.
my ($fileextention) = $file =~ /(\.[^.]+)$/;

if ($secure eq 'yes') {
    $mainDIR = "E:/stu_printing/HOLDING_SECURE";
    $subDIR = "$printer/$riso/$fit/$netid$hour$minute$copiesword$copies$pagerange$pages$pagerangeend$fileextention";
}

if ($secure eq 'yes' && $printer eq "RISO") {
    $mainDIR = "E:/stu_printing/HOLDING_SECURE";
    $subDIR = "$printer/single/11_17/$fit/$netid$hour$minute$copiesword$copies$pagerange$pages$pagerangeend$fileextention";
}

if ($file !~ /\.pdf$/i) {
print "\n\n\n\n\n\t\t\t$file is not a PDF type file. Please hit your back button and upload a PDF!\n";
exit;
}



#print "$mainDIR/$subDIR";
#print "$mainDIR/$subDIR";
#exit;
open ( UPLOADFILE, ">$mainDIR/$subDIR" )
 or die "$!"; 
binmode UPLOADFILE; 

while ( <$upload_filehandle> ) 
{ print UPLOADFILE; } 
close UPLOADFILE;






my $cmd = '-set option:totpages %[n] -delete 1--1 -format "%[totpages]" info:';
my $pagecount = qx(convert $mainDIR/$subDIR $cmd);

# Open a file named "output.txt"; die if there's an error
open my $fh, '>>', "E:/stu_printing/print_log.txt" or die "Cannot open print_log.txt: $!";
    print $fh "$netid, $idnumber, $papersize, $copies, $pagecount, $theTime \n"; # Print each entry in our array to the file
	close $fh; # Not necessary, but nice to do



my $html = "Content-Type: text/html

<HTML>


<HEAD>

<body>

<div style=\"text-align: center;\">
</br>
</br>
</br>
</br>
Your file has been queued on $printer and should be printing in a moment!
</br>
</br>
<b>If you chose SECURE PRINT</b></br>please check your email and click the link when you are ready to release!
</br>
</p>
</p>
</br>
Please close this window.
</br>
</br>
</p>
Thank you!
</div>
</body>
<a/>
</HTML>";

#let's display it
print $html;

if ($secure eq 'no') {
    exit;
}

##------------------------------------
##Email the Faculty and Advisor Member
use Net::SMTP;
sub send_mail
{
    my $emailmessage = "Hello,

Thank you for submitting your print job $file. 
Your print will be securely held for three days before being auto deleted.
When you are ready to release the job at the printer you specified during submission, please click the link below.

*********************
*********************
Click me to release
to $printer (password required)
https://share.aap.cornell.edu/apps/studentyprinting/secureprint.pl?a=$subDIR
*********************
*********************

Thank you - The AAP IT Solutions Print Center";
#    my $facultyformmessage = "Click here or copy and paste this link: https://sf-ambrosia04.serverfarm.cornell.edu/apps/db/process_supervisor.pl?a=@pid";

    my $domain = '@cornell.edu';
    #if($fnattachment eq ""){
    #$attachmentmessage = "(no transscript provided)";
#}
    
    # Get required arguments
    my $smtp_server = "appsmtp.mail.cornell.edu";
    my $to          = $netid . ' ' . $domain;
#    $to4          = $arch;
#    $to5          = $crp;
#   my $to6          = $art;
#   my $to7          = $bsc;
#   my $to2         = $s . ' ' . $domain;
    my $from        = 'AAP IT Apps <aap_it_apps1@cornell.edu>';

    # Get optional arguments
    my $subject = "Your Secure Print Release $file";
    my @body    = $emailmessage;

    # Connect to the SMTP server
    my $smtp = Net::SMTP->new($smtp_server);

    # If connection is successful, send mail
    if ($smtp) {

        # Establish to/from
        $smtp->mail($from);
#        $smtp->to($to,$to2);
#        $smtp->to($to);
        $smtp->to($to,$to4,$to5);

#
        # Start data transfer
        $smtp->data();

        # Send the header
        $smtp->datasend("To: $to\n");
        $smtp->datasend("To: $to4\n");
        $smtp->datasend("To: $to5\n");
#       $smtp->datasend("To: $to4\n");
#        $smtp->datasend("To: $to5\n");
#       $smtp->datasend("To: $to6\n");
#        $smtp->datasend("To: $to7\n");
        $smtp->datasend("From: $from\n");
        $smtp->datasend("Subject: $subject\n");
        $smtp->datasend("\n");

        # Send the body
        $smtp->datasend(@body);

        # End data transfer
        $smtp->dataend();

        # Close the SMTP connection
        $smtp->quit();

    # If connection fails return with error
    } else {

        # Print warning
#        warn "WARNING: Failed to connect to $smtp_server: $!";
        ##dump data to a file so we know it didn't email
#my $filename = "F:/AdmissionsCGI/bsc/studentemployment/failed_emails.txt";
#open(my $fh, '>>', $filename) or die "Could not open file '$filename' $!";
#print $fh "*****************************************************************\n";
#print $fh "Email failed for $snetid\n";
#print $fh "EMAIL Sent on $theTime \n";
#close $fh;

        return 1;
    }

    return 0;
}

# Define the message body
my @message_body = "Hello World!\n";
push @message_body, "Add another line!\n";

# Send the email!
send_mail(
    smtp_server => <smtp_server_name>,
    to          => <to_address>,
    from        => <from_address>,
    subject     => 'This is a subject',
    body        => \@message_body,
);

##End EMail Faculty
##----------------------------------------
#


exit;