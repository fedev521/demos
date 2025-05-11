# Postgres Benchmark on Kubernetes

Show the performance difference of running Postgres on Kubernetes in different
scenarios:

- with/without a connection pooler (pgbouncer)
- establishing new connections for each transaction vs reusing

Bonus: show the usage of [zalando/postgres-operator](https://github.com/zalando/postgres-operator/)
and Kustomize.

## How to Run

Optional:

```shell
kind create cluster
kubectl apply -k postgres-operator # if your cluster doesn't already have it
kubectl kustomize . | kubeconform --strict
```

Create Postgres and (suspended) CronJobs and initialize the database for benchmark:

```shell
kubectl apply -k .
kubectl config set-context --current --namespace pg-perf
kubectl create job --from=cronjob/pgbench-init pgbench-init-$(date +'%Y%m%d-%H%M')
```

Finally, trigger jobs and check their logs:

```shell
kubectl get cronjobs

# e.g.:
kubectl create job --from=cronjob/pgbench-with-pooler pgbench-with-pooler-$(date +'%Y%m%d-%H%M')
# ...
```

## Benchmark Tool

```plaintext
pgbench is a benchmarking tool for PostgreSQL.

Usage:
  pgbench [OPTION]... [DBNAME]

Initialization options:
  -i, --initialize         invokes initialization mode
  -I, --init-steps=[dtgGvpf]+ (default "dtgvp")
                           run selected initialization steps, in the specified order
                           d: drop any existing pgbench tables
                           t: create the tables used by the standard pgbench scenario
                           g: generate data, client-side
                           G: generate data, server-side
                           v: invoke VACUUM on the standard tables
                           p: create primary key indexes on the standard tables
                           f: create foreign keys between the standard tables
  -F, --fillfactor=NUM     set fill factor
  -n, --no-vacuum          do not run VACUUM during initialization
  -q, --quiet              quiet logging (one message each 5 seconds)
  -s, --scale=NUM          scaling factor
  --foreign-keys           create foreign key constraints between tables
  --index-tablespace=TABLESPACE
                           create indexes in the specified tablespace
  --partition-method=(range|hash)
                           partition pgbench_accounts with this method (default: range)
  --partitions=NUM         partition pgbench_accounts into NUM parts (default: 0)
  --tablespace=TABLESPACE  create tables in the specified tablespace
  --unlogged-tables        create tables as unlogged tables

Options to select what to run:
  -b, --builtin=NAME[@W]   add builtin script NAME weighted at W (default: 1)
                           (use "-b list" to list available scripts)
  -f, --file=FILENAME[@W]  add script FILENAME weighted at W (default: 1)
  -N, --skip-some-updates  skip updates of pgbench_tellers and pgbench_branches
                           (same as "-b simple-update")
  -S, --select-only        perform SELECT-only transactions
                           (same as "-b select-only")

Benchmarking options:
  -c, --client=NUM         number of concurrent database clients (default: 1)
  -C, --connect            establish new connection for each transaction
  -D, --define=VARNAME=VALUE
                           define variable for use by custom script
  -j, --jobs=NUM           number of threads (default: 1)
  -l, --log                write transaction times to log file
  -L, --latency-limit=NUM  count transactions lasting more than NUM ms as late
  -M, --protocol=simple|extended|prepared
                           protocol for submitting queries (default: simple)
  -n, --no-vacuum          do not run VACUUM before tests
  -P, --progress=NUM       show thread progress report every NUM seconds
  -r, --report-per-command report latencies, failures, and retries per command
  -R, --rate=NUM           target rate in transactions per second
  -s, --scale=NUM          report this scale factor in output
  -t, --transactions=NUM   number of transactions each client runs (default: 10)
  -T, --time=NUM           duration of benchmark test in seconds
  -v, --vacuum-all         vacuum all four standard tables before tests
  --aggregate-interval=NUM aggregate data over NUM seconds
  --exit-on-abort          exit when any client is aborted
  --failures-detailed      report the failures grouped by basic types
  --log-prefix=PREFIX      prefix for transaction time log file
                           (default: "pgbench_log")
  --max-tries=NUM          max number of tries to run transaction (default: 1)
  --progress-timestamp     use Unix epoch timestamps for progress
  --random-seed=SEED       set random seed ("time", "rand", integer)
  --sampling-rate=NUM      fraction of transactions to log (e.g., 0.01 for 1%)
  --show-script=NAME       show builtin script code, then exit
  --verbose-errors         print messages of all errors

Common options:
  --debug                  print debugging output
  -d, --dbname=DBNAME      database name to connect to
  -h, --host=HOSTNAME      database server host or socket directory
  -p, --port=PORT          database server port number
  -U, --username=USERNAME  connect as specified database user
  -V, --version            output version information, then exit
  -?, --help               show this help, then exit
```

```shell
docker run --rm -it --entrypoint /bin/bash postgres:17
pgbench --help
```
