use qualite_air;

-- Requête 1 : liste de l'ensemble des agences
SELECT id_agence , num_agence , nom_agence
FROM Agence  ;

-- Requête 2 : liste des agents techniques de l'agence de Bordeaux
SELECT distinct p.nom_personnel , p.prenom_personnel 
FROM personnel p
JOIN agent_technique atech ON p.id_personnel = atech.id_personnel
JOIN agence a ON a.id_agence = p.id_agence
JOIN adresse_postale ap ON a.id_region = ap.id_region
WHERE ap.ville = 'Bordeaux' ; 

-- Requête 3 : nombre total de capteurs déployés
SELECT count(*) as nb_tot_capteurs
FROM capteur;

-- Requête 4 : liste des rapports produits entre 2018 et 2022
SELECT id_rapport , titre , date_rapport
FROM rapport
WHERE YEAR(date_rapport) BETWEEN 2018 AND 2022 ;  

-- Requête 5 : concentration de CH4 en ppm en bretagne, occitanie, idf en mai et juin 2023
SELECT r.nom_region,
       rel.date_releves,
       rel.concentration_gaz
FROM releves rel
JOIN capteur c ON rel.id_capteur = c.id_capteur
JOIN gaz g ON c.id_gaz = g.id_gaz
JOIN adresse_postale ap ON c.id_adresse = ap.id_adresse
JOIN region r ON ap.id_region = r.id_region
WHERE g.sigle = 'CH4'
  AND r.nom_region IN ('Ile-de-France', 'Bretagne', 'Occitanie')
  AND rel.date_releves BETWEEN '2023-05-01' AND '2023-06-30'
ORDER BY r.nom_region, rel.date_releves;

-- Requête 6 : personnel technique maintenant les capteurs dont les gaz à effet de serre proviennent de l'industrie GESI
SELECT DISTINCT p.nom_personnel , p.prenom_personnel 
FROM personnel p
JOIN agent_technique a ON p.id_personnel = a.id_personnel
JOIN capteur c ON a.id_personnel = c.id_personnel
JOIN gaz g ON c.id_gaz = g.id_gaz
WHERE g.type_gaz = 'GESI' ;

-- Requête 7: Titres et dates des rapports concernant des concentrations de NH3, classés par ordre anti-chronologique
SELECT DISTINCT ra.titre, ra.date_rapport
FROM rapport ra
JOIN peut_se_trouver pst ON ra.id_rapport = pst.id_rapport
JOIN releves rel ON pst.id_releves = rel.id_releves
JOIN capteur c ON rel.id_capteur = c.id_capteur
JOIN gaz g ON c.id_gaz = g.id_gaz
WHERE g.sigle = 'NH3'
ORDER BY ra.date_rapport DESC;

-- Requête 8 : afficher le mois où la concentration de HFC a été la moins importante pour chaque région
SELECT region as nom_region, mois as nom_mois, concentration_min as valeur_concentration
FROM (
    SELECT r.nom_region AS region,
           DATE_FORMAT(rel.date_releves, '%Y-%m') AS mois,
           rel.concentration_gaz AS concentration_min,
           ROW_NUMBER() OVER (
               PARTITION BY r.nom_region
               ORDER BY rel.concentration_gaz ASC
           ) AS rang
    FROM releves rel
    JOIN capteur c ON rel.id_capteur = c.id_capteur
    JOIN gaz g ON c.id_gaz = g.id_gaz
    JOIN adresse_postale ap ON c.id_adresse = ap.id_adresse
    JOIN region r ON ap.id_region = r.id_region
    WHERE g.sigle = 'HFC'
) as t
WHERE rang = 1;

-- Requête 9 : Moyenne des concentrations (en ppm) dans la région « Ile-de-France » en 2020, pour chaque gaz étudié
SELECT g.sigle, AVG(rel.concentration_gaz) AS moyenne_concentration
FROM releves rel
JOIN capteur c ON rel.id_capteur = c.id_capteur
JOIN gaz g ON c.id_gaz = g.id_gaz
JOIN adresse_postale ap ON c.id_adresse = ap.id_adresse
JOIN region r ON ap.id_region = r.id_region
WHERE r.nom_region = 'Ile-de-France'
  AND YEAR(rel.date_releves) = 2020
GROUP BY g.sigle;

-- Requête 10 : taux de productivité des agents administratifs de l'agence de Toulouse ( le taux est calculé en nombre de rapports écrits par mois en moyenne, sur la durée de leur contrat)
SELECT p.id_personnel, p.nom_personnel, p.prenom_personnel,
       COUNT(e.id_rapport) /
       TIMESTAMPDIFF(MONTH, p.date_de_prise_de_poste, CURDATE()) 
       AS taux_productivite
FROM personnel p
JOIN agent_administratif aa ON p.id_personnel = aa.id_personnel
JOIN agence a ON p.id_agence = a.id_agence
LEFT JOIN ecrire e ON p.id_personnel = e.id_personnel
WHERE a.nom_agence = 'Agence Occitanie Toulouse'
GROUP BY p.id_personnel, p.nom_personnel, p.prenom_personnel;

-- Requête 11 :	Pour un gaz donné, liste des rapports contenant des données qui le concernent (on doit pouvoir donner le nom du gaz en paramètre)
DELIMITER //
CREATE PROCEDURE rapports_par_gaz(IN sigle_gaz VARCHAR(50))
BEGIN
    SELECT DISTINCT ra.titre, ra.date_rapport, ra.ref_rapport
    FROM rapport ra
    JOIN peut_se_trouver pst ON ra.id_rapport = pst.id_rapport
    JOIN releves re           ON pst.id_releves = re.id_releves
    JOIN capteur c            ON re.id_capteur = c.id_capteur
    JOIN gaz g                ON c.id_gaz = g.id_gaz
    WHERE g.sigle COLLATE utf8mb4_unicode_ci = sigle_gaz COLLATE utf8mb4_unicode_ci;
END;
//
DELIMITER ;

-- Si on veut appeller  :
CALL rapports_par_gaz('CH4');

-- Requête 12 : Liste des régions dans lesquelles il y a plus de capteurs que de personnel d’agence
SELECT r.nom_region,
       COUNT(DISTINCT c.id_capteur)   AS nb_capteurs,
       COUNT(DISTINCT p.id_personnel) AS nb_personnel
FROM region r
LEFT JOIN adresse_postale ap ON r.id_region = ap.id_region
LEFT JOIN capteur c          ON ap.id_adresse = c.id_adresse
LEFT JOIN agence a           ON r.id_region = a.id_region
LEFT JOIN personnel p        ON a.id_agence = p.id_agence
GROUP BY r.id_region, r.nom_region
HAVING nb_capteurs > nb_personnel;



