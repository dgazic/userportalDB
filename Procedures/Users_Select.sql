IF dbo.PostojiObjekt('Users_Select') = 1 BEGIN
  DROP PROCEDURE Users_Select
END
GO

CREATE PROCEDURE Users_Select(
@UserHospital VARCHAR(MAX),
@UserRoleId INT
)
AS BEGIN



	--pregled korisnika kao Administrator bolnice
	IF (@UserRoleId <> 3)
	BEGIN
		SELECT u.*, 	
			CASE 
				WHEN UserRoleId = 1 THEN 'Administrator'
			ELSE 'Obièan korisnik'
			END UserRoleName 
		FROM [User] u
		INNER JOIN UserPortal_InternaClientTable ict ON u.HospitalId = ict.id
		WHERE ict.shortName = @UserHospital
	   AND u.Id <> 1 --bis-podrska user
	END
	--pregled korisnika kao superAdministrator - IN2
	ELSE
	BEGIN
		SELECT u.*,ict.ShortName 'Hospital', 	
			CASE 
				WHEN UserRoleId = 1 THEN 'Administrator'
			ELSE 'Obièan korisnik'
			END UserRoleName 
		FROM [User] u
		INNER JOIN UserPortal_InternaClientTable ict ON u.HospitalId = ict.id
	END
END;
GO