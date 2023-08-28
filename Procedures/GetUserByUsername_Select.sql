IF dbo.PostojiObjekt('GetUserByUsername_Select') = 1 BEGIN
  DROP PROCEDURE GetUserByUsername_Select
END
GO

CREATE PROCEDURE GetUserByUsername_Select(
	@Username VARCHAR(255)
)
AS
BEGIN
	SET NOCOUNT ON
	SELECT TOP 1 u.*,
	c.ShortName 'Hospital',
	ISNULL(c.UserportalName,c.ShortName) 'UserportalHospitalName'
	FROM dbo.[User] u
	INNER JOIN [UserPortal_InternaClientTable] c ON c.Id = u.HospitalId
	WHERE (u.UserName = @Username) AND u.Activated = 1
END
GO