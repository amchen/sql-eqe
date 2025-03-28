if exists (select 1 from sysobjects where id = object_id('absvw_ExposedLimitsByLineOfBusiness') and type = 'V')
	drop view absvw_ExposedLimitsByLineOfBusiness;
go

create view absvw_ExposedLimitsByLineOfBusiness as
	SELECT
		'NodeKey'=ParentKey,
		'NodeType'=ParentType,
		e.ExposureKey,
		c.Country,
		'LineOfBusiness'=l.Name,
		'ModelRegion'=m.Describe,
		'Peril'=p.PerilDisplayName,
		'TotalValue'=sum(e.Value),
		'GrossLimit'=sum(e.Limit),
		'NetLimit'=sum(e.NetLimit)
	FROM ExposedLimitsByRegion AS e
		INNER JOIN ExposureMap x on x.ExposureKey = e.ExposureKey
		INNER JOIN Policy AS pol ON e.ExposureKey = pol.ExposureKey
			AND e.AccountKey = pol.AccountKey
			AND e.PolicyKey = pol.PolicyKey
		INNER JOIN LineOfBusiness AS l ON pol.LineOfBusinessID = l.LineOfBusinessID
		INNER JOIN RRgnList AS r ON e.RegionKey = r.RRgn_Key
		INNER JOIN Country AS c ON r.Country_ID = c.Country_ID
		INNER JOIN PTL AS p ON e.PerilID = p.Peril_ID and p.Trans_ID in (66,67)
		INNER JOIN Mdl_Regn AS m ON e.ModelRegionID = m.Mdl_Rgn_ID
	GROUP BY
		ParentKey,
		ParentType,
		e.ExposureKey,
		c.Country,
		l.Name,
		m.Describe,
		p.PerilDisplayName;

--select * from absvw_ExposedLimitsByLineOfBusiness
