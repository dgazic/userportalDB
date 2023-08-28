IF dbo.PostojiObjekt('ActivationTokenGetUser_Select') = 1 BEGIN
  DROP PROCEDURE ActivationTokenGetUser_Select
END
GO

CREATE PROCEDURE ActivationTokenGetUser_Select(
	@ActivationToken VARCHAR(MAX)
)
AS
BEGIN
	SET NOCOUNT ON
	SELECT TOP 1
	u.Id,
	u.Username,
	u.Activated
	FROM dbo.PasswordReset pr
	INNER JOIN dbo.[User] u ON pr.UserId = u.Id
	WHERE pr.ActivationToken = @ActivationToken

END
GO




