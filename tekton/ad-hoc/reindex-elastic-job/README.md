(Source code and pipelines: https://gitlab.regemini.com/op/scripts/-/tree/main/reindex-elastic?ref_type=heads )

### Execution

Example of reindixing on Sandbox Green

0) Modify `input.tf` to set correct run prefiux and slack chanel. If you need to block Kafka topics (required for Minion indices) set `block_kafka_topics` to `true`

1) Create kubernetes job:
```
otgg init -reconfigure
otgg apply
```

2) Login to newly created pod in `core` namespace

3) Create new Screen session
```
screen -S reindex
```

3.1) For Sandbox run disable ES certificate validation
```
export DISABLE_SSL=true
```

4) Run reindexer with corresponding parameters

```
universal_reindexer.py [-i <index name>] [-n <new index name>] [-t <index template>] [-s <skip prefix>] [-w <workdir>] [-e <elastic URL>] [-d]

-i    Source index name (cannot be used with -t)
-n    Override target index name with <new name> (cannot be used with -t). If not defined, the index will be named like latest template version.
-t    Reindex every index that matches patterns defined in "index template"
-s    Skip indices whose name starts with "skip prefix"
-w    Set workdir name ("prod" or "sandbox")
-e    Override ES URL (by default it's extracted from Vault)
-d    Dry-run. Results will be saved to "workdir"_dryrun folder
```

The workdir folder contains file called "processed_indices.txt". If you want to skip particular indices, add every name as a new line.
The process will also add every name that has been processed successfully to this file

Usage examples:

To reindex snat-1924-2024010301 -n snat-1924-2024010302 on Sandbox
```
python -W ignore universal_reindexer.py -i snat-1924-2024010301 -n snat-1924-2024010302 -w ./sandbox

```

To reindex all "maid" indices except 'credz_2024'
```
python -W ignore universal_reindexer.py -t maid -s credz_2024 -w ./sandbox

```

To reindex "conti" to latest template version
```
python -W ignore universal_reindexer.py -i conti -w ./sandbox

```