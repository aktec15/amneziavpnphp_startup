-- Add AmneziaWG 3.1 as a separate protocol. It intentionally coexists with
-- AWG 2.0 on a different UDP port and VPN subnet.

INSERT INTO protocols (
    name,
    slug,
    description,
    install_script,
    uninstall_script,
    output_template,
    ubuntu_compatible,
    is_active,
    definition,
    show_text_content,
    created_at,
    updated_at
) VALUES (
    'AmneziaWG 3.1',
    'awg31',
    'AmneziaWG 3.1 with header protection and behavioral randomization.',
    '#!/usr/bin/env bash
set -euo pipefail

CONTAINER_NAME="${SERVER_CONTAINER:-amnezia-awg31}"
IMAGE="amneziavpn/amneziawg-go@sha256:cbafc02b8373a83f428272db6d8001b37bc02e6211cbd8c0cb4e2e3759b12b72"
CONFIG_DIR="/opt/amnezia/awg31"
CONFIG_FILE="${CONFIG_DIR}/awg0.conf"
VPN_PORT="${SERVER_PORT:-1234}"

docker pull "${IMAGE}" >/dev/null
mkdir -p "${CONFIG_DIR}"
chmod 700 "${CONFIG_DIR}"

if [ ! -f "${CONFIG_FILE}" ]; then
  PRIVATE_KEY=$(docker run --rm "${IMAGE}" awg genkey)
  PUBLIC_KEY=$(printf "%s\\n" "${PRIVATE_KEY}" | docker run --rm -i "${IMAGE}" awg pubkey)
  PRESHARED_KEY=$(docker run --rm "${IMAGE}" awg genpsk)
  HEADER_KEY=$(docker run --rm "${IMAGE}" awg genkey)

  cat > "${CONFIG_FILE}" <<EOF
[Interface]
PrivateKey = ${PRIVATE_KEY}
Address = 10.8.2.1/24
ListenPort = ${VPN_PORT}
Jc = 6
Jmin = 10
Jmax = 50
S1 = 12
S2 = 12
S3 = 12
S4 = 12
H1 = 1
H2 = 2
H3 = 3
H4 = 4
I1 = <r 2><b 0x858000010001000000000669636c6f756403636f6d0000010001c00c000100010000105a00044d583737>
HeaderProtectionKey = ${HEADER_KEY}
ContentPaddingAddition = 10-100
RekeyAfterTime = 100-120
RekeyTimeout = 3-7
RejectAfterTime = 150-180
KeepaliveTimeout = 5-15
MaxHandshakeAttempts = 15-20
RandomTrailers = on
DisableCookies = on
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
EOF

  printf "%s\\n" "${PRIVATE_KEY}" > "${CONFIG_DIR}/wireguard_server_private_key.key"
  printf "%s\\n" "${PUBLIC_KEY}" > "${CONFIG_DIR}/wireguard_server_public_key.key"
  printf "%s\\n" "${PRESHARED_KEY}" > "${CONFIG_DIR}/wireguard_psk.key"
  printf "[]\\n" > "${CONFIG_DIR}/clientsTable"
  chmod 600 "${CONFIG_FILE}" "${CONFIG_DIR}"/*.key "${CONFIG_DIR}/clientsTable"
fi

if ! docker ps -aq -f "name=^/${CONTAINER_NAME}$" | grep -q .; then
  docker run -d --name "${CONTAINER_NAME}" --restart always --cap-add NET_ADMIN --device /dev/net/tun --sysctl net.ipv4.conf.all.src_valid_mark=1 -p "${VPN_PORT}:${VPN_PORT}/udp" -v "${CONFIG_DIR}:/opt/amnezia/awg" "${IMAGE}" sh -lc "set -e; WG_QUICK_USERSPACE_IMPLEMENTATION=amneziawg-go awg-quick up /opt/amnezia/awg/awg0.conf; exec tail -f /dev/null"
else
  docker start "${CONTAINER_NAME}" >/dev/null
fi

if command -v ufw >/dev/null 2>&1; then
  ufw allow "${VPN_PORT}/udp" comment "AmneziaWG 3.1" >/dev/null
fi

for N in $(seq 1 20); do
  if docker exec "${CONTAINER_NAME}" awg show awg0 >/dev/null 2>&1; then break; fi
  sleep 1
done
docker exec "${CONTAINER_NAME}" awg show awg0 >/dev/null

PUBLIC_KEY=$(cat "${CONFIG_DIR}/wireguard_server_public_key.key")
PRESHARED_KEY=$(cat "${CONFIG_DIR}/wireguard_psk.key")
PORT=$(sed -n -E "s/^ListenPort[[:space:]]*=[[:space:]]*//p" "${CONFIG_FILE}" | head -1)

echo "AmneziaWG 3.1 installed successfully"
echo "Port: ${PORT}"
echo "Server Public Key: ${PUBLIC_KEY}"
echo "PresharedKey = ${PRESHARED_KEY}"
echo "Variable: Jc=6"
echo "Variable: Jmin=10"
echo "Variable: Jmax=50"
echo "Variable: S1=12"
echo "Variable: S2=12"
echo "Variable: S3=12"
echo "Variable: S4=12"
echo "Variable: H1=1"
echo "Variable: H2=2"
echo "Variable: H3=3"
echo "Variable: H4=4"
echo "Variable: I1=<r 2><b 0x858000010001000000000669636c6f756403636f6d0000010001c00c000100010000105a00044d583737>"
echo "Variable: HeaderProtectionKey=$(sed -n -E "s/^HeaderProtectionKey[[:space:]]*=[[:space:]]*//p" "${CONFIG_FILE}" | head -1)"
echo "Variable: ContentPaddingAddition=10-100"
echo "Variable: RekeyAfterTime=100-120"
echo "Variable: RekeyTimeout=3-7"
echo "Variable: RejectAfterTime=150-180"
echo "Variable: KeepaliveTimeout=5-15"
echo "Variable: MaxHandshakeAttempts=15-20"
echo "Variable: RandomTrailers=on"
echo "Variable: DisableCookies=on"
echo "Variable: dns_servers=1.1.1.1, 1.0.0.1"
echo "Container: ${CONTAINER_NAME}"',
    '#!/usr/bin/env bash
set -euo pipefail
CONTAINER_NAME="${SERVER_CONTAINER:-amnezia-awg31}"
docker rm -f "${CONTAINER_NAME}" 2>/dev/null || true
echo "AmneziaWG 3.1 container removed; configuration retained in /opt/amnezia/awg31"',
    '[Interface]
Address = {{client_ip}}/32
DNS = {{dns_servers}}
MTU = 1280
PrivateKey = {{private_key}}
Jc = {{Jc}}
Jmin = {{Jmin}}
Jmax = {{Jmax}}
S1 = {{S1}}
S2 = {{S2}}
S3 = {{S3}}
S4 = {{S4}}
H1 = {{H1}}
H2 = {{H2}}
H3 = {{H3}}
H4 = {{H4}}
I1 = {{I1}}
HeaderProtectionKey = {{HEADERPROTECTIONKEY}}
ContentPaddingAddition = {{CONTENTPADDINGADDITION}}
RekeyAfterTime = {{REKEYAFTERTIME}}
RekeyTimeout = {{REKEYTIMEOUT}}
RejectAfterTime = {{REJECTAFTERTIME}}
KeepaliveTimeout = {{KEEPALIVETIMEOUT}}
MaxHandshakeAttempts = {{MAXHANDSHAKEATTEMPTS}}
RandomTrailers = {{RANDOMTRAILERS}}
DisableCookies = {{DISABLECOOKIES}}

[Peer]
PublicKey = {{server_public_key}}
PresharedKey = {{preshared_key}}
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = {{server_host}}:{{server_port}}
PersistentKeepalive = 25',
    1,
    1,
    JSON_OBJECT(
        'engine', 'shell',
        'metadata', JSON_OBJECT(
            'container_name', 'amnezia-awg31',
            'vpn_subnet', '10.8.2.0/24',
            'port_range', JSON_ARRAY(1, 9999),
            'default_port', 1234,
            'config_dir', '/opt/amnezia/awg31'
        )
    ),
    1,
    NOW(),
    NOW()
)
ON DUPLICATE KEY UPDATE
    name = VALUES(name),
    description = VALUES(description),
    install_script = VALUES(install_script),
    uninstall_script = VALUES(uninstall_script),
    output_template = VALUES(output_template),
    ubuntu_compatible = VALUES(ubuntu_compatible),
    is_active = VALUES(is_active),
    definition = VALUES(definition),
    show_text_content = VALUES(show_text_content),
    updated_at = NOW();

INSERT INTO protocol_variables (protocol_id, variable_name, variable_type, default_value, description, required)
SELECT p.id, values_table.variable_name, 'text', values_table.default_value, values_table.description, values_table.required
FROM protocols p
JOIN (
    SELECT 'Jc' variable_name, '6' default_value, 'Junk packet count' description, 1 required
    UNION ALL SELECT 'Jmin', '10', 'Minimum junk size', 1
    UNION ALL SELECT 'Jmax', '50', 'Maximum junk size', 1
    UNION ALL SELECT 'S1', '12', 'Init packet padding', 1
    UNION ALL SELECT 'S2', '12', 'Response packet padding', 1
    UNION ALL SELECT 'S3', '12', 'Cookie packet padding', 1
    UNION ALL SELECT 'S4', '12', 'Transport packet padding', 1
    UNION ALL SELECT 'H1', '1', 'Init packet header', 1
    UNION ALL SELECT 'H2', '2', 'Response packet header', 1
    UNION ALL SELECT 'H3', '3', 'Cookie packet header', 1
    UNION ALL SELECT 'H4', '4', 'Transport packet header', 1
    UNION ALL SELECT 'I1', '<r 2><b 0x858000010001000000000669636c6f756403636f6d0000010001c00c000100010000105a00044d583737>', 'Special pre-handshake packet', 1
    UNION ALL SELECT 'HeaderProtectionKey', '', 'AWG 3.1 header protection key', 1
    UNION ALL SELECT 'ContentPaddingAddition', '10-100', 'Content padding range', 1
    UNION ALL SELECT 'RekeyAfterTime', '100-120', 'Rekey interval range', 1
    UNION ALL SELECT 'RekeyTimeout', '3-7', 'Rekey retry timeout range', 1
    UNION ALL SELECT 'RejectAfterTime', '150-180', 'Reject interval range', 1
    UNION ALL SELECT 'KeepaliveTimeout', '5-15', 'Keepalive timeout range', 1
    UNION ALL SELECT 'MaxHandshakeAttempts', '15-20', 'Maximum handshake attempts', 1
    UNION ALL SELECT 'RandomTrailers', 'on', 'Random packet trailers', 1
    UNION ALL SELECT 'DisableCookies', 'on', 'Disable recognizable cookie replies', 1
) AS values_table
WHERE p.slug = 'awg31'
  AND NOT EXISTS (
      SELECT 1
      FROM protocol_variables existing
      WHERE existing.protocol_id = p.id
        AND existing.variable_name = values_table.variable_name
  );
