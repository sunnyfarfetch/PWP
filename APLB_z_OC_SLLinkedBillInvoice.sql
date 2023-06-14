USE [Viewpoint]
GO
/****** Object:  Trigger [dbo].[z_OC_APLBSLLinkedBillInvoice]    Script Date: 5/10/2022 11:55:30 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ================================================
-- Author:		Shukai Zhang
-- Create date: 05-05-2022
-- Description: This trigger erases SL Linked Bill
-- Invoice if line type is not SL

-- Auto-fill udBillNumber and udBillInvoice based on each other in AP Transaction Entry Batch
-- Set holdcode to PWP
-- ================================================
CREATE TRIGGER [dbo].[z_OC_APLBSLLinkedBillInvoice]
   ON [dbo].[bAPLB]
   AFTER INSERT, UPDATE
AS 
--For KLS where any invoice that have at least one line that is job related should apply PWP

IF EXISTS(SELECT * FROM inserted i INNER JOIN APHB a ON i.Co = a.Co AND i.Mth = a.Mth AND i.BatchId = a.BatchId AND i.BatchSeq = a.BatchSeq WHERE a.udApplyPWPComp = 'N' AND i.LineType != 7) 
AND TRIGGER_NESTLEVEL()=1

	BEGIN

	UPDATE APHB
	SET udApplyPWPComp = 'Y'
	FROM APHB
		INNER JOIN inserted
		ON inserted.Co = APHB.Co
		AND inserted.Mth = APHB.Mth
		AND inserted.BatchId = APHB.BatchId
		AND inserted.BatchSeq = APHB.BatchSeq
	END

IF NOT EXISTS(SELECT * FROM inserted i INNER JOIN APHB a ON i.Co = a.Co AND i.Mth = a.Mth AND i.BatchId = a.BatchId AND i.BatchSeq = a.BatchSeq 
INNER JOIN APLB l ON l.Mth = a.Mth AND l.BatchId = a.BatchId AND l.BatchSeq = a.BatchSeq WHERE a.udApplyPWPComp = 'Y' AND i.LineType != 7) 
AND TRIGGER_NESTLEVEL()=1

	BEGIN

	UPDATE APHB
	SET udApplyPWPComp = 'N'
	FROM APHB
		INNER JOIN inserted
		ON inserted.Co = APHB.Co
		AND inserted.Mth = APHB.Mth
		AND inserted.BatchId = APHB.BatchId
		AND inserted.BatchSeq = APHB.BatchSeq
	END



--For all 

IF EXISTS(SELECT * FROM inserted i INNER JOIN APHB a ON i.Co = a.Co AND i.Mth = a.Mth AND i.BatchId = a.BatchId AND i.BatchSeq = a.BatchSeq WHERE a.udApplyPWPComp = 'Y' and i.LineType != 7) 
AND TRIGGER_NESTLEVEL()=1

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
		AND inserted.APLine = APLB.APLine
		INNER JOIN APHB a
		ON inserted.Co = a.Co
		AND inserted.Mth = a.Mth
		AND inserted.BatchId = a.BatchId
		AND inserted.BatchSeq = a.BatchSeq
		INNER JOIN JBIN 
		ON DATEADD(month, DATEDIFF(month, 0, a.InvDate), 0) = JBIN.BillMonth
		AND APLB.Job = JBIN.Contract
	

	UPDATE APHB
	SET HoldCode = 'PWP'
	FROM APHB
		INNER JOIN inserted
		ON inserted.Co = APHB.Co
		AND inserted.Mth = APHB.Mth
		AND inserted.BatchId = APHB.BatchId
		AND inserted.BatchSeq = APHB.BatchSeq
	END

-- Erases SL Linked Bill Invoice if line type is not SL
IF EXISTS(SELECT * FROM inserted i INNER JOIN APHB a ON i.Co = a.Co AND i.Mth = a.Mth AND i.BatchId = a.BatchId AND i.BatchSeq = a.BatchSeq WHERE a.udApplyPWPComp = 'Y' and i.LineType != 7) 
AND TRIGGER_NESTLEVEL()=1

	BEGIN
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
		AND inserted.APLine = APLB.APLine
	END

IF EXISTS(SELECT * FROM inserted i INNER JOIN APHB a ON i.Co = a.Co AND i.Mth = a.Mth AND i.BatchId = a.BatchId AND i.BatchSeq = a.BatchSeq WHERE a.udApplyPWPComp = 'Y' and i.LineType = 7)
AND TRIGGER_NESTLEVEL()=1


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
		AND inserted.APLine = APLB.APLine
		INNER JOIN APHB a
		ON inserted.Co = a.Co
		AND inserted.Mth = a.Mth
		AND inserted.BatchId = a.BatchId
		AND inserted.BatchSeq = a.BatchSeq
		INNER JOIN JBIN 
		ON DATEADD(month, DATEDIFF(month, 0, a.InvDate), 0) = JBIN.BillMonth
		AND APLB.Job = JBIN.Contract

	UPDATE APHB
	SET HoldCode = 'PWP'
	FROM APHB
		INNER JOIN inserted
		ON inserted.Co = APHB.Co
		AND inserted.Mth = APHB.Mth
		AND inserted.BatchId = APHB.BatchId
		AND inserted.BatchSeq = APHB.BatchSeq
	END




--Auto-fill udBillNumber and udBillInvoice based on each other in AP Transaction Entry Batch

IF UPDATE(udBillNumber) AND EXISTS(SELECT * FROM inserted i INNER JOIN APHB a ON i.Co = a.Co AND i.Mth = a.Mth AND i.BatchId = a.BatchId AND i.BatchSeq = a.BatchSeq WHERE a.udApplyPWPComp = 'Y' and i.LineType = 7 AND a.HoldCode IS NULL) 
AND TRIGGER_NESTLEVEL()=1

	BEGIN
	UPDATE APLB
	SET udBillInvoice = JBIN.Invoice
	FROM APLB
		INNER JOIN inserted
		ON inserted.Co = APLB.Co
		AND inserted.Mth = APLB.Mth
		AND inserted.BatchId = APLB.BatchId
		AND inserted.BatchSeq = APLB.BatchSeq
		AND inserted.APLine = APLB.APLine
		INNER JOIN JBIN 
		ON inserted.udBillNumber = JBIN.BillNumber
		AND inserted.udBillMonth = JBIN.BillMonth
		WHERE inserted.udBillMonth IS NOT NULL

	
	UPDATE APHB
	SET HoldCode = 'PWP'
	FROM APHB
		INNER JOIN inserted
		ON inserted.Co = APHB.Co
		AND inserted.Mth = APHB.Mth
		AND inserted.BatchId = APHB.BatchId
		AND inserted.BatchSeq = APHB.BatchSeq
	END




IF UPDATE(udBillNumber) AND NOT EXISTS(SELECT * FROM inserted i INNER JOIN APHB a ON i.Co = a.Co AND i.Mth = a.Mth AND i.BatchId = a.BatchId AND i.BatchSeq = a.BatchSeq WHERE a.udApplyPWPComp = 'Y' and i.LineType = 7 AND a.HoldCode IS NULL) 
AND TRIGGER_NESTLEVEL()=1

	BEGIN
	UPDATE APLB
	SET udBillInvoice = JBIN.Invoice
	FROM APLB
		INNER JOIN inserted
		ON inserted.Co = APLB.Co
		AND inserted.Mth = APLB.Mth
		AND inserted.BatchId = APLB.BatchId
		AND inserted.BatchSeq = APLB.BatchSeq
		AND inserted.APLine = APLB.APLine
		INNER JOIN JBIN 
		ON inserted.udBillNumber = JBIN.BillNumber
		AND inserted.udBillMonth = JBIN.BillMonth
		WHERE inserted.udBillMonth IS NOT NULL


	END




IF UPDATE(udBillInvoice) AND EXISTS(SELECT * FROM inserted i INNER JOIN APHB a ON i.Co = a.Co AND i.Mth = a.Mth AND i.BatchId = a.BatchId AND i.BatchSeq = a.BatchSeq WHERE a.udApplyPWPComp = 'Y' and i.LineType = 7 AND a.HoldCode IS NULL) 
AND TRIGGER_NESTLEVEL()=1

	BEGIN
	UPDATE APLB
	SET udBillNumber = JBIN.BillNumber
	FROM APLB
		INNER JOIN inserted
		ON inserted.Co = APLB.Co
		AND inserted.Mth = APLB.Mth
		AND inserted.BatchId = APLB.BatchId
		AND inserted.BatchSeq = APLB.BatchSeq
		AND inserted.APLine = APLB.APLine
		INNER JOIN JBIN 
		ON inserted.udBillInvoice = JBIN.Invoice
		AND inserted.udBillMonth = JBIN.BillMonth
		WHERE inserted.udBillMonth IS NOT NULL

	UPDATE APHB
	SET HoldCode = 'PWP'
	FROM APHB
		INNER JOIN inserted
		ON inserted.Co = APHB.Co
		AND inserted.Mth = APHB.Mth
		AND inserted.BatchId = APHB.BatchId
		AND inserted.BatchSeq = APHB.BatchSeq
	END


IF UPDATE(udBillInvoice) AND NOT EXISTS(SELECT * FROM inserted i INNER JOIN APHB a ON i.Co = a.Co AND i.Mth = a.Mth AND i.BatchId = a.BatchId AND i.BatchSeq = a.BatchSeq WHERE a.udApplyPWPComp = 'Y' and i.LineType = 7 AND a.HoldCode IS NULL) 
AND TRIGGER_NESTLEVEL()=1

	BEGIN
	UPDATE APLB
	SET udBillNumber = JBIN.BillNumber
	FROM APLB
		INNER JOIN inserted
		ON inserted.Co = APLB.Co
		AND inserted.Mth = APLB.Mth
		AND inserted.BatchId = APLB.BatchId
		AND inserted.BatchSeq = APLB.BatchSeq
		AND inserted.APLine = APLB.APLine
		INNER JOIN JBIN 
		ON inserted.udBillInvoice = JBIN.Invoice
		AND inserted.udBillMonth = JBIN.BillMonth
		WHERE inserted.udBillMonth IS NOT NULL

	END


