USE [Viewpoint]
GO
/****** Object:  Trigger [dbo].[z_OC_UpdateSLCompleteAmt]    Script Date: 6/30/2022 7:34:26 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Shukai Zhang OC
-- Create date: 2022-04-07
-- Description:	The purpose of this trigger is to complete the functionalities on the custom table
-- =============================================
CREATE TRIGGER [dbo].[z_OC_UpdateSLCompleteAmt]
   ON  [dbo].[budJBProgressBillSLPo]
   After INSERT, UPDATE
AS 

IF EXISTS(SELECT * 
FROM budJBProgressBillSLPo b 
INNER JOIN deleted ON deleted.Co = b.Co AND deleted.Seq = b.Seq AND deleted.Job = b.Job
INNER JOIN inserted ON inserted.Co = b.Co AND inserted.Seq = b.Seq AND inserted.Job = b.Job AND inserted.APStatus = deleted.APStatus
INNER JOIN JBIN ON inserted.BillMonth = JBIN.BillMonth AND inserted.BillNumber = JBIN.BillNumber AND inserted.BillInvoice = JBIN.Invoice
WHERE (inserted.Interfaced = 'Y' AND deleted.Interfaced = 'Y' AND JBIN.InvStatus = 'I' AND inserted.APStatus = deleted.APStatus AND deleted.BillMonth IS NOT NULL AND deleted.BillNumber IS NOT NULL AND deleted.BillInvoice IS NOT NULL)
OR (inserted.Interfaced = 'N' AND deleted.Interfaced = 'Y' AND JBIN.InvStatus = 'I' AND inserted.APStatus = deleted.APStatus AND deleted.BillMonth IS NOT NULL AND deleted.BillNumber IS NOT NULL AND deleted.BillInvoice IS NOT NULL))
BEGIN
RAISERROR('You cannot edit a record that has been interfaced!',11,1)
ROLLBACK TRANSACTION

END

IF UPDATE(AmountCompleteThisBill)
	BEGIN
	
	IF TRIGGER_NESTLEVEL() > 1
	RETURN


	UPDATE dbo.budJBProgressBillSLPo
	SET EndRemainingAmount = inserted.BeginRemainingAmount - inserted.AmountCompleteThisBill 
	,PercentComplete = inserted.AmountCompleteThisBill/inserted.BeginRemainingAmount
	FROM dbo.budJBProgressBillSLPo b
	INNER JOIN inserted
	ON inserted.Co = b.Co
	AND inserted.Seq = b.Seq
	AND inserted.Job = b.Job

	END

IF UPDATE(EndRemainingAmount)
	BEGIN
	
	IF TRIGGER_NESTLEVEL() > 1
	RETURN


	UPDATE dbo.budJBProgressBillSLPo
	SET AmountCompleteThisBill = inserted.BeginRemainingAmount - inserted.EndRemainingAmount
	,PercentComplete = (inserted.BeginRemainingAmount - inserted.EndRemainingAmount)/inserted.BeginRemainingAmount
	FROM dbo.budJBProgressBillSLPo b
	INNER JOIN inserted
	ON inserted.Co = b.Co
	AND inserted.Seq = b.Seq
	AND inserted.Job = b.Job
	

	END

IF UPDATE(PercentComplete)
	BEGIN
	
	IF TRIGGER_NESTLEVEL() > 1
	RETURN


	UPDATE dbo.budJBProgressBillSLPo
	SET AmountCompleteThisBill = inserted.BeginRemainingAmount*inserted.PercentComplete
	,EndRemainingAmount = inserted.BeginRemainingAmount*(1-inserted.PercentComplete)
	FROM dbo.budJBProgressBillSLPo b
	INNER JOIN inserted
	ON inserted.Co = b.Co
	AND inserted.Seq = b.Seq
	AND inserted.Job = b.Job
	

	END

--IF UPDATE(BillMonth)

--	IF EXISTS(SELECT * FROM budJBProgressBillSLPo b INNER JOIN inserted ON inserted.Co = b.Co AND inserted.Seq = b.Seq AND inserted.Job = b.Job 
--	INNER JOIN deleted ON deleted.Co = b.Co AND deleted.Seq = b.Seq AND deleted.Job = b.Job WHERE inserted.Interfaced = 'Y' AND deleted.BillMonth IS NOT NULL AND deleted.BillNumber IS NOT NULL AND deleted.BillInvoice IS NOT NULL)

--	BEGIN
--	RAISERROR('You cannot edit a record that has been interfaced!',11,1)
--	ROLLBACK TRANSACTION

--	END

IF UPDATE(BillNumber)

	IF EXISTS(SELECT * FROM budJBProgressBillSLPo b INNER JOIN inserted ON inserted.Co = b.Co AND inserted.Seq = b.Seq AND inserted.Job = b.Job WHERE inserted.Interfaced = 'Y')

	BEGIN
	RAISERROR('You cannot edit a record that has been interfaced!',11,1)
	ROLLBACK TRANSACTION

	END

	ELSE IF EXISTS(SELECT * FROM budJBProgressBillSLPo b INNER JOIN inserted ON inserted.Co = b.Co AND inserted.Seq = b.Seq AND inserted.Job = b.Job WHERE inserted.BillMonth IS NOT NULL)

	BEGIN
	
	IF TRIGGER_NESTLEVEL() > 1
	RETURN

	UPDATE dbo.budJBProgressBillSLPo
	SET BillInvoice = Invoice
		,PercentComplete = 1
		,AmountCompleteThisBill = inserted.BeginRemainingAmount
		,EndRemainingAmount = 0
	FROM dbo.budJBProgressBillSLPo b
	INNER JOIN inserted
	ON inserted.Co = b.Co
	AND inserted.Seq = b.Seq
	AND inserted.Job = b.Job
	INNER JOIN JBIN
	ON JBIN.JBCo = b.Co
	AND JBIN.BillMonth = b.BillMonth
	AND JBIN.BillNumber = b.BillNumber

	END


IF UPDATE(BillInvoice)
	
	IF EXISTS(SELECT * FROM budJBProgressBillSLPo b INNER JOIN inserted ON inserted.Co = b.Co AND inserted.Seq = b.Seq AND inserted.Job = b.Job WHERE inserted.Interfaced = 'Y')

	BEGIN
	RAISERROR('You cannot edit a record that has been interfaced!',11,1)
	ROLLBACK TRANSACTION

	END

	ELSE IF EXISTS(SELECT * FROM budJBProgressBillSLPo b INNER JOIN inserted ON inserted.Co = b.Co AND inserted.Seq = b.Seq AND inserted.Job = b.Job WHERE inserted.BillMonth IS NOT NULL)

	BEGIN
	
	IF TRIGGER_NESTLEVEL() > 1
	RETURN

	UPDATE dbo.budJBProgressBillSLPo
	SET BillNumber = JBIN.BillNumber
		,PercentComplete = 1
		,AmountCompleteThisBill = inserted.BeginRemainingAmount
		,EndRemainingAmount = 0
	FROM dbo.budJBProgressBillSLPo b
	INNER JOIN inserted
	ON inserted.Co = b.Co
	AND inserted.Seq = b.Seq
	AND inserted.Job = b.Job
	INNER JOIN JBIN
	ON JBIN.JBCo = b.Co
	AND JBIN.BillMonth = b.BillMonth
	AND JBIN.Invoice = b.BillInvoice

	END


GO

ALTER TABLE [dbo].[budJBProgressBillSLPo] ENABLE TRIGGER [z_OC_UpdateSLCompleteAmt]
GO
