SELECT specialty_description, SUM(total_claim_count) AS total_claims
FROM prescriber 
INNER JOIN prescription
USING (npi)
WHERE specialty_description = 'Interventional Pain Management'
	OR specialty_description = 'Pain Management'
GROUP BY specialty_description;


SELECT specialty_description
FROM (
		SELECT specialty_description, SUM(total_claim_count) AS total_claims
		FROM prescriber
		INNER JOIN prescription
		USING (npi)
		WHERE specialty_description = 'Interventional Pain Management'
			OR specialty_description = 'Pain Management'
		GROUP BY specialty_description
	UNION ALL
		SELECT 'Total', SUM(total_claim_count) AS total_claims
			FROM prescriber
		INNER JOIN prescription
		USING (npi)
		WHERE specialty_description = 'Interventional Pain Management'
			OR specialty_description = 'Pain Management'
	) AS qrymain
GROUP BY specialty_description;

SELECT specialty_description, SUM(total_claim_count) AS total_claims
FROM prescriber 
INNER JOIN prescription
USING (npi)
WHERE specialty_description = 'Interventional Pain Management'
	OR specialty_description = 'Pain Management'
GROUP BY specialty_description;
