set -euo pipefail

cd "$(dirname "$0")/.."
mkdir -p backups

ARQUIVO="backups/zabbix-$(date +%Y%m%d-%H%M%S).dump"

docker exec zabbix-postgres sh -c 'pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" -Fc' > "$ARQUIVO.tmp"
mv "$ARQUIVO.tmp" "$ARQUIVO"

echo "Backup criado: $ARQUIVO ($(du -h "$ARQUIVO" | cut -f1))"

ls -1t backups/zabbix-*.dump | tail -n +8 | xargs -r rm --
