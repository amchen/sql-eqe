if exists(select 1 from SYSOBJECTS where ID = object_id(N'absvw_ExposureCountByNode') and objectproperty(ID,N'IsView') = 1)
begin
   drop view absvw_ExposureCountByNode;
end
go

create view absvw_ExposureCountByNode
as
SELECT c.NodeKey, 
c.NodeType, 
c.Category, 
c.CategoryID, 
SUM(c.ValidCount) AS ValidCount, 
SUM(c.TotalCount) - SUM(c.ValidCount) AS InvalidCount, 
SUM(c.TotalCount) AS TotalCount
FROM ExposureCount AS c 
INNER JOIN ExposureInfo AS i ON c.ExposureKey = i.ExposureKey
WHERE (i.Status <> 'DELETED')
GROUP BY c.NodeKey, c.NodeType, c.Category, c.CategoryID
/*
select Category, ValidCount, InvalidCount, TotalCount from absvw_ExposureCountByNode where NodeKey=1 and NodeType=2 order by CategoryID asc
*/
