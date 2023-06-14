SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ================================================
-- Author:		Shukai Zhang
-- Create date: 2022-07-18
-- Description: 
-- Automatically set PWP comp code to complied when the linked AR Cash receipt is posted
-- ================================================
CREATE TRIGGER [dbo].[z_OC_APInvPWPComplied]
   ON [dbo].[bARTL]
   AFTER INSERT, UPDATE
AS 

IF EXISTS(
	SELECT *
	FROM (SELECT ARCo, Mth, ARTrans, ApplyMth, Contract FROM inserted GROUP BY ARCo, Mth, ARTrans, ApplyMth, Contract) AS CTE
	INNER JOIN ARTH a
	ON CTE.ARCo = a.ARCo
	AND CTE.Mth = a.Mth
	AND CTE.ARTrans = a.ARTrans
	AND a.Source = 'AR Receipt'
	INNER JOIN udJBProgressBillSLPo p
	ON CTE.ARCo = p.Co
	AND CTE.ApplyMth = p.BillMonth
	AND CTE.Contract = p.Job
	INNER JOIN udSLAPInvComp u 
	ON u.Co = p.Co
	AND u.APTrans = p.APTrans
	WHERE u.Complied = 'N' AND u.CompCode = 'PWP')

	UPDATE udSLAPInvComp
	SET udSLAPInvComp.Complied = 'Y'
	FROM (SELECT ARCo, Mth, ARTrans, ApplyMth, Contract FROM inserted GROUP BY ARCo, Mth, ARTrans, ApplyMth, Contract) AS CTE
	INNER JOIN ARTH a
	ON CTE.ARCo = a.ARCo
	AND CTE.Mth = a.Mth
	AND CTE.ARTrans = a.ARTrans
	AND a.Source = 'AR Receipt'
	INNER JOIN udJBProgressBillSLPo p
	ON CTE.ARCo = p.Co
	AND CTE.ApplyMth = p.BillMonth
	AND CTE.Contract = p.Job
	INNER JOIN udSLAPInvComp u 
	ON u.Co = p.Co
	AND u.APTrans = p.APTrans
	AND u.APLine = p.APLine
	AND u.APSeq = p.APSeq
