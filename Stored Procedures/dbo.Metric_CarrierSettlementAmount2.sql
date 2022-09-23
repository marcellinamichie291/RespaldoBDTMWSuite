SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



Create  PROCEDURE [dbo].[Metric_CarrierSettlementAmount2] 
(
	--Standard Parameters
	@Result decimal(20, 5) OUTPUT, 
	@ThisCount decimal(20, 5) OUTPUT, 
	@ThisTotal decimal(20, 5) OUTPUT, 
	@DateStart datetime, 
	@DateEnd datetime, 
	@UseMetricParms int, 
	@ShowDetail int,
	@MetricCode varchar(255)='CarrierSettlementAmount',
	--Additional/Optional Parameters 
	@OnlyRevType1List varchar(128)='',
	@OnlyRevType2List varchar(128)='',
	@OnlyRevType3List varchar(128)='',
	@OnlyRevType4List varchar(128)='',
	@OnlyOrderSubCompanyList varchar(128)='',
-- added 7/15/2008
	@PreTax char(1) = 'Y', --set to NULL if trying to get all postive and negative paydetails,
	--Y is for all taxable compensation paydetails
	--N is for all non taxable paydetails
	@MinusFlag int = NULL --set to 1 if trying to get all positive paydetails regardless if it is taxed
	--set to -1 if trying to get all negative paydetails regardless  if it is taxed
-- end added 7/15/2008
)
AS

/* Revision History:
7/15/2008:	added @PreTax and @MinusFlag parameters and supporting code Steve Pembridge

*/

	--Populate default currency and currency date types
        Exec PopulateSessionIDParamatersInProc 'Pay',@MetricCode  

/* NOTE: This SQL is used by MetricProcessing to automatically generate an new metric item in a category called NewItems.
	<METRIC-INSERT-SQL>

	EXEC MetricInitializeItem
		@sMetricCode = 'CarrierSettlementAmount2', 
		@nActive = 0,	-- 1=active, 0=inactive.
		@nSort = 303, 	-- Used to determine the sort order that updates should be run.
		@sFormatText = '',	-- Typically 'PCT' or blank ('').
		@nNumDigitsAfterDecimal = 0,
		@nPlusDeltaIsGood = 0,
		@nCumulative = 0,
		@sCaption = 'Carrier Settlement Amount',
		@sCaptionFull = 'Carrier Settlement Amount',
		@sProcedureName = 'Metric_CarrierSettlementAmount2',
		@sCachedDetailYN = '',
		@nCacheRefreshAgeMaxMinutes = 0,
		@sShowDetailByDefaultYN = 'N', -- Typically 'N'
		@sRefreshHistoryYN = '',	-- Typically 'N'
		@sCategory = '@@NOCATEGORY'

	</METRIC-INSERT-SQL>
*/

	DECLARE @TotalPay decimal(20,5)
	SET NOCOUNT ON  -- PTS46367

	SET @OnlyRevType1List= ',' + ISNULL(@OnlyRevType1List,'') + ','
	SET @OnlyRevType2List= ',' + ISNULL(@OnlyRevType2List,'') + ','
	SET @OnlyRevType3List= ',' + ISNULL(@OnlyRevType3List,'') + ','
	SET @OnlyRevType4List= ',' + ISNULL(@OnlyRevType4List,'') + ','
	SET @OnlyOrderSubCompanyList= ',' + ISNULL(@OnlyOrderSubCompanyList,'') + ','
	
	SELECT @TotalPay = IsNull(SUM(IsNull(dbo.fnc_convertcharge(pyd_amount,pyd_currency,'Pay',pyd_number,pyd_currencydate,default,default,default,default,default,default,default,pyd_transdate,pyd_workperiod,pyh_payperiod),0.00)),0.00)
	FROM paydetail WITH (NOLOCK) 
		join legheader WITH (NOLOCK) on paydetail.lgh_number = legheader.lgh_number
		join orderheader WITH (NOLOCK) on legheader.ord_hdrnumber = orderheader.ord_hdrnumber
	WHERE ord_completiondate >= @DateStart AND ord_completiondate < @DateEnd
		--AND orderheader.ord_status = 'CMP'
		AND asgn_type = 'CAR'
-- added 7/15/2008
		And	(
				(@PreTax Is Not Null And pyd_pretax = @PreTax)
					Or
				(@PreTax Is Null)
			)
		And	(
				(@MinusFlag Is Not Null and pyd_minus = @MinusFlag)
					Or
				(@MinusFlag Is Null)
			)
-- end added 7/15/2008
		AND (@OnlyRevType1List =',,' OR CHARINDEX(',' + RTRIM( lgh_class1 ) + ',', @OnlyRevType1List) >0)
		AND (@OnlyRevType2List =',,' OR CHARINDEX(',' + RTRIM( lgh_class2 ) + ',', @OnlyRevType2List) >0)
		AND (@OnlyRevType3List =',,' OR CHARINDEX(',' + RTRIM( lgh_class3 ) + ',', @OnlyRevType3List) >0)
		AND (@OnlyRevType4List =',,' OR CHARINDEX(',' + RTRIM( lgh_class4 ) + ',', @OnlyRevType4List) >0) 
		AND (@OnlyOrderSubCompanyList =',,' OR CHARINDEX(',' + RTRIM( ord_subcompany ) + ',', @OnlyOrderSubCompanyList) >0) 

	--==============================================================================
	SET @ThisCount = @TotalPay
	
	SELECT @ThisTotal = CASE WHEN CONVERT(VARCHAR(10), @DateStart, 121) = CONVERT(VARCHAR(10), @DateEnd, 121) 
							THEN 1 ELSE DATEDIFF(day, @DateStart, @DateEnd) END

	SELECT @Result = CASE ISNULL(@ThisTotal, 0) WHEN 0 THEN NULL ELSE @ThisCount / @ThisTotal END

	if (@ShowDetail=1)
	BEGIN
		Select 
			@DateStart MinimumPayPeriodUsed,
			@DateEnd   MaximumPayPeriodUsed,
			paydetail.lgh_number,
			asgn_type,
			asgn_id,
			paydetail.mov_number,
			paydetail.ord_hdrnumber,
			orderheader.ord_completiondate,
			pyd_description PayDescription,
			pyd_quantity Quantity,
			pyd_rate 	Rate,
			IsNull(dbo.fnc_convertcharge(pyd_amount,pyd_currency,'Pay',pyd_number,pyd_currencydate,default,default,default,default,default,default,default,pyd_transdate,pyd_workperiod,pyh_payperiod),0.00) as 'Amount', 
			pyh_payperiod PayPeriod
	FROM Paydetail WITH (NOLOCK)
		join legheader WITH (NOLOCK) on paydetail.lgh_number = legheader.lgh_number
		join orderheader WITH (NOLOCK) on legheader.ord_hdrnumber = orderheader.ord_hdrnumber
	WHERE ord_completiondate >= @DateStart AND ord_completiondate < @DateEnd
		--AND orderheader.ord_status = 'CMP'
		AND asgn_type = 'CAR'
-- added 7/15/2008
		And	(
				(@PreTax Is Not Null And pyd_pretax = @PreTax)
					Or
				(@PreTax Is Null)
			)
		And	(
				(@MinusFlag Is Not Null and pyd_minus = @MinusFlag)
					Or
				(@MinusFlag Is Null)
			)
-- end added 7/15/2008
		AND (@OnlyRevType1List =',,' OR CHARINDEX(',' + RTRIM( lgh_class1 ) + ',', @OnlyRevType1List) >0)
		AND (@OnlyRevType2List =',,' OR CHARINDEX(',' + RTRIM( lgh_class2 ) + ',', @OnlyRevType2List) >0)
		AND (@OnlyRevType3List =',,' OR CHARINDEX(',' + RTRIM( lgh_class3 ) + ',', @OnlyRevType3List) >0)
		AND (@OnlyRevType4List =',,' OR CHARINDEX(',' + RTRIM( lgh_class4 ) + ',', @OnlyRevType4List) >0) 
		AND (@OnlyOrderSubCompanyList =',,' OR CHARINDEX(',' + RTRIM( ord_subcompany ) + ',', @OnlyOrderSubCompanyList) >0) 
			
	END



GO
GRANT EXECUTE ON  [dbo].[Metric_CarrierSettlementAmount2] TO [public]
GO