CREATE TABLE UserPortalMantisBT(
	UserId INT NOT NULL,
	TicketId INT NOT NULL
)

ALTER TABLE UserPortalMantisBT
ADD CONSTRAINT PK_UserPortalMantisBT PRIMARY KEY(UserId,TicketId)

