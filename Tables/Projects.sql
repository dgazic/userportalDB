CREATE TABLE Projects(
	Id INT IDENTITY(1,1),
	Name VARCHAR(255),
	Code VARCHAR(255),
	ProductId INT
)

ALTER TABLE Projects
ADD CONSTRAINT PK_Projects PRIMARY KEY(id)