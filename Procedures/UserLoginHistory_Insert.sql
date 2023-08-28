IF dbo.PostojiObjekt('UserLoginHistory_Insert') = 1 BEGIN
  DROP PROCEDURE UserLoginHistory_Insert
END
GO

CREATE PROCEDURE dbo.UserLoginHistory_Insert
(
    @SessionUuid VARCHAR(100),
	@UserId INT,
	@ApplicationType VARCHAR(20),
	@DevicePlatform VARCHAR(20),
	@DeviceVersion VARCHAR(20),
	@DeviceBrand VARCHAR(30),
	@DeviceModel VARCHAR(30),
	@Browser VARCHAR(30),
	@BrowserVersion VARCHAR(30)
)
AS
BEGIN
    INSERT dbo.UserLoginHistory (SessionUuid, UserId, LoginDate, LogoutDate, ApplicationType, DevicePlatform, DeviceVersion, DeviceBrand, DeviceModel, Browser, BrowserVersion)
    VALUES (@SessionUuid, @UserId, GETDATE(), NULL, @ApplicationType, @DevicePlatform, @DeviceVersion, @DeviceBrand, @DeviceModel, @Browser, @BrowserVersion)
END
