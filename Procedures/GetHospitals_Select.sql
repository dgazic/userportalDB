IF dbo.PostojiObjekt('GetHospitals_Select') = 1 BEGIN
  DROP PROCEDURE GetHospitals_Select
END
GO

CREATE PROCEDURE GetHospitals_Select
AS BEGIN
	SELECT MIN(Id), ShortName 'ShortName' FROM dbo.UserPortal_InternaClientTable
	GROUP BY ShortName
END;
GO
