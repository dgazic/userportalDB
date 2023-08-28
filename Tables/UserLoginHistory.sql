    CREATE TABLE dbo.UserLoginHistory
    (
        Id				INT	IDENTITY(1,1) NOT NULL,
		SessionUuid		VARCHAR(100) NOT NULL,
		UserId			INT			NOT NULL,
		LoginDate		DATETIME	NOT NULL,
		LogoutDate		DATETIME	NULL,
		ApplicationType VARCHAR(20) NULL,
		DevicePlatform	VARCHAR(20) NULL,		
		DeviceVersion	VARCHAR(20) NULL,
		DeviceBrand		VARCHAR(30) NULL,
		DeviceModel		VARCHAR(30) NULL,
		Browser			VARCHAR(30) NULL,
		BrowserVersion	VARCHAR(30) NULL,
        CONSTRAINT PK_UserLoginHistory PRIMARY KEY (Id),
    )
