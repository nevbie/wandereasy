#!/usr/bin/env bash
# Führt alle Migrationen, den Seed und die pgTAP-Tests (supabase/tests) auf einem Wegwerf-Postgres
# aus – ohne Docker. Braucht PostgreSQL mit PostGIS und pgTAP (Debian/Ubuntu:
# postgresql-16-postgis-3 postgresql-16-pgtap). CI prüft dieselben Tests gegen echtes Supabase.
#
# Aufruf: tools/supabase_local/test.sh      (als normaler Benutzer, nicht root)
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
BIN=${PG_BIN:-$(ls -d /usr/lib/postgresql/*/bin 2>/dev/null | sort -V | tail -1)}
DATA=$(mktemp -d)
trap '"$BIN/pg_ctl" -D "$DATA" -m immediate stop >/dev/null 2>&1 || true; rm -rf "$DATA"' EXIT

"$BIN/initdb" -D "$DATA" -U postgres --auth=trust >/dev/null
"$BIN/pg_ctl" -D "$DATA" -o "-k $DATA -c listen_addresses=''" -l "$DATA/log" -w start >/dev/null
psql() { command psql -h "$DATA" -U postgres -X -q -v ON_ERROR_STOP=1 "$@"; }

psql -d postgres -c 'create database test'
psql -d test -c 'alter database test set search_path = "$user", public, extensions'
psql -d test -f "$ROOT/tools/supabase_local/stub.sql"
for f in "$ROOT"/supabase/migrations/*.sql; do
  echo "migration $(basename "$f")"
  psql -d test -f "$f"
done
echo "seed"
psql -d test -f "$ROOT/supabase/seed.sql"
psql -d test -c 'create extension pgtap with schema extensions'

failed=0
for f in "$ROOT"/supabase/tests/*.sql; do
  out=$(psql -d test -t -A -f "$f" 2>&1) || failed=1
  echo "$out" | grep -E '^(not ok|# )' || true
  if echo "$out" | grep -qE '^not ok|Looks like you|ERROR'; then failed=1; fi
  echo "$(basename "$f"): $(echo "$out" | grep -c '^ok') ok, $(echo "$out" | grep -c '^not ok') failed"
done
exit $failed
