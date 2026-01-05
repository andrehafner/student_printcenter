#!/usr/bin/perl
use CGI;

my $q = CGI->new();

##!/usr/bin/perl
use strict;
use warnings;
use DBI;

# Database connection details
my $db = "pc";  # Your database name
my $host = "localhost";  # Your database host
my $user = "root";  # Your MySQL username
my $dbpasswordretreive = 'E:/dbaccess/employer.txt';  # Path to the password file

# Get DB password
my $password = do {
  local $/ = undef;
  open my $fh, "<", $dbpasswordretreive or die "Could not open $dbpasswordretreive: $!";
  <$fh>;
};

# Connect to the MySQL database
my $dbh = DBI->connect("DBI:mysql:database=$db;host=$host", $user, $password)
  or die "Cannot connect to database: $DBI::errstr\n";

# SQL query to fetch the first and last rowid where billed IS NULL
my $sql = "SELECT MIN(id) AS first_rowid, MAX(id) AS last_rowid FROM printcenter WHERE billed IS NULL";
my $sth = $dbh->prepare($sql);
$sth->execute();

# Fetch the result into an array
my @rowids = $sth->fetchrow_array();

# Print the first and last rowids


# Clean up
$sth->finish();
$dbh->disconnect();




# Connect to the MySQL database
my $dbh2 = DBI->connect("DBI:mysql:database=$db;host=$host", $user, $password)
  or die "Cannot connect to database: $DBI::errstr\n";


# SQL query to sum plottotal between the start and end date
my $sql2 = "SELECT SUM(plottotal) AS total_plotsum FROM printcenter WHERE id BETWEEN ? AND ?;";
my $sth2 = $dbh2->prepare($sql2);
$sth2->execute($rowids[0], $rowids[1]);

# Fetch the result into an array
my @result2 = $sth2->fetchrow_array();

# Clean up
$sth->finish();
$dbh->disconnect();


my $html = qq{Content-Type: text/html

<HTML>
  <link rel="stylesheet" type="text/css" href="admissions.css">
  <form class="form-style-7" ACTION="process_info.pl" METHOD="post" enctype="multipart/form-data">
<form ACTION="process_info.pl" METHOD="post" enctype="multipart/form-data">
  <BODY>
<p>
}
;

my $number = @result2[0];

# Use sprintf to format with two decimals
my $formatted_number = sprintf("%.2f", $number);

# Add commas manually with regex
$formatted_number =~ s/(\d)(?=(\d{3})+(\.\d{2})?$)/$1,/g;


print $html;

# Print HTML header and include admissions.css stylesheet
#print $q->header(-type => 'text/html');
print qq{
<body>

  <h1>Billing Report Generation</h1>
    <ul>
      <li>    
Current Unbilled:<br>
First row ID: <b>$rowids[0]</b><br>
Last row ID: <b>$rowids[1]</b><br>
Total Amount Unbilled: <b>\$$formatted_number</b><br>
      </li>
      <li>
        <label for="start">Starting Row ID:</label>
        <input type="text" id="start" name="start" value="$rowids[0]" required>
      </li>
      <li>
        <label for="end">Ending Row ID:</label>
        <input type="text" id="end" name="end" value="$rowids[1]" required>
      </li>
      <li>
        <label for="sfs">SFS Code:</label>
        <input type="text" id="sfs" name="sfs" required>
        <span><a href="https://drive.google.com/file/d/1-VHl_ROrRtyNPBbVfaXweHvtyHd5FXci/view?usp=sharing" target="_blank">SFS Codes</a></span>
      </li>
      <li>
        <label for="date">Date:</label>
        <input type="text" id="date" name="date" required>
        <span>MMDDYY</span>
      </li>
      <li>
        <label for="set_billed">Set as Billed Command:</label>
        <input type="text" id="set_billed" name="set_billed">
        <span>this is secret and protected</span>
      </li>
      <li>
        <label for="ignore_billed">Should we Ignore Billed Query?:</label>
        <input type="text" id="ignore_billed" name="ignore_billed">
        <span>set to yes if you want old data and to ignore 'billed is null' in the MYSql query</span>
      </li>
        <input type="submit" value="Generate Report">
    </ul>
  </form>

</body>
</html>
};


