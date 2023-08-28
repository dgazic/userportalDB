IF dbo.PostojiObjekt('GetClient') = 1 BEGIN
  DROP FUNCTION GetClient
END
GO



CREATE FUNCTION GetClient(@UserId INT) RETURNS VARCHAR(255)
AS
BEGIN
	DECLARE @Klijent VARCHAR(255)

	SELECT @Klijent = ShortName FROM [UserPortal_InternaClientTable] c
	INNER JOIN dbo.[User] u ON u.HospitalId = c.Id
	WHERE u.Id = @UserId
	
	RETURN @Klijent
END
GO
