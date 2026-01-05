#!/usr/bin/perl

# ============================================
# AAP IT Web Print - Billing Report Processor
# Generates Excel export for Ithaca campus only
# Admin: ah97
# ============================================

use CGI;
use DBI;
use Excel::Writer::XLSX;
use strict;
use warnings;

# Database Configuration
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

# Get current logged in user
my $netid = Win32::LoginName;

# Admin access control - ONLY ah97 can access billing export
my @authorized_admins = ('ah97');
my $is_admin = grep { $_ eq $netid } @authorized_admins;

# Start CGI
my $query = CGI->new;

# Check admin access
unless ($is_admin) {
    print "Content-Type: text/html\n\n";
    print "<html><body><h1>Access Denied</h1><p>You do not have permission to access billing export.</p></body></html>";
    exit;
}

# Get form parameters
my $start_id     = $query->param('start') || 0;
my $end_id       = $query->param('end') || 0;
my $sfs_code     = $query->param('sfs') || '';
my $date_string  = $query->param('date') || '';
my $set_billed   = $query->param('set_billed') || '';
my $ignore_billed = $query->param('ignore_billed') || '';

# Validate parameters
if ($start_id <= 0 || $end_id <= 0 || $end_id < $start_id) {
    print "Content-Type: text/html\n\n";
    print "<html><body><h1>Error</h1><p>Invalid row ID range. Please go back and enter valid start/end IDs.</p></body></html>";
    exit;
}

# Connect to database
my $dbh = DBI->connect("DBI:mysql:database=$db;host=$host", $user, $password, {
    RaiseError => 1,
    PrintError => 0,
    mysql_enable_utf8 => 1
}) or die "Cannot connect to database: $DBI::errstr\n";

# Build query - Ithaca only, exclude blockchain from bursar billing
my $sql;
if ($ignore_billed eq 'yes') {
    # Include all jobs in range (for historical reports), exclude blockchain
    $sql = "SELECT * FROM webprint WHERE id BETWEEN ? AND ? AND location = 'ITHACA' AND billingmethod = 'Bursar' ORDER BY id";
} else {
    # Only unbilled jobs, exclude blockchain
    $sql = "SELECT * FROM webprint WHERE billed IS NULL AND id BETWEEN ? AND ? AND location = 'ITHACA' AND billingmethod = 'Bursar' ORDER BY id";
}

my $sth = $dbh->prepare($sql);
$sth->execute($start_id, $end_id);

# Collect all rows
my @all_data;
while (my $row = $sth->fetchrow_hashref()) {
    push @all_data, $row;
}
$sth->finish();

# Calculate totals
my $total_amount = 0;
foreach my $row (@all_data) {
    $total_amount += $row->{printtotal} || 0;
}

# Generate timestamp for filename
my ($sec, $min, $hour, $mday, $mon, $year) = localtime();
my $timestamp = sprintf("%04d%02d%02d_%02d%02d%02d", $year + 1900, $mon + 1, $mday, $hour, $min, $sec);
my $filename = "webprint_billing_ithaca_$timestamp.xlsx";

# Output Excel file
print "Content-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet\n";
print "Content-Disposition: attachment; filename=\"$filename\"\n\n";

# Create Excel workbook in memory
my $workbook = Excel::Writer::XLSX->new(\*STDOUT);

# Define formats
my $header_format = $workbook->add_format(
    bold => 1,
    bg_color => '#1e3a5f',
    color => 'white',
    align => 'center',
    border => 1
);

my $data_format = $workbook->add_format(
    border => 1,
    align => 'left'
);

my $money_format = $workbook->add_format(
    border => 1,
    align => 'right',
    num_format => '$#,##0.00'
);

my $id_format = $workbook->add_format(
    border => 1,
    align => 'center',
    num_format => '0000000'
);

my $summary_format = $workbook->add_format(
    bold => 1,
    bg_color => '#22c55e',
    color => 'white',
    align => 'right',
    border => 1
);

# ============================================
# Sheet 1: All Data
# ============================================
my $ws_all = $workbook->add_worksheet('All Data');
$ws_all->set_column(0, 0, 8);   # ID
$ws_all->set_column(1, 1, 12);  # NetID
$ws_all->set_column(2, 2, 12);  # Student ID
$ws_all->set_column(3, 3, 12);  # Printer
$ws_all->set_column(4, 4, 10);  # Paper Size
$ws_all->set_column(5, 5, 8);   # Copies
$ws_all->set_column(6, 6, 8);   # Pages
$ws_all->set_column(7, 7, 10);  # Total
$ws_all->set_column(8, 8, 30);  # Filename
$ws_all->set_column(9, 9, 18);  # Submitted

# Headers
my @headers = ('ID', 'NetID', 'Student ID', 'Printer', 'Paper Size', 'Copies', 'Pages', 'Total', 'Filename', 'Submitted');
for my $col (0 .. $#headers) {
    $ws_all->write(0, $col, $headers[$col], $header_format);
}

# Data rows
my $row_num = 1;
foreach my $row (@all_data) {
    $ws_all->write($row_num, 0, $row->{id}, $data_format);
    $ws_all->write($row_num, 1, $row->{netid}, $data_format);
    $ws_all->write($row_num, 2, $row->{student_id}, $id_format);
    $ws_all->write($row_num, 3, $row->{printer}, $data_format);
    $ws_all->write($row_num, 4, $row->{papersize}, $data_format);
    $ws_all->write($row_num, 5, $row->{copies}, $data_format);
    $ws_all->write($row_num, 6, $row->{pagecount}, $data_format);
    $ws_all->write($row_num, 7, $row->{printtotal}, $money_format);
    $ws_all->write($row_num, 8, $row->{filename}, $data_format);
    $ws_all->write($row_num, 9, $row->{submitted_at}, $data_format);
    $row_num++;
}

# Summary row
$ws_all->write($row_num, 6, 'TOTAL:', $summary_format);
$ws_all->write($row_num, 7, $total_amount, $money_format);

# ============================================
# Sheet 2: ITHACA BURSAR (formatted for SIS upload)
# ============================================
my $ws_bursar = $workbook->add_worksheet('ITHACA BURSAR FMT');
$ws_bursar->set_column(0, 0, 12);  # Student ID
$ws_bursar->set_column(1, 1, 6);   # Spaces
$ws_bursar->set_column(2, 2, 12);  # Amount
$ws_bursar->set_column(3, 3, 15);  # Fixed code
$ws_bursar->set_column(4, 4, 10);  # Date
$ws_bursar->set_column(5, 5, 15);  # SFS
$ws_bursar->set_column(6, 6, 12);  # NetID

# Headers
my @bursar_headers = ('Student ID', 'Spacer', 'Amount', 'Code', 'Date', 'SFS', 'NetID');
for my $col (0 .. $#bursar_headers) {
    $ws_bursar->write(0, $col, $bursar_headers[$col], $header_format);
}

# Data rows formatted for SIS
$row_num = 1;
foreach my $row (@all_data) {
    my $student_id = sprintf("%07d", $row->{student_id} || 0);
    my $amount = sprintf("%08.2f", $row->{printtotal} || 0);

    $ws_bursar->write($row_num, 0, $student_id, $data_format);
    $ws_bursar->write($row_num, 1, '    ', $data_format);  # 4 spaces
    $ws_bursar->write($row_num, 2, $amount, $data_format);
    $ws_bursar->write($row_num, 3, '001000000777', $data_format);
    $ws_bursar->write($row_num, 4, $date_string, $data_format);
    $ws_bursar->write($row_num, 5, $sfs_code, $data_format);
    $ws_bursar->write($row_num, 6, $row->{netid}, $data_format);
    $row_num++;
}

# ============================================
# Sheet 3: Summary
# ============================================
my $ws_summary = $workbook->add_worksheet('Summary');
$ws_summary->set_column(0, 0, 25);
$ws_summary->set_column(1, 1, 20);

my @summary_data = (
    ['Report Generated', scalar localtime()],
    ['Generated By', $netid],
    ['', ''],
    ['Location', 'ITHACA'],
    ['Billing Method', 'Bursar'],
    ['', ''],
    ['Start ID', $start_id],
    ['End ID', $end_id],
    ['', ''],
    ['Total Jobs', scalar @all_data],
    ['Total Amount', sprintf('$%.2f', $total_amount)],
    ['', ''],
    ['SFS Code', $sfs_code],
    ['Billing Date', $date_string],
    ['', ''],
    ['Marked as Billed', ($set_billed eq 'justdoit' ? 'YES' : 'NO')],
);

$row_num = 0;
foreach my $item (@summary_data) {
    $ws_summary->write($row_num, 0, $item->[0], $data_format);
    $ws_summary->write($row_num, 1, $item->[1], $data_format);
    $row_num++;
}

# Close workbook
$workbook->close();

# ============================================
# Mark as billed if requested
# ============================================
if ($set_billed eq 'justdoit') {
    my $dbh2 = DBI->connect("DBI:mysql:database=$db;host=$host", $user, $password, {
        RaiseError => 1,
        PrintError => 0
    });

    my $update_sql = "UPDATE webprint SET billed = 'yes', billed_at = NOW() WHERE id >= ? AND id <= ? AND location = 'ITHACA' AND billingmethod = 'Bursar'";
    my $sth_update = $dbh2->prepare($update_sql);
    $sth_update->execute($start_id, $end_id);
    $sth_update->finish();

    # Log the billing export
    my $log_sql = "INSERT INTO billing_exports (admin_netid, start_id, end_id, sfs_code, export_date, total_amount, record_count, marked_as_billed) VALUES (?, ?, ?, ?, ?, ?, ?, 1)";
    my $sth_log = $dbh2->prepare($log_sql);
    $sth_log->execute($netid, $start_id, $end_id, $sfs_code, $date_string, $total_amount, scalar @all_data);
    $sth_log->finish();

    $dbh2->disconnect();
}

$dbh->disconnect();
