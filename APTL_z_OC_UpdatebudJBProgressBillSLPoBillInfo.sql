USE [Viewpoint]
GO

/****** Object:  Trigger [dbo].[z_OC_UpdatebudJBProgressBillSLPoBillInfo]    Script Date: 6/30/2022 7:26:14 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- ================================================
-- Author:		Shukai Zhang
-- Create date: 05-05-2022
-- Description: This trigger updates Bill info in 
-- custom table 
-- ================================================
CREATE TRIGGER [dbo].[z_OC_UpdatebudJBProgressBillSLPoBillInfo]
   ON [dbo].[bAPTL]
   AFTER UPDATE
AS 
	IF UPDATE(udBillNumber)

	BEGIN
	
		UPDATE budJBProgressBillSLPo
		SET BillInvoice = inserted.udBillInvoice
			,BillMonth = inserted.udBillMonth
			,BillNumber = inserted.udBillNumber
			,PercentComplete = 1
			,AmountCompleteThisBill = BeginRemainingAmount
			,EndRemainingAmount = 0
			,Interfaced = CASE WHEN JBIN.InvStatus = 'I' THEN 'Y'
							ELSE 'N'
							END
		FROM inserted
		INNER JOIN budJBProgressBillSLPo b
		ON b.Co = inserted.APCo
		AND b.TransMth = inserted.Mth
		AND b.APTrans = inserted.APTrans
		AND b.APLine = inserted.APLine
		INNER JOIN APTD
		ON inserted.APCo = APTD.APCo
		AND inserted.Mth = APTD.Mth
		AND inserted.APTrans = APTD.APTrans
		AND inserted.APLine = APTD.APLine
		AND b.APSeq = APTD.APSeq
		INNER JOIN APTH
		ON APTH.APCo = b.Co
		AND APTH.APTrans = b.APTrans
		AND APTH.Mth = b.TransMth
		LEFT JOIN APVM
		ON APTH.VendorGroup = APVM.VendorGroup
		AND APTH.Vendor = APVM.Vendor
		INNER JOIN JBIN 
		ON JBIN.JBCo = b.Co 
		AND JBIN.BillMonth = inserted.udBillMonth 
		AND JBIN.BillNumber = inserted.udBillNumber 
		AND JBIN.Invoice = inserted.udBillInvoice 
		AND JBIN.Contract = b.Job
		WHERE APTH.APCo = 9                  -- 9 is live company
		AND APTH.Mth >= '2020-01-01' 
		AND inserted.SL IS NOT NULL 
		AND APTD.Status != 3 

		-- Auto complied PWP for linked bill already paid in full
		IF EXISTS(SELECT 1 FROM budSLAPInvComp c
		INNER JOIN inserted i ON c.Co = i.APCo AND c.TransMth = i.Mth AND c.APTrans = i.APTrans AND c.APLine = i.APLine
		INNER JOIN ARTH a ON a.ARCo = i.APCo AND a.Contract = i.Job AND a.Invoice = i.udBillInvoice
		WHERE a.PayFullDate IS NOT NULL AND a.Source = 'JB' AND c.CompCode = 'PWP')
		BEGIN

		UPDATE c
		SET c.Complied = 'Y'
		FROM budSLAPInvComp c
		INNER JOIN inserted i ON c.Co = i.APCo AND c.TransMth = i.Mth AND c.APTrans = i.APTrans AND c.APLine = i.APLine
		INNER JOIN ARTH a ON a.ARCo = i.APCo AND a.Contract = i.Job AND a.Invoice = i.udBillInvoice
		WHERE a.PayFullDate IS NOT NULL AND a.Source = 'JB' AND c.CompCode = 'PWP'
		END

	END
