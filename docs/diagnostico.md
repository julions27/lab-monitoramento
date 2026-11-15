# Diagnóstico: serviço "Up" que não funciona

**Regra:** observar antes de agir. Nunca rodar `down` antes de ler os logs:
ele remove o contêiner, e os logs vão junto.

Todos os comandos rodam de dentro de `~/lab-monitoramento`.

## 1. O contêiner está vivo ou reiniciando?

```bash
docker compose ps
docker inspect -f '{{.State.Status}} restarts={{.RestartCount}}' zabbix-server
```
- **Normal:** `Up`, `restarts=0`
- **Com problema:** pode continuar `Up` e `restarts=0` (Lab B). Este passo só
  detecta processo que morre ou fica reiniciando.

## 2. O que o serviço está dizendo?

```bash
docker compose logs --tail=30 zabbix-server
```
- **Normal:** processos iniciando (poller, history syncer...) e reconexões
  ao banco depois que ele reinicia.
- **Com problema:** o entrypoint repetindo que o PostgreSQL não está
  disponível. No Lab B, foi aqui que o problema apareceu primeiro.

## 3. As dependências estão saudáveis?

```bash
docker compose ps postgres-server
```
- **Normal:** `(healthy)`
- **Com problema:** no Lab B continuou `(healthy)`, porque o banco estava bem
  e o erro estava no cliente. Este passo **descarta** a hipótese "o banco caiu".

## 4. Os processos estão realmente trabalhando?

```bash
docker top zabbix-server
```
- **Normal:** dezenas de linhas como `zabbix_server: poller #1`,
  `history syncer #2`...
- **Com problema:** poucas linhas (init, `docker-entrypoint.sh`, `sleep`).
  O nome `zabbix_server` aparece só como argumento do script.

## 5. A outra ponta (o banco) confirma a conexão?

```bash
docker exec zabbix-postgres sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT client_addr, count(*) FROM pg_stat_activity WHERE datname = current_database() GROUP BY 1;"'
```
- **Normal:** o IP do zabbix-server com ~14 conexões, mais uma linha sem IP
  (o próprio `psql`).
- **Com problema:** só a linha sem IP. Ninguém conectou no banco.
