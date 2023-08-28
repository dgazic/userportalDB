IF dbo.PostojiObjekt('PasswordReset_Update') = 1 BEGIN
  DROP PROCEDURE PasswordReset_Update
END
GO

CREATE PROCEDURE PasswordReset_Update(
	@Password VARBINARY(MAX),
	@SaltPassword VARBINARY(MAX),
	@Activated INT,
	@UserId INT
)
AS
BEGIN

	UPDATE [User] 
	SET [Password] = @Password, SaltPassword= @SaltPassword, Activated = @Activated
	WHERE Id = @UserId
	DELETE FROM PasswordReset WHERE UserId = @UserId
END
GO
