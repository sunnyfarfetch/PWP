USE [Viewpoint]
GO
/****** Object:  Trigger [dbo].[z_OC_InsertUpdatebudJBProgressBillSLPo]    Script Date: 7/19/2022 11:34:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Shukai Zhang OC
-- Create date: 2022-04-07
-- Description:	The purpose of this trigger is to insert into budJBProgressBillSLPo
-- =============================================
CREATE TRIGGER [dbo].[z_OC_InsertUpdatebudJBProgressBillSLPo]
   ON  [dbo].[bAPTD]
   After INSERT, UPDATE
	AS 
	IF EXISTS(SELECT * 
		FROM inserted 
		LEFT JOIN budJBProgressBillSLPo b 
		ON inserted.APCo = b.Co
		AND inserted.Mth = b.TransMth
		AND inserted.APTrans = b.APTrans
		AND inserted.APLine = b.APLine
		AND inserted.APSeq = b.APSeq
		WHERE Status !=3 AND b.SL IS NULL)
		AND NOT EXISTS(SELECT * 
		FROM inserted 
		INNER JOIN budJBProgressBillSLPo b 
		ON inserted.APCo = b.Co
		AND inserted.Mth = b.TransMth
		AND inserted.APTrans = b.APTrans
		AND inserted.APLine = b.APLine
		AND inserted.APSeq = b.APSeq
		WHERE Status !=3)
		
		BEGIN
	
		DECLARE @newseq INT = (SELECT max(Seq)+1 FROM (SELECT Seq FROM budJBProgressBillSLPo UNION SELECT Seq FROM budJBBillSLPoHistory) AS sub)
		INSERT INTO budJBProgressBillSLPo (
			Co
			,TransMth
			,APTrans
			,APLine
			,APSeq
			,Vendor
			,VendorName
			,Job
			,SL
			,Description
			,APInvDate
			,Retainage
			,BeginRemainingAmount
			,PercentComplete
			,AmountCompleteThisBill
			,EndRemainingAmount
			,APStatus
			,TotalAmount
			,Interfaced
			,Seq
			,BillInvoice
			,BillMonth
			,BillNumber)
		SELECT APTH.APCo AS [Co], APTH.Mth AS [TransMth], APTH.APTrans AS [APTrans], APTL.APLine AS [APLine], inserted.APSeq AS [APSeq], APTH.Vendor AS [Vendor], APVM.Name AS [VendorName], APTL.Job AS [Job]
			, APTL.SL AS [SL],  APTL.Description AS [Description], InvDate AS [APInvDate], Retainage AS [Retainage], inserted.Amount AS [BeginRemainingAmount], 0 AS [PercentComplete], 0 AS [AmountCompleteThisBill], inserted.Amount AS [EndRemainingAmount], 
			CASE 
				WHEN Status = 1 THEN 'Open'
				WHEN Status = 2 THEN 'On Hold'
				END AS [APStatus]
			, inserted.Amount AS [TotalAmount], 'N' AS [Interfaced], ISNULL(@newseq,1) AS [Seq], APTL.udBillInvoice AS [BillInvoice], APTL.udBillMonth AS [BillMonth], APTL.udBillNumber AS [BillNumber]
			FROM APTH 
			INNER JOIN APTL
			ON APTH.APCo = APTL.APCo
			AND APTH.Mth = APTL.Mth
			AND APTH.APTrans = APTL.APTrans
			LEFT JOIN APVM
			ON APTH.VendorGroup = APVM.VendorGroup
			AND APTH.Vendor = APVM.Vendor
			INNER JOIN inserted
			ON inserted.APCo = APTL.APCo
			AND inserted.Mth = APTL.Mth
			AND inserted.APTrans = APTL.APTrans
			AND inserted.APLine = APTL.APLine
			WHERE APTH.APCo = 9 -- Live Company is 9
			AND APTH.Mth >= '2020-01-01' AND APTL.SL IS NOT NULL AND inserted.Status != 3 

	END

	IF EXISTS(SELECT * 
		FROM inserted 
		LEFT JOIN budJBProgressBillSLPo b 
		ON inserted.APCo = b.Co
		AND inserted.Mth = b.TransMth
		AND inserted.APTrans = b.APTrans
		AND inserted.APLine = b.APLine
		AND inserted.APSeq = b.APSeq
		WHERE Status !=3 AND b.SL IS NOT NULL)
		AND EXISTS(SELECT * 
		FROM inserted 
		INNER JOIN budJBProgressBillSLPo b 
		ON inserted.APCo = b.Co
		AND inserted.Mth = b.TransMth
		AND inserted.APTrans = b.APTrans
		AND inserted.APLine = b.APLine
		AND inserted.APSeq = b.APSeq
		WHERE Status !=3 AND b.SL IS NOT NULL)

	BEGIN

	UPDATE budJBProgressBillSLPo 
	SET		Co = APTH.APCo
			,TransMth =  APTH.Mth
			,APTrans = APTH.APTrans
			,APLine = APTL.APLine
			,APSeq = inserted.APSeq
			,Vendor = APTH.Vendor
			,VendorName = APVM.Name
			,Job = APTL.Job
			,SL = APTL.SL
			,Description = APTL.Description
			,APInvDate = APTH.InvDate
			,Retainage = APTL.Retainage
			,APStatus = CASE 
				WHEN Status = 1 THEN 'Open'
				WHEN Status = 2 THEN 'On Hold'
				END
			,TotalAmount = inserted.Amount 
			,BeginRemainingAmount = inserted.Amount
			,PercentComplete = 1
			,AmountCompleteThisBill = inserted.Amount
			,EndRemainingAmount = 0
			,BillInvoice = APTL.udBillInvoice
			,BillMonth = APTL.udBillMonth
			,BillNumber =  APTL.udBillNumber
			FROM APTH 
			INNER JOIN APTL
			ON APTH.APCo = APTL.APCo
			AND APTH.Mth = APTL.Mth
			AND APTH.APTrans = APTL.APTrans
			LEFT JOIN APVM
			ON APTH.VendorGroup = APVM.VendorGroup
			AND APTH.Vendor = APVM.Vendor
			INNER JOIN inserted
			ON inserted.APCo = APTL.APCo
			AND inserted.Mth = APTL.Mth
			AND inserted.APTrans = APTL.APTrans
			AND inserted.APLine = APTL.APLine
			INNER JOIN budJBProgressBillSLPo b 
			ON inserted.APCo = b.Co
			AND inserted.Mth = b.TransMth
			AND inserted.APTrans = b.APTrans
			AND inserted.APLine = b.APLine
			AND inserted.APSeq = b.APSeq
			WHERE APTH.APCo = 9 -- Live Company is 9
			AND APTH.Mth >= '2020-01-01' AND APTL.SL IS NOT NULL AND inserted.Status != 3  

	END

	IF UPDATE(Status) 
		IF EXISTS(SELECT * 
		FROM inserted 
		INNER JOIN deleted 
		ON inserted.APCo = deleted.APCo
		AND inserted.Mth = deleted.Mth
		AND inserted.APTrans = deleted.APTrans
		AND inserted.APLine = deleted.APLine
		AND inserted.APSeq = deleted.APSeq
		WHERE inserted.Status != 3 AND inserted.Status != deleted.Status)

		UPDATE budJBProgressBillSLPo
		SET budJBProgressBillSLPo.APStatus = CASE inserted.Status WHEN 1 THEN 'Open' 
													WHEN 2 THEN 'On Hold' 
													WHEN 3 THEN 'Paid'
													END
		FROM inserted
		INNER JOIN budJBProgressBillSLPo b
		ON inserted.APCo = b.Co
		AND inserted.Mth = b.TransMth
		AND inserted.APTrans = b.APTrans
		AND inserted.APLine = b.APLine
		AND inserted.APSeq = b.APSeq
		
		IF EXISTS(SELECT * 
		FROM inserted 
		INNER JOIN deleted 
		ON inserted.APCo = deleted.APCo
		AND inserted.Mth = deleted.Mth
		AND inserted.APTrans = deleted.APTrans
		AND inserted.APLine = deleted.APLine
		AND inserted.APSeq = deleted.APSeq
		WHERE inserted.Status = 3 and deleted.Status != 3)

		BEGIN

		INSERT INTO budJBBillSLPoHistory (
			Co
			,TransMth
			,APTrans
			,APLine
			,APSeq
			,Vendor
			,VendorName
			,Job
			,SL
			,Description
			,APInvDate
			,Retainage
			,BeginRemainingAmount
			,PercentComplete
			,AmountCompleteThisBill
			,EndRemainingAmount
			,APStatus
			,TotalAmount
			,Interfaced
			,BillMonth
			,BillNumber
			,BillInvoice
			,Seq)
		SELECT Co
			,TransMth
			,b.APTrans
			,b.APLine
			,b.APSeq
			,b.Vendor
			,VendorName
			,b.Job
			,b.SL
			,b.Description
			,APInvDate
			,b.Retainage
			,BeginRemainingAmount
			,PercentComplete
			,AmountCompleteThisBill
			,EndRemainingAmount
			,'Paid'
			,TotalAmount
			,Interfaced
			,BillMonth
			,BillNumber
			,BillInvoice
			,Seq
			FROM dbo.budJBProgressBillSLPo b
			INNER JOIN APTH 
			ON APTH.APCo = b.Co
			AND APTH.Mth = b.TransMth
			AND APTH.APTrans = b.APTrans
			AND APTH.Vendor = b.Vendor
			INNER JOIN APTL
			ON APTH.APCo = APTL.APCo
			AND APTH.Mth = APTL.Mth
			AND APTH.APTrans = APTL.APTrans
			AND b.APLine = APTL.APLine
			INNER JOIN inserted
			ON inserted.APCo = b.Co
			AND inserted.Mth = b.TransMth
			AND inserted.APLine = b.APLine
			AND inserted.APSeq = b.APSeq
			AND inserted.APTrans = APTH.APTrans
			WHERE inserted.Status = 3

		DELETE b
		FROM dbo.budJBProgressBillSLPo b
		INNER JOIN APTH 
		ON APTH.APCo = b.Co
		AND APTH.Mth = b.TransMth
		AND APTH.APTrans = b.APTrans
		AND APTH.Vendor = b.Vendor
		INNER JOIN APTL
		ON APTH.APCo = APTL.APCo
		AND APTH.Mth = APTL.Mth
		AND APTH.APTrans = APTL.APTrans
		AND b.APLine = APTL.APLine
		INNER JOIN inserted
		ON inserted.APCo = b.Co
		AND inserted.Mth = b.TransMth
		AND inserted.APLine = b.APLine
		AND inserted.APSeq = b.APSeq
		AND inserted.APTrans = APTH.APTrans
		WHERE inserted.Status = 3

	END

	IF UPDATE(Amount) 
		
		IF EXISTS(SELECT * 
		FROM inserted 
		INNER JOIN deleted 
		ON inserted.APCo = deleted.APCo
		AND inserted.Mth = deleted.Mth
		AND inserted.APTrans = deleted.APTrans
		AND inserted.APLine = deleted.APLine
		AND inserted.APSeq = deleted.APSeq
		WHERE inserted.Status != 3 and deleted.Status != 3)

		BEGIN

		UPDATE b
		SET b.TotalAmount = inserted.Amount
			,b.BeginRemainingAmount = inserted.Amount
			,b.PercentComplete = b.AmountCompleteThisBill/inserted.Amount
			,b.EndRemainingAmount = inserted.Amount - b.AmountCompleteThisBill
		FROM dbo.budJBProgressBillSLPo b
		INNER JOIN APTH 
		ON APTH.APCo = b.Co
		AND APTH.Mth = b.TransMth
		AND APTH.APTrans = b.APTrans
		AND APTH.Vendor = b.Vendor
		INNER JOIN APTL
		ON APTH.APCo = APTL.APCo
		AND APTH.Mth = APTL.Mth
		AND APTH.APTrans = APTL.APTrans
		AND b.APLine = APTL.APLine
		INNER JOIN inserted
		ON inserted.APCo = b.Co
		AND inserted.Mth = b.TransMth
		AND inserted.APLine = b.APLine
		AND inserted.APSeq = b.APSeq
		AND inserted.APTrans = APTH.APTrans
		WHERE inserted.Status != 3

	END
