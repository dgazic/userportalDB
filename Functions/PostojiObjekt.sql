IF dbo.PostojiObjekt('PostojiObjekt') = 1 BEGIN
  DROP FUNCTION PostojiObjekt
END
GO

CREATE FUNCTION PostojiObjekt (@Ime varchar(255))
RETURNS int
AS
BEGIN

	DECLARE @Shema varchar(500)
	DECLARE @Tab varchar(500)
	DECLARE @UID int
	DECLARE @Rez int
	
	IF CHARINDEX('.', @Ime) > 0 BEGIN
		SELECT @Shema =  SUBSTRING(@Ime, 1, CHARINDEX('.', @Ime) - 1)
		SELECT @Tab =	 SUBSTRING(@Ime, CHARINDEX('.', @Ime) + 1, LEN(@Ime) - CHARINDEX('.', @Ime))
	END ELSE BEGIN
		SET @Shema = 'dbo'
		SET @Tab = @Ime
	END
	
	IF CAST(SUBSTRING(CAST(SERVERPROPERTY('productversion') AS VARCHAR),1,CAST(CHARINDEX('.', cast(SERVERPROPERTY('productversion') as varchar)) as int) - 1) as int) > 8 BEGIN
		SELECT @UID = [Schema_ID] FROM sys.schemas WHERE name = @Shema
	END ELSE BEGIN
		SELECT @UID = [uid] FROM sysusers WHERE name = @Shema
	END
	
	IF EXISTS (SELECT * FROM sysobjects WHERE UID = @UID AND name = @Tab) BEGIN
		SET @Rez = 1
	END ELSE BEGIN
		SET @Rez = 0
	END
	
	RETURN @Rez
END
GO
