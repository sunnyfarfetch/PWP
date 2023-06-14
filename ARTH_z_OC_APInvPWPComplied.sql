USE [Viewpoint]
GO
/****** Object:  Trigger [dbo].[z_OC_APInvPWPComplied]    Script Date: 10/7/2022 5:06:23 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ================================================
-- Author:		Shukai Zhang
-- Create date: 2022-07-18
-- Description: 
-- Automatically set PWP comp code to complied when the linked Job bill is PaidInFull
-- ================================================
CREATE TRIGGER [dbo].[z_OC_APInvPWPComplied]
   ON [dbo].[bARTH]
   AFTER INSERT, UPDATE
AS 


IF EXISTS(
SELECT *
FROM inserted i
INNER JOIN udJBProgressBillSLPo p
ON i.ARCo = p.Co
AND i.Invoice = p.BillInvoice
AND i.Contract = p.Job
INNER JOIN udSLAPInvComp u 
ON u.Co = p.Co
AND u.APTrans = p.APTrans
WHERE u.Complied = 'N' AND u.CompCode = 'PWP' AND i.Source = 'JB' AND i.PayFullDate IS NOT NULL)

BEGIN

UPDATE u
SET u.Complied = 'Y'
FROM inserted i
INNER JOIN udJBProgressBillSLPo p
ON i.ARCo = p.Co
AND i.Invoice = p.BillInvoice
AND i.Contract = p.Job
INNER JOIN udSLAPInvComp u 
ON u.Co = p.Co
AND u.APTrans = p.APTrans
WHERE u.Complied = 'N' AND u.CompCode = 'PWP' AND i.Source = 'JB' AND i.PayFullDate IS NOT NULL

END
