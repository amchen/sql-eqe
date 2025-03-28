if exists(select * from SYSOBJECTS where ID = object_id(N'absp_11640_InsertTemplateInfoFromStepInfo') and objectproperty(id,N'IsProcedure') = 1)
begin
	drop procedure absp_11640_InsertTemplateInfoFromStepInfo;
end
go

create procedure  absp_11640_InsertTemplateInfoFromStepInfo
as

begin
	set nocount on
	if exists (select 1 from sys.objects where name='TemplateInfo' and type = 'U' )
	begin
		delete from TemplateInfo where TemplateType=3 and UserLevel='S'
		insert into TemplateInfo(TemplateName,TemplateType,UserLevel, IsLocked, IsActive, Category,ReferenceCount,TemplateVersion,CreateDate,ModifyDate,CreatedBy,ModifiedBy,TemplateXml) values('50 Pct Trigger',3,'S','Y','Y','X',0,'2016.001','20160215204151','20160215204151',1,1,'<?xml version="1.0"?><StepPolicyTemplate><StepQuery> <![CDATA[ select top 2000 StepDef.* from StepDef join StepInfo on  StepInfo.StepTemplateID=StepDef.StepTemplateID where StepConditionName = ? order by StepDef.Priority]]>  </StepQuery>   </StepPolicyTemplate>')
		insert into TemplateInfo(TemplateName,TemplateType,UserLevel, IsLocked, IsActive, Category,ReferenceCount,TemplateVersion,CreateDate,ModifyDate,CreatedBy,ModifiedBy,TemplateXml) values('COOP10PCT',3,'S','Y','Y','X',0,'2016.001','20160215204151','20160215204151',1,1,'<?xml version="1.0"?><StepPolicyTemplate><StepQuery> <![CDATA[ select top 2000 StepDef.* from StepDef join StepInfo on  StepInfo.StepTemplateID=StepDef.StepTemplateID where StepConditionName = ? order by StepDef.Priority]]>  </StepQuery>   </StepPolicyTemplate>')
		insert into TemplateInfo(TemplateName,TemplateType,UserLevel, IsLocked, IsActive, Category,ReferenceCount,TemplateVersion,CreateDate,ModifyDate,CreatedBy,ModifiedBy,TemplateXml) values('COOP20PCT',3,'S','Y','Y','X',0,'2016.001','20160215204151','20160215204151',1,1,'<?xml version="1.0"?><StepPolicyTemplate><StepQuery> <![CDATA[ select top 2000 StepDef.* from StepDef join StepInfo on  StepInfo.StepTemplateID=StepDef.StepTemplateID where StepConditionName = ? order by StepDef.Priority]]>  </StepQuery>   </StepPolicyTemplate>')
		insert into TemplateInfo(TemplateName,TemplateType,UserLevel, IsLocked, IsActive, Category,ReferenceCount,TemplateVersion,CreateDate,ModifyDate,CreatedBy,ModifiedBy,TemplateXml) values('COOP30PCT',3,'S','Y','Y','X',0,'2016.001','20160215204151','20160215204151',1,1,'<?xml version="1.0"?><StepPolicyTemplate><StepQuery> <![CDATA[ select top 2000 StepDef.* from StepDef join StepInfo on  StepInfo.StepTemplateID=StepDef.StepTemplateID where StepConditionName = ? order by StepDef.Priority]]>  </StepQuery>   </StepPolicyTemplate>')
		insert into TemplateInfo(TemplateName,TemplateType,UserLevel, IsLocked, IsActive, Category,ReferenceCount,TemplateVersion,CreateDate,ModifyDate,CreatedBy,ModifiedBy,TemplateXml) values('FJCC',3,'S','Y','Y','X',0,'2016.001','20160215204151','20160215204151',1,1,'<?xml version="1.0"?><StepPolicyTemplate><StepQuery> <![CDATA[ select top 2000 StepDef.* from StepDef join StepInfo on  StepInfo.StepTemplateID=StepDef.StepTemplateID where StepConditionName = ? order by StepDef.Priority]]>  </StepQuery>   </StepPolicyTemplate>')
		insert into TemplateInfo(TemplateName,TemplateType,UserLevel, IsLocked, IsActive, Category,ReferenceCount,TemplateVersion,CreateDate,ModifyDate,CreatedBy,ModifiedBy,TemplateXml) values('Franchise',3,'S','Y','Y','X',0,'2016.001','20160215204151','20160215204151',1,1,'<?xml version="1.0"?><StepPolicyTemplate><StepQuery> <![CDATA[ select top 2000 StepDef.* from StepDef join StepInfo on  StepInfo.StepTemplateID=StepDef.StepTemplateID where StepConditionName = ? order by StepDef.Priority]]>  </StepQuery>   </StepPolicyTemplate>')
		insert into TemplateInfo(TemplateName,TemplateType,UserLevel, IsLocked, IsActive, Category,ReferenceCount,TemplateVersion,CreateDate,ModifyDate,CreatedBy,ModifiedBy,TemplateXml) values('Franchise Quake EFEI',3,'S','Y','Y','X',0,'2016.001','20160215204151','20160215204151',1,1,'<?xml version="1.0"?><StepPolicyTemplate><StepQuery> <![CDATA[ select top 2000 StepDef.* from StepDef join StepInfo on  StepInfo.StepTemplateID=StepDef.StepTemplateID where StepConditionName = ? order by StepDef.Priority]]>  </StepQuery>   </StepPolicyTemplate>')
		insert into TemplateInfo(TemplateName,TemplateType,UserLevel, IsLocked, IsActive, Category,ReferenceCount,TemplateVersion,CreateDate,ModifyDate,CreatedBy,ModifiedBy,TemplateXml) values('Japan Flood Trigger',3,'S','Y','Y','X',0,'2016.001','20160215204151','20160215204151',1,1,'<?xml version="1.0"?><StepPolicyTemplate><StepQuery> <![CDATA[ select top 2000 StepDef.* from StepDef join StepInfo on  StepInfo.StepTemplateID=StepDef.StepTemplateID where StepConditionName = ? order by StepDef.Priority]]>  </StepQuery>   </StepPolicyTemplate>')
		insert into TemplateInfo(TemplateName,TemplateType,UserLevel, IsLocked, IsActive, Category,ReferenceCount,TemplateVersion,CreateDate,ModifyDate,CreatedBy,ModifiedBy,TemplateXml) values('Japan Quake - Bldg',3,'S','Y','Y','X',0,'2016.001','20160215204151','20160215204151',1,1,'<?xml version="1.0"?><StepPolicyTemplate><StepQuery> <![CDATA[ select top 2000 StepDef.* from StepDef join StepInfo on  StepInfo.StepTemplateID=StepDef.StepTemplateID where StepConditionName = ? order by StepDef.Priority]]>  </StepQuery>   </StepPolicyTemplate>')
		insert into TemplateInfo(TemplateName,TemplateType,UserLevel, IsLocked, IsActive, Category,ReferenceCount,TemplateVersion,CreateDate,ModifyDate,CreatedBy,ModifiedBy,TemplateXml) values('Japan Quake - Cont',3,'S','Y','Y','X',0,'2016.001','20160215204151','20160215204151',1,1,'<?xml version="1.0"?><StepPolicyTemplate><StepQuery> <![CDATA[ select top 2000 StepDef.* from StepDef join StepInfo on  StepInfo.StepTemplateID=StepDef.StepTemplateID where StepConditionName = ? order by StepDef.Priority]]>  </StepQuery>   </StepPolicyTemplate>')
		insert into TemplateInfo(TemplateName,TemplateType,UserLevel, IsLocked, IsActive, Category,ReferenceCount,TemplateVersion,CreateDate,ModifyDate,CreatedBy,ModifiedBy,TemplateXml) values('Japan Wind',3,'S','Y','Y','X',0,'2016.001','20160215204151','20160215204151',1,1,'<?xml version="1.0"?><StepPolicyTemplate><StepQuery> <![CDATA[ select top 2000 StepDef.* from StepDef join StepInfo on  StepInfo.StepTemplateID=StepDef.StepTemplateID where StepConditionName = ? order by StepDef.Priority]]>  </StepQuery>   </StepPolicyTemplate>')
		insert into TemplateInfo(TemplateName,TemplateType,UserLevel, IsLocked, IsActive, Category,ReferenceCount,TemplateVersion,CreateDate,ModifyDate,CreatedBy,ModifiedBy,TemplateXml) values('Kyosuiren Kasai EFEI 2014',3,'S','Y','Y','X',0,'2016.001','20160215204151','20160215204151',1,1,'<?xml version="1.0"?><StepPolicyTemplate><StepQuery> <![CDATA[ select top 2000 StepDef.* from StepDef join StepInfo on  StepInfo.StepTemplateID=StepDef.StepTemplateID where StepConditionName = ? order by StepDef.Priority]]>  </StepQuery>   </StepPolicyTemplate>')
		insert into TemplateInfo(TemplateName,TemplateType,UserLevel, IsLocked, IsActive, Category,ReferenceCount,TemplateVersion,CreateDate,ModifyDate,CreatedBy,ModifiedBy,TemplateXml) values('Kyosuiren Kasai EQ Specialty 2014',3,'S','Y','Y','X',0,'2016.001','20160215204151','20160215204151',1,1,'<?xml version="1.0"?><StepPolicyTemplate><StepQuery> <![CDATA[ select top 2000 StepDef.* from StepDef join StepInfo on  StepInfo.StepTemplateID=StepDef.StepTemplateID where StepConditionName = ? order by StepDef.Priority]]>  </StepQuery>   </StepPolicyTemplate>')
		insert into TemplateInfo(TemplateName,TemplateType,UserLevel, IsLocked, IsActive, Category,ReferenceCount,TemplateVersion,CreateDate,ModifyDate,CreatedBy,ModifiedBy,TemplateXml) values('Kyosuiren Kasai Wind Standard 2014',3,'S','Y','Y','X',0,'2016.001','20160215204151','20160215204151',1,1,'<?xml version="1.0"?><StepPolicyTemplate><StepQuery> <![CDATA[ select top 2000 StepDef.* from StepDef join StepInfo on  StepInfo.StepTemplateID=StepDef.StepTemplateID where StepConditionName = ? order by StepDef.Priority]]>  </StepQuery>   </StepPolicyTemplate>')
		insert into TemplateInfo(TemplateName,TemplateType,UserLevel, IsLocked, IsActive, Category,ReferenceCount,TemplateVersion,CreateDate,ModifyDate,CreatedBy,ModifiedBy,TemplateXml) values('Kyosuiren Kurashi 70 EQ',3,'S','Y','Y','X',0,'2016.001','20160215204151','20160215204151',1,1,'<?xml version="1.0"?><StepPolicyTemplate><StepQuery> <![CDATA[ select top 2000 StepDef.* from StepDef join StepInfo on  StepInfo.StepTemplateID=StepDef.StepTemplateID where StepConditionName = ? order by StepDef.Priority]]>  </StepQuery>   </StepPolicyTemplate>')
		insert into TemplateInfo(TemplateName,TemplateType,UserLevel, IsLocked, IsActive, Category,ReferenceCount,TemplateVersion,CreateDate,ModifyDate,CreatedBy,ModifiedBy,TemplateXml) values('Kyosuiren Kurashi 75 EQ',3,'S','Y','Y','X',0,'2016.001','20160215204151','20160215204151',1,1,'<?xml version="1.0"?><StepPolicyTemplate><StepQuery> <![CDATA[ select top 2000 StepDef.* from StepDef join StepInfo on  StepInfo.StepTemplateID=StepDef.StepTemplateID where StepConditionName = ? order by StepDef.Priority]]>  </StepQuery>   </StepPolicyTemplate>')
		insert into TemplateInfo(TemplateName,TemplateType,UserLevel, IsLocked, IsActive, Category,ReferenceCount,TemplateVersion,CreateDate,ModifyDate,CreatedBy,ModifiedBy,TemplateXml) values('Non-Zenkyoren Kyosai Quake',3,'S','Y','Y','X',0,'2016.001','20160215204151','20160215204151',1,1,'<?xml version="1.0"?><StepPolicyTemplate><StepQuery> <![CDATA[ select top 2000 StepDef.* from StepDef join StepInfo on  StepInfo.StepTemplateID=StepDef.StepTemplateID where StepConditionName = ? order by StepDef.Priority]]>  </StepQuery>   </StepPolicyTemplate>')
		insert into TemplateInfo(TemplateName,TemplateType,UserLevel, IsLocked, IsActive, Category,ReferenceCount,TemplateVersion,CreateDate,ModifyDate,CreatedBy,ModifiedBy,TemplateXml) values('Saikyosairen EQ A',3,'S','Y','Y','X',0,'2016.001','20160215204151','20160215204151',1,1,'<?xml version="1.0"?><StepPolicyTemplate><StepQuery> <![CDATA[ select top 2000 StepDef.* from StepDef join StepInfo on  StepInfo.StepTemplateID=StepDef.StepTemplateID where StepConditionName = ? order by StepDef.Priority]]>  </StepQuery>   </StepPolicyTemplate>')
		insert into TemplateInfo(TemplateName,TemplateType,UserLevel, IsLocked, IsActive, Category,ReferenceCount,TemplateVersion,CreateDate,ModifyDate,CreatedBy,ModifiedBy,TemplateXml) values('Saikyosairen EQ B',3,'S','Y','Y','X',0,'2016.001','20160215204151','20160215204151',1,1,'<?xml version="1.0"?><StepPolicyTemplate><StepQuery> <![CDATA[ select top 2000 StepDef.* from StepDef join StepInfo on  StepInfo.StepTemplateID=StepDef.StepTemplateID where StepConditionName = ? order by StepDef.Priority]]>  </StepQuery>   </StepPolicyTemplate>')
		insert into TemplateInfo(TemplateName,TemplateType,UserLevel, IsLocked, IsActive, Category,ReferenceCount,TemplateVersion,CreateDate,ModifyDate,CreatedBy,ModifiedBy,TemplateXml) values('Saikyosairen EQ Standard',3,'S','Y','Y','X',0,'2016.001','20160215204151','20160215204151',1,1,'<?xml version="1.0"?><StepPolicyTemplate><StepQuery> <![CDATA[ select top 2000 StepDef.* from StepDef join StepInfo on  StepInfo.StepTemplateID=StepDef.StepTemplateID where StepConditionName = ? order by StepDef.Priority]]>  </StepQuery>   </StepPolicyTemplate>')
		insert into TemplateInfo(TemplateName,TemplateType,UserLevel, IsLocked, IsActive, Category,ReferenceCount,TemplateVersion,CreateDate,ModifyDate,CreatedBy,ModifiedBy,TemplateXml) values('Saikyosairen TY A',3,'S','Y','Y','X',0,'2016.001','20160215204151','20160215204151',1,1,'<?xml version="1.0"?><StepPolicyTemplate><StepQuery> <![CDATA[ select top 2000 StepDef.* from StepDef join StepInfo on  StepInfo.StepTemplateID=StepDef.StepTemplateID where StepConditionName = ? order by StepDef.Priority]]>  </StepQuery>   </StepPolicyTemplate>')
		insert into TemplateInfo(TemplateName,TemplateType,UserLevel, IsLocked, IsActive, Category,ReferenceCount,TemplateVersion,CreateDate,ModifyDate,CreatedBy,ModifiedBy,TemplateXml) values('Saikyosairen TY B',3,'S','Y','Y','X',0,'2016.001','20160215204151','20160215204151',1,1,'<?xml version="1.0"?><StepPolicyTemplate><StepQuery> <![CDATA[ select top 2000 StepDef.* from StepDef join StepInfo on  StepInfo.StepTemplateID=StepDef.StepTemplateID where StepConditionName = ? order by StepDef.Priority]]>  </StepQuery>   </StepPolicyTemplate>')
		insert into TemplateInfo(TemplateName,TemplateType,UserLevel, IsLocked, IsActive, Category,ReferenceCount,TemplateVersion,CreateDate,ModifyDate,CreatedBy,ModifiedBy,TemplateXml) values('Saikyosairen TY Standard',3,'S','Y','Y','X',0,'2016.001','20160215204151','20160215204151',1,1,'<?xml version="1.0"?><StepPolicyTemplate><StepQuery> <![CDATA[ select top 2000 StepDef.* from StepDef join StepInfo on  StepInfo.StepTemplateID=StepDef.StepTemplateID where StepConditionName = ? order by StepDef.Priority]]>  </StepQuery>   </StepPolicyTemplate>')
		insert into TemplateInfo(TemplateName,TemplateType,UserLevel, IsLocked, IsActive, Category,ReferenceCount,TemplateVersion,CreateDate,ModifyDate,CreatedBy,ModifiedBy,TemplateXml) values('Zenkyoren Quake Hokkaido',3,'S','Y','Y','X',0,'2016.001','20160215204151','20160215204151',1,1,'<?xml version="1.0"?><StepPolicyTemplate><StepQuery> <![CDATA[ select top 2000 StepDef.* from StepDef join StepInfo on  StepInfo.StepTemplateID=StepDef.StepTemplateID where StepConditionName = ? order by StepDef.Priority]]>  </StepQuery>   </StepPolicyTemplate>')
		insert into TemplateInfo(TemplateName,TemplateType,UserLevel, IsLocked, IsActive, Category,ReferenceCount,TemplateVersion,CreateDate,ModifyDate,CreatedBy,ModifiedBy,TemplateXml) values('Zenkyoren Quake Rest of Japan',3,'S','Y','Y','X',0,'2016.001','20160215204151','20160215204151',1,1,'<?xml version="1.0"?><StepPolicyTemplate><StepQuery> <![CDATA[ select top 2000 StepDef.* from StepDef join StepInfo on  StepInfo.StepTemplateID=StepDef.StepTemplateID where StepConditionName = ? order by StepDef.Priority]]>  </StepQuery>   </StepPolicyTemplate>')
		insert into TemplateInfo(TemplateName,TemplateType,UserLevel, IsLocked, IsActive, Category,ReferenceCount,TemplateVersion,CreateDate,ModifyDate,CreatedBy,ModifiedBy,TemplateXml) values('Zenkyoren Wind 2014',3,'S','Y','Y','X',0,'2016.001','20160215204151','20160215204151',1,1,'<?xml version="1.0"?><StepPolicyTemplate><StepQuery> <![CDATA[ select top 2000 StepDef.* from StepDef join StepInfo on  StepInfo.StepTemplateID=StepDef.StepTemplateID where StepConditionName = ? order by StepDef.Priority]]>  </StepQuery>   </StepPolicyTemplate>')
		insert into TemplateInfo(TemplateName,TemplateType,UserLevel, IsLocked, IsActive, Category,ReferenceCount,TemplateVersion,CreateDate,ModifyDate,CreatedBy,ModifiedBy,TemplateXml) values('Zenkyoren Wind Post-2004 Hokkaido',3,'S','Y','Y','X',0,'2016.001','20160215204151','20160215204151',1,1,'<?xml version="1.0"?><StepPolicyTemplate><StepQuery> <![CDATA[ select top 2000 StepDef.* from StepDef join StepInfo on  StepInfo.StepTemplateID=StepDef.StepTemplateID where StepConditionName = ? order by StepDef.Priority]]>  </StepQuery>   </StepPolicyTemplate>')
		insert into TemplateInfo(TemplateName,TemplateType,UserLevel, IsLocked, IsActive, Category,ReferenceCount,TemplateVersion,CreateDate,ModifyDate,CreatedBy,ModifiedBy,TemplateXml) values('Zenkyoren Wind Post-2004 Rest of Japan',3,'S','Y','Y','X',0,'2016.001','20160215204151','20160215204151',1,1,'<?xml version="1.0"?><StepPolicyTemplate><StepQuery> <![CDATA[ select top 2000 StepDef.* from StepDef join StepInfo on  StepInfo.StepTemplateID=StepDef.StepTemplateID where StepConditionName = ? order by StepDef.Priority]]>  </StepQuery>   </StepPolicyTemplate>')
		insert into TemplateInfo(TemplateName,TemplateType,UserLevel, IsLocked, IsActive, Category,ReferenceCount,TemplateVersion,CreateDate,ModifyDate,CreatedBy,ModifiedBy,TemplateXml) values('Zenkyoren Wind Pre-2004',3,'S','Y','Y','X',0,'2016.001','20160215204151','20160215204151',1,1,'<?xml version="1.0"?><StepPolicyTemplate><StepQuery> <![CDATA[ select top 2000 StepDef.* from StepDef join StepInfo on  StepInfo.StepTemplateID=StepDef.StepTemplateID where StepConditionName = ? order by StepDef.Priority]]>  </StepQuery>   </StepPolicyTemplate>')
	end;
end;

