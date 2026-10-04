-- Keep Xray on TCP/443. AWG may use UDP/443 at the same time, so the
-- availability test must inspect TCP listeners only.
UPDATE protocols
SET install_script = REPLACE(install_script, 'XRAY_PORT=${SERVER_PORT:-8443}', 'XRAY_PORT=${SERVER_PORT:-443}')
WHERE slug = 'xray-reality-advanced';

UPDATE protocols
SET install_script = REPLACE(install_script, 'SERVER_NAME="${SERVER_NAME:-ya.ru}"', 'SERVER_NAME="${SERVER_NAME:-www.rutube.ru}"')
WHERE slug = 'xray-reality-advanced';

UPDATE protocols
SET install_script = REPLACE(install_script, 'if ss -lntu 2>/dev/null', 'if ss -lnt 2>/dev/null')
WHERE slug = 'xray-reality-advanced';

UPDATE protocols
SET install_script = REPLACE(
    install_script,
    '  "log": { "loglevel": "warning" },
  "stats": {},',
    '  "log": { "loglevel": "warning" },
  "dns": {
    "servers": [ "1.1.1.1", "1.0.0.1" ],
    "queryStrategy": "UseIPv4"
  },
  "stats": {},'
)
WHERE slug = 'xray-reality-advanced';

UPDATE protocols
SET install_script = REPLACE(
    install_script,
    '      "protocol": "vless",
      "settings": {',
    '      "protocol": "vless",
      "tag": "vless-in",
      "settings": {'
)
WHERE slug = 'xray-reality-advanced';

UPDATE protocols
SET install_script = REPLACE(
    install_script,
    '          "spiderX": "${SPIDER_X}"
        }
      }
    },',
    '          "spiderX": "${SPIDER_X}"
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [ "http", "tls", "quic" ],
        "routeOnly": false
      }
    },'
)
WHERE slug = 'xray-reality-advanced';

UPDATE protocols
SET install_script = REPLACE(
    install_script,
    '      "settings": {
        "domainStrategy": "UseIPv4"
      }
    },',
    '      "settings": {
        "domainStrategy": "AsIs"
      },
      "streamSettings": {
        "sockopt": {
          "domainStrategy": "UseIPv4"
        }
      }
    },'
)
WHERE slug = 'xray-reality-advanced';

UPDATE protocols
SET install_script = REPLACE(
    install_script,
    'docker run -d --name "$CONTAINER_NAME" --restart always -p "${XRAY_PORT}:${XRAY_PORT}" -v "${CONFIG_DIR}:${CONFIG_DIR}" teddysun/xray xray run -c "${CONFIG_DIR}/server.json"

sleep 2',
    'docker run -d --name "$CONTAINER_NAME" --restart always -p "${XRAY_PORT}:${XRAY_PORT}" -v "${CONFIG_DIR}:${CONFIG_DIR}" teddysun/xray xray run -c "${CONFIG_DIR}/server.json"

if command -v ufw >/dev/null 2>&1; then
  ufw allow "${XRAY_PORT}/tcp" comment "XRay REALITY Advanced" >/dev/null
fi

sleep 2'
)
WHERE slug = 'xray-reality-advanced';

UPDATE protocols
SET description = 'VLESS REALITY + Vision on TCP/443 with IPv4-only DNS and Rutube SNI',
    definition = JSON_OBJECT(
        'metadata', JSON_OBJECT(
            'container_name', 'amnezia-xray-reality-advanced',
            'default_port', 443,
            'port_range', JSON_ARRAY(443, 443),
            'server_name', 'www.rutube.ru',
            'fingerprint', 'chrome',
            'config_dir', '/opt/amnezia/xray-reality-advanced'
        )
    ),
    output_template = 'vless://{{client_id}}@{{server_host}}:{{server_port}}?encryption=none&flow=xtls-rprx-vision-udp443&packetEncoding=xudp&security=reality&sni={{reality_server_name}}&fp=chrome&pbk={{reality_public_key}}&sid={{reality_short_id}}&spx=%2F&type=tcp#{{login}}',
    show_text_content = 1,
    updated_at = NOW()
WHERE slug = 'xray-reality-advanced';

UPDATE protocol_variables pv
JOIN protocols p ON p.id = pv.protocol_id
SET pv.default_value = '443'
WHERE p.slug = 'xray-reality-advanced'
  AND pv.variable_name = 'server_port';

UPDATE protocol_variables pv
JOIN protocols p ON p.id = pv.protocol_id
SET pv.default_value = 'www.rutube.ru'
WHERE p.slug = 'xray-reality-advanced'
  AND pv.variable_name = 'reality_server_name';
