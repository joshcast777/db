CREATE PROCEDURE usp_GeneratePaseReport
    @StartDate DATETIME,
    @EndDate DATETIME
AS
BEGIN
    SET NOCOUNT ON;

    -- Verifica si la tabla temporal existe y la borra en caso de ser necesario
    IF EXISTS (SELECT * FROM tempdb.dbo.sysobjects WHERE id = OBJECT_ID('tempdb..#objpases'))
    BEGIN
        DROP TABLE #objpases;
    END

    -- Llena el objeto temporal
    SELECT 
        capAnno, capMes, capMotivoPase, Capcodigo, 
        verCodigo AS NOMBREOBJETO, depModApp AS APLICACION, 
        deptipoobjver AS OBJ_VER, SUBSTRING(vercodigo, 1, 1) AS INICIAL, 
        CASE 
            WHEN '' + SUBSTRING(vercodigo, 2, 2) = 'X4' THEN '43'
            WHEN '' + SUBSTRING(vercodigo, 2, 2) = 'P5' THEN '55'
            WHEN '' + SUBSTRING(vercodigo, 2, 2) = 'XT' THEN SUBSTRING(vercodigo, 4, 2)
            WHEN '' + SUBSTRING(vercodigo, 2, 2) = 'T4' THEN SUBSTRING(vercodigo, 3, 2)
            WHEN '' + SUBSTRING(vercodigo, 2, 2) = '5L' THEN '55'
            ELSE SUBSTRING(vercodigo, 2, 2)
        END AS MODULO,
        CASE 
            WHEN SUBSTRING(vercodigo, 1, 1) IN ('B', 'N', 'X') THEN 'BSFN'
            WHEN SUBSTRING(vercodigo, 1, 1) IN ('D', 'T') THEN 'DSTR'
            WHEN SUBSTRING(vercodigo, 1, 1) IN ('F') THEN 'TBL'
            WHEN SUBSTRING(vercodigo, 1, 1) IN ('J') THEN 'BSSV'
            WHEN SUBSTRING(vercodigo, 1, 1) IN ('P') THEN 'APPL'
            WHEN SUBSTRING(vercodigo, 1, 1) IN ('R') THEN 'UBE'
            WHEN SUBSTRING(vercodigo, 1, 1) IN ('V') THEN 'BSVW'
            ELSE 'OTRO'
        END AS TIPO, 
        capDesarrollador AS DESARROLLADOR, capFecAutPVDesa AS FECHA_PASE, 
        capNomPrj AS Desc_MOTIVO, capObservacion AS OBSERVACION,
        capFecAutPVDesa AS Fecha_Aprobación_Des, capFecImpEst AS Fecha_Imp_Est,
        depDesCambio AS DESC_CAMBIO, capReqImpPV AS especificacion, 
        modCodigo, capSerProduccion, depDestino, CAPSERDESARROLLO, 
        depOrigen, capLocalidad, 
        (SELECT parDescripcion FROM DBO.PARAMETRO WHERE capTipoPase = parSecuencia) AS tipoPase
    INTO #objpases
    FROM vw_cappaseversion
    JOIN vw_DETPASEVERSION ON vw_cappaseversion.capSecuencia = vw_DETPASEVERSION.capSecuencia
    WHERE capFecImpEst>='2001-02-01 00:00:00'
    ORDER BY vercodigo, capFecAutPVDesa;

    -- Select para generar la consulta y el excel. por fecha inicio y fin
    SELECT 
        capanno, capmes, 
        CASE tipoPase  
            WHEN 'POR PROYECTO' THEN 'PRO' 
            ELSE SUBSTRING(dESC_MOTIVO, 1, 3) 
        END AS caso, 
        tipopase, capcodigo, APLICACION,
        DESARROLLADOR, CONVERT(date, fecha_pase, 102) AS FechaPase, 
        Fecha_Aprobación_Des, Desc_MOTIVO, OBSERVACION, especificacion, 
        CONVERT(date, Fecha_Imp_Est, 102) AS FechaImpEst, '' AS Desmes, capMotivoPase,
        CASE TIPOPASE 
            WHEN 'POR PROYECTO' THEN 'PROYECTO'
            ELSE 
                CASE SUBSTRING(dESC_MOTIVO, 1, 3) 
                    WHEN 'RFC' THEN 'MEJORAS INTERNAS A APLICACIONES'
                    WHEN 'REQ' THEN 'MEJORAS INTERNAS A APLICACIONES'
                    WHEN 'PRO' THEN 'PROYECTO'
                    WHEN 'INC' THEN 'RESOLUCIÓN DE INCIDENTES'
                    WHEN 'PRB' THEN 'RESOLUCIÓN DE PROBLEMAS'
                    ELSE ''
                END
        END AS DescripcionCaso
    FROM #objpases
    WHERE Fecha_Imp_Est BETWEEN @StartDate AND @EndDate
    GROUP BY capanno, capmes, TipoPase, capcodigo, APLICACION, DESARROLLADOR, 
             fecha_pase, Fecha_Aprobación_Des, desc_motivo, OBSERVACION, especificacion, 
             Fecha_Imp_Est, capMotivoPase
    ORDER BY DESARROLLADOR, Fecha_Aprobación_Des;

    -- borra la tabla temporal
    DROP TABLE #objpases;
END
GO
