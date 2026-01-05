#!/usr/bin/perl
#use strict;
use warnings;
use JSON;
use LWP::UserAgent;
use POSIX qw(strftime);
use CGI;
use File::Path;
use File::Copy;
use DBI;
use LWP::UserAgent;
use IO::Socket::SSL;
#use Image::Magick;

#this is where the database password is loacted
my $dbpasswordretreive =  'E:\dbaccess\employer.txt';

$|=1;            # Flush immediately.
print "Content-Type: text/plain\n\n";

print "test";

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


# API URL and wallet address
my $url = 'http://128.253.41.49:9053/blockchain/transaction/byAddress?offset=0&limit=1000';
my $wallet_address = '"9gjX7hZQHzRG7iHC8yf2Hk9miPxd8QPrthSVMQuGSGwdXAgTBht"';
my $target_address = '9gjX7hZQHzRG7iHC8yf2Hk9miPxd8QPrthSVMQuGSGwdXAgTBht';
my $target_token_id = '6ae91b0b309752896eb14025358889661da7e2078d89b4669dceef0a3d125a33';

# Calculate the timestamp for 30 minutes ago
my $current_time = time;
my $time_30_minutes_ago = $current_time - (30 * 60);

# Set up the HTTP client
my $ua = LWP::UserAgent->new;
$ua->default_header('accept' => 'application/json');
$ua->default_header('Content-Type' => 'application/json');

# Make the API request
my $response = $ua->post($url, Content => $wallet_address);

print "\nResponse: $response\n";

if ($response->is_success) {
    my $content = $response->decoded_content;
    print "\nContent: $content\n";
    my $data = decode_json($content);

    # Process transactions
    foreach my $item (@{$data->{items}}) {
        my $transaction_id = $item->{id};
        my $block_height   = $item->{inclusionHeight};
        my $timestamp      = $item->{timestamp};

        # Skip transactions older than 30 minutes
        next if $timestamp / 1000 < $time_30_minutes_ago;

        # Convert the timestamp to a human-readable date
        my $date = strftime("%Y-%m-%d %H:%M:%S", gmtime($timestamp / 1000));

        # Filter outputs by target address
        my @filtered_outputs = grep { $_->{address} eq $target_address } @{$item->{outputs}};

        # Skip if no outputs match the target address
        next unless @filtered_outputs;



#print "$sql\n";


        # Display outputs matching the target address
        foreach my $output (@filtered_outputs) {
            my $erg_value = $output->{value} / 1_000_000_000; # Convert to ERG
            $erg_value = sprintf("%.6f", $erg_value);
            print "erg amount: $erg_value\n";
            #wite the form data back to the database
            $sql = "update printcenter set blockchain_payment_cleared='y', blockchain_txid='$transaction_id' where amnt_erg_due='$erg_value' ORDER BY id DESC LIMIT 500;";
            print "erg sql: $sql\n";
            $sth = $dbh->prepare($sql);
            $sth->execute() or die "SQL Error: " . $dbh->errstr;
            $rowid = $dbh->{q{mysql_insertid}};

            # Filter for the specific token ID
            my @filtered_assets = grep { $_->{tokenId} eq $target_token_id } @{$output->{assets}};

            if (@filtered_assets) {
                #print "  Tokens:\n";
                foreach my $asset (@filtered_assets) {
                    my $brick_id = $asset->{tokenId};
                    my $brick_amt = $asset->{amount};
                    print "brick amount: $brick_amt \n";
                #wite the form data back to the database
                $sql = "update printcenter set blockchain_payment_cleared='y', blockchain_txid='$transaction_id' where amt_brick_due='$brick_amt' ORDER BY id DESC LIMIT 500;";  
                print "brick sql: $sql\n";
                $sth = $dbh->prepare($sql);
                $sth->execute() or die "SQL Error: " . $dbh->errstr;
                $rowid = $dbh->{q{mysql_insertid}};

                }

            }


#$sql = ();
        }

        
    }
} else {
    die "Failed to fetch data: " . $response->status_line . "\n";
}