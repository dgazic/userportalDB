IF dbo.PostojiObjekt('TicketMantis_Insert') = 1 BEGIN
  DROP PROCEDURE TicketMantis_Insert
END
GO

CREATE TYPE dbo.TicketAttachment_UDT AS TABLE 
(
	Title	VARCHAR(255)				NOT NULL,
	DocumentExtension	VARCHAR(255)	NOT NULL,
	DocumentData	VARBINARY(MAX)		NOT NULL,
	Size	INT							NOT NULL
)
GO

CREATE PROCEDURE TicketMantis_Insert(
	@Abstract VARCHAR(255),
	@Description VARCHAR(MAX),
	@Type VARCHAR(MAX),
	@UserId INT,
	@Product VARCHAR(MAX),
	@Domain VARCHAR(MAX),
	@Priority VARCHAR(255),
	@TicketAttachment TicketAttachment_UDT READONLY
)
AS BEGIN
	DECLARE @Opis VARCHAR(MAX), @Solved VARCHAR(MAX), @ProizvodId INT, @Podrska VARCHAR(MAX), @TezinaZahtjeva VARCHAR(MAX), @DateSubmitted INT,
			@Subject VARCHAR(MAX), @TipZahtjeva VARCHAR(MAX), @Handler VARCHAR(MAX), @Klijent VARCHAR(MAX), @KontaktOsoba VARCHAR(MAX), @Domena VARCHAR(MAX), @Email VARCHAR(MAX), @KontaktOsobaMobitel VARCHAR(MAX)

	--Dodavanje input parametara u proceduru
	SET @Subject = @Abstract
	SET @Opis = @Description
	SET @TipZahtjeva = @Type
	SET @Domena = @Domain

	--Klijent
	SELECT @Klijent = dbo.GetClient(@UserId)
	
	--Email 
	SELECT @Email = Email FROM [User] WHERE Id = @UserId
	
	SET @ProizvodId = (SELECT TOP 1 MantisProjectID FROM UserPortal_InternaProductTable WHERE name = @Product)
	
	--Kontakt osoba
	SELECT @KontaktOsoba = ISNULL(LastName,'') + ' ' + ISNULL(FirstName,'') +
	CASE 
		WHEN 
		PhoneNumber <> '' THEN ', ' + ISNULL(PhoneNumber,'')
		ELSE ''
		END 
	FROM dbo.[User] 
	WHERE Id = @UserId

	SELECT @KontaktOsobaMobitel = PhoneNumber FROM dbo.[User] WHERE Id = @UserId

	DECLARE @ID INT
	DECLARE @PodrskaID INT
	SET @PodrskaID = ISNULL((SELECT id FROM UserPortalTicket_MantisUserTable Where username = @Podrska), 75)
	
	DECLARE @Odrzavanje INT
	SET @Odrzavanje = ISNULL((SELECT id FROM UserPortalTicket_MantisUserTable Where username = 'odrzavanje'), 35)
	
	DECLARE @HandlerID int
	SET @HandlerID = ISNULL((SELECT id FROM UserPortalTicket_MantisUserTable Where username = @Handler), 35)

	DECLARE @Status INT
	If @Solved = 'DA' 
		SET @Status = 90
	ELSE
		SET @Status = 50	

	IF @Priority = 'Normalni'
		SET @TezinaZahtjeva = 30
	ELSE IF @Priority = 'Ništa'
		SET @TezinaZahtjeva = 10
	ELSE IF @Priority = 'Niski'
		SET @TezinaZahtjeva = 20
	ELSE IF @Priority = 'Visoki'
		SET @TezinaZahtjeva = 40
	ELSE IF @Priority = 'Hitno'
		SET @TezinaZahtjeva = 50
	ELSE IF @Priority = 'Trenutno'
		SET @TezinaZahtjeva = 60

	SET @TipZahtjeva = (SELECT TOP 1 ID FROM UserPortalTicket_MantisCategoryTable WHERE MantisBT.dbo.Convert2Default(name) = @TipZahtjeva)

	DECLARE @Now INT
    SET @Now = DATEDIFF (ss , DATEADD(ss, DATEDIFF(s, GETUTCDATE(), GETDATE()), '1/1/1970 00:00:00'), GETDATE())	
	


			INSERT INTO UserPortalTicket_MantisBugTextTable (description, steps_to_reproduce, additional_information) 
			SELECT  MantisBT.dbo.Convert2UTF8(@Opis), CASE WHEN @Solved = 'DA' THEN '' ELSE '' END, '' 	

			INSERT  INTO UserPortalTicket_MantisBugTable
			(
				project_id, reporter_id, handler_id, duplicate_id, priority, severity, reproducibility, status, resolution, 
				projection, date_submitted, last_updated, eta, bug_text_id, os, os_build, platform, version, fixed_in_version, 
				build, profile_id, view_state, summary, sponsorship_total, sticky, target_version, category_id, due_date
			)                         
			VALUES  (
					  @ProizvodId ,	--project_id -> BIS
					  @PodrskaID ,  --reporter_id -> bis-podrska
					  @HandlerID , --handler_id --> odrzavanje
					  @PodrskaID ,  --duplicate_id DEFAULT    
					  CASE WHEN ISNULL(@TezinaZahtjeva, '') <> '' THEN @TezinaZahtjeva
						   ELSE 30
					  END ,			--priority DEFAULT   		
					  50 ,     		--severity DEFAUL
					  70 ,			--reproducibility
					  @Status ,     --status -> 10 novi, 50 dodijeljen
					  10 ,     		--resolution DEFAULT
					  10 ,     		--projection DEFAULT    
					  ISNULL(@DateSubmitted, @Now),   		--date_submitted
					  @Now ,   		--last_updated DEFAULT
					  10 ,     		--eta
					  SCOPE_IDENTITY(),    		--bug_text_id
					  '' ,     		--os DEFAULT
					  '' ,     		--os_build DEFAULT
					  '' ,     		--platform DEFAULT
					  '' ,     		--version DEFAULT
					  '' ,     		--fixed_in_version DEFAULT
					  '' ,     		--build DEFAULT
					  0 ,      		--profile_id  DEFAULT
					  10 ,     		--view_state DEFAULT
					  MantisBT.dbo.Convert2UTF8(@Subject) ,   	--summary
					  0 ,			--sponsorship_total DEFAULT
					  0 ,          	--sticky DEFAULT
					  '' ,         	--target_version DEFAULT    
					  CASE 
					  WHEN @ProizvodId = 69 THEN 21 -- Support
					  WHEN ISNULL(@TipZahtjeva, '') <> '' THEN @TipZahtjeva
						   ELSE 1
					  END ,					--category_id	    
					  1	--due_date DEFAULT	    
					) 
					
		SET @ID = SCOPE_IDENTITY()
		IF @ProizvodId != 69 BEGIN
			INSERT INTO UserPortalTicket_MantisCustomFieldStringTable (field_id, bug_id, value) 
			VALUES(1, @ID, CASE WHEN ISNULL(@Klijent, '') <> '' THEN MantisBT.dbo.Convert2UTF8(@Klijent) ELSE 'Nepoznato' END)
		END
		
		INSERT INTO UserPortalTicket_MantisCustomFieldStringTable (field_id, bug_id, value)
        VALUES(4, @ID,MantisBT.dbo.Convert2UTF8(@KontaktOsoba))

		INSERT INTO UserPortalTicket_MantisCustomFieldStringTable (field_id, bug_id, value) 
			SELECT CASE WHEN @ProizvodId = 38 THEN 56 ELSE 23 END, @ID, 
					CASE 
						WHEN ISNULL(@Domena, '') <> '' THEN MantisBT.dbo.Convert2UTF8(@Domena)
						WHEN ISNULL(@Domena, '') = '' AND @ProizvodId = 38 THEN 'BK' 
						ELSE '...' 
					END 
					
		INSERT INTO UserPortalTicket_MantisCustomFieldStringTable (field_id, bug_id, value) 
		VALUES(24, @ID, @Email)

		--Dodavanje u veznu tablicu UserId(userportal) i TicketId(MantisBT baza) referenca
		INSERT INTO UserPortalMantisBT(UserId,TicketId)
		VALUES(@UserId,@ID)
		
		--dodavanje attatchemnta

		INSERT INTO UserPortalTicket_MantisBugFileTable (bug_id,title,description,diskfile,filename,folder,filesize,file_type,content,date_added,user_id)
					SELECT 
						@ID,
						'',
						'',
						'',
						 MantisBT.dbo.Convert2UTF8(Title),
						'',
						Size,
						'.' + DocumentExtension,
						DocumentData,
						@Now,
						75 --bis_podrska
					FROM @TicketAttachment

		INSERT INTO UserPortalTicket_MantisBugHistoryTable(user_id, bug_id, date_modified, field_name, old_value, new_value, type) 
		VALUES(@PodrskaID, @ID, @Now, '', '', '', 1) 

END;