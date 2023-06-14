USE [Viewpoint]
GO

/****** Object:  Trigger [dbo].[z_OC_InterfaceRelatedSL]    Script Date: 6/30/2022 7:32:17 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		Shukai Zhang OC
-- Create date: 2022-04-11
-- Description:	The purpose of this trigger is to automatically interface the applied SL lines in budJBProgressBillSLPo when the bill interfaces
-- =============================================
CREATE TRIGGER [dbo].[z_OC_InterfaceRelatedSL]
   ON  [dbo].[bJBIN]
   After INSERT, UPDATE
AS 

IF UPDATE(InvStatus)

	IF EXISTS (SELECT * FROM inserted INNER JOIN budJBProgressBillSLPo b ON inserted.JBCo = b.Co AND inserted.BillMonth = b.BillMonth AND inserted.BillNumber = b.BillNumber AND inserted.Invoice = b.BillInvoice AND inserted.Contract = b.Job
	WHERE inserted.InvStatus = 'I' AND (b.BillMonth IS NOT NULL OR b.BillNumber IS NOT NULL OR b.BillInvoice IS NOT NULL))

	BEGIN
	DECLARE @p14 varchar(90)=NULL
	DECLARE @Co INT
	DECLARE @TransMth DATE
	DECLARE @APTrans INT
	DECLARE @APLine INT
	DECLARE @APSeq INT
	DECLARE @PayAmount varchar(max)
	DECLARE @UserId varchar(100) = (SELECT SUSER_SNAME())

	DECLARE cur CURSOR LOCAL for
		SELECT inserted.JBCo, b.TransMth, b.APTrans, b.APLine, b.APSeq, b.EndRemainingAmount FROM inserted INNER JOIN budJBProgressBillSLPo b ON inserted.JBCo = b.Co AND inserted.BillMonth = b.BillMonth AND inserted.BillNumber = b.BillNumber AND inserted.Invoice = b.BillInvoice AND inserted.Contract = b.Job

	OPEN cur

	FETCH NEXT FROM cur INTO @Co, @TransMth, @APTrans, @APLine, @APSeq, @PayAmount

	while @@FETCH_STATUS = 0 BEGIN

		DECLARE @APRef varchar(max) = (SELECT APRef FROM APTH WHERE APCo = @Co AND Mth = @TransMth AND APTrans = @APTrans)

		--execute your sproc on each row
		EXEC bspAPProcessPartialPayments @apco=@Co,@mth=@TransMth,@aptrans=@APTrans,@apline=@APLine,@apseq=@APSeq,@payamount=@PayAmount,@supplier=NULL,@origholdflag=N'N',@holdcode=N'',@distribflag=N'N',@userid=@UserId,@distributetax=N'N',@ApplyCurrTaxRateYN=N'N',@msg=@p14 output

		FETCH NEXT FROM cur INTO @Co, @TransMth, @APTrans, @APLine, @APSeq, @PayAmount
	END

	close cur
	deallocate cur

	UPDATE dbo.budJBProgressBillSLPo
	SET Interfaced = 'Y'
	FROM dbo.budJBProgressBillSLPo b
	INNER JOIN inserted
	ON inserted.JBCo = b.Co 
	AND inserted.BillMonth = b.BillMonth 
	AND inserted.BillNumber = b.BillNumber 
	AND inserted.Invoice = b.BillInvoice
	AND inserted.Contract = b.Job
	WHERE b.BillMonth IS NOT NULL OR b.BillNumber IS NOT NULL OR b.BillInvoice IS NOT NULL
	

	END

	IF EXISTS (SELECT * FROM inserted INNER JOIN budJBProgressBillSLPo b ON inserted.JBCo = b.Co AND inserted.BillMonth = b.BillMonth AND inserted.BillNumber = b.BillNumber AND inserted.Invoice = b.BillInvoice AND inserted.Contract = b.Job
	WHERE inserted.InvStatus != 'I' AND (b.BillMonth IS NOT NULL OR b.BillNumber IS NOT NULL OR b.BillInvoice IS NOT NULL))

	BEGIN
	
	UPDATE dbo.budJBProgressBillSLPo
	SET Interfaced = 'N'
	FROM dbo.budJBProgressBillSLPo b
	INNER JOIN inserted
	ON inserted.JBCo = b.Co 
	AND inserted.BillMonth = b.BillMonth 
	AND inserted.BillNumber = b.BillNumber 
	AND inserted.Invoice = b.BillInvoice
	AND inserted.Contract = b.Job
	WHERE b.BillMonth IS NOT NULL OR b.BillNumber IS NOT NULL OR b.BillInvoice IS NOT NULL


	END
