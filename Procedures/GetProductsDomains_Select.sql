IF dbo.PostojiObjekt('GetProductDomains_Select') = 1 BEGIN
  DROP PROCEDURE GetProductDomains_Select
END
GO

CREATE PROCEDURE GetProductDomains_Select
(
	@ProductName VARCHAR(255)
)
AS BEGIN
	SELECT 
	mdp.Domena 'ProductDomain',
	mdp.Project 'ProductName'
	FROM 
	[UserPortal_MantisDomenaProject] mdp
	WHERE mdp.Project = @ProductName
END;
GO