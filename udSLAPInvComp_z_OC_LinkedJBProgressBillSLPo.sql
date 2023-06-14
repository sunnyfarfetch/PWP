SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<OC Shukai Zhang>
-- Create date: <2022-05-31>
-- Description:	<This trigger is to complete the functionalities 
-- of the AP Level compliance table>
-- =============================================
CREATE TRIGGER [dbo].[z_OC_LinkedJBProgressBillSLPo]
   ON  [dbo].[budSLAPInvComp]
   AFTER INSERT,UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF UPDATE(CompCode)
	BEGIN
		UPDATE budSLAPInvComp
		SET budSLAPInvComp.Description = h.Description
		,budSLAPInvComp.TransMth = j.TransMth
		,budSLAPInvComp.APTrans = j.APTrans
		,budSLAPInvComp.APLine = j.APLine
		,budSLAPInvComp.APSeq = j.APSeq
		,budSLAPInvComp.APRef = APTH.APRef
		FROM budSLAPInvComp
		INNER JOIN HQCP h
		ON budSLAPInvComp.CompCode = h.CompCode
		INNER JOIN budJBProgressBillSLPo j
		ON budSLAPInvComp.Job = j.Job
		AND budSLAPInvComp.Seq = j.Seq
		AND budSLAPInvComp.Co = j.Co
		INNER JOIN APTH 
		ON j.Co = APTH.APCo
		AND j.TransMth = APTH.Mth
		AND j.APTrans = APTH.APTrans

	END

	IF UPDATE(Complied) AND EXISTS(SELECT * FROM inserted i INNER JOIN deleted d ON i.Co = d.Co AND i.Job = d.Job AND i.Seq = d.Seq AND i.CompCode = d.CompCode 
	WHERE i.Complied = 'Y' AND d.Complied = 'N' AND i.APSeq IS NOT NULL) AND NOT EXISTS(SELECT * FROM inserted i INNER JOIN budSLAPInvComp b ON i.Co = b.Co
	AND i.Job = b.Job AND i.Seq = b.Seq WHERE b.Complied = 'N') 
	BEGIN
		INSERT INTO APHR(
			APCo
			,UserId
			,Mth
			,APTrans
			,APLine
			,APSeq
			,PayType
			,Amount
			,HoldCode
			,ApplyNewTaxRateYN
		)
			SELECT DISTINCT 
				d.APCo,
				(SELECT USER_NAME()),
				d.Mth,
				d.APTrans,
				d.APLine,
				d.APSeq,
				d.PayType,
				d.Amount,
				'PWP',
				'Y'
			FROM dbo.APTH h
			JOIN dbo.APTL l
				ON l.APCo = h.APCo
					AND l.Mth = h.Mth
					AND l.APTrans = h.APTrans
			JOIN dbo.APTD d
				ON d.APCo = l.APCo
					AND d.Mth = l.Mth
					AND d.APTrans = l.APTrans
					AND d.APLine = l.APLine
			INNER JOIN inserted i
				ON h.APCo = i.Co
				AND h.Mth = i.TransMth
				AND h.APTrans = i.APTrans
				--AND d.APLine = i.APLine
				--AND d.APSeq = i.APSeq
			WHERE h.APCo = 9 -- 9 is live company for Ideal
				AND h.VendorGroup = 9 --9 is live company for Ideal
				AND d.[Status] IN (1, 2)
				AND h.InUseBatchId IS NULL
				AND h.InPayControl = 'N'
				AND EXISTS (
					SELECT 1
					FROM dbo.bAPHD hd
					WHERE hd.APCo = d.APCo
						AND hd.Mth = d.Mth
						AND hd.APTrans = d.APTrans
						AND hd.APLine = d.APLine
						AND hd.APSeq = d.APSeq
						AND hd.HoldCode = isnull('PWP', hd.HoldCode)
					)
				AND NOT (
					EXISTS (
						SELECT 1
						FROM dbo.bAPHR r
						WHERE r.APCo = d.APCo
							AND r.UserId = (SELECT USER_NAME())
							AND r.Mth = d.Mth
							AND r.APTrans = d.APTrans
							AND r.APLine = d.APLine
							AND r.APSeq = d.APSeq
						)
					);

		DECLARE @userid VARCHAR(max) = (SELECT USER_NAME());
		EXECUTE vspAPHoldRelReleaseHoldCodes @apco = 9, @userid = @userid, @msg = OUTPUT;  --9 is live company

	END

	IF UPDATE(Complied) AND EXISTS(SELECT * FROM inserted i INNER JOIN deleted d ON i.Co = d.Co AND i.Job = d.Job AND i.Seq = d.Seq AND i.CompCode = d.CompCode 
	WHERE i.Complied = 'N' AND d.Complied = 'Y' AND i.APSeq IS NOT NULL) AND EXISTS(SELECT * FROM inserted i INNER JOIN budSLAPInvComp b ON i.Co = b.Co
	AND i.Job = b.Job AND i.Seq = b.Seq WHERE b.Complied = 'N') 
	
	BEGIN
	
	DECLARE @job VARCHAR(max) = (SELECT Job FROM inserted)
	DECLARE @Co INT = (SELECT Co FROM inserted)
	DECLARE @Vendor INT = (SELECT b.Vendor FROM inserted i INNER JOIN budJBProgressBillSLPo b ON i.Co = b.Co AND i.Job = b.Job AND i.Seq = b.Seq)
	DECLARE @Mth VARCHAR(20) = (SELECT TransMth FROM inserted)
	DECLARE @APTrans INT = (SELECT APTrans FROM inserted)
	DECLARE @APLine INT = (SELECT APLine FROM inserted)
	DECLARE @APSeq INT = (SELECT APSeq FROM inserted)
	exec vspAPAssignReleaseHoldCode @aropt='A',@holdcode='PWP',@jcco=@Co,@job=@job,@apco=@Co,@vendgrp=@Co,
	@vendor=@Vendor,@PayTypeList=',3,',@fmth=@Mth,@ftrans=@APTrans,@fline=@APLine,@fseq=@APSeq,@PhaseList='',@ApplyNewTaxRate='N',@msg= output

	END
END
