IF dbo.PostojiObjekt('GetHospitalUsers_Select') = 1 BEGIN
  DROP PROCEDURE GetHospitalUsers_Select
END
GO

CREATE PROCEDURE GetHospitalUsers_Select(
	@HospitalName VARCHAR(255)
)
AS BEGIN

    IF LEN(@HospitalName) = 0
	    SET @HospitalName = NULL

	SELECT ISNULL(u.LastName,'') + ' ' + ISNULL(u.FirstName, '') 'LastNameFirstName'
		FROM [dbo].[User] u
		INNER JOIN dbo.UserPortal_InternaClientTable ict ON ict.id = u.HospitalId
		WHERE (@HospitalName IS NULL OR ict.ShortName = @HospitalName)
		OPTION(RECOMPILE)
END;
GO