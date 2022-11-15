USE [Cms_Records]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER TABLE
  [dbo].[Log_ProductHistory]
ALTER COLUMN
  [ProductID]
    INT NULL;
GO

SET IDENTITY_INSERT [dbo].[M_EntityTypes] ON

INSERT [dbo].[M_EntityTypes] ([ID], [Name], [ParentID])
VALUES (13, N'Organization', NULL), (14, N'Person', NULL)

SET IDENTITY_INSERT [dbo].[M_EntityTypes] OFF
GO

SET IDENTITY_INSERT [dbo].[Log_TableNames] ON

INSERT [dbo].[Log_TableNames] ([ID], [TableName], [DatabaseConnectionID])
VALUES (22, N'Organizations', 7)

SET IDENTITY_INSERT [dbo].[Log_TableNames] OFF
GO

SET IDENTITY_INSERT [dbo].[Log_Fields] ON

INSERT [dbo].[Log_Fields] ([ID], [FieldName], [TableID], [DisplayName], [ShowInLog])
VALUES 
	(56, N'ID', 22, N'Organization ID', 1),
    (57, N'OrganizationName', 22, N'Organization', 1),
    (58, N'StatusID', 22, N'Status', 1),
    (59, N'Keywords', 22, N'Keywords', 1),
    (60, N'Description', 22, N'Description', 1),
    (61, N'Mission', 22, N'Mission', 1),
    (62, N'ServicesProvided', 22, N'Services Provided', 1),
    (63, N'RestrictedLocationID', 22, N'State Restrictions', 1),
    (64, N'RestrictedLocationID', 22, N'Country Restrictions', 1),
    (65, N'Address1', 22, N'Address 1', 1),
    (66, N'Address2', 22, N'Address 2', 1),
    (67, N'City', 22, N'City', 1),
    (68, N'StateID', 22, N'State', 1),
    (69, N'CountryID', 22, N'Country', 1),
    (70, N'Zip', 22, N'Zip', 1),
    (71, N'Phone', 22, N'Phone', 1),
    (72, N'Tollfree', 22, N'Toll Free Phone', 1),
    (73, N'Email', 22, N'Email', 1),
    (74, N'URL', 22, N'URL', 1),
    (75, N'SocialMedia', 22, N'Social Media', 1),
    (76, N'PublishedAt', 22, N'Published Date', 1),
    (77, N'IsLocked', 22, N'Locked', 1),
    (78, N'LockedByID', 22, N'Locked By', 1),
    (79, N'IsDeleted', 22, N'Deleted', 1),
    (80, N'DeletedByID', 22, N'Deleted By', 1),
    (81, N'DeletedAt', 22, N'Deleted Date', 1)

SET IDENTITY_INSERT [dbo].[Log_Fields] OFF
GO


-- CMSS-2291
USE [Cms_Records]
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
    (90, N'DataValue', 23, N'Data Value', 1)

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
