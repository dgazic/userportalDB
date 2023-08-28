IF dbo.PostojiObjekt('User_Delete') = 1 BEGIN
  DROP PROCEDURE User_Delete
END
GO

CREATE PROCEDURE User_Delete(
	@UserId INT
)
AS
BEGIN
	DELETE FROM dbo.PasswordReset WHERE UserId = @UserId
	DELETE FROM dbo.[User] WHERE Id = @UserId
END
GO