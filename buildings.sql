IF OBJECT_ID('tempdb..#coursesections') IS NOT NULL DROP TABLE #coursesections
IF OBJECT_ID('tempdb..#professionals') IS NOT NULL DROP TABLE #professionals
IF OBJECT_ID('tempdb..#coursesectionsfiltered') IS NOT NULL DROP TABLE #coursesectionsfiltered
IF OBJECT_ID('tempdb..#coursebuildings') IS NOT NULL DROP TABLE #coursebuildings
IF OBJECT_ID('tempdb..#coursebuildingsfiltered') IS NOT NULL DROP TABLE #coursebuildingsfiltered

DECLARE @sequences table (course varchar(10))
DECLARE @buildings table (building varchar(10), facnum int)
DECLARE @startqtr int = 20232

-- honors sequences here: https://honors.uw.edu/courses/
-- sequences including intro bio, phys, math, and chem sequences along with their honors equivalents
INSERT INTO @sequences values ('BIOL_180'), ('BIOL_200'), ('BIOL_220'), ('CHEM_142'), ('CHEM_152'), ('CHEM_162'), 
    ('CHEM_145'), ('CHEM_155'), ('CHEM_165'), ('MATH_124'), ('MATH_125'), ('MATH_126'), ('MATH_134'), ('MATH_135'), ('MATH_136'),
    ('PHYS_121'), ('PHYS_122'), ('PHYS_123'), ('PHYS_114'), ('PHYS_115'), ('PHYS_116'), ('PHYS_141'), ('PHYS_142'), ('PHYS_143')

-- this building list is pulled from the document detailing the BRP
INSERT INTO @buildings values ('ECE',	1008), ('ESO',	1017), ('GCS',	1019), ('WLA',	1022), ('CCC',	1023), ('PO6',	1026), 
('IC2',	1029), ('WSG',	1030), ('WSP',	1031), ('PL1',	1036), ('OR2',	1037), ('PO2',	1038), ('PO3',	1039), ('PO5',	1040), 
('EIC',	1041), ('SHA',	1045), ('PO7',	1046), ('RAX',	1047), ('ODB',	1049), ('GIL',	1051), ('WNX',	1054), ('EHD',	1072), 
('ADS',	1080), ('ESB',	1100), ('FSB',	1101), ('ISA',	1102), ('DRC',	1103), ('FTR',	1104), ('PSV',	1106), ('ALB',	1107), 
('CHB',	1108), ('MUE',	1109), ('TPG',	1110), ('FLK',	1111), ('PCH',	1112), ('URC',	1113), ('BTB',	1115), ('NLB',	1116), 
('WRS',	1117), ('SCG',	1118), ('ACC',	1119), ('WAC',	1120), ('SWS',	1121), ('MAR',	1122), ('CDH',	1124), ('OUG',	1125), 
('MNY',	1126), ('SMZ',	1127), ('CMA',	1129), ('KIN',	1130), ('AER',	1131), ('BLD',	1132), ('CPG',	1133), ('GTH',	1134), 
('GLD',	1135), ('PDL',	1136), ('IMA',	1137), ('MSB',	1138), ('GDR',	1139), ('EGL',	1140), ('OTB',	1141), ('FAC',	1144), 
('MPG',	1146), ('PSB',	1148), ('NPV',	1150), ('WFS',	1151), ('HUB',	1153), ('HND',	1154), ('TSB',	1155), ('PHT',	1159), 
('CMU',	1161), ('PBB',	1163), ('GRB',	1164), ('NPC',	1167), ('HST',	1168), ('WCL',	1170), ('MOR',	1171), ('UHF',	1172), 
('HSK',	1173), ('HSJ',	1174), ('HSRR',	1175), ('LEW',	1177), ('CLK',	1178), ('PAR',	1179), ('ARC',	1180), ('DEN',	1181), 
('EGA',	1182), ('ICH',	1183), ('PO4',	1184), ('ADL',	1185), ('HHL',	1186), ('OSS',	1189), ('ROB',	1191), ('MLR',	1192), 
('SUZ',	1193), ('HAG',	1194), ('PVP',	1196), ('MGH',	1197), ('GUG',	1198), ('OPB',	1199), ('JHN',	1200), ('GWN',	1201), 
('HLL',	1203), ('KIR',	1205), ('BAG',	1206), ('SMI',	1208), ('HPT',	1209), ('CHCL',	1219), ('CHSB',	1220), ('HSA',	1221), 
('HSAA',	1222), ('HSBB',	1223), ('HSC',	1224), ('HSE',	1225), ('HSF',	1226), ('HSG',	1227), ('HSH',	1228), ('PAB',	1242), 
('PAT',	1243), ('WCP',	1273), ('KNE',	1276), ('BNS',	1277), ('CHL',	1279), ('SGS',	1285), ('OTS',	1286), ('NHS',	1291), 
('ATG',	1294), ('SPG',	1295), ('ART',	1298), ('MUS',	1299), ('HSI',	1300), ('RAI',	1301), ('HUT',	1302), ('HSB',	1304), 
('PAA',	1306), ('SOCC',	1308), ('OCN',	1314), ('EXED',	1316), ('AVA',	1317), ('ICT',	1323), ('HCK',	1324), ('ELB',	1325), 
('SAV',	1327), ('HSD',	1328), ('SIG',	1332), ('GUA',	1344), ('WIL',	1345), ('LOW',	1346), ('MEB',	1347), ('NPS',	1348), 
('OBS',	1349), ('PWR',	1350), ('AND',	1351), ('OCE',	1352), ('CHSC',	1354), ('THO',	1356), ('FSH',	1357), ('LAW',	1420), 
('AHO',	1740), ('W29',	3895), ('GH1',	3924), ('GH2',	3925), ('GH3',	3926), ('GH4',	3927), ('GH5',	3928), ('GH6',	3929), 
('GH7',	3930), ('CSE',	3991), ('PO1',	4038), ('BIOE',	4057), ('GNOM',	4058), ('ERS',	4097), ('CYCO',	4204), ('OTS2',	4352), 
('RTB',	4353), ('NMH',	4436), ('GHEN',	4559), ('GHES',	4560), ('UWTT',	4593), ('UWTO',	4594), ('UWTC',	4595), ('UWTS',	4596), 
('W46',	4601), ('PCAR',	5980), ('DEM',	5981), ('INT',	6082), ('MOL',	6105), ('ECC',	6337), ('UMCU',	6353), ('MRCG',	6381), 
('UWPD',	6392), ('ARCF',	6403), ('NAN',	6428), ('WCUP',	6445), ('W8',	6477), ('BRK',	6492), ('NCG',	6493), ('UMPH',	6498), 
('CSE2',	6502), ('LSB',	6513), ('LSG',	6514), ('HRC',	6524)


SELECT cs.AcademicQtrKeyId
    , cs.CourseSectionCode
    , cs.CourseSectionStudentCount
    , cs.CourseSectionSCH
    , cs.CurriculumAbbrCode
    , cs.CourseNbr
    , cs.CourseLevelGroupCode
    , cs.CourseLevelCode
    , csm.CourseSectionMeetingTypeDesc
    , TRIM(csm.CourseSectionMeetingBuildingAbbr) as CourseSectionMeetingBuildingAbbr -- some building names have leading/trailing spaces
    , csm.CourseSectionMeetingRoomNbr
    INTO #coursesections
    FROM [AnalyticInteg].[sec].[IV_CourseSections] cs
    LEFT JOIN [AnalyticInteg].[sec].[IV_CourseSectionMeetings] csm -- spoke to Bob. He's OK with a one-to-many join here
        ON cs.AcademicQtrKeyId = csm.AcademicQtrKeyId
        AND cs.CourseSectionCode = csm.CourseSectionCode
    WHERE cs.CourseCampus = 0
        AND cs.AcademicQtrKeyId > @startqtr
        AND ((cs.CourseLevelGroupCode = 'Undergraduate') OR (cs.CourseLevelCode = 'Professional'))
        AND csm.CourseCampus = 0
        AND csm.AcademicQtrKeyId > @startqtr -- only courses over the past year
        AND csm.DistanceLearningInd != 'Y' -- do not want to include distance learning courses


-- These are buildings in the time schedule that are not in the BRP building list
-- Confirmed to include: HSEB, CSH, FNDR, MCC, POP
-- Building codes (respective) for the above list (as found here: https://facilities.uw.edu/bldg):
-- 6534, 1166, 6550, 6742, 6138
SELECT DISTINCT CourseSectionMeetingBuildingAbbr, facnum
    FROM #coursesections cs
    LEFT JOIN @buildings b
    ON cs.CourseSectionMeetingBuildingAbbr = b.building
    WHERE building IS NULL
        AND CourseSectionMeetingBuildingAbbr NOT IN ('*', '')

SELECT *
    INTO #coursesectionsfiltered
    FROM #coursesections cs
    JOIN @buildings b
    ON cs.CourseSectionMeetingBuildingAbbr = b.building
    WHERE CourseSectionMeetingBuildingAbbr IS NOT NULL
        AND CourseSectionMeetingBuildingAbbr <> ''
        AND CourseSectionMeetingBuildingAbbr <> '*'


-- question 1: SCH per building listed
SELECT AcademicQtrKeyId 
    , CourseSectionMeetingBuildingAbbr as 'BuildingAbbr'
    , FacNum
    , SUM(CourseSectionSCH) as 'TotalSCH'
    FROM #coursesectionsfiltered
    WHERE CourseSectionSCH > 0
        AND CourseLevelGroupCode = 'Undergraduate'
    GROUP BY CourseSectionMeetingBuildingAbbr,FacNum, AcademicQtrKeyId
    ORDER BY AcademicQtrKeyId, FacNum

-- question 2: SCH per building for sequence courses
SELECT AcademicQtrKeyId
    , CONCAT(CurriculumAbbrCode, '_', CourseNbr) as 'Course'
    , CourseSectionMeetingBuildingAbbr as 'BuildingAbbr'
    , FacNum
    , SUM(CourseSectionSCH) as 'TotalSCH'
    FROM #coursesectionsfiltered cs
    JOIN @sequences s
        ON s.course = CONCAT(cs.CurriculumAbbrCode, '_', cs.CourseNbr)
    WHERE cs.CourseSectionSCH > 0
        AND cs.CourseLevelGroupCode = 'Undergraduate'
    GROUP BY CONCAT(CurriculumAbbrCode, '_', CourseNbr), FacNum, CourseSectionMeetingBuildingAbbr, AcademicQtrKeyId
    ORDER BY CONCAT(CurriculumAbbrCode, '_', CourseNbr), FacNum, AcademicQtrKeyId

-- question 3: SCH per building for professional courses
SELECT AcademicQtrKeyId 
    , CourseSectionMeetingBuildingAbbr as 'BuildingAbbr'
    , FacNum
    , SUM(CourseSectionSCH) as 'TotalSCH'
    FROM #coursesectionsfiltered
    WHERE CourseSectionSCH > 0
        AND CourseLevelCode = 'Professional'
    GROUP BY CourseSectionMeetingBuildingAbbr, FacNum, AcademicQtrKeyId
    ORDER BY AcademicQtrKeyId, FacNum

-- question 4: SCH per building for lab/studio courses
SELECT AcademicQtrKeyId
    , CourseSectionMeetingTypeDesc
    , CourseSectionMeetingBuildingAbbr as 'BuildingAbbr'
    , FacNum
    , SUM(CourseSectionSCH) as 'TotalSCH'
    FROM #coursesectionsfiltered
    WHERE CourseSectionSCH > 0
        AND CourseSectionMeetingTypeDesc IN ('Lab', 'Studio', 'Clinic')
    GROUP BY CourseSectionMeetingBuildingAbbr, FacNum, CourseSectionMeetingTypeDesc, AcademicQtrKeyId
    ORDER BY AcademicQtrKeyId, CourseSectionMeetingTypeDesc, FacNum