-- ============================================
-- AAP IT Student Web Print Center Database
-- Cornell University
-- ============================================
-- Database Connection Info:
--   Host: localhost
--   User: root
--   Password: (stored in E:/dbaccess/employer.txt)
--   Database: student_printing
-- ============================================

-- Create database if not exists
CREATE DATABASE IF NOT EXISTS student_printing CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE student_printing;

-- ============================================
-- Main Print Jobs Table
-- ============================================
CREATE TABLE IF NOT EXISTS webprint (
    id INT AUTO_INCREMENT PRIMARY KEY,

    -- Student Information
    netid VARCHAR(50) NOT NULL,
    student_id VARCHAR(7) NOT NULL COMMENT '7-digit Cornell student ID',

    -- Print Job Details
    printer VARCHAR(50) NOT NULL COMMENT 'Printer location (AAP_IT, RISO, Sibley_235)',
    papersize VARCHAR(20) NOT NULL COMMENT 'Paper size (85_11, 11_17)',
    duplex VARCHAR(20) NOT NULL COMMENT 'Print mode (single, duplex)',
    fit VARCHAR(20) NOT NULL COMMENT 'Scaling (fit, original)',
    copies INT DEFAULT 1,
    pagecount INT DEFAULT 0,
    filename VARCHAR(255) NOT NULL,

    -- Billing Information
    billingmethod ENUM('Bursar', 'Nautilus') NOT NULL DEFAULT 'Bursar',
    printtotal DECIMAL(10,2) DEFAULT 0.00 COMMENT 'Total cost in USD',

    -- Blockchain Payment Fields (Nautilus)
    blockchain_flag CHAR(1) DEFAULT 'n' COMMENT 'y if blockchain payment',
    nautilus_brick_amount INT DEFAULT 0 COMMENT 'Amount in BRICK tokens',
    blockchain_payment_cleared CHAR(1) DEFAULT 'n' COMMENT 'y when payment confirmed',
    blockchain_txid VARCHAR(128) DEFAULT NULL COMMENT 'Transaction ID from blockchain',
    nautilus_wallet_address VARCHAR(128) DEFAULT NULL COMMENT 'Student wallet address',

    -- Status and Timestamps
    location VARCHAR(20) DEFAULT 'ITHACA',
    billed VARCHAR(10) DEFAULT NULL COMMENT 'NULL=unbilled, yes=billed',
    secure_print CHAR(1) DEFAULT 'n',
    job_status ENUM('pending_payment', 'queued', 'printed', 'cancelled') DEFAULT 'queued',

    -- Timestamps
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    billed_at TIMESTAMP NULL,

    -- Indexes
    INDEX idx_netid (netid),
    INDEX idx_student_id (student_id),
    INDEX idx_billed (billed),
    INDEX idx_billingmethod (billingmethod),
    INDEX idx_location (location),
    INDEX idx_submitted_at (submitted_at),
    INDEX idx_blockchain_payment (blockchain_flag, blockchain_payment_cleared)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- Pricing Table (for future flexibility)
-- ============================================
CREATE TABLE IF NOT EXISTS pricing (
    id INT AUTO_INCREMENT PRIMARY KEY,
    papersize VARCHAR(20) NOT NULL,
    price_per_page DECIMAL(10,4) NOT NULL,
    description VARCHAR(100),
    active TINYINT(1) DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY unique_papersize (papersize)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Insert default pricing (per sheet, varies by duplex mode)
-- Pricing: 8.5x11 single=$0.005, duplex=$0.10 | 11x17 single=$0.10, duplex=$0.20
INSERT INTO pricing (papersize, price_per_page, description) VALUES
('85_11_single', 0.005, '8.5x11 Letter - Single Sided'),
('85_11_duplex', 0.10, '8.5x11 Letter - Double Sided'),
('11_17_single', 0.10, '11x17 Tabloid - Single Sided'),
('11_17_duplex', 0.20, '11x17 Tabloid - Double Sided')
ON DUPLICATE KEY UPDATE price_per_page = VALUES(price_per_page);

-- ============================================
-- Admin Users Table
-- ============================================
CREATE TABLE IF NOT EXISTS admin_users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    netid VARCHAR(50) NOT NULL UNIQUE,
    role ENUM('admin', 'viewer') DEFAULT 'viewer',
    can_export_billing TINYINT(1) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_netid (netid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Insert admin user ah97 with full billing export access
INSERT INTO admin_users (netid, role, can_export_billing) VALUES
('ah97', 'admin', 1)
ON DUPLICATE KEY UPDATE role = 'admin', can_export_billing = 1;

-- ============================================
-- Billing Export Log (audit trail)
-- ============================================
CREATE TABLE IF NOT EXISTS billing_exports (
    id INT AUTO_INCREMENT PRIMARY KEY,
    admin_netid VARCHAR(50) NOT NULL,
    start_id INT NOT NULL,
    end_id INT NOT NULL,
    sfs_code VARCHAR(50),
    export_date VARCHAR(10),
    total_amount DECIMAL(10,2),
    record_count INT,
    marked_as_billed TINYINT(1) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_admin (admin_netid),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- Printers Table
-- ============================================
CREATE TABLE IF NOT EXISTS printers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    printer_code VARCHAR(50) NOT NULL UNIQUE,
    printer_name VARCHAR(100) NOT NULL,
    location VARCHAR(50) NOT NULL,
    supports_duplex TINYINT(1) DEFAULT 1,
    supports_11x17 TINYINT(1) DEFAULT 1,
    active TINYINT(1) DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_location (location),
    INDEX idx_active (active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Insert printer configurations
INSERT INTO printers (printer_code, printer_name, location, supports_duplex, supports_11x17) VALUES
('AAP_IT', 'AAP IT Office Printer', 'Sibley Hall', 1, 1),
('RISO', 'RISO Room Laser General Printer', 'Sibley Hall', 0, 1),
('Sibley_235', 'Sibley 235 Printer', 'Sibley Hall Room 235', 1, 1)
ON DUPLICATE KEY UPDATE printer_name = VALUES(printer_name);

-- ============================================
-- Views for Reporting
-- ============================================

-- View: Unbilled Ithaca jobs (for admin billing export)
CREATE OR REPLACE VIEW v_unbilled_ithaca AS
SELECT
    id,
    netid,
    student_id,
    printer,
    papersize,
    copies,
    pagecount,
    billingmethod,
    printtotal,
    filename,
    submitted_at
FROM webprint
WHERE billed IS NULL
  AND location = 'ITHACA'
  AND billingmethod = 'Bursar'
ORDER BY id;

-- View: Unbilled summary
CREATE OR REPLACE VIEW v_unbilled_summary AS
SELECT
    MIN(id) AS first_id,
    MAX(id) AS last_id,
    COUNT(*) AS total_jobs,
    SUM(printtotal) AS total_amount,
    billingmethod
FROM webprint
WHERE billed IS NULL
  AND location = 'ITHACA'
GROUP BY billingmethod;

-- View: Blockchain pending payments
CREATE OR REPLACE VIEW v_pending_blockchain AS
SELECT
    id,
    netid,
    student_id,
    nautilus_brick_amount,
    printtotal,
    submitted_at
FROM webprint
WHERE blockchain_flag = 'y'
  AND blockchain_payment_cleared = 'n'
  AND job_status = 'pending_payment'
ORDER BY submitted_at DESC;

-- ============================================
-- Sample Queries for Reference
-- ============================================

-- Get unbilled jobs for billing export:
-- SELECT * FROM webprint WHERE billed IS NULL AND location = 'ITHACA' AND id BETWEEN ? AND ?;

-- Mark jobs as billed:
-- UPDATE webprint SET billed = 'yes', billed_at = NOW() WHERE id >= ? AND id <= ?;

-- Check blockchain payment status:
-- SELECT * FROM webprint WHERE blockchain_flag = 'y' AND blockchain_payment_cleared = 'n';

-- Update blockchain payment as cleared:
-- UPDATE webprint SET blockchain_payment_cleared = 'y', blockchain_txid = ?, job_status = 'queued' WHERE id = ?;

-- ============================================
-- Grant permissions (run as root if needed)
-- ============================================
-- GRANT ALL PRIVILEGES ON pc.* TO 'root'@'localhost';
-- FLUSH PRIVILEGES;

