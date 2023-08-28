CREATE TABLE MantisTicketStatus(
	Id INT IDENTITY(1,1),
	Code INT,
	Name VARCHAR(255),
)
ALTER TABLE MantisTicketStatus
ADD CONSTRAINT PK_MantisTicketStatus PRIMARY KEY(Id)

