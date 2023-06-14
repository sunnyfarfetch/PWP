USE [Viewpoint]
GO

/****** Object:  Trigger [dbo].[z_OC_APUISLComp]    Script Date: 6/30/2022 7:21:08 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- ================================================
-- Author:		Shukai Zhang
-- Create date: 06-06-2022
-- Description: This trigger is to complete the 
-- SL AP Invoice compliance functionalities
-- ================================================
CREATE TRIGGER [dbo].[z_OC_APUISLComp]
   ON [dbo].[bAPUI]
   AFTER INSERT, UPDATE
AS 
BEGIN

	SET NOCOUNT ON;
	IF (SELECT TRIGGER_NESTLEVEL()) > 3
	RETURN
	
	IF EXISTS(SELECT * FROM inserted WHERE udApplyPWPComp = 'Y')
		AND NOT EXISTS(SELECT * FROM inserted i INNER JOIN udSLAPUIComp u
		ON u.Co = i.APCo
		AND u.UIMth = i.UIMth
		AND u.UISeq = i.UISeq
		AND u.CompCode = 'PWP')
	BEGIN
		INSERT INTO udSLAPUIComp(
		Co,
		UISeq,
		CompCode,
		Description,
		APRef,
		UIMth
		)
		SELECT APCo, UISeq, 'PWP', 'Pay When Paid', APRef, UIMth
		FROM inserted

		UPDATE APUL
		SET APUL.udBillMonth = JBIN.BillMonth,
			APUL.udBillInvoice = JBIN.Invoice,
			APUL.udBillNumber = JBIN.BillNumber
		FROM APUL
			INNER JOIN inserted
			ON inserted.APCo = APUL.APCo
			AND inserted.UIMth = APUL.UIMth
			AND inserted.UISeq = APUL.UISeq
			AND APUL.LineType = 7 -- LineType is SL
			INNER JOIN JBIN 
			ON DATEADD(month, DATEDIFF(month, 0, inserted.InvDate), 0) = JBIN.BillMonth
			AND APUL.Job = JBIN.Contract
	END

	
	
	IF EXISTS(SELECT * FROM inserted WHERE udApplyPWPComp = 'Y')
		AND NOT EXISTS(SELECT * FROM inserted i INNER JOIN udSLAPUIComp u
		ON u.Co = i.APCo
		AND u.UIMth = i.UIMth
		AND u.UISeq = i.UISeq
		AND u.CompCode = 'PWP')
	BEGIN
		IF EXISTS(SELECT * 		
			FROM APUL
			INNER JOIN inserted
			ON inserted.APCo = APUL.APCo
			AND inserted.UIMth = APUL.UIMth
			AND inserted.UISeq = APUL.UISeq
			AND APUL.LineType = 7 -- LineType is SL
			INNER JOIN JBIN 
			ON DATEADD(month, DATEDIFF(month, 0, inserted.InvDate), 0) = JBIN.BillMonth
			AND APUL.Job = JBIN.Contract)
		BEGIN

			UPDATE APUL
			SET APUL.udBillMonth = JBIN.BillMonth,
				APUL.udBillInvoice = JBIN.Invoice,
				APUL.udBillNumber = JBIN.BillNumber
			FROM APUL
				INNER JOIN inserted
				ON inserted.APCo = APUL.APCo
				AND inserted.UIMth = APUL.UIMth
				AND inserted.UISeq = APUL.UISeq
				AND APUL.LineType = 7 -- LineType is SL
				INNER JOIN JBIN 
				ON DATEADD(month, DATEDIFF(month, 0, inserted.InvDate), 0) = JBIN.BillMonth
				AND APUL.Job = JBIN.Contract
		END

		IF NOT EXISTS(SELECT * 		
			FROM APUL
			INNER JOIN inserted
			ON inserted.APCo = APUL.APCo
			AND inserted.UIMth = APUL.UIMth
			AND inserted.UISeq = APUL.UISeq
			AND APUL.LineType = 7 -- LineType is SL
			INNER JOIN JBIN 
			ON DATEADD(month, DATEDIFF(month, 0, inserted.InvDate), 0) = JBIN.BillMonth
			AND APUL.Job = JBIN.Contract)
		
		BEGIN
			UPDATE APUL
			SET APUL.udBillMonth = NULL,
				APUL.udBillInvoice = NULL,
				APUL.udBillNumber = NULL
			FROM APUL
				INNER JOIN inserted
				ON inserted.APCo = APUL.APCo
				AND inserted.UIMth = APUL.UIMth
				AND inserted.UISeq = APUL.UISeq
				AND APUL.LineType = 7 -- LineType is SL
		
		END
	END









	
	IF EXISTS(SELECT * FROM inserted WHERE udApplyPWPComp = 'N')
		AND EXISTS(SELECT * FROM inserted i INNER JOIN udSLAPUIComp u
		ON u.Co = i.APCo
		AND u.UIMth = i.UIMth
		AND u.UISeq = i.UISeq
		AND u.CompCode = 'PWP')

	BEGIN
		DELETE u
		FROM udSLAPUIComp u
		INNER JOIN inserted i
		ON u.Co = i.APCo
		AND u.UIMth = i.UIMth
		AND u.UISeq = i.UISeq
		AND u.CompCode = 'PWP'

		UPDATE APUL
		SET APUL.udBillMonth = NULL,
			APUL.udBillInvoice = NULL,
			APUL.udBillNumber = NULL
		FROM APUL
			INNER JOIN inserted
			ON inserted.APCo = APUL.APCo
			AND inserted.UIMth = APUL.UIMth
			AND inserted.UISeq = APUL.UISeq
	END

	IF UPDATE(APRef) AND EXISTS(SELECT * FROM inserted i INNER JOIN udSLAPUIComp u
									ON u.Co = i.APCo
									AND u.UIMth = i.UIMth
									AND u.UISeq = i.UISeq
									AND u.CompCode = 'PWP')
	BEGIN
		UPDATE udSLAPUIComp
		SET udSLAPUIComp.APRef = APUI.APRef
		FROM udSLAPUIComp
		INNER JOIN APUI
		ON udSLAPUIComp.Co = APUI.APCo
		AND udSLAPUIComp.UIMth = APUI.UIMth
		AND udSLAPUIComp.UISeq = APUI.UISeq
	END
	
END
