#!/usr/bin/perl
use CGI;
use DBI;
use Excel::Writer::XLSX;

my $q = CGI->new();
print $q->header(-type => 'application/vnd.ms-excel', -attachment => 'report.xlsx');

# Get user input
my $start_id    = $q->param('start');
my $end_id      = $q->param('end');
my $sfs_code    = $q->param('sfs');
my $date_string = $q->param('date');
my $set_billed  = $q->param('set_billed');
my $ignore_billed = $q->param('ignore_billed');

# DB Connection
my $db  = "pc";
my $host = "localhost";
my $user = "root";
my $dbpasswordretreive = 'E:/dbaccess/employer.txt';

# Get DB password
my $password = do {
    local $/ = undef;
    open my $fh, "<", $dbpasswordretreive or die "Could not open $dbpasswordretreive: $!";
    <$fh>;
};

# Connect to MySQL database
my $dbh = DBI->connect("DBI:mysql:database=$db;host=$host", $user, $password)
    or die "Cannot connect to database: $DBI::errstr\n";

# Create new Excel workbook
my $workbook = Excel::Writer::XLSX->new(\*STDOUT);

# Fetch data for all rows where billed IS NULL and id in range
my $sql = "SELECT * FROM printcenter WHERE billed IS NULL AND id BETWEEN ? AND ? AND billingmethod <> 'Blockchain'";

if ($ignore_billed eq 'yes') {
    $sql = "SELECT * FROM printcenter WHERE id BETWEEN ? AND ? AND billingmethod <> 'Blockchain'";
}

my $sth = $dbh->prepare($sql);
$sth->execute($start_id, $end_id);

# Tab 1 - All data
my $sheet1  = $workbook->add_worksheet('All Data');
my $row_num = 0;
while (my @row = $sth->fetchrow_array) {
    $sheet1->write_row($row_num++, 0, \@row);
}

# Tab 2 - ITHACA
$sth->execute($start_id, $end_id); # Re-execute query for same range
my $sheet2 = $workbook->add_worksheet('ITHACA');
$row_num   = 0;
while (my @row = $sth->fetchrow_array) {
    if ($row[22] eq 'ITHACA') { # Assuming location is in 23rd column (index 22)
        $sheet2->write_row($row_num++, 0, \@row);
    }
}

# Tab 3 - ITHACA BURSAR (Non-7-character account)
$sth->execute($start_id, $end_id);
my $sheet3 = $workbook->add_worksheet('ITHACA BURSAR');
$row_num   = 0;
while (my @row = $sth->fetchrow_array) {
    if ($row[22] eq 'ITHACA' && length($row[18]) != 7) { # account in col 18
        $sheet3->write_row($row_num++, 0, \@row);
    }
}

# Tab 4 - ITHACA ACCT (7-character account)
$sth->execute($start_id, $end_id);
my $sheet4 = $workbook->add_worksheet('ITHACA ACCT');
$row_num   = 0;
while (my @row = $sth->fetchrow_array) {
    if ($row[22] eq 'ITHACA' && length($row[18]) == 7) {
        $sheet4->write_row($row_num++, 0, \@row);
    }
}

# Tab 5 - ITHACA BURSAR FMT (Formatted BURSAR data)
$sth->execute($start_id, $end_id);
my $sheet5 = $workbook->add_worksheet('ITHACA BURSAR FMT');
$row_num   = 0;
while (my @row = $sth->fetchrow_array) {
    if ($row[22] eq 'ITHACA' && length($row[18]) != 7) {
        $sheet5->write($row_num, 0, sprintf("%07d", $row[17]));  # 7-digit ID
        $sheet5->write($row_num, 1, '    ');                     # 4 spaces
        $sheet5->write($row_num, 2, sprintf("%08.2f", $row[5])); # plottotal as 000000.00
        $sheet5->write($row_num, 3, '001000000777');             # Fixed value
        $sheet5->write($row_num, 4, $date_string);               # Date string
        $sheet5->write($row_num, 5, $sfs_code);                  # SFS code
        $sheet5->write($row_num, 6, $row[1]);                    # netid for checking
        $row_num++;
    }
}

# Tab 6 - NYC and TATA
$sth->execute($start_id, $end_id);
my $sheet6 = $workbook->add_worksheet('NYC and TATA');
$row_num   = 0;
while (my @row = $sth->fetchrow_array) {
    if ($row[22] eq 'NYC' || $row[22] eq 'TATA') {
        $sheet6->write_row($row_num++, 0, \@row);
    }
}

# Tab 7 - NYC and TATA BURSAR (Non-7-character account)
$sth->execute($start_id, $end_id);
my $sheet7 = $workbook->add_worksheet('NYC and TATA BURSAR');
$row_num   = 0;
while (my @row = $sth->fetchrow_array) {
    if (($row[22] eq 'NYC' || $row[22] eq 'TATA') && length($row[18]) != 7) {
        $sheet7->write_row($row_num++, 0, \@row);
    }
}

# Tab 8 - NYC and TATA ACCT (7-character account)
$sth->execute($start_id, $end_id);
my $sheet8 = $workbook->add_worksheet('NYC and TATA ACCT');
$row_num   = 0;
while (my @row = $sth->fetchrow_array) {
    if (($row[22] eq 'NYC' || $row[22] eq 'TATA') && length($row[18]) == 7) {
        $sheet8->write_row($row_num++, 0, \@row);
    }
}

# Tab 9 - NYC and TATA BURSAR FMT (Formatted BURSAR data)
$sth->execute($start_id, $end_id);
my $sheet9 = $workbook->add_worksheet('NYC and TATA BURSAR FMT');
$row_num   = 0;
while (my @row = $sth->fetchrow_array) {
    # FIXED: use same account logic as NYC/TATA BURSAR (tab 7)
    if (($row[22] eq 'NYC' || $row[22] eq 'TATA') && length($row[18]) != 7) {
        $sheet9->write($row_num, 0, sprintf("%07d", $row[17]));  # 7-digit ID
        $sheet9->write($row_num, 1, '    ');                     # 4 spaces
        $sheet9->write($row_num, 2, sprintf("%08.2f", $row[5])); # plottotal 000000.00
        $sheet9->write($row_num, 3, '001000000777');             # Fixed value
        $sheet9->write($row_num, 4, $date_string);               # Date string
        $sheet9->write($row_num, 5, $sfs_code);                  # SFS code
        $sheet9->write($row_num, 6, $row[1]);                    # netid for checking
        $row_num++;
    }
}

# Tab 10 - ROME
$sth->execute($start_id, $end_id);
my $sheet10 = $workbook->add_worksheet('ROME');
$row_num    = 0;
while (my @row = $sth->fetchrow_array) {
    if ($row[22] eq 'ROME') {
        $sheet10->write_row($row_num++, 0, \@row);
    }
}

# Tab 11 - ROME BURSAR (Non-7-character account)
$sth->execute($start_id, $end_id);
my $sheet11 = $workbook->add_worksheet('ROME BURSAR');
$row_num    = 0;
while (my @row = $sth->fetchrow_array) {
    if ($row[22] eq 'ROME' && length($row[18]) != 7) {
        $sheet11->write_row($row_num++, 0, \@row);
    }
}

# Tab 12 - ROME ACCT (7-character account)
$sth->execute($start_id, $end_id);
my $sheet12 = $workbook->add_worksheet('ROME ACCT');
$row_num    = 0;
while (my @row = $sth->fetchrow_array) {
    if ($row[22] eq 'ROME' && length($row[18]) == 7) {
        $sheet12->write_row($row_num++, 0, \@row);
    }
}

# Tab 13 - ROME BURSAR FMT (Formatted BURSAR data)
$sth->execute($start_id, $end_id);
my $sheet13 = $workbook->add_worksheet('ROME BURSAR FMT');
$row_num    = 0;
while (my @row = $sth->fetchrow_array) {
    # FIXED: use same account logic as ROME BURSAR (tab 11)
    if ($row[22] eq 'ROME' && length($row[18]) != 7) {
        $sheet13->write($row_num, 0, sprintf("%07d", $row[17]));  # 7-digit ID
        $sheet13->write($row_num, 1, '    ');                     # 4 spaces
        $sheet13->write($row_num, 2, sprintf("%08.2f", $row[5])); # plottotal 000000.00
        $sheet13->write($row_num, 3, '001000000777');             # Fixed value
        $sheet13->write($row_num, 4, $date_string);               # Date string
        $sheet13->write($row_num, 5, $sfs_code);                  # SFS code
        $sheet13->write($row_num, 6, $row[1]);                    # netid for checking
        $row_num++;
    }
}

# Clean up
$sth->finish();
$dbh->disconnect();

# Close Excel workbook
$workbook->close();

if ($set_billed eq 'justdoit') {
    # Connect to the MySQL database
    my $dbh3 = DBI->connect("DBI:mysql:database=$db;host=$host", $user, $password)
        or die "Cannot connect to database: $DBI::errstr\n";

    my $sql3 = "UPDATE printcenter SET billed='yes' WHERE id >= ? AND id <= ?";
    my $sth3 = $dbh3->prepare($sql3);
    $sth3->execute($start_id, $end_id);
}

exit;

