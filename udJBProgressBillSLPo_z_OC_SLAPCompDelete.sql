USE [Viewpoint]
GO

/****** Object:  Trigger [dbo].[z_OC_SLAPCompDelete]    Script Date: 6/30/2022 7:40:11 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Shukai Zhang, Olsen Consulting
-- Create date: 06-03-2022
-- Description:	This trigger is to delete from
-- SL AP Invoice CompCode
-- =============================================
CREATE TRIGGER [dbo].[z_OC_SLAPCompDelete] 
   ON  [dbo].[budJBProgressBillSLPo] 
   AFTER DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DELETE budSLAPInvComp
	FROM budSLAPInvComp b
	JOIN deleted d
	ON d.Co = b.Co
	AND d.Job = b.Job
	AND d.Seq = b.Seq

	DELETE b 
	FROM budSLAPUIComp b
	INNER JOIN deleted d
	ON d.Co = b.Co 
	AND d.TransMth = b.TransMth  
	INNER JOIN APTH a 
	ON a.APCo = b.Co 
	AND a.Mth = b.TransMth 
	AND d.APTrans = a.APTrans
	AND a.APRef = b.APRef

	DELETE b 
	FROM budSLAPHBComp b
	INNER JOIN deleted d
	ON d.Co = b.Co 
	AND d.TransMth = b.Mth  
	INNER JOIN APTH a 
	ON a.APCo = b.Co 
	AND a.Mth = b.Mth 
	AND d.APTrans = a.APTrans
	AND a.APRef = b.APRef
END


GO

ALTER TABLE [dbo].[budJBProgressBillSLPo] ENABLE TRIGGER [z_OC_SLAPCompDelete]
GO


