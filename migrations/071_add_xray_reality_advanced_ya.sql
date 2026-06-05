-- Add a separate XRay REALITY Advanced protocol.
-- It intentionally does not modify xray-vless on port 443.

INSERT INTO protocols (
  name,
  slug,
  description,
  definition,
  install_script,
  uninstall_script,
  output_template,
  show_text_content,
  ubuntu_compatible,
  is_active,
  created_at,
  updated_at
) VALUES (
  'XRay REALITY Advanced',
  'xray-reality-advanced',
  'Separate VLESS REALITY + Vision profile using ya.ru as the REALITY serverName',
  '{"metadata":{"container_name":"amnezia-xray-reality-advanced","default_port":8443,"port_range":[8443,8443],"server_name":"ya.ru","fingerprint":"chrome","config_dir":"/opt/amnezia/xray-reality-advanced"}}',
  '#!/bin/bash
set -eu

CONTAINER_NAME="${CONTAINER_NAME:-amnezia-xray-reality-advanced}"
XRAY_PORT=${SERVER_PORT:-8443}
SERVER_NAME="${SERVER_NAME:-ya.ru}"
FINGERPRINT="${FINGERPRINT:-chrome}"
SPIDER_X="${SPIDER_X:-/}"
CONFIG_DIR="/opt/amnezia/xray-reality-advanced"

if ss -lntu 2>/dev/null | grep -Eq "[:.]${XRAY_PORT}[[:space:]]|:${XRAY_PORT}$"; then
  echo "Port ${XRAY_PORT} is busy"
  exit 1
fi

docker pull teddysun/xray >/dev/null 2>&1 || true

GEN=$(docker run --rm --entrypoint /usr/bin/xray teddysun/xray x25519 2>/dev/null || true)
PRIVATE_KEY=$(printf "%s\n" "$GEN" | sed -n -E "s/^[Pp]rivate[[:space:]]*[Kk]ey:[[:space:]]*(.*)$/\\1/p; s/^[Pp]rivate[Kk]ey:[[:space:]]*(.*)$/\\1/p" | tr -d " \t\r\n")
PUBLIC_KEY=$(printf "%s\n" "$GEN" | sed -n -E "s/^[Pp]ublic[[:space:]]*[Kk]ey:[[:space:]]*(.*)$/\\1/p; s/^Password \\([Pp]ublic[Kk]ey\\):[[:space:]]*(.*)$/\\1/p" | tr -d " \t\r\n")

if [ -z "$PRIVATE_KEY" ]; then
  echo "Failed to generate REALITY private key"
  exit 1
fi

if [ -z "$PUBLIC_KEY" ]; then
  PUBLIC_KEY=$(docker run --rm --entrypoint /usr/bin/xray teddysun/xray x25519 -i "$PRIVATE_KEY" 2>/dev/null | sed -n -E "s/^[Pp]ublic[[:space:]]*[Kk]ey:[[:space:]]*(.*)$/\\1/p; s/^Password \\([Pp]ublic[Kk]ey\\):[[:space:]]*(.*)$/\\1/p" | tr -d " \t\r\n" || true)
fi

if [ -z "$PUBLIC_KEY" ]; then
  echo "Failed to derive REALITY public key"
  exit 1
fi

SHORT_ID=$(od -An -tx1 -N8 /dev/urandom | tr -d " \n")
CLIENT_ID=$(cat /proc/sys/kernel/random/uuid)

docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
mkdir -p "$CONFIG_DIR"

cat > "${CONFIG_DIR}/server.json" <<EOJSON
{
  "log": { "loglevel": "warning" },
  "stats": {},
  "api": {
    "tag": "api",
    "services": [ "StatsService" ]
  },
  "policy": {
    "levels": {
      "0": {
        "statsUserUplink": true,
        "statsUserDownlink": true
      }
    },
    "system": {
      "statsInboundUplink": true,
      "statsInboundDownlink": true
    }
  },
  "inbounds": [
    {
      "listen": "0.0.0.0",
      "port": ${XRAY_PORT},
      "protocol": "vless",
      "settings": {
        "clients": [
          { "id": "${CLIENT_ID}", "flow": "xtls-rprx-vision", "email": "${CLIENT_ID}" }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "show": false,
          "dest": "${SERVER_NAME}:443",
          "xver": 0,
          "serverNames": [ "${SERVER_NAME}" ],
          "privateKey": "${PRIVATE_KEY}",
          "shortIds": [ "${SHORT_ID}" ],
          "fingerprint": "${FINGERPRINT}",
          "spiderX": "${SPIDER_X}"
        }
      }
    },
    {
      "listen": "127.0.0.1",
      "port": 10085,
      "protocol": "dokodemo-door",
      "tag": "api",
      "settings": {
        "address": "127.0.0.1"
      }
    }
  ],
  "outbounds": [
    { "protocol": "freedom", "tag": "direct" }
  ],
  "routing": {
    "rules": [
      {
        "inboundTag": [ "api" ],
        "outboundTag": "api",
        "type": "field"
      }
    ]
  }
}
EOJSON

docker run -d --name "$CONTAINER_NAME" --restart always -p "${XRAY_PORT}:${XRAY_PORT}" -v "${CONFIG_DIR}:${CONFIG_DIR}" teddysun/xray xray run -c "${CONFIG_DIR}/server.json"

sleep 2

echo "XrayPort: ${XRAY_PORT}"
echo "Port: ${XRAY_PORT}"
echo "ClientID: ${CLIENT_ID}"
echo "PublicKey: ${PUBLIC_KEY}"
echo "PrivateKey: ${PRIVATE_KEY}"
echo "ShortID: ${SHORT_ID}"
echo "ServerName: ${SERVER_NAME}"
echo "ContainerName: ${CONTAINER_NAME}"
',
  '#!/bin/bash
set -eu

CONTAINER_NAME="${CONTAINER_NAME:-amnezia-xray-reality-advanced}"
CONFIG_DIR="/opt/amnezia/xray-reality-advanced"

docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
rm -rf "$CONFIG_DIR"

echo "XRay REALITY Advanced removed"
',
  'vless://{{client_id}}@{{server_host}}:{{server_port}}?encryption=none&flow=xtls-rprx-vision&security=reality&sni={{reality_server_name}}&fp=chrome&pbk={{reality_public_key}}&sid={{reality_short_id}}&spx=%2F&type=tcp#{{login}}',
  1,
  1,
  1,
  NOW(),
  NOW()
)
ON DUPLICATE KEY UPDATE
  name = VALUES(name),
  description = VALUES(description),
  definition = VALUES(definition),
  install_script = VALUES(install_script),
  uninstall_script = VALUES(uninstall_script),
  output_template = VALUES(output_template),
  show_text_content = VALUES(show_text_content),
  ubuntu_compatible = VALUES(ubuntu_compatible),
  is_active = VALUES(is_active),
  updated_at = NOW();

SET @pid = (SELECT id FROM protocols WHERE slug = 'xray-reality-advanced' LIMIT 1);

INSERT INTO protocol_variables (protocol_id, variable_name, variable_type, default_value, description, required)
SELECT @pid, 'server_host', 'string', '', 'Server hostname or IP address', true
WHERE @pid IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM protocol_variables WHERE protocol_id = @pid AND variable_name = 'server_host');

INSERT INTO protocol_variables (protocol_id, variable_name, variable_type, default_value, description, required)
SELECT @pid, 'server_port', 'number', '8443', 'XRay REALITY listen port', true
WHERE @pid IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM protocol_variables WHERE protocol_id = @pid AND variable_name = 'server_port');

INSERT INTO protocol_variables (protocol_id, variable_name, variable_type, default_value, description, required)
SELECT @pid, 'client_id', 'string', '', 'VLESS client UUID', true
WHERE @pid IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM protocol_variables WHERE protocol_id = @pid AND variable_name = 'client_id');

INSERT INTO protocol_variables (protocol_id, variable_name, variable_type, default_value, description, required)
SELECT @pid, 'reality_public_key', 'string', '', 'REALITY public key', true
WHERE @pid IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM protocol_variables WHERE protocol_id = @pid AND variable_name = 'reality_public_key');

INSERT INTO protocol_variables (protocol_id, variable_name, variable_type, default_value, description, required)
SELECT @pid, 'reality_short_id', 'string', '', 'REALITY shortId', true
WHERE @pid IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM protocol_variables WHERE protocol_id = @pid AND variable_name = 'reality_short_id');

INSERT INTO protocol_variables (protocol_id, variable_name, variable_type, default_value, description, required)
SELECT @pid, 'reality_server_name', 'string', 'ya.ru', 'REALITY serverName / SNI', true
WHERE @pid IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM protocol_variables WHERE protocol_id = @pid AND variable_name = 'reality_server_name');
