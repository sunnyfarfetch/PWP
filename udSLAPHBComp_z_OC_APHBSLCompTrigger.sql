USE [Viewpoint]
GO
/****** Object:  Trigger [dbo].[z_OC_APHBSLCompTrigger]    Script Date: 7/11/2022 7:20:08 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ================================================
-- Author:		Shukai Zhang
-- Create date: 06-02-2022
-- Description: This trigger is to complete the 
-- SL AP Invoice compliance functionalities
-- ================================================
CREATE TRIGGER [dbo].[z_OC_APHBSLCompTrigger]
   ON [dbo].[budSLAPHBComp]
   AFTER INSERT, UPDATE
AS 
BEGIN

	SET NOCOUNT ON;
	
	IF EXISTS(SELECT * FROM inserted i INNER JOIN APHB a ON i.Co = a.Co AND i.Mth = a.Mth AND i.BatchId = a.BatchId AND i.BatchSeq = a.BatchSeq AND a.udApplyPWPComp = 'N' WHERE i.CompCode = 'PWP')
	UPDATE APHB
	SET udApplyPWPComp = 'Y'
	FROM APHB a
	INNER JOIN inserted i
	ON i.Co = a.Co
	AND i.Mth = a.Mth
	AND i.BatchId = a.BatchId
	AND i.BatchSeq = a.BatchSeq

	IF UPDATE(CompCode)
	BEGIN
		UPDATE udSLAPHBComp
		SET udSLAPHBComp.Description = HQCP.Description
		FROM udSLAPHBComp
		INNER JOIN HQCP
		ON udSLAPHBComp.CompCode = HQCP.CompCode

		UPDATE udSLAPHBComp
		SET udSLAPHBComp.APRef = APHB.APRef
		FROM udSLAPHBComp
		INNER JOIN APHB
		ON udSLAPHBComp.Co = APHB.Co
		AND udSLAPHBComp.Mth = APHB.Mth
		AND udSLAPHBComp.BatchId = APHB.BatchId
		AND udSLAPHBComp.BatchSeq = APHB.BatchSeq
	END
	
END
