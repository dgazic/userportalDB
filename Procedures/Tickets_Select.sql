IF dbo.PostojiObjekt('Tickets_Select') = 1 BEGIN
  DROP PROCEDURE Tickets_Select
END
GO

CREATE PROCEDURE Tickets_Select
AS BEGIN
   SELECT * FROM Ticket
END;
GO