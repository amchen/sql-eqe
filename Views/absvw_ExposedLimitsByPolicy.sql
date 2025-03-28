if exists (select 1 from sysobjects where id = object_id('absvw_ExposedLimitsByPolicy') and type = 'V')
	drop view absvw_ExposedLimitsByPolicy;
go

create view absvw_ExposedLimitsByPolicy as
	SELECT
		'NodeKey'=ParentKey,
		'NodeType'=ParentType,
		e.ExposureKey,
		'Account'=a.AccountNumber,
		'Policy'=y.PolicyNumber,
		'ModelRegion'=m.Describe,
		'Peril'=p.PerilDisplayName,
		'TotalValue'=sum(e.Value),
		'GrossLimit'=sum(e.GrossLimit),
		'NetLimit'=sum(e.NetFacLimit),
		'FacLimit'=sum(e.FacLimit)
	FROM ExposedLimitsByPolicy e
		INNER JOIN ExposureMap x on x.ExposureKey = e.ExposureKey
		INNER JOIN Mdl_Regn m ON e.ModelRegionID = m.Mdl_Rgn_ID
		INNER JOIN PTL p ON e.PerilID = p.Peril_ID and p.Trans_ID in (66,67)
		INNER JOIN Account a ON e.ExposureKey = a.ExposureKey
			AND e.AccountKey = a.AccountKey
		INNER JOIN Policy y ON e.ExposureKey = y.ExposureKey
			AND e.AccountKey = y.AccountKey
			AND e.PolicyKey = y.PolicyKey
	GROUP BY
		ParentKey,
		ParentType,
		e.ExposureKey,
		a.AccountNumber,
		y.PolicyNumber,
		m.Describe,
		p.PerilDisplayName;

--select * from absvw_ExposedLimitsByPolicy
