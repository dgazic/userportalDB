IF dbo.PostojiObjekt('GetHospitalProducts_Select') = 1 BEGIN
  DROP PROCEDURE GetHospitalProducts_Select
END
GO

CREATE PROCEDURE GetHospitalProducts_Select
(
	@UserHospital VARCHAR(255)
)
AS BEGIN
	SELECT DISTINCT
		ipt.name 'ProductName'
	FROM UserPortal_InternaClientContracted icc
	INNER JOIN UserPortal_InternaProductTable ipt ON ipt.Id = icc.ProductId
	INNER JOIN dbo.UserPortal_InternaClientTable ict ON ict.ID = icc.ClientID
	WHERE ict.ShortName = @UserHospital AND ipt.MantisProjectId IS NOT NULL
END;
GO


