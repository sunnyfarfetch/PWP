USE [Viewpoint]
GO
/****** Object:  Trigger [dbo].[z_OC_APULSLLinkedBillInvoice]    Script Date: 6/30/2022 7:16:04 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ================================================
-- Author:		Shukai Zhang
-- Create date: 05-05-2022
-- Description: This trigger erases SL Linked Bill
-- Invoice if line type is not SL

-- Auto-fill udBillNumber and udBillInvoice based on each other in AP Unapproved Entry
-- Set holdcode to PWP
-- ================================================
CREATE TRIGGER [dbo].[z_OC_APULSLLinkedBillInvoice]
   ON [dbo].[bAPUL]
   AFTER INSERT, UPDATE
AS 
--For any invoice that have at least one line that is SL related should apply PWP

IF EXISTS(SELECT * FROM inserted i INNER JOIN APUI a ON i.APCo = a.APCo AND i.UIMth = a.UIMth AND i.UISeq = a.UISeq WHERE a.udApplyPWPComp = 'N' and i.LineType = 7) 
AND TRIGGER_NESTLEVEL()=1

	BEGIN

	UPDATE APUI
	SET udApplyPWPComp = 'Y'
	FROM APUI
		INNER JOIN inserted
		ON inserted.APCo = APUI.APCo
		AND inserted.UIMth = APUI.UIMth
		AND inserted.UISeq = APUI.UISeq
	END

IF NOT EXISTS(SELECT * FROM inserted i INNER JOIN APUI a ON i.APCo = a.APCo AND i.UIMth = a.UIMth AND i.UISeq = a.UISeq
INNER JOIN APUL l ON l.UIMth = a.UIMth AND l.UISeq = a.UISeq WHERE a.udApplyPWPComp = 'Y' and i.LineType = 7) 
AND TRIGGER_NESTLEVEL()=1

	BEGIN

	UPDATE APUI
	SET udApplyPWPComp = 'N'
	FROM APUI
		INNER JOIN inserted
		ON inserted.APCo = APUI.APCo
		AND inserted.UIMth = APUI.UIMth
		AND inserted.UISeq = APUI.UISeq
	END

IF EXISTS(SELECT * FROM inserted i INNER JOIN APUI a ON i.APCo = a.APCo AND i.UIMth = a.UIMth AND i.UISeq = a.UISeq WHERE a.udApplyPWPComp = 'Y' and i.LineType != 7) -- LineType is SL
AND TRIGGER_NESTLEVEL()=1

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
		AND inserted.Line = APUL.Line
	END

IF EXISTS(SELECT * FROM inserted i INNER JOIN APUI a ON i.APCo = a.APCo AND i.UIMth = a.UIMth AND i.UISeq = a.UISeq WHERE a.udApplyPWPComp = 'Y' and i.LineType = 7) -- LineType is SL
AND TRIGGER_NESTLEVEL()=1

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
		AND inserted.Line = APUL.Line
		INNER JOIN APUI a
		ON inserted.APCo = a.APCo
		AND inserted.UIMth = a.UIMth
		AND inserted.UISeq = a.UISeq
		INNER JOIN JBIN 
		ON DATEADD(month, DATEDIFF(month, 0, a.InvDate), 0) = JBIN.BillMonth
		AND APUL.Job = JBIN.Contract

	UPDATE APUI
	SET HoldCode = 'PWP'
	FROM APUI
		INNER JOIN inserted
		ON inserted.APCo = APUI.APCo
		AND inserted.UIMth = APUI.UIMth
		AND inserted.UISeq = APUI.UISeq
	END



IF UPDATE(udBillNumber) AND EXISTS(SELECT * FROM inserted i INNER JOIN APUI a ON i.APCo = a.APCo AND i.UIMth = a.UIMth AND i.UISeq = a.UISeq WHERE a.udApplyPWPComp = 'Y' and i.LineType = 7 AND a.HoldCode IS NULL) 
AND TRIGGER_NESTLEVEL()=1

	BEGIN
	UPDATE APUL
	SET udBillInvoice = JBIN.Invoice
	FROM APUL
		INNER JOIN inserted
		ON inserted.APCo = APUL.APCo
		AND inserted.UIMth = APUL.UIMth
		AND inserted.UISeq = APUL.UISeq
		AND inserted.Line = APUL.Line
		INNER JOIN JBIN 
		ON inserted.udBillNumber = JBIN.BillNumber
		AND inserted.udBillMonth = JBIN.BillMonth
		WHERE inserted.udBillMonth IS NOT NULL
	END

IF UPDATE(udBillNumber) AND NOT EXISTS(SELECT * FROM inserted i INNER JOIN APUI a ON i.APCo = a.APCo AND i.UIMth = a.UIMth AND i.UISeq = a.UISeq WHERE a.udApplyPWPComp = 'Y' and i.LineType = 7 AND a.HoldCode IS NULL) 
AND TRIGGER_NESTLEVEL()=1

	BEGIN
	UPDATE APUL
	SET udBillInvoice = JBIN.Invoice
	FROM APUL
		INNER JOIN inserted
		ON inserted.APCo = APUL.APCo
		AND inserted.UIMth = APUL.UIMth
		AND inserted.UISeq = APUL.UISeq
		AND inserted.Line = APUL.Line
		INNER JOIN JBIN 
		ON inserted.udBillNumber = JBIN.BillNumber
		AND inserted.udBillMonth = JBIN.BillMonth
		WHERE inserted.udBillMonth IS NOT NULL

	UPDATE APUI
	SET HoldCode = 'PWP'
	FROM APUI
		INNER JOIN inserted
		ON inserted.APCo = APUI.APCo
		AND inserted.UIMth = APUI.UIMth
		AND inserted.UISeq = APUI.UISeq
	END


IF UPDATE(udBillInvoice) AND EXISTS(SELECT * FROM inserted i INNER JOIN APUI a ON i.APCo = a.APCo AND i.UIMth = a.UIMth AND i.UISeq = a.UISeq WHERE a.udApplyPWPComp = 'Y' and i.LineType = 7 AND a.HoldCode IS NULL) 
AND TRIGGER_NESTLEVEL()=1


	BEGIN
	UPDATE APUL
	SET udBillNumber = JBIN.BillNumber
	FROM APUL
		INNER JOIN inserted
		ON inserted.APCo = APUL.APCo
		AND inserted.UIMth = APUL.UIMth
		AND inserted.UISeq = APUL.UISeq
		AND inserted.Line = APUL.Line
		INNER JOIN JBIN 
		ON inserted.udBillInvoice = JBIN.Invoice
		AND inserted.udBillMonth = JBIN.BillMonth
		WHERE inserted.udBillMonth IS NOT NULL
	END




IF UPDATE(udBillInvoice) AND NOT EXISTS(SELECT * FROM inserted i INNER JOIN APUI a ON i.APCo = a.APCo AND i.UIMth = a.UIMth AND i.UISeq = a.UISeq WHERE a.udApplyPWPComp = 'Y' and i.LineType = 7 AND a.HoldCode IS NULL) 
AND TRIGGER_NESTLEVEL()=1


	BEGIN
	UPDATE APUL
	SET udBillNumber = JBIN.BillNumber
	FROM APUL
		INNER JOIN inserted
		ON inserted.APCo = APUL.APCo
		AND inserted.UIMth = APUL.UIMth
		AND inserted.UISeq = APUL.UISeq
		AND inserted.Line = APUL.Line
		INNER JOIN JBIN 
		ON inserted.udBillInvoice = JBIN.Invoice
		AND inserted.udBillMonth = JBIN.BillMonth
		WHERE inserted.udBillMonth IS NOT NULL

	UPDATE APUI
	SET HoldCode = 'PWP'
	FROM APUI
		INNER JOIN inserted
		ON inserted.APCo = APUI.APCo
		AND inserted.UIMth = APUI.UIMth
		AND inserted.UISeq = APUI.UISeq
	END





