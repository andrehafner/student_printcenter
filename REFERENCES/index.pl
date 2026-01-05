#!/usr/bin/perl

use CGI;
use File::Path;
use File::Copy;
use DBI;
use List::Util 1.33 'any';
use warnings;

print "Content-Type: text/html\n\n";

#get the current logged in user
$netid = Win32::LoginName;

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

my $bursarTEXT = '';

if ($found) {
$bursarTEXT = '<div class="radio-option">
                    <input type="radio" value="Bursar" name="billingmethod" id="billing_bursar" required>
                    <label for="billing_bursar">Bursar<span class="location-badge">Active Students Only</span></label>
                </div>'
}

# HTML FORM
my $html = qq{<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AAP IT Plot Center | Cornell University</title>
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
        }

        .container {
            max-width: 1000px;
            margin: 0 auto;
            padding: 2rem;
        }

        .header {
            text-align: center;
            margin-bottom: 3rem;
            padding: 2rem 0;
        }

        .cornell-logo {
            color: #b91c1c;
            font-size: 1.2rem;
            font-weight: 600;
            margin-bottom: 1rem;
            text-transform: uppercase;
            letter-spacing: 1px;
        }

        .main-title {
            font-size: 2.8rem;
            font-weight: 700;
            color: #f8fafc;
            margin-bottom: 0.5rem;
            text-shadow: 0 2px 4px rgba(0,0,0,0.3);
        }

        .subtitle {
            font-size: 1.4rem;
            color: #94a3b8;
            font-weight: 600;
            margin-bottom: 1rem;
        }

        .restriction-notice {
            color: #b91c1c;
            font-weight: 600;
            font-size: 1rem;
            margin-bottom: 1.5rem;
        }

        .history-link {
            display: inline-block;
            background: linear-gradient(135deg, #7c3aed 0%, #5b21b6 100%);
            color: white;
            padding: 0.75rem 1.5rem;
            text-decoration: none;
            border-radius: 8px;
            font-weight: 600;
            transition: all 0.3s ease;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }

        .history-link:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 15px -3px rgba(124, 58, 237, 0.3);
        }

        .form-container {
            background: rgba(30, 41, 59, 0.7);
            backdrop-filter: blur(10px);
            border: 1px solid rgba(71, 85, 105, 0.3);
            border-radius: 16px;
            padding: 2.5rem;
            box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
            margin-top: 2rem;
        }

        .form-group {
            margin-bottom: 2rem;
        }

        .form-label {
            display: block;
            font-weight: 600;
            color: #f1f5f9;
            margin-bottom: 0.75rem;
            font-size: 1rem;
        }

        .form-help {
            font-size: 0.9rem;
            color: #94a3b8;
            margin-top: 0.5rem;
            font-style: italic;
        }

        .form-warning {
            font-size: 0.9rem;
            color: #f87171;
            margin-top: 0.5rem;
            font-weight: 500;
        }

        input[type="file"] {
            width: 100%;
            padding: 1rem;
            background: rgba(15, 23, 42, 0.8);
            border: 2px dashed rgba(71, 85, 105, 0.5);
            border-radius: 8px;
            color: #e2e8f0;
            font-size: 1rem;
            transition: all 0.3s ease;
        }

        input[type="file"]:hover {
            border-color: #7c3aed;
            background: rgba(15, 23, 42, 0.9);
        }

        input[type="text"] {
            width: 100%;
            padding: 0.875rem 1rem;
            background: rgba(15, 23, 42, 0.8);
            border: 1px solid rgba(71, 85, 105, 0.5);
            border-radius: 8px;
            color: #f8fafc;
            font-size: 1rem;
            transition: all 0.3s ease;
        }

        input[type="text"]:focus {
            outline: none;
            border-color: #7c3aed;
            box-shadow: 0 0 0 3px rgba(124, 58, 237, 0.1);
        }

        .radio-group {
            display: flex;
            flex-direction: column;
            gap: 0.75rem;
        }

        .radio-group.grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 0.75rem;
        }

        .radio-group.paper-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(140px, 1fr));
            gap: 0.5rem;
        }

        .radio-option {
            display: flex;
            align-items: center;
            padding: 0.75rem;
            background: rgba(15, 23, 42, 0.4);
            border: 1px solid rgba(71, 85, 105, 0.3);
            border-radius: 8px;
            cursor: pointer;
            transition: all 0.3s ease;
        }

        .radio-option:hover {
            background: rgba(15, 23, 42, 0.6);
            border-color: #7c3aed;
        }

        .radio-option input[type="radio"] {
            margin-right: 0.75rem;
            width: 18px;
            height: 18px;
            accent-color: #7c3aed;
        }

        .radio-option label {
            cursor: pointer;
            flex: 1;
            margin: 0;
            font-weight: 500;
        }

        .section-title {
            font-weight: 700;
            color: #f8fafc;
            margin-bottom: 1rem;
            font-size: 1.1rem;
            padding-bottom: 0.5rem;
            border-bottom: 2px solid rgba(124, 58, 237, 0.3);
        }

        .pricing-link {
            color: #a78bfa;
            text-decoration: none;
            font-weight: 500;
        }

        .pricing-link:hover {
            color: #c4b5fd;
            text-decoration: underline;
        }

        .submit-button {
            width: 100%;
            padding: 1rem 2rem;
            background: linear-gradient(135deg, #7c3aed 0%, #5b21b6 100%);
            color: white;
            border: none;
            border-radius: 8px;
            font-size: 1.1rem;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s ease;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
            margin-bottom: 1rem;
        }

        .submit-button:hover:not(:disabled) {
            background: linear-gradient(135deg, #6d28d9 0%, #4c1d95 100%);
            transform: translateY(-2px);
            box-shadow: 0 8px 15px -3px rgba(0, 0, 0, 0.2);
        }

        .submit-button:disabled {
            opacity: 0.7;
            cursor: not-allowed;
            transform: none;
        }

        .upload-warning {
            text-align: center;
            color: #fbbf24;
            font-weight: 600;
            margin-bottom: 2rem;
            padding: 1rem;
            background: rgba(245, 158, 11, 0.1);
            border: 1px solid rgba(245, 158, 11, 0.3);
            border-radius: 8px;
        }

        .definitions {
            background: rgba(15, 23, 42, 0.6);
            border: 1px solid rgba(71, 85, 105, 0.3);
            border-radius: 8px;
            padding: 1.5rem;
            margin-top: 2rem;
        }

        .definitions h3 {
            color: #f8fafc;
            margin-bottom: 1rem;
            font-size: 1.1rem;
        }

        .definitions p {
            margin-bottom: 0.5rem;
            font-size: 0.9rem;
            color: #cbd5e1;
        }

        .location-badge {
            display: inline-block;
            background: rgba(124, 58, 237, 0.2);
            color: #c4b5fd;
            padding: 0.25rem 0.5rem;
            border-radius: 4px;
            font-size: 0.75rem;
            font-weight: 500;
            margin-left: 0.5rem;
        }

        \@media (max-width: 768px) {
            .container {
                padding: 1rem;
            }
            
            .main-title {
                font-size: 2.2rem;
            }
            
            .form-container {
                padding: 1.5rem;
            }

            .radio-group.grid,
            .radio-group.paper-grid {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="cornell-logo">Cornell University</div>
            <h1 class="main-title">AAP IT Plot Center</h1>
            <div class="subtitle">PLOT SUBMISSION PORTAL</div>
            <div class="restriction-notice">For AAP Students only, we do not have the staff to scale to outside of AAP.</div>
            <a href="https://share.aap.cornell.edu/printcenter/student_history.pl" class="history-link">
                Lookup Your Plotting History
            </a>
        </div>

        <div class="form-container">
            <form class="form-style-7" ACTION="process_upload.pl" METHOD="post" enctype="multipart/form-data">
                <div class="form-group">
                    <label class="form-label" for="iddigit">Student ID Number</label>
                    <input type="text" name="iddigit" id="iddigit" maxlength="7" required>
                    <div class="form-help">Enter your 7-digit ID number as written on your student ID</div>
                </div>

                <div class="form-group">
                    <label class="form-label" for="plotwidth">Width (inches)</label>
                    <input type="text" name="plotwidth" id="plotwidth" maxlength="10" required>
                    <div class="form-warning">Max of 42 for Bond and Photo, max of 36 for Mylar and Transparency, 44, 24, or custom size for BYOP in the ADMS</div>
                </div>

                <div class="form-group">
                    <label class="form-label" for="plotheight">Height (inches)</label>
                    <input type="text" name="plotheight" id="plotheight" maxlength="10" required>
                    <div class="form-help">Must be more than 12 inches (150 inches or less)</div>
                    <div class="form-warning">Total single page height not to exceed 150 inches, anything over 100 is your own risk.</div>
                </div>

                <div class="form-group">
                    <label class="form-label" for="file">Upload File</label>
                    <input type="file" name="file" id="file" required>
                    <div class="form-help">PDF only for HP and OCE (under 100MB), TIF only for ADMS. Your NetID will automatically be placed on your file!</div>
                    <div class="form-warning">SINGLE PAGES ONLY. Color correction is not guaranteed!</div>
                </div>

                <div class="form-group">
                    <label class="form-label">Location</label>
                    <div class="section-title">Where are you?</div>
                    <div class="radio-group grid">
                        <div class="radio-option">
                            <input type="radio" value="ITHACA" name="location" id="location_ithaca" required>
                            <label for="location_ithaca">Ithaca Campus</label>
                        </div>
                        <div class="radio-option">
                            <input type="radio" value="TATA" name="location" id="location_tata">
                            <label for="location_tata">Tata NYC</label>
                        </div>
                        <div class="radio-option">
                            <input type="radio" value="ROME" name="location" id="location_rome">
                            <label for="location_rome">Rome</label>
                        </div>
                    </div>
                </div>

                <div class="form-group">
                    <label class="form-label">Paper Type</label>
                    
                    <div class="section-title">General Plotter Paper <span style="font-weight: normal; color: #94a3b8;">(Rome, NYC, TATA only use Bond)</span></div>
                    <div class="radio-group paper-grid">
                        <div class="radio-option">
                            <input type="radio" value="Bond" name="plotpapertype" id="paper_bond" required>
                            <label for="paper_bond">Bond</label>
                        </div>
                        <div class="radio-option">
                            <input type="radio" value="Photo" name="plotpapertype" id="paper_photo">
                            <label for="paper_photo">Photo</label>
                        </div>
                        <div class="radio-option">
                            <input type="radio" value="Transparent" name="plotpapertype" id="paper_transparent">
                            <label for="paper_transparent">Transparent</label>
                        </div>
                        <div class="radio-option">
                            <input type="radio" value="MATTE FILM" name="plotpapertype" id="paper_matte">
                            <label for="paper_matte">Matte Film (Mylar)</label>
                        </div>
                        <div class="radio-option">
                            <input type="radio" value="Entrada" name="plotpapertype" id="paper_entrada">
                            <label for="paper_entrada">Entrada</label>
                        </div>
                    </div>

                    <div class="section-title">Tjaden Fine Art (Ithaca Only)<a href="https://cornell.box.com/s/y2wr2a6svb0w9d8ky300822mkrn7hq2e" class="pricing-link" target="_blank"> - pricing</a></div>
                    <div class="radio-group paper-grid">
                        <div class="radio-option">
                            <input type="radio" value="EHPB - ADMS" name="plotpapertype" id="paper_ehpb">
                            <label for="paper_ehpb">EHPB</label>
                        </div>
                        <div class="radio-option">
                            <input type="radio" value="MLPM - ADMS" name="plotpapertype" id="paper_mlpm">
                            <label for="paper_mlpm">MLPM</label>
                        </div>
                        <div class="radio-option">
                            <input type="radio" value="EECM - ADMS" name="plotpapertype" id="paper_eecm">
                            <label for="paper_eecm">EECM</label>
                        </div>
                        <div class="radio-option">
                            <input type="radio" value="PCT - ADMS" name="plotpapertype" id="paper_pct">
                            <label for="paper_pct">PCT</label>
                        </div>
                        <div class="radio-option">
                            <input type="radio" value="PF - ADMS" name="plotpapertype" id="paper_pf">
                            <label for="paper_pf">PF</label>
                        </div>
                        <div class="radio-option">
                            <input type="radio" value="EPGP - ADMS" name="plotpapertype" id="paper_epgp">
                            <label for="paper_epgp">EPGP</label>
                        </div>
                        <div class="radio-option">
                            <input type="radio" value="EUPL - ADMS" name="plotpapertype" id="paper_eupl">
                            <label for="paper_eupl">EUPL</label>
                        </div>
                        <div class="radio-option">
                            <input type="radio" value="OP - ADMS" name="plotpapertype" id="paper_op">
                            <label for="paper_op">OP (BYOP)</label>
                        </div>
                    </div>
                </div>

                <div class="form-group">
                    <label class="form-label" for="notes">Special Notes</label>
                    <input type="text" name="notes" id="notes" maxlength="100">
                    <div class="form-help">Specify plotter preferences, color requirements, or other special instructions (not guaranteed)</div>
                </div>

                <div class="form-group">
                    <label class="form-label">Billing Method (If Bursar isn't listed, contact aap-it\@cornell.edu or ping us on Discord!</label>
                    <div class="radio-group">
                        $bursarTEXT
                        <div class="radio-option">
                            <input type="radio" value="Account" name="billingmethod" id="billing_account">
                            <label for="billing_account">Account<span class="location-badge">Employee Only</span></label>
                        </div>
                        <div class="radio-option">
                            <input type="radio" value="Blockchain" name="billingmethod" id="billing_blockchain" required>
                            <label for="billing_blockchain">Discord Blockchain<span class="location-badge">Check Discord</span></label>
                        </div>
                        <div class="radio-option">
                            <input type="radio" value="Nautilus" name="billingmethod" id="billing_nautilus">
                            <label for="billing_nautilus">Nautilus Blockchain<span class="location-badge">Pay with Wallet</span></label>
                        </div>
                    </div>
                </div>

                <div class="form-group">
                    <label class="form-label" for="account">Account Number (if Account billing selected)</label>
                    <input type="text" name="account" id="account" maxlength="19">
                    <div class="form-help">Must follow format exactly: A0XXXXX or a0XXXXX</div>
                </div>

                <input type="submit" name="Submit" value="Submit Print Job" class="submit-button"
                       onclick="event.preventDefault(); this.disabled=true; this.value='Uploading...'; this.form.requestSubmit();">

                <div class="upload-warning">
                    ONLY HIT SUBMIT ONCE PLEASE, YOUR FILE MAY TAKE A FEW MINUTES TO UPLOAD!
                </div>
            </form>
        </div>

        <div class="definitions">
            <h3>Fine Art Paper Type Definitions:</h3>
            <p><strong>ECPN</strong> - Epson Cold Press Natural</p>
            <p><strong>EHPB</strong> - Epson Hot Press Bright</p>
            <p><strong>MLPM</strong> - Moab Lasal Photo Matte</p>
            <p><strong>EECM</strong> - Epson Exhibition Canvas Matte</p>
            <p><strong>PCT</strong> - Parrot Clear Transparency</p>
            <p><strong>PF</strong> - Pictorico Film (milky white surface)</p>
            <p><strong>EPGP</strong> - Epson Premium Glossy Photo</p>
            <p><strong>EUPL</strong> - Epson Ultra-Premium Luster</p>
            <p><strong>OP</strong> - Bring your own paper</p>
        </div>
    </div>
</body>
</html>};

#show the form
print $html;

exit;