USE [Viewpoint]
GO

/****** Object:  Trigger [dbo].[z_OC_SLAPInvCompUpdate]    Script Date: 6/30/2022 7:38:52 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Shukai Zhang, Olsen Consulting
-- Create date: 06-03-2022
-- Description:	This trigger is to insert to 
-- SL AP Invoice CompCode
-- =============================================
CREATE TRIGGER [dbo].[z_OC_SLAPInvCompUpdate] 
   ON  [dbo].[budJBProgressBillSLPo] 
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- APHB
	IF EXISTS(SELECT * FROM inserted i INNER JOIN budSLAPHBComp b ON i.Co = b.Co AND i.TransMth = b.Mth 
	INNER JOIN APTH a ON a.APCo = b.Co AND a.Mth = b.Mth AND a.APRef = b.APRef)
	BEGIN

	INSERT INTO budSLAPInvComp
	(Co,
	CompCode,
	Seq,
	Job)
	SELECT b.Co, b.CompCode, i.Seq, i.Job
	FROM inserted i 
	INNER JOIN APTH a ON a.APCo = i.Co AND a.Mth = i.TransMth AND a.APTrans = i.APTrans
	INNER JOIN budSLAPHBComp b ON i.Co = b.Co AND i.TransMth = b.Mth AND a.APRef = b.APRef
	INNER JOIN APTD d ON i.Co = d.APCo AND i.TransMth = d.Mth AND i.APTrans = d.APTrans AND i.APLine = d.APLine

	END

	---- APUI
	--IF EXISTS(SELECT * FROM inserted i INNER JOIN budSLAPUIComp b ON i.Co = b.Co AND i.TransMth = b.TransMth 
	--INNER JOIN APTH a ON a.APCo = b.Co AND a.Mth = b.TransMth AND a.APRef = b.APRef)
	--BEGIN

	--INSERT INTO budSLAPInvComp
	--(Co,
	--CompCode,
	--Seq,
	--Job)
	--SELECT b.Co, b.CompCode, i.Seq, i.Job
	--FROM inserted i 
	--INNER JOIN APTH a ON a.APCo = i.Co AND a.Mth = i.TransMth AND a.APTrans = i.APTrans
	--INNER JOIN budSLAPUIComp b ON i.Co = b.Co AND i.TransMth = b.TransMth AND a.APRef = b.APRef
	--INNER JOIN APTD d ON i.Co = d.APCo AND i.TransMth = d.Mth AND i.APTrans = d.APTrans AND i.APLine = d.APLine


	--DELETE b 
	--FROM budSLAPUIComp b
	--INNER JOIN inserted i ON i.Co = b.Co AND i.TransMth = b.TransMth  
	--INNER JOIN APTH a ON a.APCo = b.Co AND a.Mth = b.TransMth AND a.APRef = b.APRef

	--END


END
GO

ALTER TABLE [dbo].[budJBProgressBillSLPo] ENABLE TRIGGER [z_OC_SLAPInvCompUpdate]
GO
