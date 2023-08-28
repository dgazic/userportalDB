IF dbo.PostojiObjekt('User_Update') = 1 BEGIN
  DROP PROCEDURE User_Update
END
GO

CREATE PROCEDURE User_Update(
	@FirstName VARCHAR(255),
	@LastName VARCHAR(255),
	@UserRoleId INT,
	@UserId INT,
	@PhoneNumber VARCHAR(255)
)
AS
BEGIN
	UPDATE [User] 
	SET FirstName = @FirstName, LastName = @LastName, UserRoleId = @UserRoleId, PhoneNumber = @PhoneNumber
	WHERE Id = @UserId
	
END
GO