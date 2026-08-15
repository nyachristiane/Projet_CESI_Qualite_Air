 drop database qualite_air;
CREATE DATABASE IF NOT EXISTS qualite_air;
USE qualite_air;

CREATE TABLE region (
    id_region   INT  NOT NULL AUTO_INCREMENT,
    nom_region  VARCHAR(128)    NOT NULL,
    PRIMARY KEY (id_region),
	UNIQUE (nom_region)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
 
CREATE TABLE adresse_postale (
    id_adresse  INT  NOT NULL AUTO_INCREMENT,
    id_region INT NOT NULL ,
    numero INT ,
    rue      VARCHAR(256),
    ville       VARCHAR(128)    NOT NULL,
    code_postal CHAR(10)         NOT NULL,
     PRIMARY KEY (id_adresse),
     FOREIGN KEY ( id_region )
     REFERENCES region (id_region) 
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE agence (
    id_agence   int   NOT NULL auto_increment ,
    num_agence  VARCHAR(50)     NOT NULL,
    nom_agence  VARCHAR(128)    NOT NULL,
    id_region   INT NOT NULL,
	PRIMARY KEY (id_agence),
    UNIQUE (num_agence),
    FOREIGN KEY (id_region)
	REFERENCES region(id_region)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE gaz (
    id_gaz      INT NOT NULL AUTO_INCREMENT,
    nom_gaz     VARCHAR(128)  NOT NULL,
    sigle       VARCHAR(50)   NOT NULL,
    type_gaz    ENUM('GES','GESI')  NOT NULL,
    PRIMARY KEY (id_gaz),
    UNIQUE (sigle)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE personnel (
    id_personnel            INT  NOT NULL AUTO_INCREMENT,
    nom_personnel           VARCHAR(128)    NOT NULL,
    prenom_personnel        VARCHAR(128)    NOT NULL,
    date_de_naissance       DATE            NOT NULL,
    date_de_prise_de_poste  DATE            NOT NULL,
    id_adresse              int    NOT NULL,
    id_agence               int NOT NULL,
   PRIMARY KEY (id_personnel),
   FOREIGN KEY (id_adresse)
   REFERENCES adresse_postale(id_adresse),
   FOREIGN KEY (id_agence)
   REFERENCES agence(id_agence)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE agent_technique (
    id_personnel    INT  NOT NULL,
	PRIMARY KEY (id_personnel),
    FOREIGN KEY (id_personnel)
	REFERENCES personnel(id_personnel)
	ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE agent_administratif (
    id_personnel    INT   NOT NULL,
   PRIMARY KEY (id_personnel),
   FOREIGN KEY (id_personnel)
   REFERENCES personnel(id_personnel)
   ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table CHEF_D_AGENCE (table fille de PERSONNEL)

CREATE TABLE chef_d_agence (
    id_personnel            INT  NOT NULL,
    dernier_diplome_obtenu  VARCHAR(128)    NOT NULL,
    PRIMARY KEY (id_personnel),
	FOREIGN KEY (id_personnel)
	REFERENCES personnel(id_personnel)
	ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table CAPTEUR
-- id_personnel nullable car il peut ne pas avoir de responsable

CREATE TABLE capteur (
    id_capteur      INT NOT NULL AUTO_INCREMENT,
    num_capteur     VARCHAR(50)     NOT NULL,
    etat            BOOLEAN         NOT NULL DEFAULT TRUE,
    id_adresse      int NOT NULL,
    id_gaz          INT NOT NULL,
    id_personnel    INT NULL,           
	PRIMARY KEY (id_capteur),
	UNIQUE (num_capteur),
    FOREIGN KEY (id_adresse)
	REFERENCES adresse_postale(id_adresse)
	ON UPDATE CASCADE ON DELETE RESTRICT,
	FOREIGN KEY (id_gaz)
	REFERENCES gaz(id_gaz)
	ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (id_personnel)
	REFERENCES agent_technique(id_personnel)
	ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE releves (
    id_releves          INT   NOT NULL AUTO_INCREMENT,
    ref_releves         VARCHAR(50)     NOT NULL,
    date_releves        DATE            NOT NULL,
    concentration_gaz   DECIMAL(7,2)    NOT NULL,
    id_capteur          INT   NOT NULL,
    PRIMARY KEY (id_releves),
    UNIQUE (ref_releves),
    FOREIGN KEY (id_capteur)
	REFERENCES capteur(id_capteur)
	ON UPDATE CASCADE ON DELETE RESTRICT,
	CHECK (concentration_gaz >= 0.01 AND concentration_gaz <= 500.00),
    CHECK (DAY(date_releves) = 1)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table RAPPORT
-- Immuable : INSERT uniquement, pas d'UPDATE ni de DELETE

CREATE TABLE rapport (
    id_rapport      INT NOT NULL AUTO_INCREMENT,
    titre           VARCHAR(128)    NOT NULL,
    date_rapport    DATE            NOT NULL,
    details_analyse TEXT            NOT NULL,
    ref_rapport     VARCHAR(50)     NOT NULL,
	PRIMARY KEY (id_rapport),
    UNIQUE (ref_rapport)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE ecrire (
    id_personnel    INT NOT NULL,
    id_rapport      INT  NOT NULL,
    PRIMARY KEY (id_personnel, id_rapport),
	FOREIGN KEY (id_personnel)
	REFERENCES agent_administratif(id_personnel)
	ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (id_rapport)
	REFERENCES rapport(id_rapport)
	ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table PEUT_SE_TROUVER 
-- Immuable : INSERT uniquement

CREATE TABLE peut_se_trouver (
    id_releves  INT NOT NULL,
    id_rapport  INT  NOT NULL,
	PRIMARY KEY (id_releves, id_rapport),
    FOREIGN KEY (id_releves)
	REFERENCES releves(id_releves)
	ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (id_rapport)
	REFERENCES rapport(id_rapport)
	ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Index pour optimiser les jointures et filtres fréquents

CREATE INDEX IDX_releves_date      ON releves          (date_releves);
CREATE INDEX IDX_releves_capteur   ON releves          (id_capteur);
CREATE INDEX IDX_capteur_adresse   ON capteur          (id_adresse);
CREATE INDEX IDX_capteur_gaz       ON capteur          (id_gaz);
CREATE INDEX IDX_personnel_agence  ON personnel        (id_agence);
CREATE INDEX IDX_rapport_date      ON rapport          (date_rapport);
CREATE INDEX IDX_agence_region     ON agence           (id_region);

SET FOREIGN_KEY_CHECKS = 1;
-- Comptes utilisateurs et droits

-- Compte administrateur : tous les droits sur la base
CREATE USER IF NOT EXISTS 'admin_cleardata'@'localhost'
    IDENTIFIED BY 'MotDePasseAdmin!';
GRANT ALL PRIVILEGES ON qualite_air.* TO 'admin_cleardata'@'localhost';

-- Compte utilisateur (chef d'agence) :
--   - Lecture sur tout
--   - Ajout/suppression de relevés (pas de modification)
--   - Ajout uniquement pour les rapports (pas de modification ni suppression)
--   - Gestion des capteurs et du personnel
CREATE USER IF NOT EXISTS 'user_cleardata'@'localhost'
    IDENTIFIED BY 'MotDePasseUser!';

GRANT SELECT ON qualite_air.*                           TO 'user_cleardata'@'localhost';
GRANT INSERT, DELETE ON qualite_air.releves             TO 'user_cleardata'@'localhost';
GRANT INSERT ON qualite_air.rapport                     TO 'user_cleardata'@'localhost';
GRANT INSERT ON qualite_air.ecrire                      TO 'user_cleardata'@'localhost';
GRANT INSERT ON qualite_air.peut_se_trouver             TO 'user_cleardata'@'localhost';
GRANT INSERT, UPDATE, DELETE ON qualite_air.capteur             TO 'user_cleardata'@'localhost';
GRANT INSERT, UPDATE, DELETE ON qualite_air.personnel           TO 'user_cleardata'@'localhost';
GRANT INSERT, UPDATE, DELETE ON qualite_air.agent_technique     TO 'user_cleardata'@'localhost';
GRANT INSERT, UPDATE, DELETE ON qualite_air.agent_administratif TO 'user_cleardata'@'localhost';
GRANT INSERT, UPDATE, DELETE ON qualite_air.chef_d_agence       TO 'user_cleardata'@'localhost';
GRANT INSERT, UPDATE, DELETE ON qualite_air.agence              TO 'user_cleardata'@'localhost';
GRANT INSERT, UPDATE, DELETE ON qualite_air.adresse_postale     TO 'user_cleardata'@'localhost';

FLUSH PRIVILEGES;
