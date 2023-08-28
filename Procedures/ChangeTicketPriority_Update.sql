IF dbo.PostojiObjekt('ChangeTicketPriority_Update') = 1 BEGIN
  DROP PROCEDURE ChangeTicketPriority_Update
END
GO

CREATE PROCEDURE ChangeTicketPriority_Update(
	@Id INT,
	@Priority VARCHAR(255)
)
AS
BEGIN

	DECLARE @PriorityMantisCode INT
	IF @Priority = 'Normalni'
		SET @PriorityMantisCode = 30
	ELSE IF @Priority = 'Ništa'
		SET @PriorityMantisCode = 10
	ELSE IF @Priority = 'Niski'
		SET @PriorityMantisCode = 20
	ELSE IF @Priority = 'Visoki'
		SET @PriorityMantisCode = 40
	ELSE IF @Priority = 'Hitno'
		SET @PriorityMantisCode = 50
	ELSE IF @Priority = 'Trenutno'
		SET @PriorityMantisCode = 60


	UPDATE UserPortalTicket_MantisBugTable 
	SET [priority] = @PriorityMantisCode
	WHERE Id = @Id 
END
GO