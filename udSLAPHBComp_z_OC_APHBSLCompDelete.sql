USE [Viewpoint]
GO
/****** Object:  Trigger [dbo].[z_OC_APHBSLCompDelete]    Script Date: 7/19/2022 3:22:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ================================================
-- Author:		Shukai Zhang, OC
-- Create date: 2022-07-18
-- Description: This trigger is to complete the 
-- AP Invoice compliance functionalities
-- ================================================
CREATE TRIGGER [dbo].[z_OC_APHBSLCompDelete]
   ON [dbo].[budSLAPHBComp]
   AFTER DELETE
AS 
BEGIN

	SET NOCOUNT ON;

	IF EXISTS(SELECT * FROM deleted d INNER JOIN APHB a ON d.Co = a.Co AND d.Mth = a.Mth AND d.BatchId = a.BatchId AND d.BatchSeq = a.BatchSeq AND a.udApplyPWPComp = 'Y' WHERE d.CompCode = 'PWP')
	UPDATE APHB
	SET udApplyPWPComp = 'N'
	FROM APHB a
	INNER JOIN deleted d
	ON d.Co = a.Co
	AND d.Mth = a.Mth
	AND d.BatchId = a.BatchId
	AND d.BatchSeq = a.BatchSeq

END
