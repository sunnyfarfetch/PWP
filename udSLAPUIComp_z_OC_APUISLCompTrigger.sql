USE [Viewpoint]
GO
/****** Object:  Trigger [dbo].[z_OC_APUISLCompTrigger]    Script Date: 7/11/2022 7:24:12 PM ******/
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
CREATE TRIGGER [dbo].[z_OC_APUISLCompTrigger]
   ON [dbo].[budSLAPUIComp]
   AFTER INSERT, UPDATE
AS 
BEGIN

	SET NOCOUNT ON;

	IF EXISTS(SELECT * FROM inserted i INNER JOIN APUI a ON i.Co = a.APCo AND i.UIMth = a.UIMth AND i.UISeq = i.UISeq AND a.udApplyPWPComp = 'N' WHERE i.CompCode = 'PWP')
	UPDATE APUI
	SET udApplyPWPComp = 'Y'
	FROM APUI a
	INNER JOIN inserted i
	ON i.Co = a.APCo 
	AND i.UIMth = a.UIMth 
	AND i.UISeq = i.UISeq
	
	IF UPDATE(CompCode)
	BEGIN
		UPDATE budSLAPUIComp
		SET budSLAPUIComp.Description = HQCP.Description
		FROM budSLAPUIComp
		INNER JOIN HQCP
		ON budSLAPUIComp.CompCode = HQCP.CompCode

		UPDATE udSLAPUIComp
		SET udSLAPUIComp.APRef = APUI.APRef
		FROM udSLAPUIComp
		INNER JOIN APUI
		ON udSLAPUIComp.Co = APUI.APCo
		AND udSLAPUIComp.UIMth = APUI.UIMth
		AND udSLAPUIComp.UISeq = APUI.UISeq
	END

END

