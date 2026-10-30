/******************************************************************
        ANALYSE AVANCÉE DES DONNÉES AVEC SQL SERVER
        Compatible SQL Server 2017 / 2019 / 2022
******************************************************************/

/*===============================================================
1. STATISTIQUES DESCRIPTIVES
===============================================================*/

SELECT
    COUNT(*) AS NombreObservations,
    SUM(Montant) AS SommeMontants,
    AVG(Montant) AS Moyenne,
    MIN(Montant) AS Minimum,
    MAX(Montant) AS Maximum,
    MAX(Montant) - MIN(Montant) AS Etendue,
    STDEV(Montant) AS EcartType,
    VAR(Montant) AS Variance
FROM Ventes;


/*===============================================================
2. MÉDIANE
===============================================================*/

SELECT DISTINCT
    PERCENTILE_CONT(0.5)
    WITHIN GROUP (ORDER BY Montant)
    OVER () AS Mediane
FROM Ventes;


/*===============================================================
3. QUARTILES
===============================================================*/

SELECT DISTINCT
    PERCENTILE_CONT(0.25)
        WITHIN GROUP (ORDER BY Montant)
        OVER () AS Q1,
    PERCENTILE_CONT(0.50)
        WITHIN GROUP (ORDER BY Montant)
        OVER () AS Q2,
    PERCENTILE_CONT(0.75)
        WITHIN GROUP (ORDER BY Montant)
        OVER () AS Q3
FROM Ventes;


/*===============================================================
4. PERCENTILES
===============================================================*/

SELECT DISTINCT
    PERCENTILE_CONT(0.90)
        WITHIN GROUP (ORDER BY Montant)
        OVER () AS P90,
    PERCENTILE_CONT(0.95)
        WITHIN GROUP (ORDER BY Montant)
        OVER () AS P95,
    PERCENTILE_CONT(0.99)
        WITHIN GROUP (ORDER BY Montant)
        OVER () AS P99
FROM Ventes;


/*===============================================================
5. CLASSEMENT DES VENTES
===============================================================*/

SELECT
    IdVente,
    Montant,
    RANK() OVER (
        ORDER BY Montant DESC
    ) AS RangVente
FROM Ventes;


/*===============================================================
6. TOP 10 DES VENTES
===============================================================*/

SELECT TOP 10
    *
FROM Ventes
ORDER BY Montant DESC;


/*===============================================================
7. TOP 10 CLIENTS
===============================================================*/

SELECT TOP 10
    c.NomClient,
    SUM(v.Montant) AS ChiffreAffaires
FROM Ventes v
INNER JOIN Clients c
    ON c.IdClient = v.IdClient
GROUP BY c.NomClient
ORDER BY ChiffreAffaires DESC;


/*===============================================================
8. TOP 10 PRODUITS
===============================================================*/

SELECT TOP 10
    p.NomProduit,
    SUM(v.Quantite) AS QuantiteVendue
FROM Ventes v
INNER JOIN Produits p
    ON p.IdProduit = v.IdProduit
GROUP BY p.NomProduit
ORDER BY QuantiteVendue DESC;


/*===============================================================
9. SOMME CUMULÉE
===============================================================*/

SELECT
    DateVente,
    Montant,
    SUM(Montant)
    OVER (
        ORDER BY DateVente
    ) AS CumulCA
FROM Ventes;


/*===============================================================
10. MOYENNE MOBILE 7 JOURS
===============================================================*/

SELECT
    DateVente,
    Montant,
    AVG(Montant)
    OVER (
        ORDER BY DateVente
        ROWS BETWEEN 6 PRECEDING
        AND CURRENT ROW
    ) AS MoyenneMobile7J
FROM Ventes;


/*===============================================================
11. ÉVOLUTION MENSUELLE
===============================================================*/

SELECT
    YEAR(DateVente) AS Annee,
    MONTH(DateVente) AS Mois,
    SUM(Montant) AS TotalVentes
FROM Ventes
GROUP BY
    YEAR(DateVente),
    MONTH(DateVente)
ORDER BY
    Annee,
    Mois;


/*===============================================================
12. TAUX DE CROISSANCE
===============================================================*/

WITH VentesMensuelles AS
(
    SELECT
        YEAR(DateVente) AS Annee,
        MONTH(DateVente) AS Mois,
        SUM(Montant) AS Total
    FROM Ventes
    GROUP BY
        YEAR(DateVente),
        MONTH(DateVente)
)
SELECT
    *,
    LAG(Total)
    OVER (
        ORDER BY Annee, Mois
    ) AS TotalPrecedent,
    ROUND(
        (
            (
                Total -
                LAG(Total)
                OVER (
                    ORDER BY Annee, Mois
                )
            )
            * 100.0
        )
        /
        NULLIF(
            LAG(Total)
            OVER (
                ORDER BY Annee, Mois
            ),
            0
        ),
        2
    ) AS CroissancePourcent
FROM VentesMensuelles;


/*===============================================================
13. SCORE Z
===============================================================*/

WITH Stats AS
(
    SELECT
        AVG(Montant) AS Moyenne,
        STDEV(Montant) AS EcartType
    FROM Ventes
)
SELECT
    v.IdVente,
    v.Montant,
    ROUND(
        (
            v.Montant - s.Moyenne
        )
        /
        s.EcartType,
        4
    ) AS ZScore
FROM Ventes v
CROSS JOIN Stats s;


/*===============================================================
14. DÉTECTION DES OUTLIERS
===============================================================*/

WITH Stats AS
(
    SELECT
        AVG(Montant) AS Moyenne,
        STDEV(Montant) AS EcartType
    FROM Ventes
)
SELECT
    v.*
FROM Ventes v
CROSS JOIN Stats s
WHERE ABS(
    (
        v.Montant - s.Moyenne
    )
    /
    s.EcartType
) > 3;


/*===============================================================
15. HISTOGRAMME
===============================================================*/

SELECT
    FLOOR(Montant / 1000) * 1000 AS Classe,
    COUNT(*) AS Effectif
FROM Ventes
GROUP BY FLOOR(Montant / 1000)
ORDER BY Classe;


/*===============================================================
16. ANALYSE PAR JOUR DE SEMAINE
===============================================================*/

SELECT
    DATENAME(WEEKDAY, DateVente) AS Jour,
    COUNT(*) AS NombreVentes,
    SUM(Montant) AS Total
FROM Ventes
GROUP BY DATENAME(WEEKDAY, DateVente)
ORDER BY Total DESC;


/*===============================================================
17. ANALYSE SAISONNIÈRE
===============================================================*/

SELECT
    MONTH(DateVente) AS Mois,
    AVG(Montant) AS MoyenneMensuelle,
    SUM(Montant) AS TotalMensuel
FROM Ventes
GROUP BY MONTH(DateVente)
ORDER BY Mois;


/*===============================================================
18. CORRÉLATION
===============================================================*/

SELECT
(
    COUNT(*) * SUM(CAST(Quantite * Montant AS FLOAT))
    -
    SUM(CAST(Quantite AS FLOAT))
    *
    SUM(CAST(Montant AS FLOAT))
)
/
(
    SQRT(
        (
            COUNT(*) * SUM(CAST(POWER(Quantite,2) AS FLOAT))
            -
            POWER(SUM(CAST(Quantite AS FLOAT)),2)
        )
        *
        (
            COUNT(*) * SUM(CAST(POWER(Montant,2) AS FLOAT))
            -
            POWER(SUM(CAST(Montant AS FLOAT)),2)
        )
    )
) AS Correlation
FROM Ventes;


/*===============================================================
19. ANALYSE ABC
===============================================================*/

WITH CA AS
(
    SELECT
        IdProduit,
        SUM(Montant) AS ChiffreAffaires
    FROM Ventes
    GROUP BY IdProduit
),
Classement AS
(
    SELECT
        *,
        SUM(ChiffreAffaires)
        OVER (
            ORDER BY ChiffreAffaires DESC
        ) AS Cumul,
        SUM(ChiffreAffaires)
        OVER () AS TotalCA
    FROM CA
)
SELECT
    *,
    ROUND(
        (Cumul * 100.0) / TotalCA,
        2
    ) AS PourcentageCumule,
    CASE
        WHEN (Cumul * 1.0 / TotalCA) <= 0.80
            THEN 'A'
        WHEN (Cumul * 1.0 / TotalCA) <= 0.95
            THEN 'B'
        ELSE 'C'
    END AS ClasseABC
FROM Classement;


/*===============================================================
20. KPI GLOBAUX
===============================================================*/

SELECT
    COUNT(*) AS NombreVentes,
    COUNT(DISTINCT IdClient) AS NombreClients,
    COUNT(DISTINCT IdProduit) AS NombreProduits,
    SUM(Montant) AS ChiffreAffaires,
    AVG(Montant) AS PanierMoyen,
    MAX(Montant) AS VenteMax,
    MIN(Montant) AS VenteMin,
    STDEV(Montant) AS EcartType
FROM Ventes;


/*===============================================================
21. VUE ANALYTIQUE
===============================================================*/

CREATE OR ALTER VIEW vw_AnalyseVentes
AS
SELECT
    p.NomProduit,
    SUM(v.Quantite) AS QuantiteVendue,
    SUM(v.Montant) AS ChiffreAffaires,
    AVG(v.Montant) AS PanierMoyen
FROM Ventes v
INNER JOIN Produits p
    ON p.IdProduit = v.IdProduit
GROUP BY p.NomProduit;


/*===============================================================
22. TABLEAU DE BORD POWER BI
===============================================================*/

SELECT
    CAST(DateVente AS DATE) AS DateAnalyse,
    SUM(Montant) AS ChiffreAffaires,
    COUNT(*) AS NombreTransactions
FROM Ventes
GROUP BY CAST(DateVente AS DATE)
ORDER BY DateAnalyse;


/******************************************************************
      FIN - ANALYSE AVANCÉE DES DONNÉES SQL SERVER
******************************************************************/