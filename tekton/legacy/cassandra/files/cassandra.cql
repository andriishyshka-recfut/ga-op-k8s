create
keyspace vortex with replication = {'class': 'SimpleStrategy', 'replication_factor': 2};

ALTER TABLE vortex.card WITH caching = {'keys': 'ALL', 'rows_per_partition': '100'};
ALTER TABLE vortex.bin_zip_probability WITH caching = {'keys': 'ALL', 'rows_per_partition': '100'};
ALTER TABLE vortex.zip_probability WITH caching = {'keys': 'ALL', 'rows_per_partition': '10'};
ALTER TABLE vortex.bin_probability WITH caching = {'keys': 'ALL', 'rows_per_partition': '10'};

ALTER TABLE vortex.card WITH compaction = { 'class' : 'LeveledCompactionStrategy' };
ALTER TABLE vortex.bin_zip_probability WITH compaction = { 'class' : 'LeveledCompactionStrategy' };
ALTER TABLE vortex.zip_probability WITH compaction = { 'class' : 'LeveledCompactionStrategy' };
ALTER TABLE vortex.bin_probability WITH compaction = { 'class' : 'LeveledCompactionStrategy' };

ALTER TABLE vortex.card WITH bloom_filter_fp_chance = 0.1;
ALTER TABLE vortex.bin_zip_probability WITH bloom_filter_fp_chance = 0.1;
ALTER TABLE vortex.zip_probability WITH bloom_filter_fp_chance = 0.1;
ALTER TABLE vortex.bin_probability WITH bloom_filter_fp_chance = 0.1;

CREATE TABLE vortex.card
(
    id             varchar PRIMARY KEY,
    document_id    varchar,
    shop_id        varchar,
    unique_id      varchar,
    bank           varchar,
    issuer_country varchar,
    city           varchar,
    state          varchar,
    country        varchar,
    seen           varchar,
    added          timestamp,
    last_seen      timestamp,
    name_split     list< varchar >,
    for_sale       boolean
);

CREATE TABLE vortex.bin_zip_probability
(
    key         varchar PRIMARY KEY,
    probability double
);

CREATE TABLE vortex.bin_probability
(
    key         varchar PRIMARY KEY,
    probability double
);

CREATE TABLE vortex.zip_probability
(
    key         varchar PRIMARY KEY,
    probability double
);

CREATE TABLE vortex.month_diff_probability
(
    key         smallint PRIMARY KEY,
    probability double
);