IF dbo.PostojiObjekt('User_Insert') = 1 BEGIN
  DROP PROCEDURE User_Insert
END
GO

CREATE PROCEDURE User_Insert(
	@Username VARCHAR(255),
	@Email VARCHAR(255),
	@LastName VARCHAR(255),
	@FirstName VARCHAR(255),
	@UserRoleId INT,
	@Password VARBINARY(MAX),
	@SaltPassword VARBINARY(MAX),
	@Activated INT,
	@ActivationToken VARBINARY(MAX),
	@AdministratorId INT,
	@PhoneNumber VARCHAR(255),
	@HospitalName VARCHAR(255)
)
AS
BEGIN
	DECLARE @UserId INT
	DECLARE @HospitalId INT
	--dodavanje korisnika od strane IN2 superUsera
	IF (@HospitalName IS NOT NULL)
	BEGIN
		SELECT TOP 1 @HospitalId = Id FROM dbo.UserPortal_InternaClientTable WHERE ShortName = @HospitalName ORDER BY id

		INSERT [User] (Username,Email, LastName, FirstName,UserRoleId, [Password] ,SaltPassword, Activated, HospitalId, PhoneNumber)
		VALUES (@Username,@Email, @LastName, @FirstName, @UserRoleId, @Password, @SaltPassword, @Activated, @HospitalId, @PhoneNumber)
	END
	--dodavanje korisnika od admina bolnice
	ELSE
	BEGIN
		SELECT @HospitalId = HospitalId FROM dbo.[User] WHERE Id = @AdministratorId
		INSERT [User] (Username,Email, LastName, FirstName,UserRoleId, [Password] ,SaltPassword, Activated, HospitalId, PhoneNumber)
		VALUES (@Username,@Email, @LastName, @FirstName, @UserRoleId, @Password, @SaltPassword, @Activated, @HospitalId, @PhoneNumber)
	END
	
	SET @UserId = (SELECT SCOPE_IDENTITY())
	INSERT PasswordReset(UserId,ActivationToken)
	VALUES (@UserId,@ActivationToken)

END
GO