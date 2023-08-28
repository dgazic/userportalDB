IF dbo.PostojiObjekt('GetTicketAttachment_Select') = 1 BEGIN
  DROP PROCEDURE GetTicketAttachment_Select
END
GO

CREATE PROCEDURE GetTicketAttachment_Select(
	@Id INT
)
AS
BEGIN
		SELECT 
		MantisBT.dbo.Convert2Default(mbft.filename) 'title',
		mbft.filesize 'size',
		mbft.file_type 'documentExtension',
		mbft.content 'documentData'
		FROM dbo.UserPortalTicket_MantisBugFileTable mbft
		WHERE mbft.bug_id = @Id
		ORDER BY mbft.bug_id DESC
END
GO