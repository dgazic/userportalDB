IF dbo.PostojiObjekt('LoginData_Select') = 1 BEGIN
  DROP PROCEDURE LoginData_Select
END
GO

CREATE PROCEDURE LoginData_Select(
	@Username VARCHAR(255)
)
AS
BEGIN
	SET NOCOUNT ON
	SELECT TOP 1
	u.Username,
	u.[Password],
	u.SaltPassword
	FROM dbo.[User] u
	WHERE (u.UserName = @Username OR u.Email = @Username) AND u.Activated = 1

END
GO

