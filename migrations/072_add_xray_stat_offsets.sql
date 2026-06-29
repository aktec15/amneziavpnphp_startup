-- Preserve cumulative XRay traffic when a container restarts and its API counters reset.

SET @has_xray_raw = (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'vpn_clients'
    AND COLUMN_NAME = 'xray_raw_bytes_sent'
);

SET @sql = IF(
  @has_xray_raw = 0,
  'ALTER TABLE vpn_clients
     ADD COLUMN xray_raw_bytes_sent BIGINT UNSIGNED NOT NULL DEFAULT 0,
     ADD COLUMN xray_raw_bytes_received BIGINT UNSIGNED NOT NULL DEFAULT 0,
     ADD COLUMN xray_offset_bytes_sent BIGINT UNSIGNED NOT NULL DEFAULT 0,
     ADD COLUMN xray_offset_bytes_received BIGINT UNSIGNED NOT NULL DEFAULT 0',
  'SELECT 1'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
