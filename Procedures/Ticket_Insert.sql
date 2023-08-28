IF dbo.PostojiObjekt('Ticket_Insert') = 1 BEGIN
  DROP PROCEDURE Ticket_Insert
END
GO

CREATE PROCEDURE Ticket_Insert(
	@Abstract VARCHAR(255),
	@Description VARCHAR(MAX),
	@Type INT,
	@UserId INT
)
AS
BEGIN
	INSERT Ticket (Abstract,[Description], [Type], UserId)
	VALUES (@Abstract,@Description,@Type, @UserId)

END
GO