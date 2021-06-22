-- CREATE NEW DATABASE
CREATE DATABASE hospital;
-- USE DATABASE hospital
USE hospital;

-- CREATE DIMENSION TABLE business
CREATE TABLE `hospital`.`dim_business` (
  `ims_org_id` VARCHAR(50) NOT NULL,
  `business_name` VARCHAR(100) NULL,
  `ttl_license_beds` INT NULL,
  `ttl_census_beds` INT NULL,
  `ttl_staffed_beds` INT NULL,
  `bed_cluster_id` INT NULL,
  PRIMARY KEY (`ims_org_id`));  

-- CREATE DIMENSION TABLE bed_type
CREATE TABLE `hospital`.`dim_bed_type` (
  `bed_id` INT NOT NULL AUTO_INCREMENT,
  `bed_code` CHAR(2) NULL,
  `bed_desc` VARCHAR(45) NULL,
  PRIMARY KEY (`bed_id`));

-- CREATE FACT TABLE bed_fact
CREATE TABLE `hospital`.`bed_fact` (
  `bed_factid` INT NOT NULL AUTO_INCREMENT,
  `ims_org_id` VARCHAR(50) NOT NULL,
  `bed_id` INT NOT NULL,
  `license_beds` INT NULL,
  `census_beds` INT NULL,
  `staffed_beds` INT NULL,
  PRIMARY KEY (`bed_factid`));

-- INSERT VALUE INTO DIMENTION TABLE dim_business USING IMPORT WIZARD
-- CHECK DATA
SELECT * FROM dim_business;

-- INSERT VALUE INTO DIMENTION TABLE bed_type USING IMPORT WIZARD
-- CHECK DATA
SELECT * FROM dim_bed_type;

-- INSERT VALUE INTO FACT TABLE bed_fact USING IMPORT WIZARD
-- CHECK DATA
SELECT * FROM bed_fact;

-- ADD CONSTRAINT TO DIMENTION TABLE dim_business
ALTER TABLE `hospital`.`bed_fact` 
ADD INDEX `FK_ims_org_id_idx` (`ims_org_id` ASC) VISIBLE;
-- ADD FORIGN KEY TO DIMENTION TABLE dim_business
ALTER TABLE `hospital`.`bed_fact` 
ADD CONSTRAINT `FK_ims_org_id`
  FOREIGN KEY (`ims_org_id`)
  REFERENCES `hospital`.`dim_business` (`ims_org_id`)
  ON DELETE CASCADE
  ON UPDATE NO ACTION;

-- ADD CONSTRAINT TO DIMENTION TABLE bed_type
ALTER TABLE `hospital`.`bed_fact` 
ADD INDEX `FK_bed_id_idx` (`bed_id` ASC) VISIBLE;
-- ADD FORIGN KEY TO DIMENTION TABLE bed_type
ALTER TABLE `hospital`.`bed_fact` 
ADD CONSTRAINT `FK_bed_id`
  FOREIGN KEY (`bed_id`)
  REFERENCES `hospital`.`dim_bed_type` (`bed_id`)
  ON DELETE CASCADE
  ON UPDATE NO ACTION;

-- RETRIVE THE INFORMATION
WITH LicenseBeds AS
-- Top 10 hospitals by number of licensed beds
(
SELECT 
    ims_org_id, 
    business_name, 
    licenseICU, 
    licenseSICU, 
    license_total
FROM
(
SELECT
    d1.ims_org_id,
    business_name,
    SUM(CASE WHEN bed_desc = 'ICU' THEN license_beds END) AS licenseICU,
    SUM(CASE WHEN bed_desc = 'SICU' THEN license_beds END) AS licenseSICU,
    SUM(CASE WHEN bed_desc IN ('ICU', 'SICU') THEN license_beds END) AS license_total
FROM bed_fact f
    INNER JOIN  dim_business d1
    ON d1.ims_org_id = f.ims_org_id
    INNER JOIN dim_bed_type d2 ON d2.bed_id = f.bed_id
GROUP BY 
    d1.ims_org_id, 
    business_name
) tl
ORDER BY license_total DESC
LIMIT 10
),
CensusBeds AS
-- Top 10 hospitals by number of census beds
(
SELECT 
    ims_org_id, 
    business_name, 
    censusICU, 
    censusSICU, 
    census_total
FROM
(
SELECT
    d1.ims_org_id,
    business_name,
    SUM(CASE WHEN bed_desc = 'ICU' THEN census_beds END) AS censusICU,
    SUM(CASE WHEN bed_desc = 'SICU' THEN census_beds END) AS censusSICU,
    SUM(CASE WHEN bed_desc IN ('ICU', 'SICU') THEN census_beds END) AS census_total
FROM bed_fact f
    INNER JOIN  dim_business d1
    ON d1.ims_org_id = f.ims_org_id
    INNER JOIN dim_bed_type d2 ON d2.bed_id = f.bed_id
GROUP BY 
    d1.ims_org_id, 
    business_name
) tc
ORDER BY census_total DESC
LIMIT 10
),
StaffedBeds AS
-- Top 10 hospitals by number of staffed beds
(
SELECT 
    ims_org_id, 
    business_name, 
    staffedICU, 
    staffedSICU, 
    staffed_total
FROM
(
SELECT
    d1.ims_org_id,
    business_name,
    SUM(CASE WHEN bed_desc = 'ICU' THEN staffed_beds END) AS staffedICU,
    SUM(CASE WHEN bed_desc = 'SICU' THEN staffed_beds END) AS staffedSICU,
    SUM(CASE WHEN bed_desc IN ('ICU', 'SICU') THEN staffed_beds END) AS staffed_total
FROM bed_fact f
    INNER JOIN  dim_business d1
    ON d1.ims_org_id = f.ims_org_id
    INNER JOIN dim_bed_type d2 ON d2.bed_id = f.bed_id
GROUP BY 
    d1.ims_org_id, 
    business_name
) ts
ORDER BY staffed_total DESC
LIMIT 10
),
Sum_hospitals AS (
SELECT ims_org_id,business_name
FROM LicenseBeds
UNION 
SELECT ims_org_id,business_name
FROM CensusBeds
UNION 
SELECT ims_org_id,business_name
FROM StaffedBeds
)
SELECT h.ims_org_id, h.business_name,
CASE 
	WHEN licenseICU IS NULL THEN 'NA'
	ELSE licenseICU 
	END AS licenseICU,
CASE 
	WHEN licenseSICU IS NULL THEN 'NA'
	ELSE licenseSICU 
	END AS licenseSICU,
CASE 
	WHEN censusICU IS NULL THEN 'NA'
	ELSE censusICU 
	END AS censusICU,
CASE 
	WHEN censusSICU IS NULL THEN 'NA'
	ELSE censusSICU 
	END AS censusSICU,
CASE 
	WHEN staffedICU IS NULL THEN 'NA'
	ELSE staffedICU 
	END AS staffedICU,
CASE 
	WHEN staffedSICU IS NULL THEN 'NA'
	ELSE staffedSICU 
	END AS staffedSICU
FROM Sum_hospitals h
LEFT JOIN LicenseBeds l 
ON h.ims_org_id = l.ims_org_id 
LEFT JOIN CensusBeds c
ON h.ims_org_id = c.ims_org_id
LEFT JOIN StaffedBeds s
ON h.ims_org_id = s.ims_org_id;
-- ORDER BY license_total/census_total/staffed_total, LIMIT 10
















