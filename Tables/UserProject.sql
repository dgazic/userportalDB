CREATE TABLE UserProject(
	UserId INT NOT NULL,
	ProjectId INT NOT NULL
);

ALTER TABLE UserProject
ADD CONSTRAINT PK_UserProject PRIMARY KEY(UserId,ProjectId)

