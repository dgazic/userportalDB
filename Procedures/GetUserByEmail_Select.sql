IF dbo.PostojiObjekt('GetUserByEmail_Select') = 1 BEGIN
  DROP PROCEDURE GetUserByEmail_Select
END
GO

CREATE PROCEDURE GetUserByEmail_Select(
	@Email VARCHAR(255)
)
AS
BEGIN
	SET NOCOUNT ON
	SELECT TOP 1
	u.Username
	FROM dbo.[User] u
	WHERE (u.Email = @Email)
END
GO