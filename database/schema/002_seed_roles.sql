USE digital_vicoba;

INSERT INTO roles (name, slug, description, is_system) VALUES
('Super Admin', 'super_admin', 'Platform-wide administration', 1),
('Regional Admin', 'regional_admin', 'Regional oversight and reporting', 1),
('Group Chairperson', 'chairperson', 'Group leadership and approvals', 0),
('Secretary', 'secretary', 'Records and meeting management', 0),
('Treasurer', 'treasurer', 'Financial records and disbursements', 0),
('Money Counter', 'money_counter', 'Cash counting and verification', 0),
('Key Holder', 'key_holder', 'Safe/key custody', 0),
('Member', 'member', 'Regular group member', 0),
('Trainer / Field Officer', 'trainer', 'Field training and group setup', 1);

INSERT INTO permissions (name, slug, module) VALUES
('View Dashboard', 'view_dashboard', 'dashboard'),
('Manage Users', 'manage_users', 'users'),
('Manage Groups', 'manage_groups', 'groups'),
('Create Group', 'create_group', 'groups'),
('Manage Members', 'manage_members', 'members'),
('Record Shares', 'record_shares', 'savings'),
('Record Contributions', 'record_contributions', 'savings'),
('Apply Loan', 'apply_loan', 'loans'),
('Approve Loan', 'approve_loan', 'loans'),
('Disburse Loan', 'disburse_loan', 'loans'),
('Record Repayment', 'record_repayment', 'loans'),
('Manage Meetings', 'manage_meetings', 'meetings'),
('Record Attendance', 'record_attendance', 'meetings'),
('Initiate Share Out', 'initiate_share_out', 'share_out'),
('Approve Share Out', 'approve_share_out', 'share_out'),
('View Reports', 'view_reports', 'reports'),
('Export Reports', 'export_reports', 'reports'),
('Manage Mobile Money', 'manage_mobile_money', 'payments'),
('Sync Data', 'sync_data', 'sync'),
('View Audit Logs', 'view_audit_logs', 'audit'),
('Regional Reports', 'regional_reports', 'reports'),
('Train Groups', 'train_groups', 'training');

-- Super Admin gets all permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p WHERE r.slug = 'super_admin';

-- Regional Admin
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r JOIN permissions p ON p.slug IN (
  'view_dashboard','manage_groups','view_reports','export_reports',
  'regional_reports','view_audit_logs','manage_users'
) WHERE r.slug = 'regional_admin';

-- Chairperson
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r JOIN permissions p ON p.slug IN (
  'view_dashboard','manage_members','approve_loan','manage_meetings',
  'initiate_share_out','approve_share_out','view_reports','sync_data'
) WHERE r.slug = 'chairperson';

-- Secretary
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r JOIN permissions p ON p.slug IN (
  'view_dashboard','manage_members','manage_meetings','record_attendance',
  'view_reports','sync_data'
) WHERE r.slug = 'secretary';

-- Treasurer
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r JOIN permissions p ON p.slug IN (
  'view_dashboard','record_shares','record_contributions','disburse_loan',
  'record_repayment','manage_mobile_money','view_reports','sync_data'
) WHERE r.slug = 'treasurer';

-- Money Counter
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r JOIN permissions p ON p.slug IN (
  'view_dashboard','record_shares','record_contributions','record_repayment','sync_data'
) WHERE r.slug = 'money_counter';

-- Member
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r JOIN permissions p ON p.slug IN (
  'view_dashboard','apply_loan','view_reports','sync_data'
) WHERE r.slug = 'member';

-- Trainer
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r JOIN permissions p ON p.slug IN (
  'view_dashboard','create_group','manage_groups','manage_members','train_groups','sync_data'
) WHERE r.slug = 'trainer';

INSERT INTO regions (name, code) VALUES
('Dar es Salaam', 'DSM'),
('Arusha', 'ARK'),
('Mwanza', 'MWZ'),
('Dodoma', 'DDM'),
('Mbeya', 'MBY'),
('Morogoro', 'MRO'),
('Tanga', 'TNG'),
('Kagera', 'KGR');
