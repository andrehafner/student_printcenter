#!/usr/bin/perl

use CGI;
use File::Path;
use File::Copy;
use DBI;
use JSON;
use LWP::UserAgent;
#use warnings;

# ============================================
# Database Configuration
# ============================================
my $db = "student_printing";
my $host = "localhost";
my $user = "root";
my $dbpasswordretreive = 'E:/dbaccess/employer.txt';

# Read password from file
my $password = do {
    local $/ = undef;
    open my $fh, "<", $dbpasswordretreive or die "Could not open password file: $!";
    <$fh>;
};
chomp($password);

# Pricing configuration (per sheet, varies by paper size and duplex mode)
# 8.5x11 single=$0.005, duplex=$0.10 | 11x17 single=$0.10, duplex=$0.20
my %PRICING = (
    '85_11_single' => 0.005,
    '85_11_duplex' => 0.10,
    '11_17_single' => 0.10,
    '11_17_duplex' => 0.20
);
my $BRICK_MULTIPLIER = 9;

# Nautilus blockchain configuration
my $NAUTILUS_WALLET = '9gjX7hZQHzRG7iHC8yf2Hk9miPxd8QPrthSVMQuGSGwdXAgTBht';
my $NAUTILUS_TOKEN_ID = '6ae91b0b309752896eb14025358889661da7e2078d89b4669dceef0a3d125a33';
my $NAUTILUS_API = 'http://128.253.41.49:9053/blockchain/transaction/byAddress';

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
$billingmethod = $query->param("billingmethod") || 'Bursar';
$nautilus_brick_amount = $query->param("nautilus_brick_amount") || 0;
$blockchain_payment_confirmed = $query->param("blockchain_payment_confirmed") || 'no';
$blockchain_txid = $query->param("blockchain_txid") || '';

# Validate 7-digit student ID
if ($idnumber !~ /^[0-9]{7}$/) {
    print "Content-Type: text/html\n\n";
    print "<html><body><div style='text-align:center;margin-top:50px;'>";
    print "<h2>Error: Invalid Student ID</h2>";
    print "<p>Please enter a valid 7-digit student ID number.</p>";
    print "<p><a href='javascript:history.back()'>Go Back</a></p>";
    print "</div></body></html>";
    exit;
}

# Block submission if Nautilus payment required but not confirmed
if ($billingmethod eq 'Nautilus' && $blockchain_payment_confirmed ne 'yes') {
    print "Content-Type: text/html\n\n";
    print "<html><body><div style='text-align:center;margin-top:50px;'>";
    print "<h2>Error: Payment Required</h2>";
    print "<p>You must complete the Nautilus blockchain payment before submitting your print job.</p>";
    print "<p><a href='javascript:history.back()'>Go Back</a></p>";
    print "</div></body></html>";
    exit;
}

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

if ($pages !~/[0-9]/){
    $pagerange = '';
}

if ($pages !~/[0-9]/){
    $pagerangeend = '';
}

my $copiesword = "-copies=";

if ($copies !~/[0-9]/){
    $copiesword = '';
    $copies = 1;
}

# Ensure copies is a number
$copies = int($copies) || 1;
if ($copies < 1) { $copies = 1; }
if ($copies > 99) { $copies = 99; }

my $mainDIR = "E:/stu_printing";
my $riso = "";
my ($fileextention) = $file =~ /(\.[^.]+)$/;
my $subDIR = "$printer/$duplex/$papersize/$fit/$netid$hour$minute$copiesword$copies$pagerange$pages$pagerangeend$fileextention";

if ($printer eq "RISO"){
    $subDIR = "$printer/single/11_17/$fit/$netid$hour$minute$copiesword$copies$pagerange$pages$pagerangeend$fileextention";
}

if ($printer eq "Sibley_235"){
    $subDIR = "$printer/$duplex/$papersize/$fit/$netid$hour$minute$copiesword$copies$pagerange$pages$pagerangeend$fileextention";
}

# Match a dot, followed by any number of non-dots until the end of the line.
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

# Save the uploaded file
open ( UPLOADFILE, ">$mainDIR/$subDIR" )
 or die "$!";
binmode UPLOADFILE;

while ( <$upload_filehandle> )
{ print UPLOADFILE; }
close UPLOADFILE;

# Get page count using ImageMagick
my $cmd = '-set option:totpages %[n] -delete 1--1 -format "%[totpages]" info:';
my $pagecount = qx(convert "$mainDIR/$subDIR" $cmd);
$pagecount = int($pagecount) || 1;

# Calculate print total based on paper size AND duplex mode
my $pricing_key = "${papersize}_${duplex}";
my $price_per_sheet = $PRICING{$pricing_key} || 0.10;
my $printtotal = $price_per_sheet * $copies * $pagecount;
$printtotal = sprintf("%.2f", $printtotal);

# Calculate BRICK amount for Nautilus payments
my $calc_brick_amount = int($printtotal * $BRICK_MULTIPLIER);

# Determine blockchain flags
my $blockchain_flag = 'n';
my $blockchain_payment_cleared = 'n';
my $job_status = 'queued';

if ($billingmethod eq 'Nautilus') {
    $blockchain_flag = 'y';
    if ($blockchain_payment_confirmed eq 'yes' && $blockchain_txid ne '') {
        $blockchain_payment_cleared = 'y';
        $job_status = 'queued';
    } else {
        $blockchain_payment_cleared = 'n';
        $job_status = 'pending_payment';
    }
    $nautilus_brick_amount = $calc_brick_amount if $nautilus_brick_amount == 0;
}

# ============================================
# Database Insert
# ============================================
eval {
    my $dbh = DBI->connect("DBI:mysql:database=$db;host=$host", $user, $password, {
        RaiseError => 1,
        PrintError => 0,
        mysql_enable_utf8 => 1
    }) or die "Cannot connect to database: $DBI::errstr\n";

    my $sql = "INSERT INTO webprint (
        netid, student_id, printer, papersize, duplex, fit, copies, pagecount,
        filename, billingmethod, printtotal, blockchain_flag, nautilus_brick_amount,
        blockchain_payment_cleared, blockchain_txid, location, secure_print, job_status
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

    my $sth = $dbh->prepare($sql);
    $sth->execute(
        $netid,
        $idnumber,
        $printer,
        $papersize,
        $duplex,
        $fit,
        $copies,
        $pagecount,
        $file,
        $billingmethod,
        $printtotal,
        $blockchain_flag,
        $nautilus_brick_amount,
        $blockchain_payment_cleared,
        $blockchain_txid,
        'ITHACA',
        ($secure eq 'yes' ? 'y' : 'n'),
        $job_status
    );

    my $insert_id = $dbh->last_insert_id(undef, undef, 'webprint', 'id');
    $sth->finish();
    $dbh->disconnect();
};

if ($@) {
    # Log error but continue (don't break print job)
    open my $errlog, '>>', "E:/stu_printing/db_errors.txt";
    print $errlog "$theTime - DB Error: $@ - NetID: $netid, File: $file\n";
    close $errlog;
}

# Write to legacy log file
open my $fh, '>>', "E:/stu_printing/print_log.txt" or die "Cannot open print_log.txt: $!";
print $fh "$netid, $idnumber, $papersize, $copies, $pagecount, $printtotal, $billingmethod, $theTime \n";
close $fh;

# ============================================
# Build Response HTML
# ============================================
my $billing_info = "";
if ($billingmethod eq 'Bursar') {
    $billing_info = "<p><strong>Billing:</strong> Your student account (Bursar) will be charged <strong>\$$printtotal</strong></p>";
} else {
    $billing_info = "<p><strong>Billing:</strong> Paid via Nautilus Blockchain (<strong>$nautilus_brick_amount BRICK</strong>)</p>";
    if ($blockchain_txid ne '') {
        $billing_info .= "<p><strong>Transaction ID:</strong> <code>$blockchain_txid</code></p>";
    }
}

my $html = "Content-Type: text/html

<!DOCTYPE html>
<html lang='en'>
<head>
    <meta charset='UTF-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1.0'>
    <title>Print Job Submitted | AAP IT</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #0f0f23 0%, #1a1a2e 50%, #16213e 100%);
            color: #e2e8f0;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .container {
            max-width: 600px;
            text-align: center;
            padding: 2rem;
        }
        .success-icon {
            width: 80px;
            height: 80px;
            margin: 0 auto 1.5rem;
            background: linear-gradient(135deg, #22c55e, #16a34a);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .success-icon svg {
            width: 40px;
            height: 40px;
            stroke: white;
            stroke-width: 3;
            fill: none;
        }
        h1 {
            font-size: 1.75rem;
            margin-bottom: 1rem;
            color: #f8fafc;
        }
        .card {
            background: rgba(30, 41, 59, 0.7);
            backdrop-filter: blur(10px);
            border: 1px solid rgba(71, 85, 105, 0.3);
            border-radius: 12px;
            padding: 1.5rem;
            margin: 1.5rem 0;
            text-align: left;
        }
        .card p {
            margin: 0.5rem 0;
            color: #94a3b8;
        }
        .card strong {
            color: #f1f5f9;
        }
        code {
            background: rgba(15, 23, 42, 0.8);
            padding: 0.2rem 0.5rem;
            border-radius: 4px;
            font-size: 0.8rem;
            word-break: break-all;
        }
        .notice {
            background: rgba(59, 130, 246, 0.1);
            border: 1px solid rgba(59, 130, 246, 0.3);
            border-radius: 8px;
            padding: 1rem;
            margin-top: 1rem;
            color: #93c5fd;
        }
        .btn {
            display: inline-block;
            padding: 0.75rem 1.5rem;
            background: linear-gradient(135deg, #3b82f6, #1d4ed8);
            color: white;
            text-decoration: none;
            border-radius: 8px;
            margin-top: 1.5rem;
            font-weight: 500;
        }
        .btn:hover {
            background: linear-gradient(135deg, #2563eb, #1e40af);
        }
    </style>
</head>
<body>
    <div class='container'>
        <div class='success-icon'>
            <svg viewBox='0 0 24 24'><polyline points='20 6 9 17 4 12'></polyline></svg>
        </div>
        <h1>Print Job Submitted Successfully!</h1>
        <p>Your file has been queued on <strong>$printer</strong> and should be printing shortly.</p>

        <div class='card'>
            <p><strong>File:</strong> $file</p>
            <p><strong>Printer:</strong> $printer</p>
            <p><strong>Paper Size:</strong> $papersize</p>
            <p><strong>Copies:</strong> $copies</p>
            <p><strong>Pages:</strong> $pagecount</p>
            $billing_info
        </div>
";

if ($secure eq 'yes') {
    $html .= "
        <div class='notice'>
            <strong>Secure Print Enabled</strong><br>
            Please check your email and click the release link when you are at the printer.
        </div>
";
}

$html .= "
        <a href='index.html' class='btn'>Submit Another Print Job</a>
    </div>
</body>
</html>";

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
https://share.aap.cornell.edu/apps/studentprinting/secureprint.pl?a=$subDIR
*********************
*********************

Job Details:
- File: $file
- Printer: $printer
- Copies: $copies
- Pages: $pagecount
- Total Cost: \$$printtotal
- Billing: $billingmethod

Thank you - The AAP IT Solutions Print Center";

    my $domain = '@cornell.edu';

    # Get required arguments
    my $smtp_server = "appsmtp.mail.cornell.edu";
    my $to          = $netid . ' ' . $domain;
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
        $smtp->to($to);

        # Start data transfer
        $smtp->data();

        # Send the header
        $smtp->datasend("To: $to\n");
        $smtp->datasend("From: $from\n");
        $smtp->datasend("Subject: $subject\n");
        $smtp->datasend("\n");

        # Send the body
        $smtp->datasend(@body);

        # End data transfer
        $smtp->dataend();

        # Close the SMTP connection
        $smtp->quit();

    } else {
        return 1;
    }

    return 0;
}

# Define the message body
my @message_body = "Hello World!\n";
push @message_body, "Add another line!\n";

# Send the email!
send_mail(
    smtp_server => 'appsmtp.mail.cornell.edu',
    to          => $netid,
    from        => 'aap_it_apps1@cornell.edu',
    subject     => 'This is a subject',
    body        => \@message_body,
);

##End EMail Faculty
##----------------------------------------


exit;
