CREATE TABLE [User](
	Id INT IDENTITY(1,1),
	Email VARCHAR(255),
	UserName VARCHAR(255) NULL,
	Password VARBINARY(MAX),
	SaltPassword VARBINARY(MAX),
	LastName VARCHAR(255),
	FirstName VARCHAR(255),
	Mobile VARCHAR(128),
	UserRoleId INT,
	Activated INT,
	HospitalId INT
);

ALTER TABLE [User]
ADD CONSTRAINT PK_User PRIMARY KEY(Id)
