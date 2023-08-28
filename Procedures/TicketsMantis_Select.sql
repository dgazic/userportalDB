IF dbo.PostojiObjekt('TicketsMantis_Select') = 1 BEGIN
  DROP PROCEDURE TicketsMantis_Select
END
GO

CREATE PROCEDURE TicketsMantis_Select(
	@UserRoleId INT,
	@UserId INT,
	@EnrollmentTimeDateFrom VARCHAR(255),
	@EnrollmentTimeDateTo VARCHAR(255)
)
AS
BEGIN
	
	SET NOCOUNT ON;
	DECLARE @HospitalId INT
	SELECT @HospitalId = HospitalId FROM dbo.[User] WHERE Id = @UserId

	DECLARE @HospitalShortName VARCHAR(255)

	SELECT @HospitalShortName = ShortName FROM UserPortal_InternaClientTable WHERE ID = @HospitalId	


	CREATE TABLE #Mappings (TypeId SMALLINT, Original VARCHAR(255), Converted VARCHAR(255))

	;WITH Podaci AS (SELECT DISTINCT value FROM UserPortalTicket_MantisCustomFieldStringTable WHERE field_id = 1)
	INSERT #Mappings
	SELECT 1, p.value, MantisBT.dbo.Convert2Default(p.value) FROM Podaci p

	;WITH Podaci AS (SELECT DISTINCT value FROM UserPortalTicket_MantisCustomFieldStringTable WHERE field_id = 23)
	INSERT #Mappings
	SELECT 23, p.value, MantisBT.dbo.Convert2Default(p.value) FROM Podaci p

	;WITH Podaci AS (SELECT DISTINCT value FROM UserPortalTicket_MantisCustomFieldStringTable WHERE field_id = 56)
	INSERT #Mappings
	SELECT 56, p.value, MantisBT.dbo.Convert2Default(p.value) FROM Podaci p

	CREATE TABLE #tempT (Id INT, [Status] SMALLINT, Category SMALLINT,ProductId INT, DomainName VARCHAR(MAX) ,ClientProductCurrentVersion VARCHAR(255), HospitalName VARCHAR(255),HospitalId INT, Dodijeljen BIT, Analiza BIT,Razvoj BIT, Rijesen BIT, Zatvoren BIT, IsporukaVerzija BIT, Isporucen BIT)
	--Administrator(Bolnica)
	IF @UserRoleId = 1 BEGIN
		
		INSERT INTO #tempT(Id,[Status],Category, ProductId,DomainName,ClientProductCurrentVersion)
		SELECT mbt.id, mbt.[status],mbt.category_id, ipt.ID, ISNULL(mcfst3.value,mcfst2.value) ,(SELECT TOP 1 iv.Code
																FROM dbo.UserPortal_InternaDeployRequest dp 
																INNER JOIN dbo.UserPortal_InternaClientContracted c ON c.ID = dp.ContractedID
																INNER JOIN dbo.UserPortal_InternaClientTable cl ON cl.ID = c.ClientId
																INNER JOIN UserPortalTicket_InternaVersion iv ON iv.ID = dp.VersionID
																INNER JOIN UserPortalTicket_InternaTask t ON t.VersionID = iv.ID
																INNER JOIN dbo.UserPortal_InternaProductTable p ON p.ID = iv.ProductID
																WHERE cl.shortname = @HospitalShortName AND p.ID = ipt.id
																ORDER BY iv.Code DESC) 
		FROM UserPortalTicket_MantisBugTable mbt
        INNER JOIN UserPortalMantisBT upmbt ON upmbt.TicketId = mbt.id
		INNER JOIN UserPortalTicket_MantisCustomFieldStringTable mcfst ON mcfst.bug_id = mbt.id    
		INNER JOIN UserPortalTicket_MantisProjectTable mpt ON mpt.id = mbt.project_id
		INNER JOIN dbo.UserPortal_InternaProductTable ipt ON ipt.MantisProjectID = mpt.id
		LEFT JOIN UserPortalTicket_MantisCustomFieldStringTable mcfst2 ON mcfst2.bug_id = mbt.id AND mcfst2.field_id = 23
		LEFT JOIN dbo.UserPortalTicket_MantisCustomFieldStringTable mcfst3 ON mcfst3.bug_id = mbt.id AND mcfst3.field_id = 56
        WHERE 
			DATEADD(ss,mbt.date_submitted, '1/1/1970 01:00:00') BETWEEN @EnrollmentTimeDateFrom AND DATEADD(s,-1,DATEADD(d,1,@EnrollmentTimeDateTo)) 
			AND (MantisBT.dbo.Convert2Default(mcfst.value) = @HospitalShortName AND mcfst.field_id = 1)
			AND  MantisBT.dbo.Convert2Default(mpt.name) NOT LIKE '#%' 
			AND mpt.id <> 77
			AND mbt.category_id IN (1,2,3)


		UPDATE tt SET tt.Dodijeljen = 1
		FROM #tempT tt 
		WHERE EXISTS (SELECT TOP 1 1 FROM UserPortalTicket_MantisBugTable mbt
                                                WHERE
													mbt.id = tt.Id AND
                                                    mbt.status = 50 AND (mbt.handler_id = 35 OR mbt.handler_id = 0))

		UPDATE tt SET tt.Razvoj = 1
		FROM #tempT tt
		WHERE EXISTS (SELECT TOP 1 1 FROM UserPortalTicket_MantisBugTable mbt
                                                INNER JOIN dbo.UserPortal_MantisRelationshipTable subtask ON mbt.id = subtask.source_bug_id                                  
                                                WHERE
                                                    subtask.destination_bug_id = tt.Id AND subtask.relationship_type = 2 AND (mbt.status= 30 OR mbt.status = 40 OR mbt.status = 50))
		

		UPDATE tt SET tt.Analiza = 1
		FROM #tempT tt
		WHERE EXISTS (SELECT TOP 1 1 FROM UserPortalTicket_MantisBugTable mbt                                 
                                                WHERE
													mbt.id = tt.Id AND (mbt.status = 20 OR
                                                    mbt.status NOT IN (80,90) AND (mbt.handler_id <> 35 AND mbt.handler_id <> 0)))

		UPDATE tt SET tt.Rijesen = 1
		FROM #tempT tt
        WHERE (tt.Category = 1 AND tt.Status = 80) OR (tt.Status NOT IN (20,30,40,50,90) AND NOT EXISTS (SELECT TOP 1 1 FROM UserPortalTicket_MantisBugTable mbt
                                                        INNER JOIN UserPortal_MantisRelationshipTable subtask ON mbt.id = subtask.source_bug_id                                
                                                        WHERE
                                                            (subtask.destination_bug_id = tt.ID AND subtask.relationship_type = 2
                                                            AND mbt.status <> 80)))

		UPDATE tt SET tt.Zatvoren = 1
		FROM #tempT tt
		WHERE (tt.Category = 1 AND tt.Status = 90) OR (tt.Status NOT IN (20,30,40,50,80) AND NOT EXISTS (SELECT TOP 1 1 FROM UserPortalTicket_MantisBugTable mbt
                                                INNER JOIN dbo.UserPortal_MantisRelationshipTable subtask ON mbt.id = subtask.source_bug_id                                
                                                WHERE
                                                    (subtask.destination_bug_id = tt.Id AND subtask.relationship_type = 2
                                                    AND mbt.status <> 90)))
			
		
		UPDATE tt SET tt.IsporukaVerzija = 1
		FROM #tempT tt
		WHERE tt.Category <> 1 AND EXISTS (SELECT TOP 1 1 FROM UserPortalTicket_MantisBugTable mbt 
                                                INNER JOIN dbo.UserPortal_MantisRelationshipTable supertask ON mbt.id = supertask.source_bug_id                                
                                                WHERE
                                                    supertask.destination_bug_id = tt.Id AND supertask.relationship_type = 2
                                                    AND (tt.Status = 80 OR (tt.Status = 90 AND mbt.status = 80)))
		UPDATE tt SET tt.Isporucen = 1
		FROM #tempT tt
		WHERE EXISTS (	SELECT cl.id
							FROM UserPortal_InternaDeployRequestVersion drv
							INNER JOIN UserPortal_InternaDeployRequest dr ON dr.ID = drv.DeployRequestId
							INNER JOIN UserPortal_InternaClientContracted c ON c.ID = dr.ContractedID
							INNER JOIN UserPortal_InternaClientTable cl ON cl.ID = c.ClientID
							INNER JOIN UserPortal_InternaHotfixTask ht ON ht.HotfixID = drv.HotfixID
							INNER JOIN dbo.UserPortal_MantisRelationshipTable subtask ON subtask.destination_bug_id = tt.id AND subtask.relationship_type = 2
							WHERE ht.MantisID = subtask.source_bug_id AND cl.shortName = @HospitalShortName AND dr.ModeId = 1)
		
		UPDATE tt SET tt.Isporucen = 1
		FROM #tempT tt
		WHERE EXISTS (SELECT subtask.source_bug_id,subtask.destination_bug_id FROM dbo.UserPortalTicket_MantisBugTable mbt
							INNER JOIN dbo.UserPortal_MantisRelationshipTable subtask ON subtask.destination_bug_id = tt.id
							WHERE subtask.source_bug_id <> '' AND subtask.relationship_type = 2) AND NOT EXISTS(SELECT mbt.target_version FROM dbo.UserPortalTicket_MantisBugTable mbt
							INNER JOIN dbo.UserPortal_MantisRelationshipTable subtask ON subtask.destination_bug_id = tt.Id
							WHERE subtask.source_bug_id <> mbt.id AND subtask.relationship_type = 2 AND mbt.target_version <= tt.ClientProductCurrentVersion) 

		SELECT
			mbt.id,
			MantisBT.dbo.Convert2Default(mct.name) type,
			CASE
				WHEN MantisBT.dbo.Convert2Default(mct.name) = 'Podrška'
				THEN
					CASE
						WHEN t.Analiza = 1 THEN 'Analiza u tijeku'
						WHEN t.Rijesen = 1 THEN 'Riješen'
						WHEN t.Zatvoren = 1 THEN 'Zatvoren'
						WHEN t.Dodijeljen = 1 THEN 'Dodijeljen'
					END
				WHEN MantisBT.dbo.Convert2Default(mct.name) = 'Novi zahtjev' OR MantisBT.dbo.Convert2Default(mct.name) = 'Greška'
				THEN
					CASE
						WHEN t.Isporucen = 1 THEN 'Isporuèen'
						WHEN t.IsporukaVerzija = 1 THEN 'Isporuka sa slijedeæom verzijom'
						WHEN t.Rijesen = 1 THEN 'Riješen'
						WHEN t.Zatvoren = 1 THEN 'Zatvoren'
						WHEN t.Razvoj = 1 THEN 'Razvoj'
						WHEN t.Analiza = 1 THEN 'Analiza u tijeku'
						WHEN t.Dodijeljen = 1 THEN 'Dodijeljen'
					END
			END 'status',
			MantisBT.dbo.Convert2Default(mbt.Summary) Abstract,
			MantisBT.dbo.Convert2Default(mbtt.[description]) [description],
			MantisBT.dbo.Convert2Default(mpt.name) product,
			CONVERT(VARCHAR(10),  dbo.Number2DateTime(mbt.date_submitted), 103) + ' ' + CONVERT(VARCHAR(5), dbo.Number2DateTime(mbt.date_submitted), 14) enrollmentTime,
			upmbt.UserId,
			ISNULL(u.LastName + ' ' + u.FirstName,'') firstNameLastNameApplicant,
			CASE
				WHEN mbt.priority = 30 THEN 'Normalni'
				WHEN mbt.priority = 10 THEN 'Ništa'
				WHEN mbt.priority = 20 THEN 'Niski'
				WHEN mbt.priority = 40 THEN 'Visoki'
				WHEN mbt.priority = 50 THEN 'Hitno'
				WHEN mbt.priority = 60 THEN 'Trenutno'
			END 'Priority',
			MantisBT.dbo.Convert2Default(t.DomainName) 'Domain'
        FROM #tempT t 
		INNER JOIN UserPortalTicket_MantisBugTable mbt ON mbt.id = t.Id
        INNER JOIN UserPortalTicket_MantisBugTextTable mbtt ON mbtt.id = mbt.bug_text_id
        INNER JOIN UserPortalMantisBT upmbt ON upmbt.TicketId = mbt.id
        INNER JOIN dbo.UserPortalTicket_MantisCategoryTable mct ON mct.id = mbt.category_id     
        INNER JOIN dbo.[User] u ON u.Id = upmbt.UserId
        LEFT JOIN UserPortalTicket_MantisProjectTable mpt ON mpt.id = mbt.project_id                   
        ORDER BY mbtt.id DESC
	END
	ELSE IF @UserRoleId = 2 BEGIN
		INSERT INTO #tempT(Id,[Status],Category,ProductId,DomainName, ClientProductCurrentVersion)
		SELECT mbt.id, mbt.[status],mbt.category_id, ipt.ID, ISNULL(mcfst3.value,mcfst.value), (SELECT TOP 1 iv.Code
																FROM dbo.UserPortal_InternaDeployRequest dp 
																INNER JOIN dbo.UserPortal_InternaClientContracted c ON c.ID = dp.ContractedID
																INNER JOIN dbo.UserPortal_InternaClientTable cl ON cl.ID = c.ClientId
																INNER JOIN UserPortalTicket_InternaVersion iv ON iv.ID = dp.VersionID
																INNER JOIN UserPortalTicket_InternaTask t ON t.VersionID = iv.ID
																INNER JOIN dbo.UserPortal_InternaProductTable p ON p.ID = iv.ProductID
																WHERE cl.shortname = @HospitalShortName AND p.ID = ipt.id
																ORDER BY iv.Code DESC)
		FROM UserPortalTicket_MantisBugTable mbt
        INNER JOIN UserPortalMantisBT upmbt ON upmbt.TicketId = mbt.id
		INNER JOIN dbo.[User] u ON u.Id = upmbt.UserId 
		INNER JOIN UserPortalTicket_MantisProjectTable mpt ON mpt.id = mbt.project_id
		INNER JOIN dbo.UserPortal_InternaProductTable ipt ON ipt.MantisProjectID = mpt.id
		LEFT JOIN UserPortalTicket_MantisCustomFieldStringTable mcfst ON mcfst.bug_id = mbt.id AND mcfst.field_id = 23  
		LEFT JOIN dbo.UserPortalTicket_MantisCustomFieldStringTable mcfst3 ON mcfst3.bug_id = mbt.id AND mcfst3.field_id = 56
        WHERE DATEADD(ss,mbt.date_submitted, '1/1/1970 01:00:00') BETWEEN @EnrollmentTimeDateFrom AND DATEADD(s,-1,DATEADD(d,1,@EnrollmentTimeDateTo))
		AND u.Id = @UserId AND mbt.category_id IN (1,2,3)

			
		UPDATE tt SET tt.Dodijeljen = 1
		FROM #tempT tt 
		WHERE EXISTS (SELECT TOP 1 1 FROM UserPortalTicket_MantisBugTable mbt
                                                WHERE
													mbt.id = tt.Id AND
                                                    mbt.status = 50 AND (mbt.handler_id = 35 OR mbt.handler_id = 0))

		UPDATE tt SET tt.Razvoj = 1
		FROM #tempT tt
		WHERE EXISTS (SELECT TOP 1 1 FROM UserPortalTicket_MantisBugTable mbt
                                                INNER JOIN dbo.UserPortal_MantisRelationshipTable subtask ON mbt.id = subtask.source_bug_id                                  
                                                WHERE
                                                    subtask.destination_bug_id = tt.Id AND subtask.relationship_type = 2 AND (mbt.status= 30 OR mbt.status = 40 OR mbt.status = 50))
		

		UPDATE tt SET tt.Analiza = 1
		FROM #tempT tt
		WHERE EXISTS (SELECT TOP 1 1 FROM UserPortalTicket_MantisBugTable mbt                                 
                                                WHERE
													mbt.id = tt.Id AND (mbt.status = 20 OR
                                                    mbt.status NOT IN (80,90) AND (mbt.handler_id <> 35 AND mbt.handler_id <> 0)))

		UPDATE tt SET tt.Rijesen = 1
		FROM #tempT tt
        WHERE (tt.Category = 1 AND tt.Status = 80) OR (tt.Status NOT IN (20,30,40,50,90) AND NOT EXISTS (SELECT TOP 1 1 FROM UserPortalTicket_MantisBugTable mbt
                                                        INNER JOIN UserPortal_MantisRelationshipTable subtask ON mbt.id = subtask.source_bug_id                                
                                                        WHERE
                                                            (subtask.destination_bug_id = tt.ID AND subtask.relationship_type = 2
                                                            AND mbt.status <> 80)))

		UPDATE tt SET tt.Zatvoren = 1
		FROM #tempT tt
		WHERE (tt.Category = 1 AND tt.Status = 90) OR (tt.Status NOT IN (20,30,40,50,80) AND NOT EXISTS (SELECT TOP 1 1 FROM UserPortalTicket_MantisBugTable mbt
                                                INNER JOIN dbo.UserPortal_MantisRelationshipTable subtask ON mbt.id = subtask.source_bug_id                                
                                                WHERE
                                                    (subtask.destination_bug_id = tt.Id AND subtask.relationship_type = 2
                                                    AND mbt.status <> 90)))
			
		
		UPDATE tt SET tt.IsporukaVerzija = 1
		FROM #tempT tt
		WHERE tt.Category <> 1 AND EXISTS (SELECT TOP 1 1 FROM UserPortalTicket_MantisBugTable mbt 
                                                INNER JOIN dbo.UserPortal_MantisRelationshipTable supertask ON mbt.id = supertask.source_bug_id                                
                                                WHERE
                                                    supertask.destination_bug_id = tt.Id AND supertask.relationship_type = 2
                                                    AND (tt.Status = 80 OR (tt.Status = 90 AND mbt.status = 80)))
		UPDATE tt SET tt.Isporucen = 1
		FROM #tempT tt
		WHERE EXISTS (	SELECT TOP 1 1
							FROM UserPortal_InternaDeployRequestVersion drv
							INNER JOIN UserPortal_InternaDeployRequest dr ON dr.ID = drv.DeployRequestId
							INNER JOIN UserPortal_InternaClientContracted c ON c.ID = dr.ContractedID
							INNER JOIN UserPortal_InternaClientTable cl ON cl.ID = c.ClientID
							INNER JOIN UserPortal_InternaHotfixTask ht ON ht.HotfixID = drv.HotfixID
							INNER JOIN dbo.UserPortal_MantisRelationshipTable subtask ON subtask.destination_bug_id = tt.id AND subtask.relationship_type = 2
							WHERE ht.MantisID = subtask.source_bug_id AND cl.shortName = @HospitalShortName AND dr.ModeId = 1)
		
		UPDATE tt SET tt.Isporucen = 1
		FROM #tempT tt
		WHERE EXISTS (SELECT subtask.source_bug_id,subtask.destination_bug_id FROM dbo.UserPortalTicket_MantisBugTable mbt
							INNER JOIN dbo.UserPortal_MantisRelationshipTable subtask ON subtask.destination_bug_id = tt.id
							WHERE subtask.source_bug_id <> '' AND subtask.relationship_type = 2) AND NOT EXISTS(SELECT mbt.target_version FROM dbo.UserPortalTicket_MantisBugTable mbt
							INNER JOIN dbo.UserPortal_MantisRelationshipTable subtask ON subtask.destination_bug_id = tt.Id
							WHERE subtask.source_bug_id <> mbt.id AND subtask.relationship_type = 2 AND mbt.target_version <= tt.ClientProductCurrentVersion) 

		SELECT 
			mbt.id,
			MantisBT.dbo.Convert2Default(mct.name) type,
			CASE
				WHEN MantisBT.dbo.Convert2Default(mct.name) = 'Podrška'
				THEN
					CASE
						WHEN t.Analiza = 1 THEN 'Analiza u tijeku'
						WHEN t.Rijesen = 1 THEN 'Riješen'
						WHEN t.Zatvoren = 1 THEN 'Zatvoren'
						WHEN t.Dodijeljen = 1 THEN 'Dodijeljen'
					END
				WHEN MantisBT.dbo.Convert2Default(mct.name) = 'Novi zahtjev' OR MantisBT.dbo.Convert2Default(mct.name) = 'Greška'
				THEN
					CASE
						WHEN t.Isporucen = 1 THEN 'Isporuèen'
						WHEN t.IsporukaVerzija = 1 THEN 'Isporuka sa slijedeæom verzijom'
						WHEN t.Rijesen = 1 THEN 'Riješen'
						WHEN t.Zatvoren = 1 THEN 'Zatvoren'
						WHEN t.Razvoj = 1 THEN 'Razvoj'
						WHEN t.Analiza = 1 THEN 'Analiza u tijeku'
						WHEN t.Dodijeljen = 1 THEN 'Dodijeljen'
					END
			END 'status',
		MantisBT.dbo.Convert2Default(mbt.Summary) Abstract, 
		MantisBT.dbo.Convert2Default(mbtt.[description]) [description],
		MantisBT.dbo.Convert2Default(mpt.name) product,
		MantisBT.dbo.Convert2Default(t.DomainName) 'Domain',
		CONVERT(VARCHAR(10),  dbo.Number2DateTime(mbt.date_submitted), 103) + ' ' + CONVERT(VARCHAR(5), dbo.Number2DateTime(mbt.date_submitted), 14) enrollmentTime,
		upmbt.UserId,
		CASE 
			WHEN mbt.priority = 30 THEN 'Normalni'
			WHEN mbt.priority = 10 THEN 'Ništa'
			WHEN mbt.priority = 20 THEN 'Niski'
			WHEN mbt.priority = 40 THEN 'Visoki'
			WHEN mbt.priority = 50 THEN 'Hitno'
			WHEN mbt.priority = 60 THEN 'Trenutno'
		END 'Priority'
		FROM #tempT T
		INNER JOIN UserPortalTicket_MantisBugTable mbt ON mbt.id = t.Id
		INNER JOIN UserPortalTicket_MantisBugTextTable mbtt ON mbtt.id = mbt.bug_text_id
		INNER JOIN UserPortalMantisBT upmbt ON upmbt.TicketId = mbt.id
		INNER JOIN dbo.UserPortalTicket_MantisCategoryTable mct ON mct.id = mbt.category_id
		LEFT JOIN UserPortalTicket_MantisProjectTable mpt ON mpt.id = mbt.project_id
		ORDER BY mbtt.id DESC
	END
	ELSE BEGIN
		WITH LatestVersion AS (
		SELECT DISTINCT cl.shortname AS ClientShortName, p.ID AS ProductID, MAX(iv.Code) AS LatestVersionCode
		FROM dbo.UserPortal_InternaDeployRequest dp WITH (NOLOCK)
		INNER JOIN dbo.UserPortal_InternaClientContracted c ON c.ID = dp.ContractedID
		INNER JOIN dbo.UserPortal_InternaClientTable cl ON cl.ID = c.ClientId
		INNER JOIN UserPortalTicket_InternaVersion iv ON iv.ID = dp.VersionID
		INNER JOIN dbo.UserPortal_InternaProductTable p ON p.ID = iv.ProductID
		WHERE iv.Code IS NOT NULL
		GROUP BY cl.shortname, p.ID
	),
	Projekti AS(
		SELECT ID FROM dbo.UserPortalTicket_MantisProjectTable WHERE name NOT LIKE '#%'
	)


		INSERT INTO #tempT(Id,[Status],Category, HospitalName, HospitalId, ProductId,DomainName,ClientProductCurrentVersion)
		SELECT mbt.id, mbt.[status],mbt.category_id, map.Converted, MIN(ict.id),  ipt.ID,  ISNULL(map3.Converted,map2.Converted),lv.LatestVersionCode 
		FROM UserPortalTicket_MantisBugTable mbt WITH (NOLOCK)
		INNER JOIN UserPortalTicket_MantisBugTextTable mbtt ON mbtt.id = mbt.bug_text_id
		INNER JOIN UserPortalMantisBT upmbt ON upmbt.TicketId = mbt.id
		INNER JOIN UserPortalTicket_MantisCustomFieldStringTable mcfst ON mcfst.bug_id = mbt.id AND mcfst.field_id = 1
		INNER JOIN #Mappings map ON map.TypeId = 1 AND map.Original = mcfst.value
		INNER JOIN dbo.UserPortal_InternaClientTable ict ON ict.ShortName = map.Converted
		INNER JOIN Projekti mpt ON mpt.id = mbt.project_id
		INNER JOIN dbo.UserPortal_InternaProductTable ipt ON ipt.MantisProjectID = mpt.id
		INNER JOIN LatestVersion lv ON lv.ClientShortName = map.Converted AND lv.ProductID = ipt.ID
		LEFT JOIN UserPortalTicket_MantisCustomFieldStringTable mcfst2 ON mcfst2.bug_id = mbt.id AND mcfst2.field_id = 23  
		LEFT JOIN  #Mappings map2 ON map2.Original = mcfst2.value
		LEFT JOIN dbo.UserPortalTicket_MantisCustomFieldStringTable mcfst3 ON mcfst3.bug_id = mbt.id AND mcfst3.field_id = 56
		LEFT JOIN  #Mappings map3 ON map3.Original = mcfst3.value
		WHERE 
			DATEADD(ss,mbt.date_submitted, '1/1/1970 01:00:00') BETWEEN  @EnrollmentTimeDateFrom AND DATEADD(s,-1,DATEADD(d,1,@EnrollmentTimeDateTo))
			 AND mbt.category_id IN (1,2,3)
		GROUP BY mbt.Id,mbt.[status],mbt.category_id, map.Converted, ipt.ID, map2.Converted, map3.Converted, lv.LatestVersionCode
		
			
			UPDATE tt SET tt.Dodijeljen = 1
		FROM #tempT tt
		WHERE EXISTS (SELECT TOP 1 1 FROM UserPortalTicket_MantisBugTable mbt
                                                WHERE
													mbt.id = tt.Id AND
                                                    mbt.status = 50 AND (mbt.handler_id = 35 OR mbt.handler_id = 0))

		UPDATE tt SET tt.Razvoj = 1
		FROM #tempT tt
		WHERE EXISTS (SELECT TOP 1 1 FROM UserPortalTicket_MantisBugTable mbt
                                                INNER JOIN dbo.UserPortal_MantisRelationshipTable subtask ON mbt.id = subtask.source_bug_id                                  
                                                WHERE
                                                    subtask.destination_bug_id = tt.Id AND subtask.relationship_type = 2 AND (mbt.status= 30 OR mbt.status = 40 OR mbt.status = 50))
		

		UPDATE tt SET tt.Analiza = 1
		FROM #tempT tt
		WHERE EXISTS (SELECT TOP 1 1 FROM UserPortalTicket_MantisBugTable mbt                                 
                                                WHERE
													mbt.id = tt.Id AND (mbt.status = 20 OR
                                                    mbt.status NOT IN (80,90) AND (mbt.handler_id <> 35 AND mbt.handler_id <> 0)))

		UPDATE tt SET tt.Rijesen = 1
		FROM #tempT tt
        WHERE (tt.Category = 1 AND tt.Status = 80) OR (tt.Status NOT IN (20,30,40,50,90) AND NOT EXISTS (SELECT TOP 1 1 FROM UserPortalTicket_MantisBugTable mbt
                                                        INNER JOIN UserPortal_MantisRelationshipTable subtask ON mbt.id = subtask.source_bug_id                                
                                                        WHERE
                                                            (subtask.destination_bug_id = tt.ID AND subtask.relationship_type = 2
                                                            AND mbt.status <> 80)))

		UPDATE tt SET tt.Zatvoren = 1
		FROM #tempT tt
		WHERE (tt.Category = 1 AND tt.Status = 90) OR (tt.Status NOT IN (20,30,40,50,80) AND NOT EXISTS (SELECT TOP 1 1 FROM UserPortalTicket_MantisBugTable mbt
                                                INNER JOIN dbo.UserPortal_MantisRelationshipTable subtask ON mbt.id = subtask.source_bug_id                                
                                                WHERE
                                                    (subtask.destination_bug_id = tt.Id AND subtask.relationship_type = 2
                                                    AND mbt.status <> 90)))
			
		
		UPDATE tt SET tt.IsporukaVerzija = 1
		FROM #tempT tt
		WHERE tt.Category <> 1 AND EXISTS (SELECT TOP 1 1 FROM UserPortalTicket_MantisBugTable mbt 
                                                INNER JOIN dbo.UserPortal_MantisRelationshipTable supertask ON mbt.id = supertask.source_bug_id                                
                                                WHERE
                                                    supertask.destination_bug_id = tt.Id AND supertask.relationship_type = 2
                                                    AND (tt.Status = 80 OR (tt.Status = 90 AND mbt.status = 80)))
		UPDATE tt SET tt.Isporucen = 1
		FROM #tempT tt
		WHERE EXISTS (	SELECT cl.id
							FROM UserPortal_InternaDeployRequestVersion drv
							INNER JOIN UserPortal_InternaDeployRequest dr ON dr.ID = drv.DeployRequestId
							INNER JOIN UserPortal_InternaClientContracted c ON c.ID = dr.ContractedID
							INNER JOIN UserPortal_InternaClientTable cl ON cl.ID = c.ClientID
							INNER JOIN UserPortal_InternaHotfixTask ht ON ht.HotfixID = drv.HotfixID
							INNER JOIN dbo.UserPortal_MantisRelationshipTable subtask ON subtask.destination_bug_id = tt.id AND subtask.relationship_type = 2
							WHERE ht.MantisID = subtask.source_bug_id AND cl.id = tt.HospitalId AND dr.ModeId = 1)
		
		UPDATE tt SET tt.Isporucen = 1
		FROM #tempT tt
		WHERE EXISTS (
			SELECT 1
			FROM dbo.UserPortal_MantisRelationshipTable subtask 
			WHERE subtask.destination_bug_id = tt.id AND subtask.source_bug_id <> '' AND subtask.relationship_type = 2
		) 
		AND NOT EXISTS (
			SELECT mbt.target_version
			FROM dbo.UserPortalTicket_MantisBugTable mbt
			INNER JOIN dbo.UserPortal_MantisRelationshipTable subtask ON subtask.destination_bug_id = tt.Id
			WHERE subtask.source_bug_id <> mbt.id AND subtask.relationship_type = 2 AND mbt.target_version <= tt.ClientProductCurrentVersion
		) 

		;WITH Kategorije AS (
			SELECT mct.ID, MantisBT.dbo.Convert2Default(mct.name) AS name FROM dbo.UserPortalTicket_MantisCategoryTable mct
		)
		, Projekti AS (
			SELECT mpt.ID, MantisBT.dbo.Convert2Default(mpt.name) AS name FROM UserPortalTicket_MantisProjectTable mpt 
		)
		, MantisBugTable AS (
			SELECT mbt.id,MantisBT.dbo.Convert2Default(mbt.summary) AS summary,mbt.priority,mbt.date_submitted, mbt.category_id,mbt.bug_text_id,mbt.project_id FROM dbo.UserPortalTicket_MantisBugTable mbt
		)
							
		SELECT
			mbt.id,
			mct.name type,
			CASE
				WHEN mct.name = 'Podrška'
				THEN
					CASE
						WHEN t.Analiza = 1 THEN 'Analiza u tijeku'
						WHEN t.Rijesen = 1 THEN 'Riješen'
						WHEN t.Zatvoren = 1 THEN 'Zatvoren'
						WHEN t.Dodijeljen = 1 THEN 'Dodijeljen'
					END
				WHEN mct.name = 'Novi zahtjev' OR mct.name = 'Greška'
				THEN
					CASE
						WHEN t.Isporucen = 1 THEN 'Isporuèen'
						WHEN t.IsporukaVerzija = 1 THEN 'Isporuka sa slijedeæom verzijom'
						WHEN t.Rijesen = 1 THEN 'Riješen'
						WHEN t.Zatvoren = 1 THEN 'Zatvoren'
						WHEN t.Razvoj = 1 THEN 'Razvoj'
						WHEN t.Analiza = 1 THEN 'Analiza u tijeku'
						WHEN t.Dodijeljen = 1 THEN 'Dodijeljen'
					END
			END 'status',
			mbt.Summary Abstract,
			mbtt.[description] [description],
			mpt.name product,
			CONVERT(VARCHAR(10), DATEADD(ss,mbt.date_submitted, '1/1/1970 01:00:00'), 103) + ' ' + convert(VARCHAR(5), DATEADD(ss,mbt.date_submitted, '1/1/1970 01:00:00'), 14) enrollmentTime,
			upmbt.UserId,
			ISNULL(u.LastName + ' ' + u.FirstName,'') firstNameLastNameApplicant,
			CASE
				WHEN mbt.priority = 30 THEN 'Normalni'
				WHEN mbt.priority = 10 THEN 'Ništa'
				WHEN mbt.priority = 20 THEN 'Niski'
				WHEN mbt.priority = 40 THEN 'Visoki'
				WHEN mbt.priority = 50 THEN 'Hitno'
				WHEN mbt.priority = 60 THEN 'Trenutno'
			END 'Priority',
			 t.HospitalName 'HospitalName',
			 t.DomainName 'Domain'
        FROM #tempT t
		INNER JOIN MantisBugTable mbt ON mbt.id = t.Id
        INNER JOIN UserPortalTicket_MantisBugTextTable mbtt ON mbtt.id = mbt.bug_text_id
        INNER JOIN UserPortalMantisBT upmbt ON upmbt.TicketId = mbt.id
        INNER JOIN Kategorije mct ON mct.id = mbt.category_id    
        INNER JOIN dbo.[User] u ON u.Id = upmbt.UserId
        LEFT JOIN Projekti mpt ON mpt.id = mbt.project_id                  
        ORDER BY mbtt.id DESC
		END
	DROP TABLE #tempT
	DROP TABLE #Mappings
END
GO