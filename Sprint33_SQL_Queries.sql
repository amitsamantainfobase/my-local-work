-- CMSS-2291
USE [Cms_Records]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

SET IDENTITY_INSERT [dbo].[Log_TableNames] ON

INSERT [dbo].[Log_TableNames] ([ID], [TableName], [DatabaseConnectionID])
VALUES (23, N'WorkEdition', 7)

SET IDENTITY_INSERT [dbo].[Log_TableNames] OFF
GO

SET IDENTITY_INSERT [dbo].[Log_Fields] ON

INSERT [dbo].[Log_Fields] ([ID], [FieldName], [TableID], [DisplayName], [ShowInLog])
VALUES 
    (82, N'ID', 23, N'Edition ID', 1)
    (83, N'Title', 23, N'Title', 1)
    (84, N'APATitle', 23, N'APA Title', 1)
    (85, N'ShortName', 23, N'Short Name', 1)
    (86, N'PublicationYear', 23, N'Publication Year', 1)
    (87, N'Status', 23, N'Status', 1)
    (88, N'PublisherID', 23, N'Publisher', 1)
    (89, N'PublisherImprintID', 23, N'Royalty Publisher', 1)
    (90, N'DataValue', 23, N'Data Value', 1),
    (91, N'Copyright', 23, N'Copyright Statement', 1),
    (92, N'ISBN', 23, N'ISBN', 1),
    (93, N'Edition', 23, N'Edition Statement', 1)

SET IDENTITY_INSERT [dbo].[Log_Fields] OFF
GO

/****** Object:  StoredProcedure [dbo].[Log_GetWorkEditionProperties]    Script Date: 15-11-2022 17:01:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Amit Samanta
-- Create date: November 15, 2022
-- Description:	Get Work Edition Property name for Audit Log
-- =============================================
ALTER PROCEDURE [dbo].[Log_GetWorkEditionProperties]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT ID, ISNULL(Alias, [Name]) AS [Name]
    FROM [dbo].[M_WorkEditionPropertyType] (NOLOCK)
END

/****** Object:  StoredProcedure [dbo].[CreateEdition]    Script Date: 14-11-2022 09:56:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Ahuva Freeman
-- Create date: 3/14/22
-- Description:	Create new work Edition
-- Modified On: 11/14/22
-- =============================================
ALTER PROCEDURE [dbo].[CreateEdition]
	-- Add the parameters for the stored procedure here
	@workID int,
	@title nvarchar(256),
	@indexTitle nvarchar(256),
	@apaTitle nvarchar(256),
	@pubImprintid int,
	@pubid int,
	@status int,
	@pubyear int,
	@shortName nvarchar(256),
	@userID int,
	@page NVARCHAR(500)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @AuditLog AuditLog
	DECLARE @date datetime2 = GETDATE()
	DECLARE @json nvarchar(max) = N'['
	DECLARE @temp TABLE
	(
		ID int
	  , IDString nvarchar(250)
	  , Title nvarchar(max)
	  , APATitle nvarchar(max)
	  , ShortName nvarchar(max)
	  , PubYear nvarchar(250)
	  , [Status] nvarchar(250)
	  , Publisher nvarchar(250)
	  , PublisherImprint nvarchar(250)
	)

	INSERT INTO WorkEdition
	(
		WorkID
	  , Title
	  , CitationTitle
	  , [Status]
	  , PublicationYear
	  , PublisherImprintID
	  , CreatedByID
	  , CreatedAt
	  , isLocked
	  , PublisherID
	  , ShortName
	  , apaTitle
	  , IndexTitle
	)
		OUTPUT INSERTED.ID AS ID
			, N'{"ES":1, "FID":82, "P":"' + @page + '", "NV":"' + CAST(INSERTED.ID as nvarchar(250)) + '" },' AS IDString
			, N'{"ES":1, "FID":83, "P":"' + @page + '", "NV":"' + REPLACE(REPLACE(INSERTED.Title, '"', '\"'), '''', '\''') + '" },' AS Title
			, N'{"ES":1, "FID":84, "P":"' + @page + '", "NV":"' + REPLACE(REPLACE(INSERTED.apaTitle, '"', '\"'), '''', '\''') + '" },' AS APATitle
			, N'{"ES":1, "FID":85, "P":"' + @page + '", "NV":"' + REPLACE(REPLACE(INSERTED.ShortName, '"', '\"'), '''', '\''') + '" },' AS ShortName
			, N'{"ES":1, "FID":86, "P":"' + @page + '", "NV":"' + CAST(INSERTED.PublicationYear as nvarchar(250)) + '" },' AS PubYear
			, N'{"ES":1, "FID":87, "P":"' + @page + '", "NV":"' + CAST(INSERTED.[Status] as nvarchar(250)) + '" },' AS [Status]
			, N'{"ES":1, "FID":88, "P":"' + @page + '", "NV":"' + CAST(INSERTED.PublisherID as nvarchar(250)) + '" },' AS Publisher
			, N'{"ES":1, "FID":89, "P":"' + @page + '", "NV":"' + CAST(INSERTED.PublisherImprintID as nvarchar(250)) + '" },' AS PublisherImprint
			INTO @temp
	VALUES
	(
		@workID
		,@title
		,@title
		,@status
		,@pubyear
		,@pubImprintid
		,@userID
		,@date
		,0
		,@pubid
		,@shortName
		,@apaTitle
		,@indexTitle
	)
	
	SET @json = @json + (SELECT t.[Status] + t.PublisherImprint + t.Publisher + t.PubYear + t.ShortName + t.APATitle + t.Title + t.IDString FROM @temp t)
	SET @json = (SELECT CASE WHEN RIGHT(@json, 1) = ',' THEN STUFF(@json, LEN(@json), 1, '') ELSE @json END)
	SET @json = @json + ']'
	
	DECLARE @EditionID = (SELECT TOP 1 ID FROM @temp)
	
	-- Save to Log_ProductHistory
    INSERT INTO @AuditLog(EntityID, EntityTypeID, ProductID, UserID, [Page], [JSON])
    VALUES(@EditionID, 10, 188, @userID, @page, @json)

    EXECUTE InsertLog @audit=@AuditLog, @json=@json

    -- return created editionId
    SELECT @EditionID
END

/****** Object:  StoredProcedure [dbo].[UpdateEditionPropertyData]    Script Date: 15-11-2022 17:40:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Ahuva Freeman
-- Create date: 3/3/22
-- Description:	Update Editions property data
-- =============================================
ALTER PROCEDURE [dbo].[UpdateEditionPropertyData]
	-- Add the parameters for the stored procedure here
	@editionID int,
	@propertyID int,
	@value nvarchar(max),
	@remove bit,
    @audit AuditLog READONLY
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    DECLARE @json NVARCHAR(MAX) = NULL,
        @page NVARCHAR(500) = (SELECT [Page] FROM @audit)

    DECLARE @temp TABLE (OldValue NVARCHAR(MAX))

	IF @remove = 1
	BEGIN
		DELETE pd
        OUTPUT N'[{"ES":2, "FID":90, "PID":' + CONVERT(NVARCHAR(25), @propertyID) + ', "P":"' + @page + '", "OV":"' + 
	        REPLACE(REPLACE(CAST(DELETED.DataValue AS NVARCHAR(MAX)), '"', '\"'), '''', '\''') + '"}]'
	        INTO @temp
		FROM WorkEditionPropertyData pd
		WHERE pd.WorkEditionID = @editionID
		    AND pd.WorkEditionPropertyTypeID = @propertyID
	END
	ELSE
	BEGIN
		IF EXISTS (SELECT 1 FROM WorkEditionPropertyData pd
					WHERE pd.WorkEditionID = @editionID
					AND pd.WorkEditionPropertyTypeID = @propertyID)
		BEGIN
			UPDATE pd
			SET pd.DataValue = @value
            OUTPUT 
                CASE WHEN DELETED.DataValue != @value
                    THEN N'[{"ES":3, "FID":90, "PID":' + CONVERT(NVARCHAR(25), @propertyID) + ', "P":"' + @page + '", "OV":"' +
		                    REPLACE(REPLACE(CAST(DELETED.DataValue AS NVARCHAR(MAX)), '"', '\"'), '''','\''') + '", "NV":"' +
		                    REPLACE(REPLACE(CAST(INSERTED.DataValue AS NVARCHAR(MAX)), '"','\"'),'''','\''') + '"}]'
                    ELSE ''
                END AS OldValue
		            INTO @temp
			FROM WorkEditionPropertyData pd
			WHERE pd.WorkEditionID = @editionID AND pd.WorkEditionPropertyTypeID = @propertyID
		END
		ELSE
		BEGIN
			INSERT INTO WorkEditionPropertyData(WorkEditionID, WorkEditionPropertyTypeID,DataValue)
            OUTPUT N'[{"ES":1, "FID":90, "PID":' + CONVERT(NVARCHAR(25), @propertyID) + ', "P":"' + @page + '",
		            "NV":"' + REPLACE(REPLACE(CAST(INSERTED.DataValue AS NVARCHAR(MAX)), '"', '\"'), '''', '\''') + '"}]'
                    INTO @temp
			VALUES(@editionID,@propertyID,@value)
		END
	END

    --INSERT AUDIT LOG
	SET @json = (SELECT t.OldValue FROM @temp t)

	EXECUTE InsertLog @audit=@audit, @json=@json
END

/****** Object:  StoredProcedure [dbo].[UpdateEditionDetails]    Script Date: 15-11-2022 19:47:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Ahuva Freeman
-- Create date: 3/3/22
-- Description:	Update Edition Metadata Details
-- =============================================
ALTER PROCEDURE [dbo].[UpdateEditionDetails]
	-- Add the parameters for the stored procedure here
	@ID int,
	@Title nvarchar(max),
	@IndexTitle nvarchar(max),
	@APATitle nvarchar(max),
	@Copyright nvarchar(max),
	@ISBN nvarchar(max) = null,
	@PubYear int,
	@Statement int,
	@userID int,
    @page nvarchar(500)
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    DECLARE @json NVARCHAR(MAX) = N'['

    DECLARE @TempTable1 TABLE (
		[Title] NVARCHAR(MAX),
		[APATitle] NVARCHAR(MAX),
		[Copyright] NVARCHAR(MAX),
		[PubYear] NVARCHAR(500),
        [Edition] NVARCHAR(500)
	)

    DECLARE @TempTable2 TABLE ([ISBN] NVARCHAR(MAX))

    -- workedition columns
	UPDATE e
	SET
		e.Title = @title,
		e.IndexTitle = @IndexTitle,
		e.aPATitle = @APATitle,
		e.CopyRight = @Copyright,
		e.PublicationYear = @PubYear,
		e.Edition = @Statement,
		e.LastModifiedAt = getdate(),
		e.LastModifiedByID = @userID
	OUTPUT
        CASE
            WHEN DELETED.Title != @Title
                THEN N'{ "ES":3, "FID":83, "P":"' + @page + ISNULL('", "OV":"' + REPLACE(REPLACE(DELETED.[Title], '"', '\"'), '''', '\'''), '') + ISNULL('", "NV":"' + REPLACE(REPLACE(INSERTED.[Title], '"', '\"'), '''', '\'''), '') + '" },'
            ELSE ''
        END AS [Title]
        , CASE
            WHEN DELETED.[aPATitle] IS NULL AND INSERTED.[aPATitle] IS NOT NULL
                THEN N'{ "ES":1, "FID":84, "P":"' + @page + '", "NV":"' + REPLACE(REPLACE(INSERTED.[aPATitle], '"', '\"'), '''', '\''') + '" },'
            WHEN DELETED.[aPATitle] IS NOT NULL AND INSERTED.[aPATitle] IS NULL
                THEN N'{ "ES":2, "FID":84, "P":"' + @page + '", "OV":"' + REPLACE(REPLACE(DELETED.[aPATitle], '"', '\"'), '''', '\''') + '" },'
            WHEN ISNULL(DELETED.[aPATitle], '') != ISNULL(INSERTED.[aPATitle], '')
                THEN N'{ "ES":3, "FID":84, "P":"' + @page + '", "OV":"' + REPLACE(REPLACE(DELETED.[aPATitle], '"', '\"'), '''', '\''') + '", "NV":"' + REPLACE(REPLACE(INSERTED.[aPATitle], '"', '\"'), '''', '\''') + '" },'
            ELSE '' 
        END AS [APATitle]
        , CASE
            WHEN DELETED.[PublicationYear] != @PubYear
                THEN N'{ "ES":3, "FID":86, "P":"' + @page + '", "OV":"' + CAST(DELETED.[PublicationYear] AS NVARCHAR(250)) + '", "NV":"' + CAST(INSERTED.[PublicationYear] AS NVARCHAR(250)) + '" },'
            ELSE ''
        END AS [PubYear]
        , CASE
            WHEN DELETED.[Copyright] IS NULL AND INSERTED.[Copyright] IS NOT NULL
                THEN N'{ "ES":1, "FID":91, "P":"' + @page + '", "NV":"' + REPLACE(REPLACE(INSERTED.[Copyright], '"', '\"'), '''', '\''') + '" },'
            WHEN DELETED.[Copyright] IS NOT NULL AND INSERTED.[Copyright] IS NULL
                THEN N'{ "ES":2, "FID":91, "P":"' + @page + '", "OV":"' + REPLACE(REPLACE(DELETED.[Copyright], '"', '\"'), '''', '\''') + '" },'
            WHEN ISNULL(DELETED.[Copyright], '') != ISNULL(INSERTED.[Copyright], '')
                THEN N'{ "ES":3, "FID":91, "P":"' + @page + '", "OV":"' + REPLACE(REPLACE(DELETED.[Copyright], '"', '\"'), '''', '\''') + '", "NV":"' + REPLACE(REPLACE(INSERTED.[Copyright], '"', '\"'), '''', '\''') + '" },'
            ELSE ''
        END AS [Copyright]
        , CASE
            WHEN DELETED.[Edition] IS NULL AND INSERTED.[Edition] IS NOT NULL
                THEN N'{ "ES":1, "FID":93, "P":"' + @page + '", "NV":"' + CAST(INSERTED.[Edition] AS NVARCHAR(250)) + '" },'
            WHEN DELETED.[Edition] IS NOT NULL AND INSERTED.[Edition] IS NULL
                THEN N'{ "ES":2, "FID":93, "P":"' + @page + '", "OV":"' + CAST(DELETED.[Edition] AS NVARCHAR(250)) + '" },'
            WHEN ISNULL(DELETED.[Edition], '') != ISNULL(INSERTED.[Edition], '')
                THEN N'{ "ES":3, "FID":93, "P":"' + @page + '", "OV":"' + CAST(DELETED.[Edition] AS NVARCHAR(250)) + '", "NV":"' + CAST(INSERTED.[Edition] AS NVARCHAR(250)) + '" },'
            ELSE ''
        END AS [Edition]
            INTO @TempTable1
    FROM WorkEdition e 
	WHERE e.ID = @ID

	IF EXISTS (SELECT 1 FROM WorkEditionISBN i (NOLOCK) WHERE i.WorkEditionID = @ID)
	BEGIN
		IF @ISBN IS NOT NULL
		BEGIN
			--update isbn
			UPDATE ei
			SET ei.ISBN = @ISBN
            OUTPUT CASE
                WHEN DELETED.ISBN != @ISBN
                THEN N'{ "ES":3, "FID":92, "P":"' + @page + '", "OV":"' + REPLACE(REPLACE(DELETED.ISBN, '"', '\"'), '''', '\''') + '", "NV":"' + REPLACE(REPLACE(INSERTED.ISBN, '"', '\"'), '''', '\''') + '" },'
                ELSE ''
            END AS [ISBN]
                INTO @TempTable2
			FROM WorkEditionISBN ei
			WHERE ei.WorkEditionID = @ID
		END
		ELSE
		BEGIN
			DELETE ei
            OUTPUT N'{ "ES":2, "FID":92, "P":"' + @page + '", "OV":"' + REPLACE(REPLACE(DELETED.ISBN, '"', '\"'), '''', '\''') + '" },'  AS [ISBN]
                INTO @TempTable2
			FROM WorkEditionISBN ei
			WHERE ei.WorkEditionID = @ID
		END
	END
	ELSE
	BEGIN
		INSERT INTO WorkEditionISBN(WorkEditionID,ISBN)
        OUTPUT N'{ "ES":1, "FID":92, "P":"' + @page + '", "NV":"' + REPLACE(REPLACE(INSERTED.ISBN, '"', '\"'), '''', '\''') + '" },'  AS [ISBN]
            INTO @TempTable2
		VALUES(@ID, @ISBN)
	END

    SET @json = @json + (SELECT t.[Title] + t.[aPATitle] + t.[PubYear] + t.[Edition] + t.[Copyright] FROM @TempTable1 t)
    SET @json = @json + (SELECT t.[ISBN] FROM @TempTable2 t)
    SET @json = (SELECT CASE WHEN RIGHT(@json, 1) = ',' THEN STUFF(@json, LEN(@json), 1, '') ELSE @json END)
    SET @json = @json + ']'

    -- insert into Log_ProductHistory
    EXECUTE InsertLog @audit=@audit, @json=@json
END

