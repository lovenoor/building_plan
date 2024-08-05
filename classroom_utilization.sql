Use IDA
Go

SET NOCOUNT ON

IF OBJECT_ID('tempdb..#coursesections')       IS NOT NULL DROP TABLE #coursesections
IF OBJECT_ID('tempdb..#buildinginfo')       IS NOT NULL DROP TABLE #buildinginfo
IF OBJECT_ID('tempdb..#roominfo')       IS NOT NULL DROP TABLE #roominfo
IF OBJECT_ID('tempdb..#classroomstemp')       IS NOT NULL DROP TABLE #classroomstemp
IF OBJECT_ID('tempdb..#classroomshold')       IS NOT NULL DROP TABLE #classroomshold
IF OBJECT_ID('tempdb..#classroomskept')       IS NOT NULL DROP TABLE #classroomskept
IF OBJECT_ID('tempdb..#classroomsexpand')       IS NOT NULL DROP TABLE #classroomsexpand
IF OBJECT_ID('tempdb..#classroomsexpanded')       IS NOT NULL DROP TABLE #classroomsexpanded
IF OBJECT_ID('tempdb..#timeScaffold')       IS NOT NULL DROP TABLE #timeScaffold

IF OBJECT_ID('ClassUtil.ClassroomUtilizationMaster') IS NOT NULL DROP TABLE ClassUtil.ClassroomUtilizationMaster
IF OBJECT_ID('ClassUtil.ClassroomUtilizationForTableau') IS NOT NULL DROP TABLE ClassUtil.ClassroomUtilizationForTableau

DECLARE @startqtr int = 20234

SELECT DISTINCT 
    CASE WHEN bu.FACILITYCODE = 'SSB' THEN 'BTB' 
        ELSE bu.FACILITYCODE END AS 'FacilityCode' -- SSB is BTB in Facilities Data. laulck 7/9/24
    , BUILDINGNAME
    , BUILDINGKEY
    , CENTER_FACILITY_LATITUDE
    , CENTER_FACILITY_LONGITUDE
    INTO #buildinginfo
    FROM [laulck].[dbo].[Fac_BuildingInteriorSpacePoint_SPVW] bu
    LEFT JOIN [laulck].[dbo].[Fac_FacilityView_SPVW] fac
        ON bu.BUILDINGKEY = fac.BUILDINGID


SELECT DISTINCT 
    CASE WHEN FACILITYCODE = 'SSB' THEN 'BTB' -- SSB is BTB in Facilities Data. laulck 7/9/24
        ELSE FACILITYCODE END AS 'FacilityCode' 
    , BUILDINGKEY
    , [FLOOR]
    , SPACECATEGORY
    , PRIMARYUSE
    , CAPACITY
    , CASE WHEN FACILITYCODE = 'CSE' THEN REPLACE(SHORTNAME, 'CSE', '') -- Edit for CSE room prefix. laulck 7/9/24
        ELSE SHORTNAME END as 'ShortName' 
    INTO #roominfo
    FROM [laulck].[dbo].[Fac_BuildingInteriorSpacePoint_SPVW]
    WHERE SPACEID NOT IN ('1316_B1_110') -- there is a duplicate spaceid with this code. laulck 7/9/24


SELECT DISTINCT CourseSectionMeetingBuildingAbbr
    , CASE WHEN (TRIM(CourseSectionMeetingRoomNbr) = 'B125') AND TRIM(CourseSectionMeetingBuildingAbbr) = 'PAT'
        THEN 'PAB'
      WHEN (TRIM(CourseSectionMeetingRoomNbr) = 'C231') AND TRIM(CourseSectionMeetingBuildingAbbr) = 'PAB'
        THEN 'PAT'
      ELSE TRIM(CourseSectionMeetingBuildingAbbr) END AS CourseSectionMeetingBuildingAbbrClean
    , CourseSectionMeetingRoomNbr
    , CASE WHEN CourseSectionMeetingRoomNbr = '221A-E' -- manual data cleaning. laulck 7/15/24
        THEN '221A'
      WHEN (TRIM(CourseSectionMeetingRoomNbr) = 'T-567-75') AND TRIM(CourseSectionMeetingBuildingAbbr) = 'HST'
        THEN 'T567-75'
      WHEN (TRIM(CourseSectionMeetingRoomNbr) LIKE '312%') AND TRIM(CourseSectionMeetingBuildingAbbr) = 'GLD'
        THEN '312'
      WHEN (TRIM(CourseSectionMeetingRoomNbr) LIKE '137%') AND TRIM(CourseSectionMeetingBuildingAbbr) = 'ECE'
        THEN '137'
      WHEN (TRIM(CourseSectionMeetingRoomNbr) LIKE '148') AND TRIM(CourseSectionMeetingBuildingAbbr) = 'GLD'
        THEN '148A'
      WHEN (TRIM(CourseSectionMeetingRoomNbr) = '007F') AND TRIM(CourseSectionMeetingBuildingAbbr) = 'GLD' -- checked that this room refers to a computer lab in GLD basement. laulck 7/15/24
        THEN 'B007A'
      WHEN (TRIM(CourseSectionMeetingRoomNbr) IN ('133L', '133R')) AND TRIM(CourseSectionMeetingBuildingAbbr) = 'BAG'
        THEN '133'
      WHEN (TRIM(CourseSectionMeetingRoomNbr) = '035') AND TRIM(CourseSectionMeetingBuildingAbbr) = 'BNS'
        THEN 'B035'
      WHEN (TRIM(CourseSectionMeetingRoomNbr) = '288') AND TRIM(CourseSectionMeetingBuildingAbbr) = 'PBB'
        THEN '288A'
      WHEN (TRIM(CourseSectionMeetingRoomNbr) = '16') AND TRIM(CourseSectionMeetingBuildingAbbr) = 'LAW'
        THEN '116'
      WHEN (TRIM(CourseSectionMeetingRoomNbr) = '27') AND TRIM(CourseSectionMeetingBuildingAbbr) = 'MUS'
        THEN '027'
      WHEN (TRIM(CourseSectionMeetingRoomNbr) = '306') AND TRIM(CourseSectionMeetingBuildingAbbr) = 'SWS'
        THEN '306A'
      WHEN (TRIM(CourseSectionMeetingRoomNbr) = '311') AND TRIM(CourseSectionMeetingBuildingAbbr) = 'CDH'
        THEN '311A-D'
      WHEN (TRIM(CourseSectionMeetingRoomNbr) = '191B') AND TRIM(CourseSectionMeetingBuildingAbbr) = 'BAG'
        THEN '191A'
      WHEN LEFT(TRIM(CourseSectionMeetingRoomNbr), 1) = '-'
        THEN REPLACE(SUBSTRING(TRIM(CourseSectionMeetingRoomNbr), 2, LEN(TRIM(CourseSectionMeetingRoomNbr))), ' ', '')
      ELSE REPLACE(REPLACE(TRIM(CourseSectionMeetingRoomNbr), '/', '-'), ' ', '') END AS CourseSectionMeetingRoomNbrTemp
    INTO #classroomstemp
    FROM [EDW].[AnalyticInteg].[sec].[IV_CourseSectionMeetings] -- spoke to Bob. He's OK with a one-to-many join here
    WHERE CourseCampus = 0
        AND AcademicQtrKeyId >= @startqtr
        AND DistanceLearningInd != 'Y' -- do not want to include distance learning courses\
        AND TRIM(CourseSectionMeetingBuildingAbbr) <> ''
        AND TRIM(CourseSectionMeetingBuildingAbbr) <> '*'
        AND TRIM(CourseSectionMeetingRoomNbr) <> ''
        AND TRIM(CourseSectionMeetingRoomNbr) <> '*'
        AND TRIM(CourseSectionMeetingRoomNbr) <> '***'
        AND TRIM(Timeblock) <> 'No Valid time'


-- Rooms that can't be mapped/corrected: CMA 116, HST T663, GLD 240
SELECT CourseSectionMeetingBuildingAbbr
    , CourseSectionMeetingBuildingAbbrClean
    , CourseSectionMeetingRoomNbr
    , CourseSectionMeetingRoomNbrTemp
    , CASE WHEN CHARINDEX('-', CourseSectionMeetingRoomNbrTemp) > 1 
        THEN CASE WHEN SUBSTRING(CourseSectionMeetingRoomNbrTemp, CHARINDEX('-', CourseSectionMeetingRoomNbrTemp) - 1, 1) LIKE '%[a-zA-Z]%' AND
                    SUBSTRING(CourseSectionMeetingRoomNbrTemp, CHARINDEX('-', CourseSectionMeetingRoomNbrTemp) + 1, 1) LIKE '%[0-9]%'
                    THEN STUFF(CourseSectionMeetingRoomNbrTemp, CHARINDEX('-', CourseSectionMeetingRoomNbrTemp), 1, '')
            ELSE CourseSectionMeetingRoomNbrTemp END
      ELSE CourseSectionMeetingRoomNbrTemp END as CourseSectionMeetingRoomNbrClean
    , IIF((CHARINDEX('-', CourseSectionMeetingRoomNbrTemp) > 1) AND 
            (((SUBSTRING(CourseSectionMeetingRoomNbrTemp, CHARINDEX('-', CourseSectionMeetingRoomNbrTemp) - 1, 1) LIKE '%[a-zA-Z]%') AND (SUBSTRING(CourseSectionMeetingRoomNbrTemp, CHARINDEX('-', CourseSectionMeetingRoomNbrTemp) + 1, 1) LIKE '%[a-zA-Z]%')) OR
            ((SUBSTRING(CourseSectionMeetingRoomNbrTemp, CHARINDEX('-', CourseSectionMeetingRoomNbrTemp) - 1, 1) LIKE '%[0-9]%') AND (SUBSTRING(CourseSectionMeetingRoomNbrTemp, CHARINDEX('-', CourseSectionMeetingRoomNbrTemp) + 1, 1) LIKE '%[0-9]%'))), 
            'EXPAND', 'KEEP') AS 'KeepExpand'
    INTO #classroomshold
    FROM #classroomstemp


SELECT CourseSectionMeetingBuildingAbbr
    , CourseSectionMeetingBuildingAbbrClean
    , CourseSectionMeetingRoomNbr
    , bu.BUILDINGNAME AS 'BuildingName'
    , bu.BUILDINGKEY AS 'FacNum'
    , bu.CENTER_FACILITY_LATITUDE AS 'Latitude'
    , bu.CENTER_FACILITY_LONGITUDE AS 'Longitude'
    , CourseSectionMeetingRoomNbrClean
    , rm.[FLOOR]
    , rm.SPACECATEGORY
    , rm.PRIMARYUSE
    , rm.CAPACITY
    INTO #classroomskept
    FROM #classroomshold cl
    LEFT JOIN #buildinginfo bu
        ON cl.CourseSectionMeetingBuildingAbbrClean = bu.FACILITYCODE
    LEFT JOIN #roominfo rm
        ON cl.CourseSectionMeetingBuildingAbbrClean = rm.FACILITYCODE
        AND cl.CourseSectionMeetingRoomNbrClean = rm.ShortName
    WHERE KeepExpand = 'KEEP'


SELECT CourseSectionMeetingBuildingAbbr
    , CourseSectionMeetingBuildingAbbrClean
    , CourseSectionMeetingRoomNbr
    , CourseSectionMeetingRoomNbrClean
    , SUBSTRING(CourseSectionMeetingRoomNbrTemp, 1, CASE WHEN (CHARINDEX('-', CourseSectionMeetingRoomNbrTemp)) = 0 THEN 0 ELSE (CHARINDEX('-', CourseSectionMeetingRoomNbrTemp) - 1) END) AS 'RoomStart'    
    , SUBSTRING(CourseSectionMeetingRoomNbrTemp, 1, CHARINDEX('-', CourseSectionMeetingRoomNbrTemp) - LEN(SUBSTRING(CourseSectionMeetingRoomNbrTemp, CHARINDEX('-', CourseSectionMeetingRoomNbrTemp), LEN(CourseSectionMeetingRoomNbrTemp))))
        + SUBSTRING(CourseSectionMeetingRoomNbrTemp, CHARINDEX('-', CourseSectionMeetingRoomNbrTemp) + 1, LEN(CourseSectionMeetingRoomNbrTemp)) AS 'RoomEnd'
    INTO #classroomsexpand
    FROM #classroomshold cl
    WHERE KeepExpand = 'EXPAND'


SELECT CourseSectionMeetingBuildingAbbr
    , CourseSectionMeetingBuildingAbbrClean
    , CourseSectionMeetingRoomNbr
    , bu.BUILDINGNAME As 'BuildingName'
    , bu.BUILDINGKEY AS 'FacNum'
    , bu.CENTER_FACILITY_LATITUDE AS 'Latitude'
    , bu.CENTER_FACILITY_LONGITUDE AS 'Longitude'
    , rm.ShortName AS CourseSectionMeetingRoomNbrClean
    , rm.[FLOOR]
    , rm.SPACECATEGORY
    , rm.PRIMARYUSE
    , rm.CAPACITY
    INTO #classroomsexpanded
    FROM #classroomsexpand cl
    LEFT JOIN #buildinginfo bu
        ON cl.CourseSectionMeetingBuildingAbbrClean = bu.FACILITYCODE
    JOIN #roominfo rm
        ON cl.CourseSectionMeetingBuildingAbbrClean = rm.FACILITYCODE
        AND rm.ShortName BETWEEN RoomStart AND RoomEnd
    WHERE (CourseSectionMeetingBuildingAbbrClean <> 'SWS') OR rm.ShortName NOT IN ('027', '029') -- SWS 027 and 029 are restrooms
    ORDER BY CourseSectionMeetingRoomNbr, CourseSectionMeetingRoomNbrClean


SELECT cs.AcademicQtrKeyId
    , cs.CourseSectionCode
    , cs.CourseSectionStudentCount
    , cs.CourseSectionSCH
    , cs.CourseSectionId
    , cs.CurriculumAbbrCode
    , cs.CourseNbr
    , cs.CourseLevelGroupCode
    , cs.CourseLevelCode
    , cs.DistanceLearningInd
    , cs.SDBInstituteCode
    , csm.WeeklyClassroomHours
    , ios.IOSLevel3Name as 'CurriculumSchoolCollege'
    , ios.IOSLevel2Name as 'Campus'
    , csm.CourseSectionMeetingTypeDesc
    , csm.CourseSectionMeetingBuildingAbbr
    , csm.CourseSectionMeetingRoomNbr
    , COALESCE(fac.CourseSectionMeetingBuildingAbbrClean, ex.CourseSectionMeetingBuildingAbbrClean) AS 'CourseSectionMeetingBuildingAbbrClean'
    , COALESCE(fac.FacNum, ex.FacNum) AS 'FacNum'
    , COALESCE(fac.BuildingName, ex.BuildingName) AS 'BuildingName'
    , COALESCE(fac.Latitude, ex.Latitude) AS 'Latitude'
    , COALESCE(fac.Longitude, ex.Longitude) AS 'Longitude'
    , COALESCE(fac.CourseSectionMeetingRoomNbrClean, ex.CourseSectionMeetingRoomNbrClean) AS 'CourseSectionMeetingRoomNbrClean'
    , CONCAT(COALESCE(fac.CourseSectionMeetingBuildingAbbrClean, ex.CourseSectionMeetingBuildingAbbrClean), '_', COALESCE(fac.CourseSectionMeetingRoomNbrClean, ex.CourseSectionMeetingRoomNbrClean)) as 'Classroom'
    , COALESCE(fac.[FLOOR], ex.[FLOOR]) AS 'Floor'
    , COALESCE(fac.SPACECATEGORY, ex.SPACECATEGORY) AS 'SpaceCategory'
    , COALESCE(fac.PRIMARYUSE, ex.PRIMARYUSE) AS 'PrimaryUse'
    , COALESCE(fac.CAPACITY, ex.CAPACITY) AS 'RoomCapacity'
    , CourseSectionMeetingDaysOfWeek
    , Timeblock
    , CASE WHEN CAST(TRIM(LEFT(Timeblock, charindex('-', Timeblock + '-') - 1)) AS INT) < 630 THEN CAST(TRIM(LEFT(Timeblock, charindex('-', Timeblock + '-') - 1)) AS INT) + 1200
        ELSE CAST(TRIM(LEFT(Timeblock, charindex('-', Timeblock + '-') - 1)) AS INT)
        END as 'CourseSectionMeetingStartTime'
    , CASE WHEN CAST(TRIM(RIGHT(Timeblock, len(Timeblock) - charindex('-', Timeblock + '-'))) AS INT) < 700 THEN CAST(TRIM(RIGHT(Timeblock, len(Timeblock) - charindex('-', Timeblock + '-'))) AS INT) + 1200
        WHEN ((CAST(TRIM(LEFT(Timeblock, charindex('-', Timeblock + '-') - 1)) AS INT) < 630) AND (CAST(TRIM(RIGHT(Timeblock, len(Timeblock) - charindex('-', Timeblock + '-'))) AS INT) < 1200)) THEN CAST(TRIM(RIGHT(Timeblock, len(Timeblock) - charindex('-', Timeblock + '-'))) AS INT) + 1200
        ELSE CAST(TRIM(RIGHT(Timeblock, len(Timeblock) - charindex('-', Timeblock + '-'))) AS INT)
        END as 'CourseSectionMeetingEndTime'
    , MondayMeetingInd
    , TuesdayMeetingInd
    , WednesdayMeetingInd
    , ThursdayMeetingInd
    , FridayMeetingInd
    , SaturdayMeetingInd
    INTO #coursesections
    FROM [EDW].[AnalyticInteg].[sec].[IV_CourseSections] cs
    LEFT JOIN [EDW].[AnalyticInteg].[sec].[IV_CourseSectionMeetings] csm -- spoke to Bob. He's OK with a one-to-many join here
        ON cs.AcademicQtrKeyId = csm.AcademicQtrKeyId
        AND cs.CourseSectionCode = csm.CourseSectionCode
    LEFT JOIN #classroomskept fac
        ON csm.CourseSectionMeetingBuildingAbbr = fac.CourseSectionMeetingBuildingAbbr
        AND csm.CourseSectionMeetingRoomNbr = fac.CourseSectionMeetingRoomNbr
    LEFT JOIN #classroomsexpanded ex
        ON csm.CourseSectionMeetingBuildingAbbr = ex.CourseSectionMeetingBuildingAbbr
        AND csm.CourseSectionMeetingRoomNbr = ex.CourseSectionMeetingRoomNbr
    LEFT JOIN [EDW].[AnalyticInteg].[sec].[IV_HistoricalCurriculumIOS] ios
        ON cs.AcademicQtrKeyId = ios.AcademicQtrKeyId
        AND cs.CurriculumAbbrCode = ios.CurriculumAbbrCode
    WHERE cs.CourseCampus = 0
        AND cs.AcademicQtrKeyId >= @startqtr
        AND csm.CourseCampus = 0
        AND csm.AcademicQtrKeyId >= @startqtr
        AND csm.DistanceLearningInd != 'Y' -- do not want to include distance learning courses\
        AND TRIM(csm.CourseSectionMeetingBuildingAbbr) <> ''
        AND TRIM(csm.CourseSectionMeetingBuildingAbbr) <> '*'
        AND TRIM(csm.CourseSectionMeetingRoomNbr) <> ''
        AND TRIM(csm.CourseSectionMeetingRoomNbr) <> '*'
        AND TRIM(csm.CourseSectionMeetingRoomNbr) <> '***'
        AND TRIM(csm.Timeblock) <> 'No Valid time'
        AND CourseSectionStudentCount > 0
        AND ios.PrimaryOrgUnitInd = 'Y'


-- Going from wide to long
SELECT *
    INTO ClassUtil.ClassroomUtilizationMaster
    FROM 
    (SELECT AcademicQtrKeyId 
        , CourseSectionCode
        , CourseSectionStudentCount
        , CourseSectionSCH
        , CurriculumAbbrCode
        , CourseNbr
        , CourseSectionId
        , CourseLevelGroupCode
        , CourseLevelCode
        , DistanceLearningInd
        , SDBInstituteCode
        , WeeklyClassroomHours
        , CurriculumSchoolCollege
        , Campus
        , CourseSectionMeetingTypeDesc
        , CourseSectionMeetingBuildingAbbrClean
        , FacNum
        , BuildingName
        , Latitude
        , Longitude
        , [Floor]
        , SpaceCategory
        , PrimaryUse
        , RoomCapacity
        , CourseSectionMeetingRoomNbrClean
        , Classroom
        , CourseSectionMeetingDaysOfWeek
        , Timeblock
        , TimeFromParts(CourseSectionMeetingStartTime / 100, CourseSectionMeetingStartTime % 100, 0, 0, 0) as CourseSectionMeetingStartTime
        , TimeFromParts(CourseSectionMeetingEndTime / 100, CourseSectionMeetingEndTime % 100, 0, 0, 0) as CourseSectionMeetingEndTime
        , 'Monday' AS SectionMeetingDayOfWeek
        FROM #coursesections
            WHERE MondayMeetingInd = 'Y'
        UNION ALL
    SELECT AcademicQtrKeyId 
        , CourseSectionCode
        , CourseSectionStudentCount
        , CourseSectionSCH
        , CurriculumAbbrCode
        , CourseNbr
        , CourseSectionId
        , CourseLevelGroupCode
        , CourseLevelCode
        , DistanceLearningInd
        , SDBInstituteCode
        , WeeklyClassroomHours
        , CurriculumSchoolCollege
        , Campus
        , CourseSectionMeetingTypeDesc
        , CourseSectionMeetingBuildingAbbrClean
        , FacNum
        , BuildingName
        , Latitude
        , Longitude
        , [Floor]
        , SpaceCategory
        , PrimaryUse
        , RoomCapacity
        , CourseSectionMeetingRoomNbrClean
        , Classroom
        , CourseSectionMeetingDaysOfWeek
        , Timeblock
        , TimeFromParts(CourseSectionMeetingStartTime / 100, CourseSectionMeetingStartTime % 100, 0, 0, 0) as CourseSectionMeetingStartTime
        , TimeFromParts(CourseSectionMeetingEndTime / 100, CourseSectionMeetingEndTime % 100, 0, 0, 0) as CourseSectionMeetingEndTime
        , 'Tuesday' AS SectionMeetingDayOfWeek
        FROM #coursesections
            WHERE TuesdayMeetingInd = 'Y'
        UNION ALL
    SELECT AcademicQtrKeyId 
        , CourseSectionCode
        , CourseSectionStudentCount
        , CourseSectionSCH
        , CurriculumAbbrCode
        , CourseNbr
        , CourseSectionId
        , CourseLevelGroupCode
        , CourseLevelCode
        , DistanceLearningInd
        , SDBInstituteCode
        , WeeklyClassroomHours
        , CurriculumSchoolCollege
        , Campus
        , CourseSectionMeetingTypeDesc
        , CourseSectionMeetingBuildingAbbrClean
        , FacNum
        , BuildingName
        , Latitude
        , Longitude
        , [Floor]
        , SpaceCategory
        , PrimaryUse
        , RoomCapacity
        , CourseSectionMeetingRoomNbrClean
        , Classroom
        , CourseSectionMeetingDaysOfWeek
        , Timeblock
        , TimeFromParts(CourseSectionMeetingStartTime / 100, CourseSectionMeetingStartTime % 100, 0, 0, 0) as CourseSectionMeetingStartTime
        , TimeFromParts(CourseSectionMeetingEndTime / 100, CourseSectionMeetingEndTime % 100, 0, 0, 0) as CourseSectionMeetingEndTime
        , 'Wednesday' AS SectionMeetingDayOfWeek
        FROM #coursesections
            WHERE WednesdayMeetingInd = 'Y'
        UNION ALL
    SELECT AcademicQtrKeyId 
        , CourseSectionCode
        , CourseSectionStudentCount
        , CourseSectionSCH
        , CurriculumAbbrCode
        , CourseNbr
        , CourseSectionId
        , CourseLevelGroupCode
        , CourseLevelCode
        , DistanceLearningInd
        , SDBInstituteCode
        , WeeklyClassroomHours
        , CurriculumSchoolCollege
        , Campus
        , CourseSectionMeetingTypeDesc
        , CourseSectionMeetingBuildingAbbrClean
        , FacNum
        , BuildingName
        , Latitude
        , Longitude
        , [Floor]
        , SpaceCategory
        , PrimaryUse
        , RoomCapacity
        , CourseSectionMeetingRoomNbrClean
        , Classroom
        , CourseSectionMeetingDaysOfWeek
        , Timeblock
        , TimeFromParts(CourseSectionMeetingStartTime / 100, CourseSectionMeetingStartTime % 100, 0, 0, 0) as CourseSectionMeetingStartTime
        , TimeFromParts(CourseSectionMeetingEndTime / 100, CourseSectionMeetingEndTime % 100, 0, 0, 0) as CourseSectionMeetingEndTime
        , 'Thursday' AS SectionMeetingDayOfWeek
        FROM #coursesections
            WHERE ThursdayMeetingInd = 'Y'
        UNION ALL
    SELECT AcademicQtrKeyId 
        , CourseSectionCode
        , CourseSectionStudentCount
        , CourseSectionSCH
        , CurriculumAbbrCode
        , CourseNbr
        , CourseSectionId
        , CourseLevelGroupCode
        , CourseLevelCode
        , DistanceLearningInd
        , SDBInstituteCode
        , WeeklyClassroomHours
        , CurriculumSchoolCollege
        , Campus
        , CourseSectionMeetingTypeDesc
        , CourseSectionMeetingBuildingAbbrClean
        , FacNum
        , BuildingName
        , Latitude
        , Longitude
        , [Floor]
        , SpaceCategory
        , PrimaryUse
        , RoomCapacity
        , CourseSectionMeetingRoomNbrClean
        , Classroom
        , CourseSectionMeetingDaysOfWeek
        , Timeblock
        , TimeFromParts(CourseSectionMeetingStartTime / 100, CourseSectionMeetingStartTime % 100, 0, 0, 0) as CourseSectionMeetingStartTime
        , TimeFromParts(CourseSectionMeetingEndTime / 100, CourseSectionMeetingEndTime % 100, 0, 0, 0) as CourseSectionMeetingEndTime
        , 'Friday' AS SectionMeetingDayOfWeek
        FROM #coursesections
            WHERE FridayMeetingInd = 'Y'
        UNION ALL
    SELECT AcademicQtrKeyId 
        , CourseSectionCode
        , CourseSectionStudentCount
        , CourseSectionSCH
        , CurriculumAbbrCode
        , CourseNbr
        , CourseSectionId
        , CourseLevelGroupCode
        , CourseLevelCode
        , DistanceLearningInd
        , SDBInstituteCode
        , WeeklyClassroomHours
        , CurriculumSchoolCollege
        , Campus
        , CourseSectionMeetingTypeDesc
        , CourseSectionMeetingBuildingAbbrClean
        , FacNum
        , BuildingName
        , Latitude
        , Longitude
        , [Floor]
        , SpaceCategory
        , PrimaryUse
        , RoomCapacity
        , CourseSectionMeetingRoomNbrClean
        , Classroom
        , CourseSectionMeetingDaysOfWeek
        , Timeblock
        , TimeFromParts(CourseSectionMeetingStartTime / 100, CourseSectionMeetingStartTime % 100, 0, 0, 0) as CourseSectionMeetingStartTime
        , TimeFromParts(CourseSectionMeetingEndTime / 100, CourseSectionMeetingEndTime % 100, 0, 0, 0) as CourseSectionMeetingEndTime
        , 'Saturday' AS SectionMeetingDayOfWeek
        FROM #coursesections
            WHERE SaturdayMeetingInd = 'Y') as tmp


SELECT qtr.AcademicQtrKeyId
    , qtr.AcademicYrQtrDesc
    , clas.Classroom
    , clas.CourseSectionMeetingRoomNbrClean
    , clas.CourseSectionMeetingBuildingAbbrClean
    , clas.SectionMeetingDayOfWeek
    , clas.RoomCapacity
    , clas.FacNum
    , clas.BuildingName
    , clas.Latitude
    , clas.Longitude
    , clas.[Floor]
    , clas.SpaceCategory
    , clas.PrimaryUse
    , tim.StandardTime
    INTO #timeScaffold
    FROM (SELECT StandardTime 
            FROM [EDW].[EDWPresentation].[sec].[dimTime] tim
            WHERE tim.MinutesFromMidnight % 5 = 0
            AND tim.MinutesFromMidnight BETWEEN 360 AND 1260) tim
    CROSS JOIN
    (SELECT AcademicQtrKeyId
            , AcademicYrQtrDesc
            FROM [EDW].[EDWPresentation].[sec].[dmSCH_dimAcademicQtr] qtr
            WHERE qtr.AcademicQtrKeyId BETWEEN @startqtr AND @startqtr + 9
            AND RIGHT(STR(qtr.AcademicQtrKeyId), 1) <> '3') qtr -- excluding summers
    CROSS JOIN
    (SELECT DISTINCT Classroom
        , CourseSectionMeetingRoomNbrClean
        , CourseSectionMeetingBuildingAbbrClean
        , SectionMeetingDayOfWeek
        , RoomCapacity
        , FacNum
        , BuildingName
        , Latitude
        , Longitude
        , [Floor]
        , SpaceCategory
        , PrimaryUse
        FROM ClassUtil.ClassroomUtilizationMaster) clas


SELECT tim.AcademicQtrKeyId 
    , tim.AcademicYrQtrDesc
    , util.CourseSectionCode
    , COALESCE(util.CourseSectionStudentCount, 0) as CourseSectionStudentCount
    , COALESCE(util.CourseSectionSCH, 0) as CourseSectionSCH
    , util.CurriculumAbbrCode
    , util.CourseNbr
    , util.CourseSectionId
    , util.CourseLevelGroupCode
    , util.CourseLevelCode
    , util.DistanceLearningInd
    , util.SDBInstituteCode
    , util.WeeklyClassroomHours
    , util.CurriculumSchoolCollege
    , util.Campus
    , util.CourseSectionMeetingTypeDesc
    , tim.CourseSectionMeetingBuildingAbbrClean
    , tim.BuildingName
    , tim.FacNum
    , tim.[Floor]
    , tim.Latitude
    , tim.Longitude
    , tim.SpaceCategory
    , tim.PrimaryUse
    , tim.RoomCapacity
    , tim.CourseSectionMeetingRoomNbrClean
    , tim.Classroom
    , util.CourseSectionMeetingDaysOfWeek
    , util.Timeblock
    , util.CourseSectionMeetingStartTime
    , util.CourseSectionMeetingEndTime
    , tim.SectionMeetingDayOfWeek
    , tim.StandardTime
    INTO ClassUtil.ClassroomUtilizationForTableau
    FROM #timeScaffold tim
    LEFT JOIN ClassUtil.ClassroomUtilizationMaster util
        ON tim.StandardTime BETWEEN util.CourseSectionMeetingStartTime AND util.CourseSectionMeetingEndTime
        AND tim.SectionMeetingDayOfWeek = util.SectionMeetingDayOfWeek
        AND tim.Classroom = util.Classroom
        AND tim.AcademicQtrKeyId = util.AcademicQtrKeyId
