-- DATA: 07/10/2025 12:38
-- AUTOR: ROGERIO
-- OBS.: INCLUSÃO COLUNA PEDIDO ANTERIOR (CD E DATA), INTEGRAÇÃO DEXPARA , contagem dias

SELECT
    COALESCE(PED_ANT.cd_pedido, 0) AS Pedido_Anterior,
    PED_ANT.dt_aprovacao AS Dt_Aprovacao_Pedido_Anterior,
--ISNULL(DATEDIFF(DAY, PED_ANT.dt_aprovacao, PED.dt_faturado), 0) AS Dias_Entre_Aprovacao_Anterior_Faturamento,

    PED.Cd_pedido,
    PED.Dt_pedido,
    PED.Dt_aprovacao,
    PED.Dt_faturado,
    PED.Total_pedido,
    PED.Cd_tipo_operaca,
    PED.CONTROLE AS PEDCONTROLE,
    PED.Cd_cliente,
    LTRIM(RTRIM(EMP.Nome_completo)) AS Nome_completo,
    LTRIM(RTRIM(EMP.Fantasia)) AS Fantasia,
    LTRIM(RTRIM(EMP.Municipio)) AS Municipio,
    EMP.Uf AS UF,
    EMP.Dt_cadastro AS Dt_cadastro,
    EMP.Cd_centralizado AS Cod_centralizadora,
    LTRIM(RTRIM(CENTR.Nome_completo)) AS Nome_centralizadora,
    PED.Cd_representant,
    REP.Nome_completo AS nome_representante,
    PED.Cd_ordem_de_com,
    PED.usuario_criacao,
    UPPER(RIGHT(SUSER_SNAME(), LEN(SUSER_SNAME()) - CHARINDEX('\', SUSER_SNAME()))) AS NomeUsuario

FROM FAPEDIDO PED WITH (NOLOCK)

OUTER APPLY (
    SELECT TOP 1
        pa.cd_pedido,
        pa.dt_aprovacao
    FROM FAPEDIDO pa WITH (NOLOCK)
    INNER JOIN GETOPERA gp WITH (NOLOCK)
        ON gp.cd_tipo_operaca = pa.cd_tipo_operaca
    WHERE
        pa.cd_cliente = PED.cd_cliente
            and pa.cd_cliente not like 'CT%'
        AND gp.faturado = 'S'  -- somente operações faturadas
        AND pa.dt_aprovacao IS NOT NULL
        AND CAST(pa.dt_aprovacao AS DATE) < CAST(COALESCE(PED.dt_faturado, PED.dt_aprovacao) AS DATE)
        AND pa.CONTROLE NOT IN ('20','11','14','29','90','91','95')
    ORDER BY pa.dt_aprovacao DESC
) PED_ANT


INNER JOIN GETOPERA GETO WITH (NOLOCK)
    ON GETO.Cd_tipo_operaca = PED.Cd_tipo_operaca

INNER JOIN FACONTRO FAC WITH (NOLOCK)
    ON FAC.Controle = PED.Controle

INNER JOIN GEEMPRES EMP WITH (NOLOCK)
    ON EMP.cd_empresa = PED.Cd_cliente

LEFT JOIN GEEMPRES CENTR WITH (NOLOCK)
    ON CENTR.cd_empresa = EMP.Cd_centralizado

INNER JOIN GEEMPRES REP WITH (NOLOCK)
    ON REP.cd_empresa = PED.Cd_representant


INNER JOIN DEXPARA DEX WITH (NOLOCK)
    ON DEX.Cd_Operacao_Resultado_de = GETO.Cd_tipo_operaca
    AND DEX.ALPHA_1_2 = 'V'

WHERE
   PED.Cd_unid_de_neg between '@un_inicial' and '@un_final' -- INCLUIR UNIDADE DE NEGOCIO
    and CONVERT(DATE,PED.Dt_pedido) between @dt_emis_inicial AND @dt_emis_final -- INCLUIR FILTRO DE DATA
    AND FAC.Controle in ('21','15','16','25','30','35','50','55','40','56')
    AND GETO.faturado = 'S'
    AND PED.Cd_cliente <> '101'
    AND PED.Total_pedido > 0
      AND PED.Cd_pedido NOT LIKE 'CT%'