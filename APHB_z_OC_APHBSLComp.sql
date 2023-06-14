USE [Viewpoint]
GO

/****** Object:  Trigger [dbo].[z_OC_APHBSLComp]    Script Date: 6/30/2022 7:19:39 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- ================================================
-- Author:		Shukai Zhang
-- Create date: 06-02-2022
-- Description: This trigger is to complete the 
-- SL AP Invoice compliance functionalities
-- ================================================
CREATE TRIGGER [dbo].[z_OC_APHBSLComp]
   ON [dbo].[bAPHB]
   AFTER INSERT, UPDATE
AS 
BEGIN

	SET NOCOUNT ON;

	IF EXISTS(SELECT * FROM inserted WHERE udApplyPWPComp = 'Y')
		AND NOT EXISTS(SELECT * FROM inserted i INNER JOIN udSLAPHBComp u
		ON u.Co = i.Co
		AND u.Mth = i.Mth
		AND u.BatchId = i.BatchId
		AND u.BatchSeq = i.BatchSeq
		AND u.CompCode = 'PWP')
		AND NOT EXISTS(SELECT * FROM inserted i INNER JOIN udSLAPHBComp u
		ON u.Co = i.Co
		AND u.Mth = i.Mth
		AND u.BatchId = i.BatchId
		AND u.BatchSeq = i.BatchSeq
		AND u.CompCode = 'PWP'
		INNER JOIN udSLAPUIComp a
		ON u.Co = a.Co
		AND u.Mth = a.TransMth
		AND u.APRef = a.APRef) 

		BEGIN
			INSERT INTO udSLAPHBComp(
			Co,
			BatchId,
			BatchSeq,
			CompCode,
			Description,
			APRef,
			Mth
			)
			SELECT Co, BatchId, BatchSeq, 'PWP', 'Pay When Paid', APRef, Mth
			FROM inserted


			UPDATE APLB
			SET APLB.udBillMonth = JBIN.BillMonth,
				APLB.udBillInvoice = JBIN.Invoice,
				APLB.udBillNumber = JBIN.BillNumber
			FROM APLB
				INNER JOIN inserted
				ON inserted.Co = APLB.Co
				AND inserted.Mth = APLB.Mth
				AND inserted.BatchId = APLB.BatchId
				AND inserted.BatchSeq = APLB.BatchSeq
				AND APLB.LineType = 7  --limit on SL linetype only
				INNER JOIN JBIN 
				ON DATEADD(month, DATEDIFF(month, 0, inserted.InvDate), 0) = JBIN.BillMonth
				AND APLB.Job = JBIN.Contract
		END

	
	IF EXISTS(SELECT * FROM inserted WHERE udApplyPWPComp = 'Y')
		AND EXISTS(SELECT * FROM inserted i INNER JOIN udSLAPHBComp u
		ON u.Co = i.Co
		AND u.Mth = i.Mth
		AND u.BatchId = i.BatchId
		AND u.BatchSeq = i.BatchSeq
		AND u.CompCode = 'PWP')
		AND NOT EXISTS(SELECT * FROM inserted i INNER JOIN udSLAPHBComp u
		ON u.Co = i.Co
		AND u.Mth = i.Mth
		AND u.BatchId = i.BatchId
		AND u.BatchSeq = i.BatchSeq
		AND u.CompCode = 'PWP'
		INNER JOIN udSLAPUIComp a
		ON u.Co = a.Co
		AND u.Mth = a.TransMth
		AND u.APRef = a.APRef) 

		BEGIN

			UPDATE APLB
			SET APLB.udBillMonth = JBIN.BillMonth,
				APLB.udBillInvoice = JBIN.Invoice,
				APLB.udBillNumber = JBIN.BillNumber
			FROM APLB
				INNER JOIN inserted
				ON inserted.Co = APLB.Co
				AND inserted.Mth = APLB.Mth
				AND inserted.BatchId = APLB.BatchId
				AND inserted.BatchSeq = APLB.BatchSeq
				AND APLB.LineType = 7  --limit on SL linetype only
				INNER JOIN JBIN 
				ON DATEADD(month, DATEDIFF(month, 0, inserted.InvDate), 0) = JBIN.BillMonth
				AND APLB.Job = JBIN.Contract
		END


	IF EXISTS(SELECT * FROM inserted WHERE udApplyPWPComp = 'N')
	AND EXISTS(SELECT * FROM inserted i INNER JOIN udSLAPHBComp u
		ON u.Co = i.Co
		AND u.Mth = i.Mth
		AND u.BatchId = i.BatchId
		AND u.BatchSeq = i.BatchSeq
		AND u.CompCode = 'PWP')
	BEGIN
		DELETE u
		FROM udSLAPHBComp u
		INNER JOIN inserted i
		ON u.Co = i.Co
		AND u.Mth = i.Mth
		AND u.BatchId = i.BatchId
		AND u.BatchSeq = i.BatchSeq
		AND u.CompCode = 'PWP'

		UPDATE APLB
		SET APLB.udBillMonth = NULL,
			APLB.udBillInvoice = NULL,
			APLB.udBillNumber = NULL
		FROM APLB
			INNER JOIN inserted
			ON inserted.Co = APLB.Co
			AND inserted.Mth = APLB.Mth
			AND inserted.BatchId = APLB.BatchId
			AND inserted.BatchSeq = APLB.BatchSeq
	END

	IF UPDATE(APRef)
	BEGIN
		UPDATE udSLAPHBComp
		SET udSLAPHBComp.APRef = APHB.APRef
		FROM udSLAPHBComp
		INNER JOIN APHB
		ON udSLAPHBComp.Co = APHB.Co
		AND udSLAPHBComp.Mth = APHB.Mth
		AND udSLAPHBComp.BatchId = APHB.BatchId
		AND udSLAPHBComp.BatchSeq = APHB.BatchSeq
	END
	
	IF EXISTS(SELECT * FROM inserted WHERE UIMth IS NOT NULL)
	BEGIN
		UPDATE udSLAPUIComp
		SET udSLAPUIComp.TransMth = APHB.Mth
		FROM inserted i
		INNER JOIN APHB
		ON APHB.Co = i.Co
		AND APHB.Mth = i.Mth
		AND APHB.BatchId = i.BatchId
		AND APHB.BatchSeq = i.BatchSeq
		INNER JOIN udSLAPUIComp b
		ON i.Co = b.Co
		AND i.UIMth = b.UIMth
		AND i.UISeq = b.UISeq
		AND i.APRef = b.APRef
	END

	--This is to handle AP Changes

	IF EXISTS(SELECT * FROM inserted i INNER JOIN udSLAPHBComp u ON i.Co = u.Co AND i.Mth = u.Mth AND i.APRef = u.APRef HAVING COUNT(u.BatchId)>1)
	BEGIN
		DELETE u
		FROM udSLAPHBComp u
		INNER JOIN inserted i 
		ON i.Co = u.Co
		AND i.Mth = u.Mth
		AND i.APRef = u.APRef
		WHERE u.BatchId < i.BatchId
	END
END
