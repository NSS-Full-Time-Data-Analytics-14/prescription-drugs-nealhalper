--There is duplication in the drugs table.  
--Run 'SELECT COUNT(drug_name) FROM drug' then 'SELECT COUNT (DISTINCT drug_name) FROM drug'.  
--Notice the difference?  You can investigate further and then be sure to consider 
--the duplication when joining to the drug table.

SELECT COUNT(drug_name)
FROM drug;

SELECT COUNT(DISTINCT drug_name)
FROM drug;

SELECT COUNT(generic_name)
FROM drug;

SELECT COUNT(DISTINCT generic_name)
FROM drug;

--no opioid drugs are duplicated in drug name
SELECT COUNT(drug_name), drug_name
FROM drug
WHERE opioid_drug_flag  = 'Y' OR long_acting_opioid_drug_flag = 'Y'
GROUP BY drug_name
HAVING COUNT(drug_name) > 1;

--1.
    --a. Which prescriber had the highest total number of claims (totaled over all drugs)? 
	--Report the npi and the total number of claims.

SELECT npi, SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription
USING (npi)
GROUP BY npi
ORDER BY SUM(total_claim_count) DESC
LIMIT 1;

    --b. Repeat the above, but this time report the nppes_provider_first_name, 
	--nppes_provider_last_org_name,  specialty_description, and the total number of claims.

SELECT 	nppes_provider_first_name,
		nppes_provider_last_org_name, 
		specialty_description,
		SUM(total_claim_count) AS total_claims 
FROM prescriber
INNER JOIN prescription
USING (npi)
GROUP BY nppes_provider_first_name,
		nppes_provider_last_org_name, 
		specialty_description
ORDER BY SUM(total_claim_count) DESC
LIMIT 1;

--2.
    --a. Which specialty had the most total number of claims (totaled over all drugs)?

SELECT 	specialty_description,
		SUM(total_claim_count) AS total_claims 
FROM prescriber
INNER JOIN prescription
USING (npi)
GROUP BY specialty_description
ORDER BY SUM(total_claim_count) DESC
LIMIT 1;

    --b. Which specialty had the most total number of claims for opioids?

SELECT 	specialty_description,
		SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription
USING (npi)
INNER JOIN drug
USING (drug_name)
WHERE opioid_drug_flag = 'Y' OR long_acting_opioid_drug_flag = 'Y'
GROUP BY specialty_description
ORDER BY total_claims DESC;

    --c. **Challenge Question:** Are there any specialties that appear in the prescriber 
	--table that have no associated prescriptions in the prescription table?

SELECT specialty_description, SUM(total_claim_count) AS claim_count_per_specialty
FROM prescriber
INNER JOIN prescription
USING (npi)
GROUP BY specialty_description
ORDER BY claim_count_per_specialty ASC;

    --d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* 
	--For each specialty, report the percentage of total claims by that 
	--specialty which are for opioids. Which specialties have a high percentage of opioids?

WITH total_opioid_claims_by_specialty AS (SELECT 	specialty_description,
		SUM(total_claim_count) AS total_opioid_claims
FROM prescriber
INNER JOIN prescription
USING (npi)
INNER JOIN drug
USING (drug_name)
WHERE opioid_drug_flag = 'Y' OR long_acting_opioid_drug_flag = 'Y'
GROUP BY specialty_description
ORDER BY total_opioid_claims DESC),

	total_claims_by_specialty AS (SELECT 	specialty_description,
		SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription
USING (npi)
INNER JOIN drug
USING (drug_name)
GROUP BY specialty_description
ORDER BY total_claims DESC)

SELECT specialty_description, 
		TO_CHAR((total_opioid_claims/total_claims)*100, 'fm00D00%') AS percent_opioid_claims_in_specialty
FROM total_opioid_claims_by_specialty
INNER JOIN total_claims_by_specialty
USING(specialty_description)
ORDER BY percent_opioid_claims_in_specialty DESC;

--3.
    --a. Which drug (generic_name) had the highest total drug cost?

SELECT total_drug_cost, generic_name
FROM prescription
INNER JOIN drug
USING(drug_name)
GROUP BY DISTINCT generic_name, total_drug_cost
ORDER BY total_drug_cost DESC
LIMIT 1;

    --b. Which drug (generic_name) has the hightest total cost per day? 
	--**Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**

SELECT ROUND(total_drug_cost/30, 2) AS cost_per_day, generic_name
FROM prescription
INNER JOIN drug
USING(drug_name)
GROUP BY DISTINCT generic_name, total_drug_cost
ORDER BY total_drug_cost DESC;

--4.
    --a. For each drug in the drug table, return the drug name and then a column named 
	--'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', 
	--says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', 
	--and says 'neither' for all other drugs. 
	--**Hint:** You may want to use a CASE expression for this. 

SELECT DISTINCT drug_name,
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		ELSE 'neither' END AS drug_type
FROM drug;

    --b. Building off of the query you wrote for part a, determine whether more was spent 
	--(total_drug_cost) on opioids or on antibiotics. 
	--Hint: Format the total costs as MONEY for easier comparision.

SELECT (SUM(total_drug_cost)::money) AS cost_by_drug_type,
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		ELSE 'neither' END AS drug_type
FROM drug
INNER JOIN prescription
USING (drug_name)
GROUP BY drug_type
ORDER BY cost_by_drug_type DESC;

--5.
    --a. How many CBSAs are in Tennessee? 
	--**Warning:** The cbsa table contains information for all states, not just Tennessee.

SELECT COUNT(cbsaname)
FROM cbsa
WHERE cbsaname LIKE '%TN%';

    --b. Which cbsa has the largest combined population? Which has the smallest? 
	--Report the CBSA name and total population.

SELECT SUM(population) AS cbsa_population, cbsaname
FROM cbsa
LEFT JOIN population
USING (fipscounty)
WHERE population IS NOT NULL
GROUP BY cbsaname
ORDER BY SUM(population) DESC
LIMIT 1;

    --c. What is the largest (in terms of population) county which is not included in a CBSA? 
	--Report the county name and population.

SELECT county, population, fipscounty 
FROM fips_county
INNER JOIN population
USING (fipscounty)
WHERE fipscounty NOT IN (SELECT fipscounty FROM cbsa)
ORDER BY population DESC
LIMIT 1;

--6.
    --a. Find all rows in the prescription table where total_claims is at least 3000. 
	--Report the drug_name and the total_claim_count.

SELECT drug_name, total_claim_count
FROM prescription
WHERE total_claim_count >= 3000;

    --b. For each instance that you found in part a, add a column that indicates 
	--whether the drug is an opioid.

SELECT drug_name, total_claim_count,
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		ELSE 'not an opioid' END AS drug_type
FROM prescription
INNER JOIN drug
USING (drug_name)
WHERE total_claim_count >= 3000;

    --c. Add another column to you answer from the previous part which gives 
	--the prescriber first and last name associated with each row.

SELECT drug_name, total_claim_count, nppes_provider_first_name, nppes_provider_last_org_name,
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		ELSE 'not an opioid' END AS drug_type
FROM prescription
INNER JOIN drug
USING (drug_name)
INNER JOIN prescriber
USING (npi)
WHERE total_claim_count >= 3000;

--7. The goal of this exercise is to generate a full list of all pain management specialists 
--in Nashville and the number of claims they had for each opioid. 
--**Hint:** The results from all 3 parts will have 637 rows.

    --a. First, create a list of all npi/drug_name combinations for 
	--pain management specialists (specialty_description = 'Pain Management) 
	--in the city of Nashville (nppes_provider_city = 'NASHVILLE'), 
	--where the drug is an opioid (opiod_drug_flag = 'Y'). 
	--**Warning:** Double-check your query before running it. 
	--You will only need to use the prescriber and drug tables 
	--since you don't need the claims numbers yet.

WITH npi_pain_nashville AS (SELECT npi
							FROM prescriber
							WHERE specialty_description = 'Pain Management' 
							AND nppes_provider_city = 'NASHVILLE'), 

	opioid_drugs AS (SELECT drug_name
						FROM drug
						WHERE opioid_drug_flag = 'Y')
SELECT npi, drug_name
FROM npi_pain_nashville
CROSS JOIN opioid_drugs;


    --b. Next, report the number of claims per drug per prescriber. 
	--Be sure to include all combinations, whether or not the prescriber had any claims. 
	--You should report the npi, the drug name, and the number of claims (total_claim_count).

WITH npi_pain_nashville AS (SELECT npi
							FROM prescriber
							WHERE specialty_description = 'Pain Management' 
							AND nppes_provider_city = 'NASHVILLE'), 

	opioid_drugs AS (SELECT drug_name
						FROM drug
						WHERE opioid_drug_flag = 'Y')
SELECT npi_pain_nashville.npi, opioid_drugs.drug_name, total_claim_count
FROM npi_pain_nashville
CROSS JOIN opioid_drugs
LEFT JOIN prescription
ON npi_pain_nashville.npi = prescription.npi 
	AND opioid_drugs.drug_name = prescription.drug_name
ORDER BY total_claim_count DESC NULLS LAST;


    --c. Finally, if you have not done so already, fill in any missing values for 
	--total_claim_count with 0. Hint - Google the COALESCE function.

WITH npi_pain_nashville AS (SELECT npi
							FROM prescriber
							WHERE specialty_description = 'Pain Management' 
							AND nppes_provider_city = 'NASHVILLE'), 

	opioid_drugs AS (SELECT drug_name
						FROM drug
						WHERE opioid_drug_flag = 'Y')
SELECT npi_pain_nashville.npi, opioid_drugs.drug_name,
	COALESCE(total_claim_count, 0) AS total_claim_count
FROM npi_pain_nashville
CROSS JOIN opioid_drugs
LEFT JOIN prescription
ON npi_pain_nashville.npi = prescription.npi 
	AND opioid_drugs.drug_name = prescription.drug_name
ORDER BY total_claim_count DESC;