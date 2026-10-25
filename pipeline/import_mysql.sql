-- =====================================================================
-- Passo 4 (import): carrega o CSV exportado do MongoDB para o MySQL,
-- sem transformacoes. O resultado desta base de dados e o que vai no dump atpdb.sql.
-- O CSV tem de estar em /var/lib/mysql-files/ (pasta mysql_files do Docker).
-- =====================================================================
DROP DATABASE IF EXISTS atp;
CREATE DATABASE atp CHARACTER SET utf8mb4;
USE atp;

DROP TABLE IF EXISTS atpplayers;
CREATE TABLE atpplayers (
  PlayerId     varchar(100) DEFAULT NULL,
  PlayerName   varchar(100) DEFAULT NULL,
  Born         varchar(100) DEFAULT NULL,
  Height       varchar(100) DEFAULT NULL,
  Hand         varchar(100) DEFAULT NULL,
  Tournament   varchar(100) DEFAULT NULL,
  Location     varchar(100) DEFAULT NULL,
  Date         varchar(100) DEFAULT NULL,
  Ground       varchar(100) DEFAULT NULL,
  Prize        varchar(100) DEFAULT NULL,
  Round        varchar(100) DEFAULT NULL,
  OpponentRank varchar(100) DEFAULT NULL,
  Opponent     varchar(100) DEFAULT NULL,
  WL           varchar(100) DEFAULT NULL,
  Score        varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

LOAD DATA INFILE '/var/lib/mysql-files/atpplayers.csv'
INTO TABLE atpplayers
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

SELECT COUNT(*) AS linhas_importadas FROM atpplayers;
