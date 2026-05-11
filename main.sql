CREATE OR ALTER PROCEDURE dbo.salaryHistogram
    @qtdIntervalos INT
AS
BEGIN
    SET NOCOUNT ON;

    IF @qtdIntervalos IS NULL OR @qtdIntervalos <= 0
    BEGIN
        RAISERROR('O número de intervalos deve ser maior que zero.', 16, 1);
        RETURN;
    END;

    DECLARE 
        @valorMinimo BIGINT,
        @valorMaximo BIGINT,
        @larguraIntervalo BIGINT;

    SELECT
        @valorMinimo = MIN(CAST(salary AS BIGINT)),
        @valorMaximo = MAX(CAST(salary AS BIGINT))
    FROM dbo.instructor
    WHERE salary IS NOT NULL;

    IF @valorMinimo IS NULL
    BEGIN
        SELECT 
            CAST(NULL AS BIGINT) AS valorMinimo,
            CAST(NULL AS BIGINT) AS valorMaximo,
            CAST(0 AS INT) AS total
        WHERE 1 = 0;

        RETURN;
    END;

    SET @larguraIntervalo = CEILING(
        ((@valorMaximo - @valorMinimo + 1.0) / @qtdIntervalos)
    );

    ;WITH Intervalos AS
    (
        SELECT 1 AS numeroIntervalo

        UNION ALL

        SELECT numeroIntervalo + 1
        FROM Intervalos
        WHERE numeroIntervalo < @qtdIntervalos
    ),
    Faixas AS
    (
        SELECT
            numeroIntervalo,
            @valorMinimo + ((numeroIntervalo - 1) * @larguraIntervalo) AS valorMinimo,
            CASE 
                WHEN numeroIntervalo = @qtdIntervalos 
                    THEN @valorMaximo
                ELSE @valorMinimo + (numeroIntervalo * @larguraIntervalo) - 1
            END AS valorMaximo
        FROM Intervalos
    )
    SELECT
        f.valorMinimo,
        f.valorMaximo,
        COUNT(i.salary) AS total
    FROM Faixas f
    LEFT JOIN dbo.instructor i
        ON CAST(i.salary AS BIGINT) BETWEEN f.valorMinimo AND f.valorMaximo
    GROUP BY
        f.numeroIntervalo,
        f.valorMinimo,
        f.valorMaximo
    ORDER BY
        f.numeroIntervalo
    OPTION (MAXRECURSION 0);
END;

EXEC dbo.salaryHistogram 5;