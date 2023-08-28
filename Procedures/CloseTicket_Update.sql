IF dbo.PostojiObjekt('CloseTicket_Update') = 1 BEGIN
  DROP PROCEDURE CloseTicket_Update
END
GO

CREATE PROCEDURE CloseTicket_Update(
	@Id INT
)
AS
BEGIN
	UPDATE UserPortalTicket_MantisBugTable 
	SET [status] = 90 
	WHERE Id = @Id 
	AND 
	(handler_id = 35 OR handler_id = 0)
END
GO
