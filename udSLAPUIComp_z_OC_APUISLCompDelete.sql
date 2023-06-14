USE [Viewpoint]
GO
/****** Object:  Trigger [dbo].[z_OC_APUISLCompDelete]    Script Date: 7/19/2022 3:47:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ================================================
-- Author:		Shukai Zhang
-- Create date: 2022-07-18
-- Description: This trigger is to complete the 
-- AP Invoice compliance functionalities
-- ================================================
CREATE TRIGGER [dbo].[z_OC_APUISLCompDelete]
   ON [dbo].[budSLAPUIComp]
   AFTER DELETE
AS 
BEGIN


	SET NOCOUNT ON;

	IF EXISTS(SELECT * FROM deleted d INNER JOIN APUI a ON d.Co = a.APCo AND d.UIMth = a.UIMth AND d.UISeq = a.UISeq AND a.udApplyPWPComp = 'Y' WHERE d.CompCode = 'PWP')
	UPDATE APUI
	SET udApplyPWPComp = 'N'
	FROM APUI a
	INNER JOIN deleted d
	ON d.Co = a.APCo 
	AND d.UIMth = a.UIMth 
	AND d.UISeq = a.UISeq

END
