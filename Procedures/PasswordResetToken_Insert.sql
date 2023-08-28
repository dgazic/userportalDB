IF dbo.PostojiObjekt('PasswordResetToken_Insert') = 1 BEGIN
  DROP PROCEDURE PasswordResetToken_Insert
END
GO

CREATE PROCEDURE PasswordResetToken_Insert(
	@Email VARCHAR(255),
	@ResetPasswordToken VARBINARY(MAX)
)
AS
BEGIN
	DECLARE @UserId INT

	SELECT @UserId = Id FROM dbo.[User] WHERE Email = @Email

	INSERT PasswordReset(UserId,ActivationToken)
	VALUES (@UserId,@ResetPasswordToken)
END
GO
