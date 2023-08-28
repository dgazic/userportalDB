IF dbo.PostojiObjekt('ActivateDeactivateUser_Update') = 1 BEGIN
  DROP PROCEDURE ActivateDeactivateUser_Update
END
GO

CREATE PROCEDURE ActivateDeactivateUser_Update(
	@UserId INT
)
AS 
BEGIN
	DECLARE @Activated INT

	SELECT @Activated = Activated FROM dbo.[User] WHERE Id = @UserId

	IF @Activated = 1 BEGIN
		SET @Activated = 0
	END
	ELSE BEGIN
		SET @Activated = 1
	END

	UPDATE [User] SET Activated = @Activated WHERE Id = @UserId

END
GO
