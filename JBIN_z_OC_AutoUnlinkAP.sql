USE [Viewpoint]
GO
/****** Object:  Trigger [dbo].[z_OC_AutoUnlinkAP]    Script Date: 8/2/2022 6:53:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		Shukai Zhang OC
-- Create date: 2022-08-02
-- Description:	The purpose of this trigger is to automatically unlink the AP invoices that have been linked to a bill in budJBProgressBillSLPo when the JB Bill is deleted
-- =============================================
CREATE TRIGGER [dbo].[z_OC_AutoUnlinkAP]
   ON  [dbo].[bJBIN]
   After DELETE
AS 

IF EXISTS(SELECT * FROM budJBProgressBillSLPo b
	INNER JOIN deleted d
	ON b.Co = d.JBCo
	AND b.BillMonth = d.BillMonth
	AND b.BillInvoice = d.Invoice
	AND b.BillNumber = d.BillNumber)
BEGIN
	UPDATE APTL
	SET APTL.udBillMonth = NULL,
		APTL.udBillInvoice = NULL,
		APTL.udBillNumber = NULL
	FROM APTL a
	INNER JOIN budJBProgressBillSLPo b
	ON a.APCo = b.Co 
	AND a.Mth = b.TransMth
	AND a.APTrans = b.APTrans
	AND a.APLine = b.APLine
	INNER JOIN deleted d
	ON b.Co = d.JBCo
	AND b.BillMonth = d.BillMonth
	AND b.BillInvoice = d.Invoice
	AND b.BillNumber = d.BillNumber

	UPDATE budJBProgressBillSLPo
	SET BillMonth = NULL,
		BillInvoice = NULL,
		BillNumber = NULL
	FROM budJBProgressBillSLPo b
	INNER JOIN deleted d
	ON b.Co = d.JBCo
	AND b.BillMonth = d.BillMonth
	AND b.BillInvoice = d.Invoice
	AND b.BillNumber = d.BillNumber

END
