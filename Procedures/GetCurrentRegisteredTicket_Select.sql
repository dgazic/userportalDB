IF dbo.PostojiObjekt('GetCurrentRegisteredTicket_Select') = 1 BEGIN
  DROP PROCEDURE GetCurrentRegisteredTicket_Select
END
GO

CREATE PROCEDURE GetCurrentRegisteredTicket_Select(
	@UserId INT
)
AS
BEGIN
	SET NOCOUNT ON
	SELECT TOP 1
	upm.TicketId 'Id'
	FROM UserPortalMantisBT upm
	WHERE (upm.UserId = @UserId)
	ORDER BY TicketId DESC

END
GO
