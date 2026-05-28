-- Normalize AWG2 for fresh public installs.
-- The userspace AWG2 image used here exposes WireGuard-compatible wg/wg-quick
-- tools and uses wg0.conf inside /opt/amnezia/awg.

UPDATE protocols
SET install_script = REPLACE(install_script, 'awg-quick', 'wg-quick')
WHERE slug = 'awg2';

UPDATE protocols
SET install_script = REPLACE(install_script, '/opt/amnezia/awg/awg0.conf', '/opt/amnezia/awg/wg0.conf')
WHERE slug = 'awg2';

UPDATE protocols
SET install_script = REPLACE(install_script, '/opt/amnezia/awg2/awg0.conf', '/opt/amnezia/awg2/wg0.conf')
WHERE slug = 'awg2';

UPDATE protocols
SET install_script = REPLACE(install_script, 'CONF_FILE="/opt/amnezia/awg2/awg0.conf"', 'CONF_FILE="/opt/amnezia/awg2/wg0.conf"')
WHERE slug = 'awg2';

UPDATE protocols
SET output_template = '[Interface]
Address = {{client_ip}}/32
DNS = {{dns_servers}}
PrivateKey = {{private_key}}
Jc = {{Jc}}
Jmin = {{Jmin}}
Jmax = {{Jmax}}
S1 = {{S1}}
S2 = {{S2}}
H1 = {{H1}}
H2 = {{H2}}
H3 = {{H3}}
H4 = {{H4}}

[Peer]
PublicKey = {{server_public_key}}
PresharedKey = {{preshared_key}}
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = {{server_host}}:{{server_port}}
PersistentKeepalive = 25',
    show_text_content = 1
WHERE slug = 'awg2';

UPDATE protocols
SET show_text_content = 1
WHERE slug IN ('amnezia-wg-advanced', 'xray-vless');
