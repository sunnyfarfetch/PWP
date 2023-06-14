USE [Viewpoint]
GO
/****** Object:  Trigger [dbo].[z_OC_AutoLinkAP]    Script Date: 7/28/2022 4:02:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		Shukai Zhang OC
-- Create date: 2022-07-18
-- Description:	The purpose of this trigger is to automatically link the AP invoices that have not been linked to a bill in budJBProgressBillSLPo when a new JB Bill is inserted
-- =============================================
CREATE TRIGGER [dbo].[z_OC_AutoLinkAP]
   ON  [dbo].[bJBIN]
   After INSERT
AS 

IF EXISTS(SELECT * FROM budJBProgressBillSLPo b
	INNER JOIN inserted i
	ON b.Co = i.JBCo
	AND b.Job = i.Contract
	WHERE b.BillInvoice IS NULL
	AND b.BillNumber IS NULL)
BEGIN
	UPDATE APTL
	SET APTL.udBillMonth = i.BillMonth,
		APTL.udBillInvoice = i.Invoice,
		APTL.udBillNumber = i.BillNumber
	FROM APTL a
	INNER JOIN budJBProgressBillSLPo b
	ON a.APCo = b.Co 
	AND a.Mth = b.TransMth
	AND a.APTrans = b.APTrans
	AND a.APLine = b.APLine
	INNER JOIN inserted i
	ON b.Co = i.JBCo
	AND b.Job = i.Contract
	WHERE b.BillInvoice IS NULL
	AND b.BillNumber IS NULL

	UPDATE budJBProgressBillSLPo
	SET BillMonth = i.BillMonth,
		BillInvoice = i.Invoice,
		BillNumber = i.BillNumber
	FROM budJBProgressBillSLPo b
	INNER JOIN inserted i
	ON b.Co = i.JBCo
	AND b.Job = i.Contract
	WHERE b.BillInvoice IS NULL
	AND b.BillNumber IS NULL
END
