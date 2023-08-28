	IF dbo.PostojiObjekt('TicketGetById_Select') = 1 BEGIN
  DROP PROCEDURE TicketGetById_Select
END
GO

CREATE PROCEDURE TicketGetById_Select(
	@Id INT
)
AS
BEGIN
	
	DECLARE @UserId INT

	SELECT @UserId = (SELECT UserId FROM dbo.UserPortalMantisBT WHERE TicketId = @Id)

	DECLARE @Klijent VARCHAR(255)
	SELECT @Klijent = (
	SELECT DISTINCT TOP 1 MantisBT.dbo.Convert2Default(mcfst.value)
	FROM dbo.UserPortalTicket_MantisBugTable mbt
	INNER JOIN dbo.UserPortalTicket_MantisCustomFieldStringTable mcfst ON mcfst.bug_id = @Id
	WHERE mcfst.field_id = 1)

	DECLARE @ProductId INT

	SET @ProductId = (SELECT TOP 1 ipt.ID
	FROM dbo.UserPortalTicket_MantisBugTable mbt
	INNER JOIN dbo.UserPortalTicket_MantisProjectTable mpt ON mpt.id = mbt.project_id
	INNER JOIN dbo.UserPortal_InternaProductTable ipt ON ipt.MantisProjectID = mpt.id
	WHERE mbt.id = @Id)

	DECLARE @ClientProductVersion VARCHAR(255)
	--trenutna verzija klijenta
	SET @ClientProductVersion =  (SELECT TOP 1 iv.Code
	FROM dbo.UserPortal_InternaDeployRequest dp 
	INNER JOIN dbo.UserPortal_InternaClientContracted c ON c.ID = dp.ContractedID
	INNER JOIN UserPortalTicket_InternaVersion iv ON iv.ID = dp.VersionID
	INNER JOIN UserPortalTicket_InternaTask t ON t.VersionID = iv.ID
	INNER JOIN dbo.UserPortal_InternaProductTable p ON p.ID = iv.ProductID
	INNER JOIN dbo.UserPortal_InternaClientTable cl ON cl.ID = c.ClientID
	WHERE cl.ShortName = @Klijent  AND p.ID = @ProductId
	ORDER BY Code DESC)


	DECLARE @tempT TABLE (Id INT, [Status] SMALLINT, Category SMALLINT, DomainName VARCHAR(MAX), HospitalName VARCHAR(MAX), Dodijeljen BIT, Analiza BIT,Razvoj BIT, Rijesen BIT, Zatvoren BIT, IsporukaVerzija BIT, Isporucen BIT)

	INSERT INTO @tempT(Id,[Status],Category, DomainName, HospitalName)
		SELECT mbt.id, mbt.[status],mbt.category_id, ISNULL(mcfst3.value,mcfst.value), MantisBT.dbo.Convert2Default(mcfst2.value)
		FROM UserPortalTicket_MantisBugTable mbt
		INNER JOIN dbo.UserPortalTicket_MantisCustomFieldStringTable mcfst2 ON mcfst2.bug_id = mbt.id AND mcfst2.field_id = 1
		INNER JOIN dbo.UserPortal_InternaClientTable ict ON ict.ShortName = MantisBT.dbo.Convert2Default(mcfst2.value)
		LEFT JOIN UserPortalTicket_MantisCustomFieldStringTable mcfst ON mcfst.bug_id = mbt.id AND mcfst.field_id = 23  
		LEFT JOIN dbo.UserPortalTicket_MantisCustomFieldStringTable mcfst3 ON mcfst3.bug_id = mbt.id AND mcfst3.field_id = 56
		LEFT JOIN UserPortalTicket_MantisProjectTable mpt ON mpt.id = mbt.project_id
		WHERE mbt.id = @Id

		UPDATE tt SET tt.Dodijeljen = 1
		FROM @tempT tt 
		WHERE EXISTS (SELECT TOP 1 1 FROM UserPortalTicket_MantisBugTable mbt
                                                WHERE
													mbt.id = tt.Id AND
                                                    mbt.status = 50 AND (mbt.handler_id = 35 OR mbt.handler_id = 0))

		UPDATE tt SET tt.Razvoj = 1
		FROM @tempT tt
		WHERE EXISTS (SELECT TOP 1 1 FROM UserPortalTicket_MantisBugTable mbt
                                                INNER JOIN dbo.UserPortal_MantisRelationshipTable subtask ON mbt.id = subtask.source_bug_id                                  
                                                WHERE
                                                    subtask.destination_bug_id = tt.Id AND subtask.relationship_type = 2 AND (mbt.status= 30 OR mbt.status = 40 OR mbt.status = 50))
		

		UPDATE tt SET tt.Analiza = 1
		FROM @tempT tt
		WHERE EXISTS (SELECT TOP 1 1 FROM UserPortalTicket_MantisBugTable mbt                                 
                                                WHERE
													mbt.id = tt.Id AND (mbt.status = 20 OR
                                                    mbt.status NOT IN (80,90) AND (mbt.handler_id <> 35 AND mbt.handler_id <> 0)))

		UPDATE tt SET tt.Rijesen = 1
		FROM @tempT tt
        WHERE (tt.Category = 1 AND tt.Status = 80) OR (tt.Status NOT IN (20,30,40,50,90) AND NOT EXISTS (SELECT TOP 1 1 FROM UserPortalTicket_MantisBugTable mbt
                                                        INNER JOIN UserPortal_MantisRelationshipTable subtask ON mbt.id = subtask.source_bug_id                                
                                                        WHERE
                                                            (subtask.destination_bug_id = tt.ID AND subtask.relationship_type = 2
                                                            AND mbt.status <> 80)))

		UPDATE tt SET tt.Zatvoren = 1
		FROM @tempT tt
		WHERE (tt.Category = 1 AND tt.Status = 90) OR (tt.Status NOT IN (20,30,40,50,80) AND NOT EXISTS (SELECT TOP 1 1 FROM UserPortalTicket_MantisBugTable mbt
                                                INNER JOIN dbo.UserPortal_MantisRelationshipTable subtask ON mbt.id = subtask.source_bug_id                                
                                                WHERE
                                                    (subtask.destination_bug_id = tt.Id AND subtask.relationship_type = 2
                                                    AND mbt.status <> 90)))
			
		
		UPDATE tt SET tt.IsporukaVerzija = 1
		FROM @tempT tt
		WHERE tt.Category <> 1 AND EXISTS (SELECT TOP 1 1 FROM UserPortalTicket_MantisBugTable mbt 
                                                INNER JOIN dbo.UserPortal_MantisRelationshipTable supertask ON mbt.id = supertask.source_bug_id                                
                                                WHERE
                                                    supertask.destination_bug_id = tt.Id AND supertask.relationship_type = 2
                                                    AND (tt.Status = 80 OR (tt.Status = 90 AND mbt.status = 80)))
		UPDATE tt SET tt.Isporucen = 1
		FROM @tempT tt
		WHERE EXISTS (	SELECT *
							FROM UserPortal_InternaDeployRequestVersion drv
							INNER JOIN UserPortal_InternaDeployRequest dr ON dr.ID = drv.DeployRequestId
							INNER JOIN UserPortal_InternaClientContracted c ON c.ID = dr.ContractedID
							INNER JOIN UserPortal_InternaClientTable cl ON cl.ID = c.ClientID
							INNER JOIN UserPortal_InternaHotfixTask ht ON ht.HotfixID = drv.HotfixID
							INNER JOIN dbo.UserPortal_MantisRelationshipTable subtask ON subtask.destination_bug_id = tt.id AND subtask.relationship_type = 2
							WHERE ht.MantisID = subtask.source_bug_id AND cl.shortName = @Klijent AND dr.ModeId = 1)
		
		UPDATE tt SET tt.Isporucen = 1
		FROM @tempT tt
		WHERE EXISTS (SELECT subtask.source_bug_id,subtask.destination_bug_id FROM dbo.UserPortalTicket_MantisBugTable mbt
							INNER JOIN dbo.UserPortal_MantisRelationshipTable subtask ON subtask.destination_bug_id = tt.id
							WHERE subtask.source_bug_id <> '' AND subtask.relationship_type = 2) AND NOT EXISTS(SELECT mbt.target_version FROM dbo.UserPortalTicket_MantisBugTable mbt
		INNER JOIN dbo.UserPortal_MantisRelationshipTable subtask ON subtask.destination_bug_id = tt.Id
		WHERE subtask.source_bug_id <> mbt.id AND subtask.relationship_type = 2 AND mbt.target_version <= @ClientProductVersion) 

			
		SELECT 
		mbt.id,
		MantisBT.dbo.Convert2Default(mct.name) type,
		MantisBT.dbo.Convert2Default(mbt.Summary) Abstract,
		MantisBT.dbo.Convert2Default(mbtt.description) [description],
		CONVERT(VARCHAR(10), dbo.Number2DateTime(mbt.date_submitted), 103) + ' ' + CONVERT(VARCHAR(5), dbo.Number2DateTime(mbt.date_submitted), 14) enrollmentTime,
		MantisBT.dbo.Convert2Default(mpt.name) product,
		MantisBT.dbo.Convert2Default(t.DomainName) domain,
		t.HospitalName 'hospitalName',
		CASE
			WHEN MantisBT.dbo.Convert2Default(mut.realname) <> '' THEN MantisBT.dbo.Convert2Default(mut.realname) ELSE 'Održavanje'
		END 'ticketHandler',
		CASE 
			WHEN mbt.priority = 30 THEN 'Normalni'
			WHEN mbt.priority = 10 THEN 'Ništa'
			WHEN mbt.priority = 20 THEN 'Niski'
			WHEN mbt.priority = 40 THEN 'Visoki'
			WHEN mbt.priority = 50 THEN 'Hitno'
			WHEN mbt.priority = 60 THEN 'Trenutno'
		END 'Priority',
		CASE
            WHEN MantisBT.dbo.Convert2Default(mct.name) = 'Podrška'
            THEN
                CASE
					WHEN t.Rijesen = 1 THEN 'Riješen'
                    WHEN t.Zatvoren = 1 THEN 'Zatvoren'
                    WHEN t.Analiza = 1 THEN 'Analiza u tijeku'
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
		u.Id 'UserId'
		FROM @tempT t
		INNER JOIN UserPortalTicket_MantisBugTable mbt ON mbt.id = t.Id
		INNER JOIN UserPortalTicket_MantisBugTextTable mbtt ON mbtt.id = mbt.bug_text_id
		INNER JOIN dbo.UserPortalTicket_MantisCategoryTable mct ON mct.id = mbt.category_id
		INNER JOIN UserPortalTicket_MantisUserTable mut ON mut.id = mbt.handler_id
		INNER JOIN UserPortalMantisBT upmbt ON upmbt.TicketId = mbt.id
		INNER JOIN dbo.[User] u ON u.Id = upmbt.UserId
		LEFT JOIN UserPortalTicket_MantisProjectTable mpt ON mpt.id = mbt.project_id
		ORDER BY mbtt.id DESC
END
GO