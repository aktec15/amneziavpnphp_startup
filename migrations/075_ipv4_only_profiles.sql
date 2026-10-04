-- Final AWG compatibility defaults for IPv4-only hosts.
-- This migration deliberately runs after the public AWG2 normalization and
-- AWG 3.1 creation migrations, which otherwise restore dual-stack routes.

UPDATE protocols
SET output_template = '[Interface]
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

[Peer]
PublicKey = {{server_public_key}}
PresharedKey = {{preshared_key}}
AllowedIPs = 0.0.0.0/0
Endpoint = {{server_host}}:{{server_port}}
PersistentKeepalive = 25',
    show_text_content = 1,
    updated_at = NOW()
WHERE slug = 'awg2';

UPDATE protocols
SET output_template = '[Interface]
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
AllowedIPs = 0.0.0.0/0
Endpoint = {{server_host}}:{{server_port}}
PersistentKeepalive = 25',
    show_text_content = 1,
    updated_at = NOW()
WHERE slug = 'awg31';
