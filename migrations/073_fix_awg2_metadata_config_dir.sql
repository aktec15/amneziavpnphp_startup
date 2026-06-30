-- AWG2 stores files inside the container at /opt/amnezia/awg.
-- Older migrations left metadata pointing at /opt/amnezia/awg2, which can make
-- client generation/regeneration read the wrong path on fresh deployments.

UPDATE protocols
SET definition = JSON_SET(
    COALESCE(NULLIF(definition, ''), '{"engine":"shell","metadata":{}}'),
    '$.metadata.config_dir',
    '/opt/amnezia/awg',
    '$.metadata.container_name',
    'amnezia-awg2'
)
WHERE slug = 'awg2'
  AND JSON_VALID(COALESCE(NULLIF(definition, ''), '{}'));
