#!/usr/bin/perl

use CGI;
use File::Path;
use File::Copy;
use DBI;
use LWP::UserAgent;
use IO::Socket::SSL;
use JSON;
use LWP::UserAgent;
use POSIX qw(strftime);

#get the current logged in user
$netid = Win32::LoginName;

#get variables from the html form
$query = new CGI;
$plotwidth = $query->param("plotwidth");
$plotheight = $query->param("plotheight");
$plotpapertype = $query->param("plotpapertype");
$billingmethod = $query->param("billingmethod");
$plotter = $query->param("plotter");
$plotname = $query->param("plotname");
$file = $query->param("file");
$account = $query->param("account");
$iddigit = $query->param("iddigit");
$notes = $query->param("notes");
$location = $query->param("location");

# Handle Nautilus payment confirmation
my $action = $query->param("action") // '';
if ($action eq "confirm_nautilus_payment") {
    print "Content-Type: application/json\n\n";

    my $confirm_rowid = $query->param("rowid") // '';
    my $confirm_txid = $query->param("txid") // '';
    my $confirm_brick_amount = $query->param("brick_amount") // '';

    if ($confirm_rowid && $confirm_txid) {
        # Get database connection
        my $dbpasswordretreive_confirm = 'E:\dbaccess\employer.txt';
        my $password_confirm = do {
            local $/ = undef;
            open my $fh, "<", $dbpasswordretreive_confirm or die "could not open: $!";
            <$fh>;
        };

        my $dbh_confirm = DBI->connect("DBI:mysql:database=pc:host=localhost", "root", $password_confirm)
            or die "Can't connect: $DBI::errstr\n";

        # Update the payment record
        my $sql_confirm = "UPDATE printcenter SET blockchain_payment_cleared='y', blockchain_txid=? WHERE id=? AND billingmethod='Nautilus' AND blockchain_payment_cleared='n'";
        my $sth_confirm = $dbh_confirm->prepare($sql_confirm);
        my $rows_affected = $sth_confirm->execute($confirm_txid, $confirm_rowid);

        $dbh_confirm->disconnect();

        if ($rows_affected > 0) {
            print '{"success": true, "message": "Payment confirmed"}';
        } else {
            print '{"success": false, "message": "No matching pending payment found"}';
        }
    } else {
        print '{"success": false, "message": "Missing required parameters"}';
    }
    exit;
}

#clean up for mysql
$netid =~ s/[\p{Pi}\p{Pf}\p{Ps}\p{Pd}\p{Pe}\p{Pc}\p{Po}\p{Sc}\p{Sm}\p{P}'"]//g;
$file =~ s/[\p{Pi}\p{Pf}\p{Ps}\p{Pd}\p{Pe}\p{Pc}\p{Sc}\p{Sm}\p{Z}'"]//g;
$notes =~ s/\'//g;
$notes =~ s/\'//g;
$notes =~ s/\'//g;
$notes =~ s/\'//g;
$plotwidth =~ s/\'//g;
$plotheight =~ s/\'//g;
$plotwidth =~ s/\"//g;
$plotheight =~ s/\"//g;
$plotwidth =~ s/inch//g;
$plotheight =~ s/inch//g;
$plotwidth =~ s/in//g;
$plotheight =~ s/in//g;
$plotwidth =~ s/INCH//g;
$plotheight =~ s/INCH//g;
$plotwidth =~ s/IN//g;
$plotheight =~ s/IN//g;
$plotwidth =~ s/Inch//g;
$plotheight =~ s/Inch//g;
$plotwidth =~ s/In//g;
$plotheight =~ s/In//g;

#time calculation
@months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
@weekDays = qw(Sun Mon Tue Wed Thu Fri Sat Sun);
($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = localtime();
$year = 1900 + $yearOffset;
$theTime = "$months[$month] $dayOfMonth, $year - $weekDays[$dayOfWeek] $hour:$minute";

# Open the file for reading
open my $fileNETID, '<', 'E:/apps/printcenter/netid.txt' or die "Could not open 'netid.txt': $!";

# Initialize a flag to indicate whether the string is found
my $found = 0;

# Loop through each line in the file
while (my $line = <$fileNETID>) {
    chomp $line;  # Remove newline characters
    if ($line eq $netid) {
        $found = 1;
        last;  # Exit the loop when the string is found
    }
}

# Close the file
close $fileNETID;

# Open the file for reading
open my $fileNETIDNONSTUDENTS, '<', 'E:/apps/printcenter/nonstudents.txt' or die "Could not open 'nonstudents.txt': $!";

# Initialize a flag to indicate whether the string is found
my $foundNONSTUDENTS = 0;

# Loop through each line in the file
while (my $lineNONSTU = <$fileNETIDNONSTUDENTS>) {
    chomp $lineNONSTU;  # Remove newline characters
    if ($lineNONSTU eq $netid) {
        $foundNONSTUDENTS = 1;
        last;  # Exit the loop when the string is found
    }
}

# Close the file
close $fileNETIDNONSTUDENTS;

# Open the file for reading
open my $fileACCT, '<', 'E:/apps/printcenter/ACCT.txt' or die "Could not open 'ACCT.txt': $!";

# Initialize a flag to indicate whether the string is found
my $foundACCT = 0;

# Loop through each line in the file
while (my $lineACCT = <$fileACCT>) {
    chomp $lineACCT;  # Remove newline characters
    if (lc($lineACCT) eq lc($account)) {
        $foundACCT = 1;
        last;  # Exit the loop when the string is found
    }
}

# Close the file
close $fileACCT;

# Print "yes" if the string is found, otherwise print "no"
if ($found > 0 || $foundNONSTUDENTS > 0) {
    #do nothing
} else {
    print "Content-Type: text/html\n\n";
    print qq{<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Access Denied | AAP IT Plot Center</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #0f0f23 0%, #1a1a2e 50%, #16213e 100%);
            color: #e2e8f0;
            margin: 0;
            padding: 2rem;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .error-container {
            background: rgba(30, 41, 59, 0.7);
            backdrop-filter: blur(10px);
            border: 1px solid rgba(239, 68, 68, 0.3);
            border-radius: 16px;
            padding: 3rem;
            text-align: center;
            max-width: 600px;
        }
        .error-icon {
            font-size: 4rem;
            color: #ef4444;
            margin-bottom: 1rem;
        }
        .error-title {
            font-size: 1.8rem;
            font-weight: 700;
            color: #ef4444;
            margin-bottom: 1rem;
        }
        .error-message {
            font-size: 1.1rem;
            line-height: 1.6;
            color: #cbd5e1;
            margin-bottom: 2rem;
        }
        .contact-info {
            background: rgba(15, 23, 42, 0.6);
            padding: 1rem;
            border-radius: 8px;
            color: #94a3b8;
        }
    </style>
</head>
<body>
    <div class="error-container">
        <div class="error-icon">🚫</div>
        <div class="error-title">Access Denied</div>
        <div class="error-message">
            I'm sorry, you are either not a member of AAP or were missed during the access import.<br><br>
            The plotting center is reserved for the AAP community due to issues with required coursework being crowded out by non-AAP printing.
        </div>
        <div class="contact-info">
            If you believe this to be an error, please contact <strong>aap-it\@cornell.edu</strong><br>
            Thank you - AAP IT
        </div>
    </div>
</body>
</html>};
    exit;
}

# Print "yes" if the string is found, otherwise print "no"
if ($foundACCT || $account eq '') {
    
} else {
    print "Content-Type: text/html\n\n";
    print qq{<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Account Error | AAP IT Plot Center</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #0f0f23 0%, #1a1a2e 50%, #16213e 100%);
            color: #e2e8f0;
            margin: 0;
            padding: 2rem;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .error-container {
            background: rgba(30, 41, 59, 0.7);
            backdrop-filter: blur(10px);
            border: 1px solid rgba(245, 158, 11, 0.3);
            border-radius: 16px;
            padding: 3rem;
            text-align: center;
            max-width: 600px;
        }
        .error-icon {
            font-size: 4rem;
            color: #f59e0b;
            margin-bottom: 1rem;
        }
        .error-title {
            font-size: 1.8rem;
            font-weight: 700;
            color: #f59e0b;
            margin-bottom: 1rem;
        }
        .error-message {
            font-size: 1.1rem;
            line-height: 1.6;
            color: #cbd5e1;
            margin-bottom: 2rem;
        }
        .contact-info {
            background: rgba(15, 23, 42, 0.6);
            padding: 1rem;
            border-radius: 8px;
            color: #94a3b8;
        }
    </style>
</head>
<body>
    <div class="error-container">
        <div class="error-icon">⚠️</div>
        <div class="error-title">Account Error</div>
        <div class="error-message">
            I'm sorry, your account does not match the list of AAP accounts.<br><br>
            It should be in the format <strong>A01XXXX</strong>.<br><br>
            Please hit back and try again.
        </div>
        <div class="contact-info">
            If you continue to have issues, please contact <strong>aap-it@cornell.edu</strong><br>
            Thank you - AAP IT
        </div>
    </div>
</body>
</html>};
    exit;
}

if ($file !~ /\.pdf$/i && $file !~ /\.tif$/i) {
    print "Content-Type: text/html\n\n";
    print qq{<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>File Type Error | AAP IT Plot Center</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #0f0f23 0%, #1a1a2e 50%, #16213e 100%);
            color: #e2e8f0;
            margin: 0;
            padding: 2rem;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .error-container {
            background: rgba(30, 41, 59, 0.7);
            backdrop-filter: blur(10px);
            border: 1px solid rgba(239, 68, 68, 0.3);
            border-radius: 16px;
            padding: 3rem;
            text-align: center;
            max-width: 600px;
        }
        .error-icon {
            font-size: 4rem;
            color: #ef4444;
            margin-bottom: 1rem;
        }
        .error-title {
            font-size: 1.8rem;
            font-weight: 700;
            color: #ef4444;
            margin-bottom: 1rem;
        }
        .error-message {
            font-size: 1.1rem;
            line-height: 1.6;
            color: #cbd5e1;
            margin-bottom: 2rem;
        }
    </style>
</head>
<body>
    <div class="error-container">
        <div class="error-icon">📄</div>
        <div class="error-title">Invalid File Type</div>
        <div class="error-message">
            <strong>$file</strong> is not a PDF or TIF type file.<br><br>
            Please hit your back button and upload a PDF or TIF file.
        </div>
    </div>
</body>
</html>};
    exit;
}

if ($file =~ /\.tif$/i && $plotpapertype eq 'Bond') {
    print "Content-Type: text/html\n\n";
    print qq{<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>File Type Error | AAP IT Plot Center</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #0f0f23 0%, #1a1a2e 50%, #16213e 100%);
            color: #e2e8f0;
            margin: 0;
            padding: 2rem;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .error-container {
            background: rgba(30, 41, 59, 0.7);
            backdrop-filter: blur(10px);
            border: 1px solid rgba(239, 68, 68, 0.3);
            border-radius: 16px;
            padding: 3rem;
            text-align: center;
            max-width: 600px;
        }
        .error-icon {
            font-size: 4rem;
            color: #ef4444;
            margin-bottom: 1rem;
        }
        .error-title {
            font-size: 1.8rem;
            font-weight: 700;
            color: #ef4444;
            margin-bottom: 1rem;
        }
        .error-message {
            font-size: 1.1rem;
            line-height: 1.6;
            color: #cbd5e1;
            margin-bottom: 2rem;
        }
    </style>
</head>
<body>
    <div class="error-container">
        <div class="error-icon">📄</div>
        <div class="error-title">File Type Mismatch</div>
        <div class="error-message">
            <strong>$file</strong> is not a PDF type file.<br><br>
            Please hit your back button and upload a PDF for this type of plotting.
        </div>
    </div>
</body>
</html>};
    exit;
}

if ($file =~ /\.tif$/i && $plotpapertype eq 'Photo') {
    print "Content-Type: text/html\n\n";
    print qq{<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>File Type Error | AAP IT Plot Center</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #0f0f23 0%, #1a1a2e 50%, #16213e 100%);
            color: #e2e8f0;
            margin: 0;
            padding: 2rem;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .error-container {
            background: rgba(30, 41, 59, 0.7);
            backdrop-filter: blur(10px);
            border: 1px solid rgba(239, 68, 68, 0.3);
            border-radius: 16px;
            padding: 3rem;
            text-align: center;
            max-width: 600px;
        }
        .error-icon {
            font-size: 4rem;
            color: #ef4444;
            margin-bottom: 1rem;
        }
        .error-title {
            font-size: 1.8rem;
            font-weight: 700;
            color: #ef4444;
            margin-bottom: 1rem;
        }
        .error-message {
            font-size: 1.1rem;
            line-height: 1.6;
            color: #cbd5e1;
            margin-bottom: 2rem;
        }
    </style>
</head>
<body>
    <div class="error-container">
        <div class="error-icon">📄</div>
        <div class="error-title">File Type Mismatch</div>
        <div class="error-message">
            <strong>$file</strong> is not a PDF type file.<br><br>
            Please hit your back button and upload a PDF for this type of plotting.
        </div>
    </div>
</body>
</html>};
    exit;
}

if ($file =~ /\.tif$/i && $plotpapertype eq 'Transparent') {
    print "Content-Type: text/html\n\n";
    print qq{<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>File Type Error | AAP IT Plot Center</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #0f0f23 0%, #1a1a2e 50%, #16213e 100%);
            color: #e2e8f0;
            margin: 0;
            padding: 2rem;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .error-container {
            background: rgba(30, 41, 59, 0.7);
            backdrop-filter: blur(10px);
            border: 1px solid rgba(239, 68, 68, 0.3);
            border-radius: 16px;
            padding: 3rem;
            text-align: center;
            max-width: 600px;
        }
        .error-icon {
            font-size: 4rem;
            color: #ef4444;
            margin-bottom: 1rem;
        }
        .error-title {
            font-size: 1.8rem;
            font-weight: 700;
            color: #ef4444;
            margin-bottom: 1rem;
        }
        .error-message {
            font-size: 1.1rem;
            line-height: 1.6;
            color: #cbd5e1;
            margin-bottom: 2rem;
        }
    </style>
</head>
<body>
    <div class="error-container">
        <div class="error-icon">📄</div>
        <div class="error-title">File Type Mismatch</div>
        <div class="error-message">
            <strong>$file</strong> is not a PDF type file.<br><br>
            Please hit your back button and upload a PDF for this type of plotting.
        </div>
    </div>
</body>
</html>};
    exit;
}

if ($file =~ /\.tif$/i && $plotpapertype eq 'MATTE FILM') {
    print "Content-Type: text/html\n\n";
    print qq{<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>File Type Error | AAP IT Plot Center</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #0f0f23 0%, #1a1a2e 50%, #16213e 100%);
            color: #e2e8f0;
            margin: 0;
            padding: 2rem;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .error-container {
            background: rgba(30, 41, 59, 0.7);
            backdrop-filter: blur(10px);
            border: 1px solid rgba(239, 68, 68, 0.3);
            border-radius: 16px;
            padding: 3rem;
            text-align: center;
            max-width: 600px;
        }
        .error-icon {
            font-size: 4rem;
            color: #ef4444;
            margin-bottom: 1rem;
        }
        .error-title {
            font-size: 1.8rem;
            font-weight: 700;
            color: #ef4444;
            margin-bottom: 1rem;
        }
        .error-message {
            font-size: 1.1rem;
            line-height: 1.6;
            color: #cbd5e1;
            margin-bottom: 2rem;
        }
    </style>
</head>
<body>
    <div class="error-container">
        <div class="error-icon">📄</div>
        <div class="error-title">File Type Mismatch</div>
        <div class="error-message">
            <strong>$file</strong> is not a PDF type file.<br><br>
            Please hit your back button and upload a PDF for this type of plotting.
        </div>
    </div>
</body>
</html>};
    exit;
}

if ($file =~ /\.tif$/i && $plotpapertype eq 'Entrada') {
    print "Content-Type: text/html\n\n";
    print qq{<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>File Type Error | AAP IT Plot Center</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #0f0f23 0%, #1a1a2e 50%, #16213e 100%);
            color: #e2e8f0;
            margin: 0;
            padding: 2rem;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .error-container {
            background: rgba(30, 41, 59, 0.7);
            backdrop-filter: blur(10px);
            border: 1px solid rgba(239, 68, 68, 0.3);
            border-radius: 16px;
            padding: 3rem;
            text-align: center;
            max-width: 600px;
        }
        .error-icon {
            font-size: 4rem;
            color: #ef4444;
            margin-bottom: 1rem;
        }
        .error-title {
            font-size: 1.8rem;
            font-weight: 700;
            color: #ef4444;
            margin-bottom: 1rem;
        }
        .error-message {
            font-size: 1.1rem;
            line-height: 1.6;
            color: #cbd5e1;
            margin-bottom: 2rem;
        }
    </style>
</head>
<body>
    <div class="error-container">
        <div class="error-icon">📄</div>
        <div class="error-title">File Type Mismatch</div>
        <div class="error-message">
            <strong>$file</strong> is not a PDF type file.<br><br>
            Please hit your back button and upload a PDF for this type of plotting.
        </div>
    </div>
</body>
</html>};
    exit;
}

if ($plotheight > '150') {
    print "Content-Type: text/html\n\n";
    print qq{<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Size Error | AAP IT Plot Center</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #0f0f23 0%, #1a1a2e 50%, #16213e 100%);
            color: #e2e8f0;
            margin: 0;
            padding: 2rem;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .error-container {
            background: rgba(30, 41, 59, 0.7);
            backdrop-filter: blur(10px);
            border: 1px solid rgba(245, 158, 11, 0.3);
            border-radius: 16px;
            padding: 3rem;
            text-align: center;
            max-width: 600px;
        }
        .error-icon {
            font-size: 4rem;
            color: #f59e0b;
            margin-bottom: 1rem;
        }
        .error-title {
            font-size: 1.8rem;
            font-weight: 700;
            color: #f59e0b;
            margin-bottom: 1rem;
        }
        .error-message {
            font-size: 1.1rem;
            line-height: 1.6;
            color: #cbd5e1;
            margin-bottom: 2rem;
        }
    </style>
</head>
<body>
    <div class="error-container">
        <div class="error-icon">📏</div>
        <div class="error-title">File Too Large</div>
        <div class="error-message">
            <strong>$file</strong> is too long.<br><br>
            Please hit your back button and upload a PDF or TIF file that is less than 12.5 feet (150 inches).
        </div>
    </div>
</body>
</html>};
    exit;
}

if ($file =~ /#/) {
    print "Content-Type: text/html\n\n";
    print qq{<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Filename Error | AAP IT Plot Center</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #0f0f23 0%, #1a1a2e 50%, #16213e 100%);
            color: #e2e8f0;
            margin: 0;
            padding: 2rem;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .error-container {
            background: rgba(30, 41, 59, 0.7);
            backdrop-filter: blur(10px);
            border: 1px solid rgba(239, 68, 68, 0.3);
            border-radius: 16px;
            padding: 3rem;
            text-align: center;
            max-width: 600px;
        }
        .error-icon {
            font-size: 4rem;
            color: #ef4444;
            margin-bottom: 1rem;
        }
        .error-title {
            font-size: 1.8rem;
            font-weight: 700;
            color: #ef4444;
            margin-bottom: 1rem;
        }
        .error-message {
            font-size: 1.1rem;
            line-height: 1.6;
            color: #cbd5e1;
            margin-bottom: 2rem;
        }
    </style>
</head>
<body>
    <div class="error-container">
        <div class="error-icon">🚫</div>
        <div class="error-title">Invalid Filename</div>
        <div class="error-message">
            <strong>$file</strong> contains a # character. These are bad in the web world.<br><br>
            Please hit your back button, rename the file, and re-upload.
        </div>
    </div>
</body>
</html>};
    exit;
}

if ($plotpapertype =~ /ADMS/ and $plotwidth < "25") {
    $plotwidth = "24";
}

if ($plotpapertype =~ /ADMS/ and $plotwidth > "24") {
    $plotwidth = "44";
}

my $to4 = '';
my $to6 = '';
my $to7 = '';
my $to8 = '';

if ($plotpapertype =~ /ADMS/) {
    $to4 = 'jmg393@cornell.edu';
    $to6 = 'asl269@cornell.edu';
    $to7 = 'cv323@cornell.edu';
    $to8 = 'jac699@cornell.edu';
}

my $upload_filehandle = $query->upload("file");

my $photoDir = "E:/apps/printcenter/student_uploads/";
my $FMphotoDir = "E:/apps/printcenter/student_uploads/initialupload/";
my $FMphotoDirPICKUP = "E:/apps/printcenter/student_uploads/holdingfolder/";

if ($file !~ /\.pdf$/i) {
    $FMphotoDir = "E:/apps/printcenter/student_uploads/";
}

$plotname = "$netid-$hour-$minute-$second-$file";

open ( UPLOADFILE, ">$FMphotoDir/$plotname" )
 or die "$!"; 
binmode UPLOADFILE; 

while ( <$upload_filehandle> ) 
{ print UPLOADFILE; } 
close UPLOADFILE;

my $pagenumber = "-%d";

my $size = -s $file;

if ($size > '100000000' && $file !~ /\.tif$/i){
    print "Content-Type: text/html\n\n";
    print qq{<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>File Size Error | AAP IT Plot Center</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #0f0f23 0%, #1a1a2e 50%, #16213e 100%);
            color: #e2e8f0;
            margin: 0;
            padding: 2rem;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .error-container {
            background: rgba(30, 41, 59, 0.7);
            backdrop-filter: blur(10px);
            border: 1px solid rgba(245, 158, 11, 0.3);
            border-radius: 16px;
            padding: 3rem;
            text-align: center;
            max-width: 600px;
        }
        .error-icon {
            font-size: 4rem;
            color: #f59e0b;
            margin-bottom: 1rem;
        }
        .error-title {
            font-size: 1.8rem;
            font-weight: 700;
            color: #f59e0b;
            margin-bottom: 1rem;
        }
        .error-message {
            font-size: 1.1rem;
            line-height: 1.6;
            color: #cbd5e1;
            margin-bottom: 2rem;
        }
    </style>
</head>
<body>
    <div class="error-container">
        <div class="error-icon">📦</div>
        <div class="error-title">File Too Large</div>
        <div class="error-message">
            Attention - Your file labeled <strong>$file</strong> is over the 100MB limit.<br><br>
            Please hit your back button and upload a PDF that is under 100MB.
        </div>
    </div>
</body>
</html>};
    exit; 
}

#create thumbnail
system ("magick $FMphotoDir/$plotname -trim -resize 250x250^ $photoDir/$plotname$pagenumber.png");

my $imagedir = "https://share.aap.cornell.edu/apps/printcenter/student_uploads/$plotname-0.png";

my $cmd = '-set option:totpages %[n] -delete 1--1 -format "%[totpages]" info:';
my $pagecount = qx(convert $FMphotoDir/$plotname $cmd);

if ($pagecount > '1'){
    print "Content-Type: text/html\n\n";
    print qq{<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Multiple Pages Error | AAP IT Plot Center</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #0f0f23 0%, #1a1a2e 50%, #16213e 100%);
            color: #e2e8f0;
            margin: 0;
            padding: 2rem;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .error-container {
            background: rgba(30, 41, 59, 0.7);
            backdrop-filter: blur(10px);
            border: 1px solid rgba(245, 158, 11, 0.3);
            border-radius: 16px;
            padding: 3rem;
            text-align: center;
            max-width: 600px;
        }
        .error-icon {
            font-size: 4rem;
            color: #f59e0b;
            margin-bottom: 1rem;
        }
        .error-title {
            font-size: 1.8rem;
            font-weight: 700;
            color: #f59e0b;
            margin-bottom: 1rem;
        }
        .error-message {
            font-size: 1.1rem;
            line-height: 1.6;
            color: #cbd5e1;
            margin-bottom: 2rem;
        }
    </style>
</head>
<body>
    <div class="error-container">
        <div class="error-icon">📄</div>
        <div class="error-title">Multiple Pages Detected</div>
        <div class="error-message">
            Attention - Your file has more than 1 page.<br><br>
            Please hit your back button and upload a PDF that is only a single page, it is hard to manage that many in one file.<br><br>
            Thanks!
        </div>
    </div>
</body>
</html>};
    exit; 
}

#let's calculate plot total
my $plottotal = '0';

if ($plotpapertype eq 'Bond') {
    $plottotal = (($plotheight/ '12') * '5.80' * $pagecount);
}

if ($plotpapertype eq 'Photo') {
    $plottotal = (($plotheight / '12') * '6.74' * $pagecount);
}

if ($plotpapertype eq 'Transparent') {
    $plottotal = (($plotheight / '12') * '6.74' * $pagecount);
}

if ($plotpapertype eq 'MATTE FILM') {
    $plottotal = (($plotheight / '12') * '6.74' * $pagecount);
}

if ($plotpapertype eq 'Entrada') {
    $plottotal = (($plotheight / '12') * '8.85' * $pagecount);
}

if ($plotpapertype eq 'ECPN - ADMS' && $plotwidth eq '24') {
    $plottotal = (($plotheight / '12') *'10');
}

if ($plotpapertype eq 'ECPN - ADMS' && $plotwidth eq '44') {
    $plottotal = (($plotheight / '12') *'18.33');
}

if ($plotpapertype eq 'EHPB - ADMS' && $plotwidth eq '24') {
    $plottotal = (($plotheight / '12') *'10');
}

if ($plotpapertype eq 'EHPB - ADMS' && $plotwidth eq '44') {
    $plottotal = (($plotheight / '12') *'18.33');
}

if ($plotpapertype eq 'MLPM - ADMS' && $plotwidth eq '24') {
    $plottotal = (($plotheight / '12') *'8');
}

if ($plotpapertype eq 'MLPM - ADMS' && $plotwidth eq '44') {
    $plottotal = (($plotheight / '12') *'14.67');
}

if ($plotpapertype eq 'EECM - ADMS') {
    $plottotal = (($plotheight / '12') *'18.33');
}

if ($plotpapertype eq 'PCT - ADMS' && $plotwidth eq '24') {
    $plottotal = (($plotheight / '12') *'7.70');
}

if ($plotpapertype eq 'PCT - ADMS' && $plotwidth eq '44') {
    $plottotal = (($plotheight / '12') *'16.50');
}

if ($plotpapertype eq 'PF - ADMS' && $plotwidth eq '24') {
    $plottotal = (($plotheight / '12') *'7.70');
}

if ($plotpapertype eq 'PF - ADMS' && $plotwidth eq '44') {
    $plottotal = (($plotheight / '12') *'16.50');
}

if ($plotpapertype eq 'EPGP - ADMS' && $plotwidth eq '24') {
    $plottotal = (($plotheight / '12') *'8.00');
}

if ($plotpapertype eq 'EPGP - ADMS' && $plotwidth eq '44') {
    $plottotal = (($plotheight / '12') *'14.67');
}

if ($plotpapertype eq 'EUPL - ADMS' && $plotwidth eq '24') {
    $plottotal = (($plotheight / '12') *'8.00');
}

if ($plotpapertype eq 'EUPL - ADMS' && $plotwidth eq '44') {
    $plottotal = (($plotheight / '12') *'14.67');
}

if ($plotpapertype eq 'OP') {
    $plottotal = ((($plotwidth / '12') * ($plotheight / '12'))*'2.80');
}

my ($before, $after) = split /\./, $plottotal , 2;
$after  =~ s/^(.{2})(.*)/$1/;
$plottotal  = $before . '.' . $after;

#this is where the database password is located
my $dbpasswordretreive =  'E:\dbaccess\employer.txt';

#get db password
my $password = do {
  local $/ = undef;
  open my $fh, "<", $dbpasswordretreive
  or die "could not open $dbpasswordretreive: $!";
  <$fh>;
};

#definition of variables
my $db="pc";
my $host="localhost";
my $user="root";

#connect to MySQL database
my $dbh   = DBI->connect ("DBI:mysql:database=$db:host=$host",
  $user,
  $password) 
  or die "Can't connect to database: $DBI::errstr\n";

if ($file !~ /\.tif$/i) {
    $plotheight = $plotheight + '2';
}

#write the form data back to the database
my $sql = "INSERT INTO printcenter (netid, plotwidth, plotheight, plotpapertype, billingmethod, plotter, plottimesubmitted, plotinprogress, plottotal, plotname, account, 7digit, notes, location) VALUES ('$netid', '$plotwidth', '$plotheight', '$plotpapertype', '$billingmethod', '$plotter', '$theTime', 'Sub', '$plottotal', '$plotname', '$account', '$iddigit', '$notes', '$location');";

my $ergo_price = '1000';
my $current_unix_time = time;
$current_unix_time =~ s/^\d{4}//;
if ($billingmethod eq "Blockchain"){
    # API URL and headers
    my $url = 'https://api.coingecko.com/api/v3/simple/price?ids=ergo&vs_currencies=usd';
    my $api_key = 'CG-wAHxHHCk86u4t8dbaMrLakom';

    # Set up the HTTP client
    my $ua = LWP::UserAgent->new(
        ssl_opts => { verify_hostname => 0 } # Ignore SSL certificate verification
    );
    $ua->default_header('accept' => 'application/json');
    $ua->default_header('x-cg-pro-api-key' => $api_key);

    # Make the API request
    my $response = $ua->get($url);

    if ($response->is_success) {
        my $content = $response->decoded_content;
        my $data = decode_json($content);

        # Extract data for Ergo
        if (exists $data->{ergo}) {
            my $ergo_data = $data->{ergo};
            $ergo_price = $ergo_data->{usd};
        }
    }

    $amt_erg_due = ($plottotal/$ergo_price);
    $amt_erg_due = int($amt_erg_due);
    $brick_multiplier = ($plottotal * 9);
    $amt_bricks_due = int($brick_multiplier);
    $amt_erg_due = "$amt_erg_due.$current_unix_time";
    $sql = "INSERT INTO printcenter (netid, plotwidth, plotheight, plotpapertype, billingmethod, plotter, plottimesubmitted, plotinprogress, plottotal, plotname, account, 7digit, notes, location, blockchain_flag, amnt_erg_due, amt_brick_due, blockchain_payment_cleared) VALUES ('$netid', '$plotwidth', '$plotheight', '$plotpapertype', '$billingmethod', '$plotter', '$theTime', 'Sub', '$plottotal', '$plotname', '$account', '$iddigit', '$notes', '$location', 'y','$amt_erg_due','$amt_bricks_due','n');";
}

# Nautilus Blockchain payment handling
my $nautilus_brick_amount = 0;
if ($billingmethod eq "Nautilus"){
    # Calculate BRICK amount: $plottotal * 9 (same formula as Discord Blockchain)
    my $brick_multiplier = ($plottotal * 9);
    $nautilus_brick_amount = int($brick_multiplier);
    $sql = "INSERT INTO printcenter (netid, plotwidth, plotheight, plotpapertype, billingmethod, plotter, plottimesubmitted, plotinprogress, plottotal, plotname, account, 7digit, notes, location, blockchain_flag, amnt_erg_due, amt_brick_due, blockchain_payment_cleared) VALUES ('$netid', '$plotwidth', '$plotheight', '$plotpapertype', '$billingmethod', '$plotter', '$theTime', 'Sub', '$plottotal', '$plotname', '$account', '$iddigit', '$notes', '$location', 'y','0','$nautilus_brick_amount','n');";
}

#prepare the query
my $sth = $dbh->prepare($sql);

#execute the query
$sth->execute();
$rowid = $dbh->{q{mysql_insertid}};

# disconnect from the MySQL database
$dbh->disconnect();

if ($file !~ /\.tif$/i) {
    $moveme = "$FMphotoDir/$plotname";
    $movemehere = "$FMphotoDirPICKUP/$plotname";
}

# the perl move file function
move($moveme, $movemehere);

##------------------------------------
##Email the Faculty and Advisor Member
use Net::SMTP;
sub send_mail
{
    my $emailmessage = "Hello,

Thank you for submitting your print job $plotname. Your plot will be queued at the availability of a plot monitor. Your plot was $plotwidth x $plotheight (2 inches was added to the bottom to name your plot, you were not charged for those inches) and will be plotted on $plotpapertype.
The cost of your plot was $pagecount page(s) and will be $plottotal . Billing method used: $billingmethod

***IF THIS IS A Tjaden DIM LAB FINE ART PRINT THERE MOST LIKELY WILL BE AT LEAST A 24 HOUR DELAY IN YOUR PLOT!***

Our plotting hours are typically 9am to 11pm Monday through Friday and 10am to 11pm Saturday and Sunday.

You can view your current active plots here: https://share.aap.cornell.edu/apps/printcenter/studentdashboard.pl
This link will also allow you to delete any plotting jobs that have not been queued yet!

You will receive another email when your plot has been queued.

Thank you - The AAP IT Solutions Print Center";

    my $domain = '@cornell.edu';
    
    # Get required arguments
    my $smtp_server = "appsmtp.mail.cornell.edu";
    my $to          = $netid . ' ' . $domain;
    my $from        = 'AAP IT Apps <aap_it_apps1@cornell.edu>';

    # Get optional arguments
    my $subject = "Your plot has been received on $theTime";
    my @body    = $emailmessage;

    # Connect to the SMTP server
    my $smtp = Net::SMTP->new($smtp_server);

    # If connection is successful, send mail
    if ($smtp) {
        # Establish to/from
        $smtp->mail($from);
        $smtp->to($to,$to4,$to6,$to7,$to8);

        # Start data transfer
        $smtp->data();

        # Send the header
        $smtp->datasend("To: $to\n");
        $smtp->datasend("To: $to4\n");
        $smtp->datasend("To: $to6\n");
        $smtp->datasend("To: $to7\n");
        $smtp->datasend("To: $to8\n");
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
    smtp_server => <smtp_server_name>,
    to          => <to_address>,
    from        => <from_address>,
    subject     => 'This is a subject',
    body        => \@message_body,
);

##End EMail Faculty
##----------------------------------------

if ($billingmethod eq "Blockchain"){
    my $discord_path_ergo = 'E:\apps\printcenter\webhook_payment_discord.py';

    $pypath = 'E:\apps\hourswap\venv\Scripts\python.exe';

    $pyfile2 = "$pypath $discord_path_ergo \"/tip user:\@aap_it_solutions amount:$amt_bricks_due token:brick comment:for plot number $rowid\n\" \"\nBLOCKCHAIN PAYMENT REQUEST!\n\nPay in Cornell Brick:\n\n```/tip user:\@aap_it_solutions amount:$amt_bricks_due token:brick comment:for plot number $rowid```\" \"Payment for $netid!\nSize: $plotwidth x $plotheight\nPaper: $plotpapertype\nTotal: $plottotal\n\"";
    $send = qx($pyfile2);
}

my $html = "Content-Type: text/html

<!DOCTYPE html>
<html lang=\"en\">
<head>
    <meta charset=\"UTF-8\">
    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
    <title>Plot Submission Successful | AAP IT Plot Center</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            background: linear-gradient(135deg, #0f0f23 0%, #1a1a2e 50%, #16213e 100%);
            color: #e2e8f0;
            min-height: 100vh;
            line-height: 1.6;
            padding: 2rem;
        }

        .container {
            max-width: 800px;
            margin: 0 auto;
        }

        .success-container {
            background: rgba(30, 41, 59, 0.7);
            backdrop-filter: blur(10px);
            border: 1px solid rgba(34, 197, 94, 0.3);
            border-radius: 16px;
            padding: 3rem;
            text-align: center;
            box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
        }

        .success-icon {
            font-size: 4rem;
            color: #22c55e;
            margin-bottom: 1rem;
        }

        .success-title {
            font-size: 2.2rem;
            font-weight: 700;
            color: #22c55e;
            margin-bottom: 1rem;
        }

        .job-id {
            background: rgba(124, 58, 237, 0.2);
            color: #c4b5fd;
            padding: 0.5rem 1rem;
            border-radius: 8px;
            font-weight: 600;
            font-size: 1.2rem;
            margin-bottom: 2rem;
            display: inline-block;
        }

        .preview-section {
            margin: 2rem 0;
        }

        .preview-title {
            font-size: 1.2rem;
            font-weight: 600;
            color: #f1f5f9;
            margin-bottom: 1rem;
        }

        .preview-note {
            color: #94a3b8;
            margin-bottom: 1rem;
            font-style: italic;
        }

        .preview-image {
            max-width: 100%;
            height: auto;
            border: 2px solid rgba(71, 85, 105, 0.3);
            border-radius: 8px;
            box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
	    background: #fff;
        }

        .blockchain-section {
            background: rgba(245, 158, 11, 0.1);
            border: 1px solid rgba(245, 158, 11, 0.3);
            border-radius: 12px;
            padding: 2rem;
            margin: 2rem 0;
        }

        .blockchain-title {
            font-size: 1.3rem;
            font-weight: 700;
            color: #f59e0b;
            margin-bottom: 1rem;
        }

        .blockchain-warning {
            color: #fbbf24;
            font-weight: 600;
            margin-bottom: 1.5rem;
        }

        .discord-link {
            display: inline-block;
            background: linear-gradient(135deg, #5865f2 0%, #4752c4 100%);
            color: white;
            padding: 1rem 2rem;
            text-decoration: none;
            border-radius: 8px;
            font-weight: 600;
            transition: all 0.3s ease;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }

        .discord-link:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 15px -3px rgba(88, 101, 242, 0.3);
        }

        .thank-you {
            font-size: 1.3rem;
            font-weight: 600;
            color: #f8fafc;
            margin-top: 2rem;
        }

        \@media (max-width: 768px) {
            body {
                padding: 1rem;
            }
            
            .success-container {
                padding: 2rem;
            }
            
            .success-title {
                font-size: 1.8rem;
            }
        }
    </style>
</head>
<body>
    <div class=\"container\">
        <div class=\"success-container\">
            <div class=\"success-icon\">✅</div>
            <h1 class=\"success-title\">Plot Submission Successful!</h1>
            
            <div class=\"job-id\">Job ID: $rowid</div>
            
            <div class=\"preview-section\">
                <h2 class=\"preview-title\">File Preview</h2>
                <p class=\"preview-note\">Please inspect the thumbnail below. If you don't see one, there was an issue and you need to contact aap-it\@cornell.edu</p>
                <img src=\"$imagedir\" alt=\"Plot Preview\" class=\"preview-image\">
            </div>";

if ($billingmethod eq "Blockchain") {
    $html .= "
            <div class=\"blockchain-section\">
                <h2 class=\"blockchain-title\">🔗 Discord Blockchain Payment Required</h2>
                <p class=\"blockchain-warning\">Your plot will not be sent unless you complete the blockchain payment!</p>
                <a href=\"https://discord.com/channels/870014867246039110/1313953585616392325\" class=\"discord-link\" target=\"_blank\">
                    Go to Discord to Pay
                </a>
            </div>";
}

if ($billingmethod eq "Nautilus") {
    $html .= "
            <div class=\"blockchain-section\" style=\"border-color: rgba(124, 58, 237, 0.5); background: rgba(124, 58, 237, 0.1);\">
                <h2 class=\"blockchain-title\" style=\"color: #a78bfa;\">🦑 Nautilus Blockchain Payment Required</h2>
                <p class=\"blockchain-warning\" style=\"color: #c4b5fd;\">Your plot will not be sent unless you complete the blockchain payment!</p>

                <div style=\"background: rgba(15, 23, 42, 0.6); padding: 1.5rem; border-radius: 12px; margin: 1.5rem 0;\">
                    <div style=\"font-size: 1.2rem; color: #94a3b8; margin-bottom: 0.5rem;\">Amount Due:</div>
                    <div style=\"font-size: 2.5rem; font-weight: 700; color: #d4af37;\">🧱 $nautilus_brick_amount BRICK</div>
                    <div style=\"font-size: 0.9rem; color: #64748b; margin-top: 0.5rem;\">(\\\$$plottotal USD value)</div>
                </div>

                <div id=\"walletSection\">
                    <button id=\"connectWalletBtn\" onclick=\"nautConnectWallet()\" style=\"display: inline-block; background: linear-gradient(135deg, #7c3aed 0%, #5b21b6 100%); color: white; padding: 1rem 2rem; border: none; border-radius: 8px; font-weight: 600; cursor: pointer; transition: all 0.3s ease; text-transform: uppercase; letter-spacing: 0.5px; font-size: 1rem;\">
                        Connect Nautilus Wallet
                    </button>
                    <div id=\"walletInfo\" style=\"margin-top: 1rem;\"></div>
                </div>

                <div id=\"paymentSection\" style=\"display: none; margin-top: 1.5rem;\">
                    <button id=\"payBtn\" onclick=\"nautSubmitPayment()\" style=\"display: inline-block; background: linear-gradient(135deg, #22c55e 0%, #16a34a 100%); color: white; padding: 1rem 2rem; border: none; border-radius: 8px; font-weight: 600; cursor: pointer; transition: all 0.3s ease; text-transform: uppercase; letter-spacing: 0.5px; font-size: 1.1rem;\">
                        💳 Pay $nautilus_brick_amount BRICK Now
                    </button>
                    <div id=\"paymentStatus\" style=\"margin-top: 1rem;\"></div>
                </div>

                <div id=\"successSection\" style=\"display: none; margin-top: 1.5rem; padding: 1.5rem; background: rgba(34, 197, 94, 0.1); border: 1px solid rgba(34, 197, 94, 0.3); border-radius: 12px;\">
                    <div style=\"font-size: 2rem; margin-bottom: 0.5rem;\">✅</div>
                    <div style=\"font-size: 1.3rem; font-weight: 600; color: #22c55e;\">Payment Successful!</div>
                    <div id=\"txLink\" style=\"margin-top: 1rem; font-size: 0.9rem; color: #94a3b8;\"></div>
                </div>
            </div>

            <script>
                var NAUT_BRICK_TOKEN_ID = '6ae91b0b309752896eb14025358889661da7e2078d89b4669dceef0a3d125a33';
                var NAUT_TREASURY_ADDRESS = '9gjX7hZQHzRG7iHC8yf2Hk9miPxd8QPrthSVMQuGSGwdXAgTBht';
                var NAUT_BRICK_AMOUNT = $nautilus_brick_amount;
                var NAUT_ROW_ID = '$rowid';

                var nautConnectedAddress = null;
                var nautBrickBalance = 0;

                console.log('Nautilus payment script initialized');

                function nautConnectWallet() {
                    console.log('Connect wallet button clicked');
                    document.getElementById('walletInfo').innerHTML = '<div style=\"color: #a78bfa;\">Connecting...</div>';

                    // Check if Nautilus is available
                    if (typeof window.ergoConnector === 'undefined' || !window.ergoConnector.nautilus) {
                        alert('Please install Nautilus wallet extension first!');
                        window.open('https://chrome.google.com/webstore/detail/nautilus-wallet/gjlmehlldlphhljhpnlddaodbjjcchai', '_blank');
                        document.getElementById('walletInfo').innerHTML = '';
                        return;
                    }

                    console.log('Nautilus extension found, attempting connection...');

                    window.ergoConnector.nautilus.connect()
                        .then(function(connected) {
                            if (connected) {
                                console.log('Nautilus connected successfully');
                                return ergo.get_change_address();
                            } else {
                                throw new Error('Connection rejected');
                            }
                        })
                        .then(function(address) {
                            nautConnectedAddress = address;
                            console.log('Got address:', address);
                            return ergo.get_utxos();
                        })
                        .then(function(utxos) {
                            nautBrickBalance = 0;
                            var ergBalance = 0;

                            for (var i = 0; i < utxos.length; i++) {
                                var utxo = utxos[i];
                                ergBalance += parseInt(utxo.value);
                                if (utxo.assets) {
                                    for (var j = 0; j < utxo.assets.length; j++) {
                                        var asset = utxo.assets[j];
                                        if (asset.tokenId === NAUT_BRICK_TOKEN_ID) {
                                            nautBrickBalance += parseInt(asset.amount);
                                        }
                                    }
                                }
                            }

                            ergBalance = ergBalance / 1e9;

                            var walletInfoHTML = '<div style=\"background: rgba(34, 197, 94, 0.15); padding: 1rem; border-radius: 8px; text-align: left;\">';
                            walletInfoHTML += '<strong style=\"color: #22c55e;\">✓ Connected!</strong><br>';
                            walletInfoHTML += '<span style=\"color: #94a3b8;\">Address: ' + nautConnectedAddress.substring(0, 15) + '...</span><br>';
                            walletInfoHTML += '<span style=\"color: #94a3b8;\">ERG: ' + ergBalance.toFixed(4) + '</span><br>';
                            walletInfoHTML += '<span style=\"color: #d4af37;\">BRICK: 🧱 ' + nautBrickBalance.toLocaleString() + '</span>';

                            if (ergBalance < 0.01) {
                                walletInfoHTML += '<div style=\"color: #ef4444; font-weight: 600; margin-top: 0.5rem;\">⚠️ Low ERG balance for fees!</div>';
                            }

                            if (nautBrickBalance < NAUT_BRICK_AMOUNT) {
                                walletInfoHTML += '<div style=\"color: #ef4444; font-weight: 600; margin-top: 0.5rem;\">⚠️ Insufficient BRICK balance!</div>';
                            }

                            walletInfoHTML += '</div>';

                            document.getElementById('walletInfo').innerHTML = walletInfoHTML;
                            document.getElementById('connectWalletBtn').style.display = 'none';

                            if (nautBrickBalance >= NAUT_BRICK_AMOUNT && ergBalance >= 0.01) {
                                document.getElementById('paymentSection').style.display = 'block';
                            }
                        })
                        .catch(function(err) {
                            console.error('Wallet connection error:', err);
                            document.getElementById('walletInfo').innerHTML = '<div style=\"color: #ef4444;\">Error: ' + err.message + '</div>';
                        });
                }

                function nautSubmitPayment() {
                    var payBtn = document.getElementById('payBtn');
                    var paymentStatus = document.getElementById('paymentStatus');

                    payBtn.disabled = true;
                    payBtn.style.opacity = '0.5';
                    payBtn.style.cursor = 'not-allowed';
                    paymentStatus.innerHTML = '<div style=\"color: #a78bfa;\">🔄 Loading SDK...</div>';

                    // Dynamically load Fleet SDK
                    import('https://cdn.jsdelivr.net/npm/\@fleet-sdk/core\@0.6.1/+esm')
                        .then(function(module) {
                            var TransactionBuilder = module.TransactionBuilder;
                            var OutputBuilder = module.OutputBuilder;

                            paymentStatus.innerHTML = '<div style=\"color: #a78bfa;\">🔄 Building transaction...</div>';

                            return ergo.get_current_height().then(function(currentHeight) {
                                return ergo.get_utxos().then(function(utxos) {
                                    var outputBuilder = new OutputBuilder('1000000', NAUT_TREASURY_ADDRESS);
                                    outputBuilder.addTokens({
                                        tokenId: NAUT_BRICK_TOKEN_ID,
                                        amount: NAUT_BRICK_AMOUNT.toString()
                                    });

                                    var unsignedTx = new TransactionBuilder(currentHeight)
                                        .from(utxos)
                                        .to(outputBuilder)
                                        .sendChangeTo(nautConnectedAddress)
                                        .payMinFee()
                                        .build()
                                        .toEIP12Object();

                                    paymentStatus.innerHTML = '<div style=\"color: #a78bfa;\">🔄 Please sign in Nautilus...</div>';
                                    return ergo.sign_tx(unsignedTx);
                                });
                            });
                        })
                        .then(function(signedTx) {
                            paymentStatus.innerHTML = '<div style=\"color: #a78bfa;\">🔄 Submitting transaction...</div>';
                            return ergo.submit_tx(signedTx);
                        })
                        .then(function(txId) {
                            paymentStatus.innerHTML = '<div style=\"color: #a78bfa;\">🔄 Confirming payment...</div>';

                            var formData = new FormData();
                            formData.append('action', 'confirm_nautilus_payment');
                            formData.append('rowid', NAUT_ROW_ID);
                            formData.append('txid', txId);
                            formData.append('brick_amount', NAUT_BRICK_AMOUNT);

                            return fetch('process_upload.pl', {
                                method: 'POST',
                                body: formData
                            }).then(function(response) {
                                return response.json().then(function(result) {
                                    return { result: result, txId: txId };
                                });
                            });
                        })
                        .then(function(data) {
                            if (data.result.success) {
                                document.getElementById('paymentSection').style.display = 'none';
                                document.getElementById('successSection').style.display = 'block';
                                document.getElementById('txLink').innerHTML = 'Transaction ID: <a href=\"https://explorer.ergoplatform.com/en/transactions/' + data.txId + '\" target=\"_blank\" style=\"color: #a78bfa;\">' + data.txId.substring(0, 20) + '...</a>';
                            } else {
                                paymentStatus.innerHTML = '<div style=\"color: #ef4444;\">⚠️ Payment submitted but confirmation failed. TX: ' + data.txId + '</div>';
                            }
                        })
                        .catch(function(err) {
                            console.error('Payment error:', err);
                            paymentStatus.innerHTML = '<div style=\"color: #ef4444;\">❌ Error: ' + err.message + '</div>';
                            payBtn.disabled = false;
                            payBtn.style.opacity = '1';
                            payBtn.style.cursor = 'pointer';
                        });
                }
            </script>";
}

$html .= "
            <div class=\"thank-you\">Thank you!</div>
        </div>
    </div>
</body>
</html>";

#let's display it
print $html;

exit;