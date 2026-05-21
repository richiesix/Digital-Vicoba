-- Digital Vikoba - MySQL 8 InnoDB Schema
-- VICOBA/VSLA Community Savings Platform for Tanzania

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

CREATE DATABASE IF NOT EXISTS digital_vicoba
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE digital_vicoba;

-- ============ RBAC ============
CREATE TABLE roles (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(50) NOT NULL UNIQUE,
  slug VARCHAR(50) NOT NULL UNIQUE,
  description TEXT,
  is_system TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP NULL,
  INDEX idx_roles_slug (slug)
) ENGINE=InnoDB;

CREATE TABLE permissions (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  slug VARCHAR(100) NOT NULL UNIQUE,
  module VARCHAR(50) NOT NULL,
  description TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_permissions_module (module)
) ENGINE=InnoDB;

CREATE TABLE role_permissions (
  role_id BIGINT UNSIGNED NOT NULL,
  permission_id BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (role_id, permission_id),
  FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
  FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============ USERS & DEVICES ============
CREATE TABLE users (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  phone_number VARCHAR(20) NOT NULL UNIQUE,
  phone_verified_at TIMESTAMP NULL,
  national_id VARCHAR(30) NULL,
  voter_id VARCHAR(30) NULL,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  email VARCHAR(255) NULL,
  pin_hash VARCHAR(255) NULL,
  password_hash VARCHAR(255) NULL,
  profile_photo_url VARCHAR(500) NULL,
  preferred_language ENUM('sw', 'en') NOT NULL DEFAULT 'sw',
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  last_login_at TIMESTAMP NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP NULL,
  INDEX idx_users_phone (phone_number),
  INDEX idx_users_national_id (national_id)
) ENGINE=InnoDB;

CREATE TABLE user_roles (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  role_id BIGINT UNSIGNED NOT NULL,
  group_id BIGINT UNSIGNED NULL,
  region_id BIGINT UNSIGNED NULL,
  assigned_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  assigned_by BIGINT UNSIGNED NULL,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
  UNIQUE KEY uk_user_role_group (user_id, role_id, group_id),
  INDEX idx_user_roles_user (user_id),
  INDEX idx_user_roles_group (group_id)
) ENGINE=InnoDB;

CREATE TABLE devices (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  device_uuid CHAR(36) NOT NULL,
  device_name VARCHAR(100) NULL,
  platform ENUM('android', 'ios', 'web', 'ussd') NOT NULL DEFAULT 'android',
  fcm_token VARCHAR(500) NULL,
  is_verified TINYINT(1) NOT NULL DEFAULT 0,
  last_seen_at TIMESTAMP NULL,
  bound_at TIMESTAMP NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  UNIQUE KEY uk_device_uuid (device_uuid),
  INDEX idx_devices_user (user_id)
) ENGINE=InnoDB;

CREATE TABLE refresh_tokens (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  device_id BIGINT UNSIGNED NULL,
  token_hash VARCHAR(255) NOT NULL,
  expires_at TIMESTAMP NOT NULL,
  revoked_at TIMESTAMP NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_refresh_tokens_user (user_id),
  INDEX idx_refresh_tokens_hash (token_hash)
) ENGINE=InnoDB;

CREATE TABLE otp_verifications (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  phone_number VARCHAR(20) NOT NULL,
  otp_hash VARCHAR(255) NOT NULL,
  purpose ENUM('register', 'login', 'reset_pin', 'bind_device') NOT NULL,
  attempts TINYINT UNSIGNED NOT NULL DEFAULT 0,
  expires_at TIMESTAMP NOT NULL,
  verified_at TIMESTAMP NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_otp_phone (phone_number, purpose)
) ENGINE=InnoDB;

-- ============ REGIONS ============
CREATE TABLE regions (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  code VARCHAR(10) NOT NULL UNIQUE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_regions_code (code)
) ENGINE=InnoDB;

-- ============ GROUPS ============
CREATE TABLE `groups` (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  name VARCHAR(200) NOT NULL,
  registration_number VARCHAR(50) NULL,
  region_id BIGINT UNSIGNED NULL,
  ward VARCHAR(100) NULL,
  village VARCHAR(100) NULL,
  share_price DECIMAL(15,2) NOT NULL DEFAULT 0,
  currency CHAR(3) NOT NULL DEFAULT 'TZS',
  max_loan_multiplier DECIMAL(5,2) NOT NULL DEFAULT 3.00,
  loan_interest_rate DECIMAL(5,2) NOT NULL DEFAULT 10.00,
  penalty_rate DECIMAL(5,2) NOT NULL DEFAULT 5.00,
  meeting_day ENUM('monday','tuesday','wednesday','thursday','friday','saturday','sunday') NULL,
  meeting_frequency ENUM('weekly','biweekly','monthly') NOT NULL DEFAULT 'weekly',
  constitution_json JSON NULL,
  status ENUM('forming','active','share_out','dormant','closed') NOT NULL DEFAULT 'forming',
  formed_at DATE NULL,
  created_by BIGINT UNSIGNED NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP NULL,
  FOREIGN KEY (region_id) REFERENCES regions(id) ON DELETE SET NULL,
  INDEX idx_groups_status (status),
  INDEX idx_groups_region (region_id)
) ENGINE=InnoDB;

CREATE TABLE group_cycles (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  group_id BIGINT UNSIGNED NOT NULL,
  cycle_number INT UNSIGNED NOT NULL DEFAULT 1,
  start_date DATE NOT NULL,
  end_date DATE NULL,
  total_shares INT UNSIGNED NOT NULL DEFAULT 0,
  total_savings DECIMAL(15,2) NOT NULL DEFAULT 0,
  total_loans_outstanding DECIMAL(15,2) NOT NULL DEFAULT 0,
  emergency_fund_balance DECIMAL(15,2) NOT NULL DEFAULT 0,
  social_fund_balance DECIMAL(15,2) NOT NULL DEFAULT 0,
  status ENUM('active','share_out_pending','completed') NOT NULL DEFAULT 'active',
  share_out_completed_at TIMESTAMP NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (group_id) REFERENCES `groups`(id) ON DELETE CASCADE,
  UNIQUE KEY uk_group_cycle (group_id, cycle_number),
  INDEX idx_group_cycles_status (status)
) ENGINE=InnoDB;

CREATE TABLE sumaku_groups (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  group_id BIGINT UNSIGNED NOT NULL,
  name VARCHAR(100) NOT NULL,
  description TEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (group_id) REFERENCES `groups`(id) ON DELETE CASCADE,
  INDEX idx_sumaku_group (group_id)
) ENGINE=InnoDB;

-- ============ MEMBERS ============
CREATE TABLE members (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  group_id BIGINT UNSIGNED NOT NULL,
  user_id BIGINT UNSIGNED NULL,
  member_number VARCHAR(20) NOT NULL,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  phone_number VARCHAR(20) NOT NULL,
  national_id VARCHAR(30) NULL,
  sumaku_group_id BIGINT UNSIGNED NULL,
  join_date DATE NOT NULL,
  status ENUM('pending','active','suspended','exited') NOT NULL DEFAULT 'pending',
  total_shares INT UNSIGNED NOT NULL DEFAULT 0,
  savings_balance DECIMAL(15,2) NOT NULL DEFAULT 0,
  loan_balance DECIMAL(15,2) NOT NULL DEFAULT 0,
  financial_score DECIMAL(5,2) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP NULL,
  FOREIGN KEY (group_id) REFERENCES `groups`(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
  FOREIGN KEY (sumaku_group_id) REFERENCES sumaku_groups(id) ON DELETE SET NULL,
  UNIQUE KEY uk_member_group_number (group_id, member_number),
  INDEX idx_members_group (group_id),
  INDEX idx_members_phone (phone_number),
  INDEX idx_members_status (status)
) ENGINE=InnoDB;

CREATE TABLE member_roles (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  member_id BIGINT UNSIGNED NOT NULL,
  role_id BIGINT UNSIGNED NOT NULL,
  assigned_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  assigned_by BIGINT UNSIGNED NULL,
  FOREIGN KEY (member_id) REFERENCES members(id) ON DELETE CASCADE,
  FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
  UNIQUE KEY uk_member_role (member_id, role_id)
) ENGINE=InnoDB;

-- ============ FINANCIAL ============
CREATE TABLE shares (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  group_id BIGINT UNSIGNED NOT NULL,
  member_id BIGINT UNSIGNED NOT NULL,
  cycle_id BIGINT UNSIGNED NOT NULL,
  quantity INT UNSIGNED NOT NULL DEFAULT 1,
  unit_price DECIMAL(15,2) NOT NULL,
  total_amount DECIMAL(15,2) NOT NULL,
  payment_method ENUM('cash','mpesa','airtel','mixx','halopesa','group_wallet') NOT NULL DEFAULT 'cash',
  reference VARCHAR(100) NULL,
  recorded_by BIGINT UNSIGNED NULL,
  meeting_id BIGINT UNSIGNED NULL,
  recorded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  synced_at TIMESTAMP NULL,
  client_id VARCHAR(64) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (group_id) REFERENCES `groups`(id) ON DELETE CASCADE,
  FOREIGN KEY (member_id) REFERENCES members(id) ON DELETE CASCADE,
  FOREIGN KEY (cycle_id) REFERENCES group_cycles(id) ON DELETE CASCADE,
  INDEX idx_shares_member (member_id),
  INDEX idx_shares_group_cycle (group_id, cycle_id),
  INDEX idx_shares_client_id (client_id)
) ENGINE=InnoDB;

CREATE TABLE contributions (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  group_id BIGINT UNSIGNED NOT NULL,
  member_id BIGINT UNSIGNED NOT NULL,
  cycle_id BIGINT UNSIGNED NOT NULL,
  type ENUM('savings','emergency','social','penalty','fine') NOT NULL DEFAULT 'savings',
  amount DECIMAL(15,2) NOT NULL,
  payment_method ENUM('cash','mpesa','airtel','mixx','halopesa','group_wallet') NOT NULL DEFAULT 'cash',
  reference VARCHAR(100) NULL,
  notes TEXT NULL,
  recorded_by BIGINT UNSIGNED NULL,
  meeting_id BIGINT UNSIGNED NULL,
  recorded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  synced_at TIMESTAMP NULL,
  client_id VARCHAR(64) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (group_id) REFERENCES `groups`(id) ON DELETE CASCADE,
  FOREIGN KEY (member_id) REFERENCES members(id) ON DELETE CASCADE,
  FOREIGN KEY (cycle_id) REFERENCES group_cycles(id) ON DELETE CASCADE,
  INDEX idx_contributions_member (member_id),
  INDEX idx_contributions_type (type),
  INDEX idx_contributions_client_id (client_id)
) ENGINE=InnoDB;

CREATE TABLE loans (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  group_id BIGINT UNSIGNED NOT NULL,
  member_id BIGINT UNSIGNED NOT NULL,
  cycle_id BIGINT UNSIGNED NOT NULL,
  principal_amount DECIMAL(15,2) NOT NULL,
  interest_rate DECIMAL(5,2) NOT NULL,
  interest_amount DECIMAL(15,2) NOT NULL DEFAULT 0,
  total_amount DECIMAL(15,2) NOT NULL,
  outstanding_balance DECIMAL(15,2) NOT NULL,
  term_weeks INT UNSIGNED NOT NULL,
  purpose TEXT NULL,
  status ENUM('draft','pending_guarantors','pending_vote','approved','disbursed','active','completed','defaulted','rejected') NOT NULL DEFAULT 'draft',
  disbursement_method ENUM('cash','mpesa','airtel','mixx','halopesa','group_wallet') NULL,
  disbursed_at TIMESTAMP NULL,
  due_date DATE NULL,
  approved_by BIGINT UNSIGNED NULL,
  approved_at TIMESTAMP NULL,
  recorded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  synced_at TIMESTAMP NULL,
  client_id VARCHAR(64) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (group_id) REFERENCES `groups`(id) ON DELETE CASCADE,
  FOREIGN KEY (member_id) REFERENCES members(id) ON DELETE CASCADE,
  FOREIGN KEY (cycle_id) REFERENCES group_cycles(id) ON DELETE CASCADE,
  INDEX idx_loans_member (member_id),
  INDEX idx_loans_status (status),
  INDEX idx_loans_client_id (client_id)
) ENGINE=InnoDB;

CREATE TABLE loan_guarantors (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  loan_id BIGINT UNSIGNED NOT NULL,
  guarantor_member_id BIGINT UNSIGNED NOT NULL,
  status ENUM('pending','approved','rejected') NOT NULL DEFAULT 'pending',
  responded_at TIMESTAMP NULL,
  notes TEXT NULL,
  FOREIGN KEY (loan_id) REFERENCES loans(id) ON DELETE CASCADE,
  FOREIGN KEY (guarantor_member_id) REFERENCES members(id) ON DELETE CASCADE,
  UNIQUE KEY uk_loan_guarantor (loan_id, guarantor_member_id)
) ENGINE=InnoDB;

CREATE TABLE loan_votes (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  loan_id BIGINT UNSIGNED NOT NULL,
  member_id BIGINT UNSIGNED NOT NULL,
  vote ENUM('approve','reject','abstain') NOT NULL,
  voted_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (loan_id) REFERENCES loans(id) ON DELETE CASCADE,
  FOREIGN KEY (member_id) REFERENCES members(id) ON DELETE CASCADE,
  UNIQUE KEY uk_loan_vote (loan_id, member_id)
) ENGINE=InnoDB;

CREATE TABLE repayments (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  loan_id BIGINT UNSIGNED NOT NULL,
  member_id BIGINT UNSIGNED NOT NULL,
  amount DECIMAL(15,2) NOT NULL,
  principal_portion DECIMAL(15,2) NOT NULL DEFAULT 0,
  interest_portion DECIMAL(15,2) NOT NULL DEFAULT 0,
  penalty_amount DECIMAL(15,2) NOT NULL DEFAULT 0,
  payment_method ENUM('cash','mpesa','airtel','mixx','halopesa','group_wallet') NOT NULL DEFAULT 'cash',
  reference VARCHAR(100) NULL,
  recorded_by BIGINT UNSIGNED NULL,
  recorded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  synced_at TIMESTAMP NULL,
  client_id VARCHAR(64) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (loan_id) REFERENCES loans(id) ON DELETE CASCADE,
  FOREIGN KEY (member_id) REFERENCES members(id) ON DELETE CASCADE,
  INDEX idx_repayments_loan (loan_id),
  INDEX idx_repayments_client_id (client_id)
) ENGINE=InnoDB;

CREATE TABLE share_outs (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  group_id BIGINT UNSIGNED NOT NULL,
  cycle_id BIGINT UNSIGNED NOT NULL,
  total_pool DECIMAL(15,2) NOT NULL,
  total_distributed DECIMAL(15,2) NOT NULL DEFAULT 0,
  status ENUM('calculating','pending_approval','approved','disbursing','completed') NOT NULL DEFAULT 'calculating',
  calculated_at TIMESTAMP NULL,
  approved_at TIMESTAMP NULL,
  completed_at TIMESTAMP NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (group_id) REFERENCES `groups`(id) ON DELETE CASCADE,
  FOREIGN KEY (cycle_id) REFERENCES group_cycles(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE share_out_distributions (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  share_out_id BIGINT UNSIGNED NOT NULL,
  member_id BIGINT UNSIGNED NOT NULL,
  shares_count INT UNSIGNED NOT NULL,
  gross_amount DECIMAL(15,2) NOT NULL,
  loan_deduction DECIMAL(15,2) NOT NULL DEFAULT 0,
  net_amount DECIMAL(15,2) NOT NULL,
  disbursement_status ENUM('pending','processing','completed','failed') NOT NULL DEFAULT 'pending',
  FOREIGN KEY (share_out_id) REFERENCES share_outs(id) ON DELETE CASCADE,
  FOREIGN KEY (member_id) REFERENCES members(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============ MEETINGS ============
CREATE TABLE meetings (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  group_id BIGINT UNSIGNED NOT NULL,
  cycle_id BIGINT UNSIGNED NOT NULL,
  scheduled_at TIMESTAMP NOT NULL,
  started_at TIMESTAMP NULL,
  ended_at TIMESTAMP NULL,
  location VARCHAR(255) NULL,
  agenda TEXT NULL,
  notes TEXT NULL,
  quorum_required INT UNSIGNED NOT NULL DEFAULT 0,
  quorum_met TINYINT(1) NULL,
  cash_on_hand DECIMAL(15,2) NULL,
  cash_reconciled DECIMAL(15,2) NULL,
  status ENUM('scheduled','in_progress','completed','cancelled') NOT NULL DEFAULT 'scheduled',
  created_by BIGINT UNSIGNED NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (group_id) REFERENCES `groups`(id) ON DELETE CASCADE,
  FOREIGN KEY (cycle_id) REFERENCES group_cycles(id) ON DELETE CASCADE,
  INDEX idx_meetings_group (group_id),
  INDEX idx_meetings_scheduled (scheduled_at)
) ENGINE=InnoDB;

CREATE TABLE attendance (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  meeting_id BIGINT UNSIGNED NOT NULL,
  member_id BIGINT UNSIGNED NOT NULL,
  status ENUM('present','late','absent','excused') NOT NULL DEFAULT 'absent',
  arrived_at TIMESTAMP NULL,
  recorded_by BIGINT UNSIGNED NULL,
  FOREIGN KEY (meeting_id) REFERENCES meetings(id) ON DELETE CASCADE,
  FOREIGN KEY (member_id) REFERENCES members(id) ON DELETE CASCADE,
  UNIQUE KEY uk_meeting_member (meeting_id, member_id)
) ENGINE=InnoDB;

CREATE TABLE fines (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  group_id BIGINT UNSIGNED NOT NULL,
  member_id BIGINT UNSIGNED NOT NULL,
  meeting_id BIGINT UNSIGNED NULL,
  type ENUM('late_arrival','absence','missed_contribution','other') NOT NULL,
  amount DECIMAL(15,2) NOT NULL,
  reason TEXT NULL,
  status ENUM('pending','paid','waived') NOT NULL DEFAULT 'pending',
  paid_at TIMESTAMP NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (group_id) REFERENCES `groups`(id) ON DELETE CASCADE,
  FOREIGN KEY (member_id) REFERENCES members(id) ON DELETE CASCADE,
  INDEX idx_fines_member (member_id)
) ENGINE=InnoDB;

-- ============ TRANSACTIONS ============
CREATE TABLE transactions (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  group_id BIGINT UNSIGNED NULL,
  member_id BIGINT UNSIGNED NULL,
  type ENUM('deposit','withdrawal','loan_disbursement','loan_repayment','share_purchase','contribution','share_out','fine','penalty') NOT NULL,
  amount DECIMAL(15,2) NOT NULL,
  currency CHAR(3) NOT NULL DEFAULT 'TZS',
  payment_method ENUM('cash','mpesa','airtel','mixx','halopesa','group_wallet') NOT NULL,
  status ENUM('pending','processing','completed','failed','reversed') NOT NULL DEFAULT 'pending',
  reference VARCHAR(100) NULL,
  external_reference VARCHAR(100) NULL,
  metadata JSON NULL,
  recorded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  completed_at TIMESTAMP NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (group_id) REFERENCES `groups`(id) ON DELETE SET NULL,
  FOREIGN KEY (member_id) REFERENCES members(id) ON DELETE SET NULL,
  INDEX idx_transactions_group (group_id),
  INDEX idx_transactions_status (status),
  INDEX idx_transactions_reference (reference)
) ENGINE=InnoDB;

CREATE TABLE mobile_money_transactions (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  transaction_id BIGINT UNSIGNED NULL,
  provider ENUM('mpesa','airtel','mixx','halopesa') NOT NULL,
  direction ENUM('inbound','outbound') NOT NULL,
  phone_number VARCHAR(20) NOT NULL,
  amount DECIMAL(15,2) NOT NULL,
  provider_reference VARCHAR(100) NULL,
  callback_payload JSON NULL,
  status ENUM('initiated','pending','success','failed','timeout') NOT NULL DEFAULT 'initiated',
  retry_count TINYINT UNSIGNED NOT NULL DEFAULT 0,
  initiated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  completed_at TIMESTAMP NULL,
  FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE SET NULL,
  INDEX idx_mm_provider_ref (provider, provider_reference),
  INDEX idx_mm_status (status)
) ENGINE=InnoDB;

-- ============ SYNC & NOTIFICATIONS ============
CREATE TABLE sync_queue (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  device_id BIGINT UNSIGNED NOT NULL,
  user_id BIGINT UNSIGNED NOT NULL,
  client_id VARCHAR(64) NOT NULL,
  entity_type VARCHAR(50) NOT NULL,
  entity_id VARCHAR(64) NULL,
  operation ENUM('create','update','delete') NOT NULL,
  payload JSON NOT NULL,
  client_timestamp TIMESTAMP(3) NOT NULL,
  server_timestamp TIMESTAMP(3) NULL,
  status ENUM('pending','processing','completed','conflict','failed') NOT NULL DEFAULT 'pending',
  conflict_resolution ENUM('server_wins','client_wins','manual') NULL,
  retry_count TINYINT UNSIGNED NOT NULL DEFAULT 0,
  error_message TEXT NULL,
  processed_at TIMESTAMP NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (device_id) REFERENCES devices(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  UNIQUE KEY uk_sync_client_id (client_id),
  INDEX idx_sync_status (status),
  INDEX idx_sync_user (user_id)
) ENGINE=InnoDB;

CREATE TABLE sync_logs (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  device_id BIGINT UNSIGNED NULL,
  direction ENUM('push','pull') NOT NULL,
  records_count INT UNSIGNED NOT NULL DEFAULT 0,
  status ENUM('started','completed','failed') NOT NULL,
  duration_ms INT UNSIGNED NULL,
  error_message TEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_sync_logs_user (user_id)
) ENGINE=InnoDB;

CREATE TABLE notifications (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  group_id BIGINT UNSIGNED NULL,
  type VARCHAR(50) NOT NULL,
  title VARCHAR(200) NOT NULL,
  body TEXT NOT NULL,
  channel ENUM('push','sms','in_app') NOT NULL DEFAULT 'in_app',
  is_read TINYINT(1) NOT NULL DEFAULT 0,
  sent_at TIMESTAMP NULL,
  read_at TIMESTAMP NULL,
  metadata JSON NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_notifications_user (user_id, is_read)
) ENGINE=InnoDB;

CREATE TABLE audit_logs (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NULL,
  group_id BIGINT UNSIGNED NULL,
  action VARCHAR(100) NOT NULL,
  entity_type VARCHAR(50) NULL,
  entity_id BIGINT UNSIGNED NULL,
  old_values JSON NULL,
  new_values JSON NULL,
  ip_address VARCHAR(45) NULL,
  user_agent VARCHAR(500) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_audit_user (user_id),
  INDEX idx_audit_group (group_id),
  INDEX idx_audit_action (action),
  INDEX idx_audit_created (created_at)
) ENGINE=InnoDB;

CREATE TABLE approval_requests (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  group_id BIGINT UNSIGNED NOT NULL,
  type ENUM('withdrawal','share_out','leadership_change','high_value_loan') NOT NULL,
  entity_type VARCHAR(50) NOT NULL,
  entity_id BIGINT UNSIGNED NOT NULL,
  required_signatures TINYINT UNSIGNED NOT NULL DEFAULT 2,
  current_signatures TINYINT UNSIGNED NOT NULL DEFAULT 0,
  status ENUM('pending','approved','rejected','expired') NOT NULL DEFAULT 'pending',
  requested_by BIGINT UNSIGNED NOT NULL,
  expires_at TIMESTAMP NOT NULL,
  completed_at TIMESTAMP NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (group_id) REFERENCES `groups`(id) ON DELETE CASCADE,
  INDEX idx_approval_status (status)
) ENGINE=InnoDB;

CREATE TABLE approval_signatures (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  approval_request_id BIGINT UNSIGNED NOT NULL,
  signer_id BIGINT UNSIGNED NOT NULL,
  signed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (approval_request_id) REFERENCES approval_requests(id) ON DELETE CASCADE,
  FOREIGN KEY (signer_id) REFERENCES users(id) ON DELETE CASCADE,
  UNIQUE KEY uk_approval_signer (approval_request_id, signer_id)
) ENGINE=InnoDB;

CREATE TABLE reports (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  group_id BIGINT UNSIGNED NULL,
  type VARCHAR(50) NOT NULL,
  title VARCHAR(200) NOT NULL,
  parameters JSON NULL,
  file_url VARCHAR(500) NULL,
  generated_by BIGINT UNSIGNED NULL,
  generated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (group_id) REFERENCES `groups`(id) ON DELETE SET NULL,
  INDEX idx_reports_group (group_id)
) ENGINE=InnoDB;

CREATE TABLE ussd_sessions (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  session_id VARCHAR(50) NOT NULL UNIQUE,
  phone_number VARCHAR(20) NOT NULL,
  menu_level TINYINT UNSIGNED NOT NULL DEFAULT 1,
  menu_state VARCHAR(100) NULL,
  user_id BIGINT UNSIGNED NULL,
  expires_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_ussd_session (session_id)
) ENGINE=InnoDB;

SET FOREIGN_KEY_CHECKS = 1;
