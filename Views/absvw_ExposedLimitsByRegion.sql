if exists (select 1 from sysobjects where id = object_id('absvw_ExposedLimitsByRegion') and type = 'V')
	drop view absvw_ExposedLimitsByRegion;
go

create view absvw_ExposedLimitsByRegion as
	SELECT
		'NodeKey'=ParentKey,
		'NodeType'=ParentType,
		e.ExposureKey,
		c.Country,
		'Region'=r.Name,
		'ModelRegion'=m.Describe,
		'Peril'=p.PerilDisplayName,
		'TotalValue'=sum(e.Value),
		'GrossLimit'=sum(e.Limit),
		'NetLimit'=sum(e.NetLimit),
		'FacLimit'=sum(e.FacLimit)
	FROM ExposedLimitsByRegion AS e
		INNER JOIN ExposureMap x on x.ExposureKey = e.ExposureKey
		INNER JOIN RRgnList AS r ON e.RegionKey = r.RRgn_Key
		INNER JOIN Country AS c ON r.Country_ID = c.Country_ID
		INNER JOIN PTL AS p ON e.PerilID = p.Peril_ID and p.Trans_ID in (66,67)
		INNER JOIN Mdl_Regn AS m ON e.ModelRegionID = m.Mdl_Rgn_ID
	GROUP BY
		ParentKey,
		ParentType,
		e.ExposureKey,
		c.Country,
		r.Name,
		m.Describe,
		p.PerilDisplayName;

--select * from absvw_ExposedLimitsByRegion
