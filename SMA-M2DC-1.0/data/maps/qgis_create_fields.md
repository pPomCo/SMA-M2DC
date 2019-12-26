# QGis queries to build new fields

Command in QGis query language to create / update computed fields

## Numerical id for general activity domain "sectionuni"

Standard *market* shop attribute.

	CASE
		WHEN "sectionuni" = 'Activites de services administratifs et de soutien' 
		THEN 1
		WHEN "sectionuni" = 'Activites financieres et d\'assurance' 
		THEN 2
		WHEN "sectionuni" = 'Activites immobilieres' 
		THEN 3
		WHEN "sectionuni" = 'Activites specialisees, scientifiques et techniques' 
		THEN 4
		WHEN "sectionuni" = 'Administration publique' 
		THEN 5
		WHEN "sectionuni" = 'Agriculture, sylviculture et peche' 
		THEN 6
		WHEN "sectionuni" = 'Arts, spectacles et activites recreatives' 
		THEN 6
		WHEN "sectionuni" = 'Autres activites de services' 
		THEN 8
		WHEN "sectionuni" = 'Commerce ; reparation d\'automobiles et de motocycles' 
		THEN 9
		WHEN "sectionuni" = 'Construction' 
		THEN 10
		WHEN "sectionuni" = 'Enseignement' 
		THEN 11
		WHEN "sectionuni" = 'Hebergement et restauration' 
		THEN 12
		WHEN "sectionuni" = 'Industrie manufacturiere' 
		THEN 13
		WHEN "sectionuni" = 'Information et communication' 
		THEN 14
		WHEN "sectionuni" = 'Production et distribution d\'electricite, de gaz, de vapeur et d\'air conditionne' 
		THEN 15
		WHEN "sectionuni" = 'Sante humaine et action sociale' 
		THEN 16
		WHEN "sectionuni" = 'Transports et entreposage' 
		THEN 17
		ELSE 0
	END

