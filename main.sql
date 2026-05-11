/* =========================================================
   QUESTÃO 01
   Procedure: dbo.salaryHistogram

   Objetivo:
   Criar uma procedure que distribui os salários dos professores
   em intervalos, formando um histograma.

   Exemplo de execução:
   EXEC dbo.salaryHistogram 5;
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.salaryHistogram
    @qtdIntervalos INT
AS
BEGIN
    SET NOCOUNT ON;

    /* Validação do parâmetro de entrada */
    IF @qtdIntervalos IS NULL OR @qtdIntervalos <= 0
    BEGIN
        RAISERROR('O número de intervalos deve ser maior que zero.', 16, 1);
        RETURN;
    END;

    /* Declaração das variáveis utilizadas no cálculo */
    DECLARE 
        @valorMinimo BIGINT,
        @valorMaximo BIGINT,
        @larguraIntervalo BIGINT;

    /* Busca o menor e o maior salário da tabela instructor */
    SELECT
        @valorMinimo = MIN(CAST(salary AS BIGINT)),
        @valorMaximo = MAX(CAST(salary AS BIGINT))
    FROM dbo.instructor
    WHERE salary IS NOT NULL;

    /* Caso não existam salários cadastrados */
    IF @valorMinimo IS NULL
    BEGIN
        SELECT 
            CAST(NULL AS BIGINT) AS valorMinimo,
            CAST(NULL AS BIGINT) AS valorMaximo,
            CAST(0 AS INT) AS total
        WHERE 1 = 0;

        RETURN;
    END;

    /* Calcula a largura de cada intervalo */
    SET @larguraIntervalo = CEILING(
        ((@valorMaximo - @valorMinimo + 1.0) / @qtdIntervalos)
    );

    /* Criação dos intervalos do histograma */
    ;WITH Intervalos AS
    (
        SELECT 1 AS numeroIntervalo

        UNION ALL

        SELECT numeroIntervalo + 1
        FROM Intervalos
        WHERE numeroIntervalo < @qtdIntervalos
    ),

    /* Define valor mínimo e máximo de cada faixa */
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

    /* Conta quantos professores existem em cada faixa salarial */
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
GO


/* =========================================================
   EXECUÇÃO DA QUESTÃO 01

   Chamada da procedure passando 5 intervalos.
   ========================================================= */

EXEC dbo.salaryHistogram 5;