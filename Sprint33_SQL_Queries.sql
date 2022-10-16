USE [Cms_Records]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
    (58, N'Status', 22, N'Status', 1),
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


/****** Object:  StoredProcedure [dbo].[CreateOrganization]    Script Date: 13-10-2022 21:03:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Ahuva Freeman
-- Create date: 8/1/22
-- Description:	Create new Organization
-- =============================================
ALTER PROCEDURE [dbo].[CreateOrganization]
	-- Add the parameters for the stored procedure here
	@Name NVARCHAR(1000),
	@StateID INT = NULL,
	@CountryID INT = NULL,
	@userID INT,
	@page NVARCHAR(500)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @json NVARCHAR(MAX) = N'[';
	DECLARE @temp TABLE(
		ID INT,
		IDString NVARCHAR(250),
		Organization NVARCHAR(MAX),
		[State] NVARCHAR(250),
		Country NVARCHAR(250)
	);

	INSERT INTO Organizations(OrganizationName, StateID, CountryID, CreatedAt, CreatedBy, [Status])
		OUTPUT INSERTED.ID AS ID
				, N'{ "ES":1, "FID":56, "P":"' + @page + '", "NV":"' + CAST(INSERTED.ID AS NVARCHAR(250)) +'" }, ' AS IDString
				, N'{ "ES":1, "FID":57, "P":"' + @page + '", "NV":"' + REPLACE(REPLACE(INSERTED.OrganizationName , '"','\"'),'''','\''')  + '" }, ' AS Organization
				, N'{ "ES":1, "FID":68, "P":"' + @page + '", "NV":"' + CAST(INSERTED.StateID AS NVARCHAR(250)) + '" }, '  AS [State]
				, N'{ "ES":1, "FID":69, "P":"' + @page + '", "NV":"' + CAST(INSERTED.CountryID AS NVARCHAR(250)) + '" }'  AS Country
			INTO @temp
	VALUES (@Name, @StateID, @CountryID, GETDATE(), @userID, 1)

    SET @json = @json  + (SELECT t.IDString + t.Organization + t.[State] + t.Country FROM @temp t)
    SET @json = @json + ']'
	
	SELECT TOP 1 ID FROM @temp
END
GO


/****** Object:  StoredProcedure [dbo].[UpdateOrganizationStatus]    Script Date: 13-10-2022 21:30:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Ahuva Freeman
-- Create date: 6/2/22
-- Description:	Update Organization Status
-- =============================================
ALTER PROCEDURE [dbo].[UpdateOrganizationStatus] 
	-- Add the parameters for the stored procedure here
	@OrganizationID INT,
	@Status INT,
	@IsPublish BIT = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @publishedOn DATETIME2(0) = GETDATE(),
		@json NVARCHAR(MAX) = N'[',
		@page NVARCHAR(500) = NULL

	DECLARE @temp TABLE (
		[Status] NVARCHAR(250),
		PublishedAt NVARCHAR(500)
	);

	UPDATE o
	SET 
		o.[Status] = @Status,
		o.PublishedAt = CASE WHEN @IsPublish = 1 THEN @publishedOn ELSE o.PublishedAt END
	OUTPUT 
		CASE WHEN DELETED.[Status] != @Status THEN N'{ "ES":3, "FID":58, "P":"' + @page + '", "OV":"' + CAST(DELETED.[Status] AS NVARCHAR(10)) + '", "NV":"' + CAST(INSERTED.[Status] AS NVARCHAR(10))+ '" }, ' ELSE '' END AS [Status]
	   , CASE WHEN ISNULL(DELETED.PublishedAt, '') != @publishedOn THEN N'{ "ES":3, "FID":76, "P":"' + @page + '", "OV":"' + CAST(DELETED.PublishedAt AS NVARCHAR(50)) + '", "NV":"' + CAST(INSERTED.PublishedAt AS NVARCHAR(50)) + '" }' ELSE '' END AS PublishedAt
	INTO @temp
	FROM Organizations o
	WHERE o.ID = @OrganizationID

	SET @json = @json + (SELECT t.[Status] + t.PublishedAt FROM @temp t)
	SET @json = (SELECT CASE WHEN RIGHT(@json, 2)=', ' THEN STUFF(@json, LEN(@json), 2, '') ELSE @json END)
	SET @json = @json + ']'
END
GO


/****** Object:  StoredProcedure [dbo].[UpdateOrganizationMetadata]    Script Date: 14-10-2022 14:17:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Ahuva Freeman
-- Create date: 6/3/22
-- Description:	Update Organization Metadata
-- =============================================
ALTER PROCEDURE [dbo].[UpdateOrganizationMetadata] 
	-- Add the parameters for the stored procedure here
	@ID int,
	@OrganizationName nvarchar(max),
	@Description nvarchar(max),
	@Mission nvarchar(max),
	@Keywords nvarchar(max),
	@ServicesProvided nvarchar(max),
	@userID int,
    @updateLastModified bit = 1
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @json NVARCHAR(MAX) = N'[',
		@page NVARCHAR(500) = NULL

	DECLARE @temp TABLE (
		[Name] NVARCHAR(MAX),
		[Description] NVARCHAR(MAX),
		[Mission] NVARCHAR(MAX),
		[Keywords] NVARCHAR(MAX),
		[ServicesProvided] NVARCHAR(MAX)
	);

	UPDATE o
	SET
		o.OrganizationName = @OrganizationName,
		o.[Description] = @Description,
		o.Mission = @Mission,
		o.Keywords = @Keywords,
		o.ServicesProvided = @ServicesProvided,
		o.ModifiedAt = CASE WHEN @updateLastModified = 1 THEN GETDATE() ELSE o.ModifiedAt END,
		o.ModifiedBy = CASE WHEN @updateLastModified = 1 THEN @userID ELSE o.ModifiedBy END
	OUTPUT
		CASE
            WHEN DELETED.Address1 IS NULL AND INSERTED.Address1 IS NOT NULL
                THEN N'{ "ES":1, "FID":65, "P":"' + @page + '", "NV":"' + REPLACE(REPLACE(INSERTED.Address1, '"', '\"'), '''', '\''') + '" }, '
            WHEN DELETED.Address1 IS NOT NULL AND INSERTED.Address1 IS NULL
                THEN N'{ "ES":2, "FID":65, "P":"' + @page + '", "OV":"' + REPLACE(REPLACE(DELETED.Address1, '"', '\"'), '''', '\''') + '" }, '
            WHEN ISNULL(DELETED.Address1, '') != ISNULL(INSERTED.Address1, '')
                THEN N'{ "ES":3, "FID":65, "P":"' + @page + '", "OV":"' + REPLACE(REPLACE(DELETED.Address1, '"', '\"'), '''', '\''') + '", "NV":"' + REPLACE(REPLACE(INSERTED.Address1, '"', '\"'), '''', '\''') + '" }, '
            ELSE ''
        END AS Address1
		, CASE
            WHEN DELETED.Address2 IS NULL AND INSERTED.Address2 IS NOT NULL
                THEN N'{ "ES":1, "FID":66, "P":"' + @page + '", "NV":"' + REPLACE(REPLACE(INSERTED.Address2, '"', '\"'), '''', '\''') + '" }, '
            WHEN DELETED.Address2 IS NOT NULL AND INSERTED.Address2 IS NULL
                THEN N'{ "ES":2, "FID":66, "P":"' + @page + '", "OV":"' + REPLACE(REPLACE(DELETED.Address2, '"', '\"'), '''', '\''') + '" }, '
            WHEN ISNULL(DELETED.Address2, '') != ISNULL(INSERTED.Address2, '')
                THEN N'{ "ES":3, "FID":66, "P":"' + @page + '", "OV":"' + REPLACE(REPLACE(DELETED.Address2, '"', '\"'), '''', '\''') + '", "NV":"' + REPLACE(REPLACE(INSERTED.Address2, '"', '\"'), '''', '\''') + '" }, '
            ELSE ''
        END AS Address2
		, CASE
            WHEN DELETED.City IS NULL AND INSERTED.City IS NOT NULL
                THEN N'{ "ES":1, "FID":67, "P":"' + @page + '", "NV":"' + REPLACE(REPLACE(INSERTED.City, '"', '\"'), '''', '\''') + '" }, '
            WHEN DELETED.City IS NOT NULL AND INSERTED.City IS NULL
                THEN N'{ "ES":2, "FID":67, "P":"' + @page + '", "OV":"' + REPLACE(REPLACE(DELETED.City, '"', '\"'), '''', '\''') + '" }, '
            WHEN ISNULL(DELETED.City, '') != ISNULL(INSERTED.City, '')
                THEN N'{ "ES":3, "FID":67, "P":"' + @page + '", "OV":"' + REPLACE(REPLACE(DELETED.City, '"', '\"'), '''', '\''') + '", "NV":"' + REPLACE(REPLACE(INSERTED.City, '"', '\"'), '''', '\''') + '" }, '
            ELSE ''
        END AS City
		, CASE
            WHEN DELETED.StateID IS NULL AND INSERTED.StateID IS NOT NULL
                THEN N'{ "ES":1, "FID":68, "P":"' + @page + '", "NV":"' + CAST(INSERTED.StateID AS NVARCHAR(10)) + '" }, '
            WHEN DELETED.StateID IS NOT NULL AND INSERTED.StateID IS NULL
                THEN N'{ "ES":2, "FID":68, "P":"' + @page + '", "OV":"' + CAST(DELETED.StateID AS NVARCHAR(10)) + '" }, '
            WHEN ISNULL(DELETED.StateID, '') != ISNULL(INSERTED.StateID, '')
                THEN N'{ "ES":3, "FID":68, "P":"' + @page + '", "OV":"' + CAST(DELETED.StateID AS NVARCHAR(10)) + '", "NV":"' + CAST(INSERTED.StateID AS NVARCHAR(10)) + '" }, '
            ELSE ''
        END AS StateID
		, CASE 
            WHEN DELETED.CountryID IS NULL AND INSERTED.CountryID IS NOT NULL
                THEN N'{ "ES":3, "FID":69, "P":"' + @page + '", "NV":"' + CAST(INSERTED.CountryID AS NVARCHAR(10)) + '" }, '
            WHEN DELETED.CountryID IS NOT NULL AND INSERTED.CountryID IS NULL
                THEN N'{ "ES":3, "FID":69, "P":"' + @page + '", "OV":"' + CAST(DELETED.CountryID AS NVARCHAR(10)) + '" }, '
            WHEN ISNULL(DELETED.CountryID, '') != ISNULL(INSERTED.CountryID, '')
                THEN N'{ "ES":3, "FID":69, "P":"' + @page + '", "OV":"' + CAST(DELETED.CountryID AS NVARCHAR(10)) + '", "NV":"' + CAST(INSERTED.CountryID AS NVARCHAR(10)) + '" }, '
            ELSE ''
        END AS CountryID
		, CASE 
            WHEN DELETED.Zip IS NULL AND INSERTED.Zip IS NOT NULL
                THEN N'{ "ES":1, "FID":70, "P":"' + @page + '", "NV":"' + REPLACE(REPLACE(INSERTED.Zip, '"', '\"'), '''', '\''') + '" }, '
            WHEN DELETED.Zip IS NOT NULL AND INSERTED.Zip IS NULL
                THEN N'{ "ES":2, "FID":70, "P":"' + @page + '", "OV":"' + REPLACE(REPLACE(DELETED.Zip, '"', '\"'), '''', '\''') + '" }, '
            WHEN ISNULL(DELETED.Zip, '') != ISNULL(INSERTED.Zip, '')
                THEN N'{ "ES":3, "FID":70, "P":"' + @page + '", "OV":"' + REPLACE(REPLACE(DELETED.Zip, '"', '\"'), '''', '\''') + '", "NV":"' + REPLACE(REPLACE(INSERTED.Zip, '"', '\"'), '''', '\''') + '" }, '
            ELSE ''
        END AS Zip
		, CASE 
            WHEN DELETED.Phone IS NULL AND INSERTED.Phone IS NOT NULL
                THEN N'{ "ES":1, "FID":71, "P":"' + @page + '", "NV":"' + REPLACE(REPLACE(INSERTED.Phone, '"', '\"'), '''', '\''') + '" }, '
            WHEN DELETED.Phone IS NOT NULL AND INSERTED.Phone IS NULL
                THEN N'{ "ES":2, "FID":71, "P":"' + @page + '", "OV":"' + REPLACE(REPLACE(DELETED.Phone, '"', '\"'), '''', '\''') + '" }, '
            WHEN ISNULL(DELETED.Phone, '') != ISNULL(INSERTED.Phone, '')
                THEN N'{ "ES":3, "FID":71, "P":"' + @page + '", "OV":"' + REPLACE(REPLACE(DELETED.Phone, '"', '\"'), '''', '\''') + '", "NV":"' + REPLACE(REPLACE(INSERTED.Phone, '"', '\"'), '''', '\''') + '" }, '
            ELSE ''
        END AS Phone
		, CASE
            WHEN DELETED.TollFree IS NULL AND INSERTED.TollFree IS NOT NULL
                THEN N'{ "ES":1, "FID":72, "P":"' + @page + '", "NV":"' + REPLACE(REPLACE(INSERTED.TollFree, '"', '\"'), '''', '\''') + '" }, '
            WHEN DELETED.TollFree IS NOT NULL AND INSERTED.TollFree IS NULL
                THEN N'{ "ES":2, "FID":72, "P":"' + @page + '", "OV":"' + REPLACE(REPLACE(DELETED.TollFree, '"', '\"'), '''', '\''') + '" }, '
            WHEN ISNULL(DELETED.TollFree, '') != ISNULL(INSERTED.TollFree, '')
                THEN N'{ "ES":3, "FID":72, "P":"' + @page + '", "OV":"' + REPLACE(REPLACE(DELETED.TollFree, '"', '\"'), '''', '\''') + '", "NV":"' + REPLACE(REPLACE(INSERTED.TollFree, '"', '\"'), '''', '\''') + '" }, '
            ELSE ''
        END AS TollFree
		, CASE 
            WHEN DELETED.Email IS NULL AND INSERTED.Email IS NOT NULL 
                THEN N'{ "ES":1, "FID":73, "P":"' + @page + '", "NV":"' + REPLACE(REPLACE(INSERTED.Email, '"', '\"'), '''', '\''') + '" }, '
            WHEN DELETED.Email IS NOT NULL AND INSERTED.Email IS NULL
                THEN N'{ "ES":2, "FID":73, "P":"' + @page + '", "OV":"' + REPLACE(REPLACE(DELETED.Email, '"', '\"'), '''', '\''') + '" }, '
            WHEN ISNULL(DELETED.Email, '') != ISNULL(INSERTED.Email, '')
                THEN N'{ "ES":3, "FID":73, "P":"' + @page + '", "OV":"' + REPLACE(REPLACE(DELETED.Email, '"', '\"'), '''', '\''') + '", "NV":"' + REPLACE(REPLACE(INSERTED.Email, '"', '\"'), '''', '\''') + '" }, '
            ELSE ''
        END AS Email
		, CASE 
            WHEN DELETED.[URL] IS NULL AND INSERTED.[URL] IS NOT NULL
                THEN N'{ "ES":1, "FID":74, "P":"' + @page + '", "NV":"' + REPLACE(REPLACE(INSERTED.[URL], '"', '\"'), '''', '\''') + '" }, '
            WHEN DELETED.[URL] IS NOT NULL AND INSERTED.[URL] IS NULL
                THEN N'{ "ES":2, "FID":74, "P":"' + @page + '", "OV":"' + REPLACE(REPLACE(DELETED.[URL], '"', '\"'), '''', '\''') + '" }, '
            WHEN ISNULL(DELETED.[URL], '') != ISNULL(INSERTED.[URL], '')
                THEN N'{ "ES":3, "FID":74, "P":"' + @page + '", "OV":"' + REPLACE(REPLACE(DELETED.[URL], '"', '\"'), '''', '\''') + '", "NV":"' + REPLACE(REPLACE(INSERTED.[URL], '"', '\"'), '''', '\''') + '" }, '
            ELSE ''
        END AS [URL]
		, CASE
            WHEN DELETED.[SocialMedia] IS NULL AND INSERTED.[SocialMedia] IS NOT NULL
                THEN N'{ "ES":1, "FID":75, "P":"' + @page + '", "NV":"' + REPLACE(REPLACE(INSERTED.SocialMedia, '"', '\"'), '''', '\''') + '" }, '
            WHEN DELETED.[SocialMedia] IS NOT NULL AND INSERTED.[SocialMedia] IS NULL
                THEN N'{ "ES":2, "FID":75, "P":"' + @page + '", "OV":"' + REPLACE(REPLACE(DELETED.SocialMedia, '"', '\"'), '''', '\''') + '" }, '
            WHEN ISNULL(DELETED.[SocialMedia], '') != ISNULL(INSERTED.[SocialMedia], '')
                THEN N'{ "ES":3, "FID":75, "P":"' + @page + '", "OV":"' + REPLACE(REPLACE(DELETED.SocialMedia, '"', '\"'), '''', '\''') + '", "NV":"' + REPLACE(REPLACE(INSERTED.SocialMedia, '"', '\"'), '''', '\''') + '" }, '
            ELSE '' 
        END AS [SocialMedia]
			INTO @temp
	FROM Organizations o
	WHERE o.ID = @ID

	SET @json = @json + (SELECT t.[Name] + t.[Description] + t.[Mission] + t.[Keywords] + t.[ServicesProvided] FROM @temp t)
	SET @json  = (SELECT CASE WHEN RIGHT(@json, 2) = ',' THEN STUFF(@json, LEN(@json), 2, '') ELSE @json END)
	SET @json = @json + ']'
END
GO


/****** Object:  StoredProcedure [dbo].[UpdateOrganizationAddress]    Script Date: 16-10-2022 16:42:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Ahuva Freeman
-- Create date: 6/3/22
-- Description:	Update Organization Address data
-- Modified On: 10/11/22 by Amit Samanta
-- =============================================
ALTER PROCEDURE [dbo].[UpdateOrganizationAddress]
	-- Add the parameters for the stored procedure here
	@address [Address] READONLY,
	@userID int,
    @updateLastModified bit = 1
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    DECLARE @json NVARCHAR(MAX) = N'[',
	    @page NVARCHAR(500) = NULL

    DECLARE @temp TABLE (
	    Address1 NVARCHAR(500),
        Address2 NVARCHAR(500),
        City NVARCHAR(500),
        StateID NVARCHAR(500),
        CountryID NVARCHAR(500),
        Zip NVARCHAR(500),
        Phone NVARCHAR(MAX),
        TollFree NVARCHAR(MAX),
        Email NVARCHAR(MAX),
        [URL] NVARCHAR(MAX),
        SocialMedia NVARCHAR(MAX)
    );

	UPDATE o
	SET 
		o.Address1 = a.Address1,
		o.Address2 = a.Address2,
		o.City = a.City,
		o.StateID = a.StateID,
		o.CountryID = a.CountryID,
		o.Zip = a.Zip,
		o.Phone = a.Phone,
		o.TollFree = a.TollFree,
		o.Email = a.Email,
		o.[URL] = a.[URL],
		o.SocialMedia = a.SocialMedia,
		o.ModifiedAt = CASE WHEN @updateLastModified = 1 THEN GETDATE() ELSE o.ModifiedAt END,
		o.ModifiedBy = CASE WHEN @updateLastModified = 1 THEN @userID ELSE o.ModifiedBy END
    OUTPUT
        CASE WHEN ISNULL(DELETED.Address1, '') != ISNULL(a.Address1, '') THEN N'{ "ES":3, "FID":65, "P":"' + @page + ISNULL('", "OV":"' + REPLACE(REPLACE(DELETED.Address1, '"', '\"'), '''', '\'''), '') + ISNULL('", "NV":"' + REPLACE(REPLACE(INSERTED.Address1, '"', '\"'), '''', '\'''), '') + '" }, ' ELSE '' END AS Address1
		, CASE WHEN ISNULL(DELETED.Address2, '') != ISNULL(a.Address2, '') THEN N'{ "ES":3, "FID":66, "P":"' + @page + ISNULL('", "OV":"' + REPLACE(REPLACE(DELETED.Address2, '"', '\"'), '''', '\'''), '') + ISNULL('", "NV":"' + REPLACE(REPLACE(INSERTED.Address2, '"', '\"'), '''', '\'''), '') + '" }, ' ELSE '' END AS Address2
		, CASE WHEN ISNULL(DELETED.City, '') != ISNULL(a.City, '') THEN N'{ "ES":3, "FID":67, "P":"' + @page + ISNULL('", "OV":"' + REPLACE(REPLACE(DELETED.City, '"', '\"'), '''', '\'''), '') + COALESCE('", "NV":"' + REPLACE(REPLACE(INSERTED.City, '"', '\"'), '''', '\'''), '') + '" }, ' ELSE '' END AS City
		, CASE WHEN ISNULL(DELETED.StateID, -1) != ISNULL(a.StateID, -1) THEN N'{ "ES":3, "FID":68, "P":"' + @page + ISNULL('", "OV":"' + CAST(DELETED.StateID AS NVARCHAR(10)), '') + ISNULL('", "NV":"' + CAST(INSERTED.StateID AS NVARCHAR(10)), '') + '" }, ' ELSE '' END AS StateID
		, CASE WHEN ISNULL(DELETED.CountryID, -1) != ISNULL(a.CountryID, -1) THEN N'{ "ES":3, "FID":69, "P":"' + @page + ISNULL('", "OV":"' + CAST(DELETED.CountryID AS NVARCHAR(10)), '') + ISNULL('", "NV":"' + CAST(INSERTED.CountryID AS NVARCHAR(10)), '') + '" }, ' ELSE '' END AS CountryID
		, CASE WHEN ISNULL(DELETED.Zip, '') != ISNULL(a.Zip, '') THEN N'{ "ES":3, "FID":70, "P":"' + @page + ISNULL('", "OV":"' + REPLACE(REPLACE(DELETED.Zip, '"', '\"'), '''', '\'''), '') + ISNULL('", "NV":"' + REPLACE(REPLACE(INSERTED.Zip, '"', '\"'), '''', '\'''), '') + '" }, ' ELSE '' END AS Zip
		, CASE WHEN ISNULL(DELETED.Phone, '') != ISNULL(a.Phone, '') THEN N'{ "ES":3, "FID":71, "P":"' + @page + ISNULL('", "OV":"' + REPLACE(REPLACE(DELETED.Phone, '"', '\"'), '''', '\'''), '') + ISNULL('", "NV":"' + REPLACE(REPLACE(INSERTED.Phone, '"', '\"'), '''', '\'''), '') + '" }, ' ELSE '' END AS Phone
		, CASE WHEN ISNULL(DELETED.TollFree, '') != ISNULL(a.TollFree, '') THEN N'{ "ES":3, "FID":72, "P":"' + @page + ISNULL('", "OV":"' + REPLACE(REPLACE(DELETED.TollFree, '"', '\"'), '''', '\'''), '') + ISNULL('", "NV":"' + REPLACE(REPLACE(INSERTED.TollFree, '"', '\"'), '''', '\'''), '') + '" }, ' ELSE '' END AS TollFree
		, CASE WHEN ISNULL(DELETED.Email, '') != ISNULL(a.Email, '') THEN N'{ "ES":3, "FID":73, "P":"' + @page + ISNULL('", "OV":"' + REPLACE(REPLACE(DELETED.Email, '"', '\"'), '''', '\'''), '') + ISNULL('", "NV":"' + REPLACE(REPLACE(INSERTED.Email, '"', '\"'), '''', '\'''), '') + '" }, ' ELSE '' END AS Email
		, CASE WHEN ISNULL(DELETED.[URL], '') != ISNULL(a.[URL], '') THEN N'{ "ES":3, "FID":74, "P":"' + @page + ISNULL('", "OV":"' + REPLACE(REPLACE(DELETED.[URL], '"', '\"'), '''', '\'''), '') + ISNULL('", "NV":"' + REPLACE(REPLACE(INSERTED.[URL], '"', '\"'), '''', '\'''), '') + '" }, ' ELSE '' END AS [URL]
		, CASE WHEN ISNULL(DELETED.SocialMedia, '') != ISNULL(a.SocialMedia, '') THEN N'{ "ES":3, "FID":75, "P":"' + @page + ISNULL('", "OV":"' + REPLACE(REPLACE(DELETED.SocialMedia, '"', '\"'), '''', '\'''), '') + ISNULL('", "NV":"' + REPLACE(REPLACE(INSERTED.SocialMedia, '"', '\"'), '''', '\'''), '') + '" }, ' ELSE '' END AS SocialMedia
            INTO @temp
	FROM Organizations o
	INNER JOIN @address a ON o.ID = a.ID

	SET @json = @json + (SELECT t.[Address1] + t.[Address1] + t.[City] + t.[StateID] + t.[CountryID]+ t.[Zip]+ t.[Phone]+ t.[TollFree]+ t.[Email]+ t.[URL]+ t.[SocialMedia] FROM @temp t)
	SET @json  = (SELECT CASE WHEN RIGHT(@json, 2) = ',' THEN STUFF(@json, LEN(@json), 2, '') ELSE @json END)
	SET @json = @json + ']'
END
GO


/****** Object:  StoredProcedure [dbo].[DeleteOrganization]    Script Date: 16-10-2022 18:50:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Ahuva Freeman
-- Create date: 8/2/2022
-- Description:	Delete Organization
-- =============================================
ALTER PROCEDURE [dbo].[DeleteOrganization]
	-- Add the parameters for the stored procedure here
	@ID int,
	@UserID int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @json NVARCHAR(MAX) = null,
		@page NVARCHAR(500) = NULL

	DECLARE @temp TABLE (OldVal NVARCHAR(MAX));

	UPDATE o
	SET o.IsDeleted = 1,
		o.DeletedAt = GETDATE(),
		o.DeletedByID = @userID
	OUTPUT N'[{ "ES":2, "FID":56, "P":"' + @page + '", "OV":"' + CAST(DELETED.ID AS NVARCHAR(250)) + '" }]' AS OldVal
    	INTO @temp
	FROM Organizations o
	WHERE o.ID = @ID

	SET @json = (SELECT t.OldVal FROM @temp t)
END
GO