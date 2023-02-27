/* Queries to Gather relevant Totals*/

-- Percentage of population vaccinated by country

select
	cv.location, 
	format(cd.population, '#,#') as TotalPopulation,
	format(max(cast(cv.people_fully_vaccinated as bigint)), '#,#') as NumFullyVaccinated,
	ROUND((max(cast(cv.people_fully_vaccinated as bigint))/cd.population)*100, 2) as PercentFullVaccinated
from covid_vax_updated cv
	join covid_deaths cd on cd.location = cv.location
	and cd.date = cv.date
where cd.continent = 'Africa'
	and cv.people_fully_vaccinated is not null
group by cv.location, cd.population
order by cv.location

-- Percentage of population vaccinated by continent

select
	cv.location, 
	format(cd.population, '#,#') as TotalPopulation,
	format(max(cast(cv.people_fully_vaccinated as bigint)), '#,#') as NumFullyVaccinated,
	ROUND((max(cast(cv.people_fully_vaccinated as bigint))/cd.population)*100, 2) as PercentFullVaccinated
from covid_vax_updated cv
	join covid_deaths cd on cd.location = cv.location
	and cd.date = cv.date
where cd.continent is null
	and cv.people_fully_vaccinated is not null
	and cv.location not like '%income%'
	and cv.location not in ('European Union','World')
group by cv.location, cd.population
order by cv.location

-- Percentage of population vaccinated by income bracket

select
	cv.location, 
	format(cd.population, '#,#') as TotalPopulation,
	format(max(cast(cv.people_fully_vaccinated as bigint)), '#,#') as NumFullyVaccinated,
	ROUND((max(cast(cv.people_fully_vaccinated as bigint))/cd.population)*100, 2) as PercentFullVaccinated
from covid_vax_updated cv
	join covid_deaths cd on cd.location = cv.location
	and cd.date = cv.date
where cd.continent is null
	and cv.people_fully_vaccinated is not null
	and cv.location like '%income%'
group by cv.location, cd.population
order by PercentFullVaccinated


-- Percent of world pop Vaccinated

select
	cv.location, 
	format(cd.population, '#,#') as TotalPopulation,
	format(max(cast(cv.people_fully_vaccinated as bigint)), '#,#') as NumFullyVaccinated,
	ROUND((max(cast(cv.people_fully_vaccinated as bigint))/cd.population)*100, 3) as '% of Pop. Vaccinated'
from covid_vax_updated cv
	join covid_deaths cd on cd.location = cv.location
	and cd.date = cv.date
where cd.continent is null
	and cv.location = 'World'
group by cv.location, cd.population

/*Summary Vaccination, Testing, and Booster Stats by Country - NO NULLS*/
select 
	location,
	format(population, '#,#') as Population,
	format(MAX(cast(total_tests as bigint)), '#,#') as TotTests,
	format(MAX(cast(total_vaccinations as bigint)), '#,#') as TotalVaccinations,
	format(MAX(cast(people_vaccinated as bigint)), '#,#') as TotVaccinatedAtLeastOnce,
	format(MAX(cast(people_fully_vaccinated as bigint)), '#,#') as TotFullVaccinated,
	format(MAX(cast(total_boosters as bigint)), '#,#') as TotBosters
from covid_vax_updated
where continent is not null
	and total_tests is not null
	and total_vaccinations is not null
	and people_vaccinated is not null
	and people_fully_vaccinated is not null
	and total_boosters is not null
group by location, population
order by location

/*Summary Vaccination, Testing, and Booster Stats by Country - W/ NULLS*/
select 
	location,
	format(population, '#,#') as Population,
	format(MAX(cast(total_tests as bigint)), '#,#') as TotTests,
	format(MAX(cast(total_vaccinations as bigint)), '#,#') as TotalVaccinations,
	format(MAX(cast(people_vaccinated as bigint)), '#,#') as TotVaccinatedAtLeastOnce,
	format(MAX(cast(people_fully_vaccinated as bigint)), '#,#') as TotFullVaccinated,
	format(MAX(cast(total_boosters as bigint)), '#,#') as TotBosters
from covid_vax_updated
where continent is not null
group by location, population
order by location

/*Summary Vaccination, and Booster Stats - W/ NULLS by Continent*/
select 
	location,
	format(population, '#,#') as Population,
	format(MAX(cast(total_vaccinations as bigint)), '#,#') as TotalVaccinations,
	format(MAX(cast(people_vaccinated as bigint)), '#,#') as TotVaccinatedAtLeastOnce,
	format(MAX(cast(people_fully_vaccinated as bigint)), '#,#') as TotFullVaccinated,
	format(MAX(cast(total_boosters as bigint)), '#,#') as TotBosters
from covid_vax_updated
where continent is null
	and location not like '%income%'
	and location not in ('European Union','World','International')
group by location, population
order by location

/*Used Import/Export tool to insert data from query [Summary Vaccination, Testing, and Booster Stats - NO NULLS] as table entries into new table 'dbo.TestVaxBoosters_NoNulls' */

/*Summary Stats for countries with NO NULLS*/
select 
	location,
	population,
	TotVaccinatedAtLeastOnce,
	round((TotVaccinatedAtLeastOnce/Population)*100, 2) as PercentVaxAtLeastOnce,
	TotFullVaccinated,
	round((TotFullVaccinated/Population)*100, 2) as PercentFullyVaccinate,
	TotBosters,
	round((TotBosters/Population)*100, 2) as PercentBoosted
from TestVaxBoosters_NoNulls
order by location

/*Used Import/Export tool to insert data from query [Summary Vaccination, Testing, and Booster Stats - W/ NULLS by Country] as table entries into new table 'dbo.TestVaxBoosters_WithNulls' */

/*Summary Stats for countries WITH NULLS*/
select 
	location,
	population,
	TotVaccinatedAtLeastOnce,
	round((TotVaccinatedAtLeastOnce/Population)*100, 2) as PercentVaxAtLeastOnce,
	TotFullVaccinated,
	round((TotFullVaccinated/Population)*100, 2) as PercentFullyVaccinate,
	TotBoosters,
	round((TotBoosters/Population)*100, 2) as PercentBoosted
from TestVaxBoosters_WithNulls

/*To see which countries had the highest positive test result rate*/

with temp3 as (
select
	cv.location,
	tv.TotTests as TotTests,
	max(cv.positive_rate) as PositiveRate
from covid_vax_updated cv
	join TestVaxBoosters_WithNulls tv 
		on tv.location = cv.location
where cv.continent is not null
group by cv.location, tv.TotTests
)

select * from temp3 
where temp3.TotTests is not null
	and temp3.PositiveRate is not null
order by temp3.PositiveRate desc

/*To review factors correlated with death rates [NULL values removed]*/

/*Factors against death rate by country*/
with temp1 as (
select 
	v.location,
	max(cast(d.total_deaths as bigint)) as TotDeaths,
	max(v.population_density) as PopDensity,
	max(v.cardiovasc_death_rate) as CardiovascDeathRate,
	max(v.diabetes_prevalence) as DiabetesPrev,
	max(v.hospital_beds_per_thousand) as NumofHospBedsPer1000,
	max(v.aged_65_older) as NumOfPop65orOlder,
	max(v.aged_70_older) as NumOfPop70orOlder,
	max(v.gdp_per_capita) as GDPperCapita,
	max(v.handwashing_facilities) as NumHandWashingFacilities
from covid_vax_updated v
	join covid_deaths d
		on d.location = v.location
		and d.date = v.date
where v.continent is not null
group by v.location
)

select * 
from temp1
--where temp1.TotDeaths is not null
order by temp1.location


/*Smoker statistics*/
select distinct
	v.location,
	max(cast(d.total_deaths as bigint)) as TotDeaths,
	v.male_smokers,
	v.female_smokers
from covid_vax_updated v
join covid_deaths d
		on d.location = v.location
		and d.date = v.date
where v.continent is not null
	and v.male_smokers is not null
	and v.female_smokers is not null
group by v.location, v.male_smokers, v.female_smokers

/*Regarding life expectancy*/
with temp4 as(
select distinct
	v.location, 
	max(cast(d.total_deaths as bigint)) as TotDeaths,
	v.life_expectancy
from covid_vax_updated v
	join covid_deaths d on d.location = v.location
		and d.date = v.date
where v.continent is not null
group by v.location, v.life_expectancy
)

select temp4.*
from temp4
where temp4.TotDeaths is not null
	and temp4.life_expectancy is not null
order by temp4.location

/*Master Spreadsheet*/

with vstats as(
select 
	location,
	population,
	TotVaccinatedAtLeastOnce,
	round((TotVaccinatedAtLeastOnce/Population)*100, 2) as PercentVaxAtLeastOnce,
	TotFullVaccinated,
	round((TotFullVaccinated/Population)*100, 2) as PercentFullyVaccinated,
	(TotVaccinatedAtLeastOnce-TotFullVaccinated) as TotIncompleteVaccinations,
	round(((TotVaccinatedAtLeastOnce/Population)*100)-((TotFullVaccinated/Population)*100), 2) as PercentIncompleteVaccinaitions,
	TotBoosters,
	round((TotBoosters/Population)*100, 2) as PercentBoosted
from TestVaxBoosters_WithNulls
),

factors as (
select 
	v.location,
	max(cast(d.total_deaths as bigint)) as TotDeaths,
	max(v.population_density) as PopDensity,
	max(v.cardiovasc_death_rate) as CardiovascDeathRate,
	max(v.diabetes_prevalence) as DiabetesPrev,
	max(v.hospital_beds_per_thousand) as NumofHospBedsPer1000,
	max(v.aged_65_older) as NumOfPop65orOlder,
	max(v.aged_70_older) as NumOfPop70orOlder,
	max(v.gdp_per_capita) as GDPperCapita,
	max(v.handwashing_facilities) as NumHandWashingFacilities
from covid_vax_updated v
	join covid_deaths d
		on d.location = v.location
		and d.date = v.date
where v.continent is not null
group by v.location
)


select 
	vstat.location,
	vstat.Population,
	factors.PopDensity,
	factors.NumOfPop65orOlder,
	factors.NumOfPop70orOlder,
	factors.TotDeaths,
	vstat.TotVaccinatedAtLeastOnce,
	vstat.PercentVaxAtLeastOnce,
	vstat.TotFullVaccinated,
	vstat.PercentFullyVaccinated,
	vstat.TotIncompleteVaccinations,
	vstat.PercentIncompleteVaccinaitions,
	vstat.TotBoosters,
	vstat.PercentBoosted,
	vstat.VaccinationGroup,
	factors.CardiovascDeathRate,
	factors.DiabetesPrev,
	factors.GDPperCapita,
	factors.NumHandWashingFacilities,
	factors.NumofHospBedsPer1000
from (
	select 
		vstats.*,
		CASE
			WHEN vstats.PercentFullyVaccinated >= 75.00 THEN '3/4 Vaccinated'
			WHEN vstats.PercentFullyVaccinated >= 50.00 THEN '1/2 Vaccinated'
			WHEN vstats.PercentFullyVaccinated >= 25.00 THEN '1/4 Vaccinated'
			ELSE 'LESS THAN 1/4 Vaccinated'
		END as VaccinationGroup
	from vstats
	) as vstat
join factors on factors.location = vstat.location