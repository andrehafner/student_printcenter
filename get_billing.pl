#!/usr/bin/perl

# ============================================
# AAP IT Web Print - Admin Billing Export Interface
# For Ithaca campus only - Admin: ah97
# ============================================

use CGI;
use DBI;
use strict;
use warnings;

# Database Configuration
my $db = "pc";
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

# Output HTML header
print $query->header('text/html');

# Check admin access
unless ($is_admin) {
    print qq{
<!DOCTYPE html>
<html>
<head>
    <title>Access Denied</title>
    <style>
        body { font-family: Arial, sans-serif; background: #1a1a2e; color: #e2e8f0;
               display: flex; align-items: center; justify-content: center; min-height: 100vh; }
        .error { text-align: center; padding: 2rem; background: rgba(239,68,68,0.1);
                 border: 1px solid rgba(239,68,68,0.3); border-radius: 12px; }
        h1 { color: #f87171; }
    </style>
</head>
<body>
    <div class="error">
        <h1>Access Denied</h1>
        <p>You do not have permission to access the billing export system.</p>
        <p>Current user: $netid</p>
        <p>Contact AAP IT if you believe this is an error.</p>
    </div>
</body>
</html>
};
    exit;
}

# Connect to database
my $dbh = DBI->connect("DBI:mysql:database=$db;host=$host", $user, $password, {
    RaiseError => 1,
    PrintError => 0,
    mysql_enable_utf8 => 1
}) or die "Cannot connect to database: $DBI::errstr\n";

# Get unbilled job statistics for Ithaca (Bursar only - blockchain handled separately)
my $sql = "SELECT MIN(id) AS first_rowid, MAX(id) AS last_rowid, COUNT(*) AS total_jobs,
           SUM(printtotal) AS total_amount
           FROM webprint
           WHERE billed IS NULL AND location = 'ITHACA' AND billingmethod = 'Bursar'";

my $sth = $dbh->prepare($sql);
$sth->execute();
my $row = $sth->fetchrow_hashref();

my $first_id = $row->{first_rowid} || 0;
my $last_id = $row->{last_rowid} || 0;
my $total_jobs = $row->{total_jobs} || 0;
my $total_amount = $row->{total_amount} || 0;

# Format total amount with commas and 2 decimals
my $formatted_total = sprintf("%.2f", $total_amount);
$formatted_total =~ s/(\d)(?=(\d{3})+(\.\d{2})?$)/$1,/g;

$sth->finish();

# Get blockchain payment summary (separate from bursar billing)
my $sql_blockchain = "SELECT COUNT(*) AS bc_jobs, SUM(nautilus_brick_amount) AS bc_brick_total
                      FROM webprint
                      WHERE billed IS NULL AND location = 'ITHACA' AND billingmethod = 'Nautilus'
                      AND blockchain_payment_cleared = 'y'";
my $sth_bc = $dbh->prepare($sql_blockchain);
$sth_bc->execute();
my $bc_row = $sth_bc->fetchrow_hashref();
my $bc_jobs = $bc_row->{bc_jobs} || 0;
my $bc_brick_total = $bc_row->{bc_brick_total} || 0;
$sth_bc->finish();

$dbh->disconnect();

# Get current date for default
my ($sec, $min, $hour, $mday, $mon, $year) = localtime();
my $default_date = sprintf("%02d%02d%02d", $mon + 1, $mday, $year % 100);

# Output the billing interface HTML
print qq{
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin Billing Export | AAP IT Web Print</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #0f0f23 0%, #1a1a2e 50%, #16213e 100%);
            color: #e2e8f0;
            min-height: 100vh;
            padding: 2rem;
        }
        .container { max-width: 800px; margin: 0 auto; }
        .header { text-align: center; margin-bottom: 2rem; }
        .header h1 { color: #f8fafc; font-size: 1.75rem; margin-bottom: 0.5rem; }
        .header .admin-badge {
            display: inline-block;
            background: linear-gradient(135deg, #22c55e, #16a34a);
            color: white;
            padding: 0.25rem 0.75rem;
            border-radius: 20px;
            font-size: 0.85rem;
            font-weight: 500;
        }
        .stats-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 1rem; margin-bottom: 2rem; }
        .stat-card {
            background: rgba(30, 41, 59, 0.7);
            border: 1px solid rgba(71, 85, 105, 0.3);
            border-radius: 12px;
            padding: 1.25rem;
            text-align: center;
        }
        .stat-card .label { color: #94a3b8; font-size: 0.85rem; margin-bottom: 0.5rem; }
        .stat-card .value { color: #f8fafc; font-size: 1.5rem; font-weight: 600; }
        .stat-card .value.amount { color: #4ade80; }
        .stat-card .value.blockchain { color: #f59e0b; }
        .form-container {
            background: rgba(30, 41, 59, 0.7);
            border: 1px solid rgba(71, 85, 105, 0.3);
            border-radius: 16px;
            padding: 2rem;
        }
        .form-title { font-size: 1.25rem; margin-bottom: 1.5rem; color: #f1f5f9; }
        .form-group { margin-bottom: 1.5rem; }
        .form-label { display: block; color: #f1f5f9; margin-bottom: 0.5rem; font-weight: 500; }
        .form-help { font-size: 0.85rem; color: #94a3b8; margin-top: 0.25rem; }
        input[type="text"], input[type="number"] {
            width: 100%;
            padding: 0.75rem 1rem;
            background: rgba(15, 23, 42, 0.8);
            border: 1px solid rgba(71, 85, 105, 0.5);
            border-radius: 8px;
            color: #f8fafc;
            font-size: 1rem;
        }
        input:focus { outline: none; border-color: #3b82f6; }
        .form-row { display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; }
        .checkbox-group { display: flex; align-items: center; gap: 0.5rem; }
        .checkbox-group input[type="checkbox"] { width: 18px; height: 18px; accent-color: #3b82f6; }
        .btn {
            padding: 0.875rem 1.5rem;
            border: none;
            border-radius: 8px;
            font-size: 1rem;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s;
        }
        .btn-primary {
            background: linear-gradient(135deg, #3b82f6, #1d4ed8);
            color: white;
            width: 100%;
        }
        .btn-primary:hover {
            background: linear-gradient(135deg, #2563eb, #1e40af);
            transform: translateY(-1px);
        }
        .warning {
            background: rgba(245, 158, 11, 0.1);
            border: 1px solid rgba(245, 158, 11, 0.3);
            border-radius: 8px;
            padding: 1rem;
            margin-bottom: 1.5rem;
            color: #fbbf24;
        }
        .info {
            background: rgba(59, 130, 246, 0.1);
            border: 1px solid rgba(59, 130, 246, 0.3);
            border-radius: 8px;
            padding: 1rem;
            margin-bottom: 1.5rem;
            color: #93c5fd;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Admin Billing Export</h1>
            <span class="admin-badge">Admin: $netid</span>
        </div>

        <div class="stats-grid">
            <div class="stat-card">
                <div class="label">First Unbilled ID</div>
                <div class="value">$first_id</div>
            </div>
            <div class="stat-card">
                <div class="label">Last Unbilled ID</div>
                <div class="value">$last_id</div>
            </div>
            <div class="stat-card">
                <div class="label">Total Unbilled Jobs</div>
                <div class="value">$total_jobs</div>
            </div>
            <div class="stat-card">
                <div class="label">Total Amount Due (Bursar)</div>
                <div class="value amount">\$$formatted_total</div>
            </div>
        </div>

        <div class="info">
            <strong>Blockchain Payments (Ithaca):</strong> $bc_jobs jobs paid via Nautilus ($bc_brick_total BRICK total)
            <br><small>Blockchain payments are handled separately and not included in bursar billing.</small>
        </div>

        <div class="form-container">
            <h2 class="form-title">Generate Billing Report</h2>

            <form action="process_billing.pl" method="post">
                <div class="form-row">
                    <div class="form-group">
                        <label class="form-label" for="start">Starting Row ID</label>
                        <input type="number" name="start" id="start" value="$first_id" required>
                    </div>
                    <div class="form-group">
                        <label class="form-label" for="end">Ending Row ID</label>
                        <input type="number" name="end" id="end" value="$last_id" required>
                    </div>
                </div>

                <div class="form-row">
                    <div class="form-group">
                        <label class="form-label" for="sfs">SFS Code</label>
                        <input type="text" name="sfs" id="sfs" placeholder="Enter SFS code">
                        <div class="form-help">Cornell SFS billing code for department</div>
                    </div>
                    <div class="form-group">
                        <label class="form-label" for="date">Billing Date (MMDDYY)</label>
                        <input type="text" name="date" id="date" value="$default_date" maxlength="6" pattern="[0-9]{6}">
                    </div>
                </div>

                <div class="warning">
                    <strong>Important:</strong> After downloading and reviewing the billing report,
                    return here and check "Mark as Billed" to update the database.
                    This prevents jobs from being billed twice.
                </div>

                <div class="form-group">
                    <div class="checkbox-group">
                        <input type="checkbox" name="ignore_billed" id="ignore_billed" value="yes">
                        <label for="ignore_billed">Include previously billed jobs (for historical reports)</label>
                    </div>
                </div>

                <div class="form-group">
                    <label class="form-label" for="set_billed">Mark as Billed Command</label>
                    <input type="text" name="set_billed" id="set_billed" placeholder="Type 'justdoit' to mark jobs as billed">
                    <div class="form-help">Type exactly "justdoit" to mark the selected range as billed after export</div>
                </div>

                <button type="submit" class="btn btn-primary">Generate Billing Report (Excel)</button>
            </form>
        </div>
    </div>
</body>
</html>
};
