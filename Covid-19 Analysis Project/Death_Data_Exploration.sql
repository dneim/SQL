--Select relevant data

select
	location,
	date,
	total_cases,
	new_cases,
	total_deaths,
	population
from covid_deaths
order by 1,2

-- Total cases vs. total deaths

select
	location,
	date,
	total_cases,
	total_deaths,
	(total_deaths/total_cases)*100 as '% mortality'
from covid_deaths
where location = 'United States'
order by 1,2

-- Total cases vs the population

select
	location,
	population,
	date,
	MAX(total_cases) as HighestInfectionCount,
	MAX((total_cases/population))*100 as PercentPopulationInfected
from covid_deaths
where continent is not null
group by location, population, date
order by PercentPopulationInfected desc

-- Countries with highest infection rate in population

select
	location,
	population,
	MAX(total_cases) as 'Highest Infection Count',
	MAX((total_cases/population))*100 as '% pop. infected'
from covid_deaths
where continent is not null
group by location, population
order by '% pop. infected' desc

-- Countires with highest death rates

select
	location,
	MAX(cast(total_deaths as int)) as 'Total Death Count'
from covid_deaths
where continent is not null
group by location
order by 'Total Death Count' desc

-- Highest death rate by continent (to be used for viz)

select
	location,
	MAX(cast(total_deaths as int)) as 'Total Death Count'
from covid_deaths
where continent is null
	and location not like '%income%'
	and location not in ('World','European Union','International')
group by location
order by 'Total Death Count' desc


-- Highest death rate by continent According to video (not accurate)

select
	continent,
	MAX(cast(total_deaths as int)) as 'Total Death Count'
from covid_deaths
where continent is not null
group by continent 
order by 'Total Death Count' desc


-- Global Numbers
select 
	MAX(total_cases) as 'Total Cases',
	MAX(cast(total_deaths as int)) as 'Total Deaths',
	MAX(cast(total_deaths as int))/MAX(total_cases)*100 as '% of world pop. dead'
from covid_deaths
where location = 'World'
group by population

-- His Way

select
	sum(new_cases) as total_cases,
	sum(cast(new_deaths as int)) as total_deaths,
	sum(cast(new_deaths as int))/sum(new_cases)*100 as DeathPercentage
from covid_deaths
where continent is not null
order by 1,2

-- % of population that has been vaccinated

select 
	cd.continent, 
	cd.location, 
	cd.date, 
	cd.population, 
	cv.new_vaccinations,
	SUM(cast(cv.new_vaccinations as bigint)) OVER (Partition by cd.location Order by cd.location,cd.date) as 'Rolling New Vaccinations Count'
from covid_deaths cd
	join covid_vax_updated cv on cv.location = cd.location
	and cv.date = cd.date
where cd.continent is not null
order by 2,3

-- Simpler way to do the above
select
	location, sum(cast(new_vaccinations as bigint))
from covid_vax_updated
where continent is not null
group by location
order by location

-- Test Stuff

WITH t1 as
(select 
	cd.continent, 
	cd.location, 
	cd.date, 
	cd.population, 
	cv.new_vaccinations,
	SUM(cast(cv.new_vaccinations as bigint)) OVER (Partition by cd.location Order by cd.location,cd.date) as RollingCount
from covid_deaths cd
	join covid_vax_updated cv on cv.location = cd.location
	and cv.date = cd.date
where cd.continent is not null)

select *, (RollingCount/population)*100 as '% of Pop. Vaccinated'
from t1

-- Percentage of population vaccinated by country

select
	cv.location, 
	format(cd.population, '#,#') as TotalPopulation,
	format(max(cast(cv.people_fully_vaccinated as bigint)), '#,#') as NumFullyVaccinated,
	concat(ROUND((max(cast(cv.people_fully_vaccinated as bigint))/cd.population)*100, 2),'%') as '% of Pop. Vaccinated'
from covid_vax_updated cv
	join covid_deaths cd on cd.location = cv.location
	and cd.date = cv.date
where cd.continent is not null
	and cv.people_fully_vaccinated is not null
group by cv.location, cd.population
order by cv.location

-- Percent population vaccinated by continent

select
	cv.location, 
	format(cd.population, '#,#') as TotalPopulation,
	format(max(cast(cv.people_fully_vaccinated as bigint)), '#,#') as NumFullyVaccinated,
	concat(ROUND((max(cast(cv.people_fully_vaccinated as bigint))/cd.population)*100, 2),'%') as '% of Pop. Vaccinated'
from covid_vax_updated cv
	join covid_deaths cd on cd.location = cv.location
	and cd.date = cv.date
where cd.continent is null
	and cv.people_fully_vaccinated is not null
	and cv.location not like '%income%'
	and cv.location not in ('European Union','World')
group by cv.location, cd.population
order by cv.location

-- Percent of world pop Vaccinated

select
	cv.location, 
	format(cd.population, '#,#') as TotalPopulation,
	format(max(cast(cv.people_fully_vaccinated as bigint)), '#,#') as NumFullyVaccinated,
	concat(ROUND((max(cast(cv.people_fully_vaccinated as bigint))/cd.population)*100, 2),'%') as '% of Pop. Vaccinated'
from covid_vax_updated cv
	join covid_deaths cd on cd.location = cv.location
	and cd.date = cv.date
where cd.continent is null
	and cv.location = 'World'
group by cv.location, cd.population



-- TEMP TABLE

Drop table if exists #PercentPopulationVaccinated

Create table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingCount numeric
)

insert into #PercentPopulationVaccinated

select 
	cd.continent, 
	cd.location, 
	cd.date, 
	cd.population, 
	cv.new_vaccinations,
	SUM(cast(cv.new_vaccinations as bigint)) OVER (Partition by cd.location Order by cd.location,cd.date) as RollingCount
from covid_deaths cd
	join covid_vax_updated cv on cv.location = cd.location
	and cv.date = cd.date
where cd.continent is not null


select *, (RollingCount/population)*100 as '% of Pop. Vaccinated'
from #PercentPopulationVaccinated

-- Create Views of Relevant Result Sets

-- % of Population vaccinated
Create View Percent_Popn_Vaccinated_Daily as
WITH t1 as
(select 
	cd.continent, 
	cd.location, 
	cd.date, 
	cd.population, 
	cv.new_vaccinations,
	SUM(cast(cv.new_vaccinations as bigint)) OVER (Partition by cd.location Order by cd.location,cd.date) as RollingCount
from covid_deaths cd
	join covid_vax_updated cv on cv.location = cd.location
	and cv.date = cd.date
where cd.continent is not null)

select *, (RollingCount/population)*100 as '% of Pop. Vaccinated'
from t1

-- % Fully Vaccinated by Country

Create View Percent_Fully_Vaccinated_by_Country as

select
	cv.location, 
	format(cd.population, '#,#') as TotalPopulation,
	format(max(cast(cv.people_fully_vaccinated as bigint)), '#,#') as NumFullyVaccinated,
	concat(ROUND((max(cast(cv.people_fully_vaccinated as bigint))/cd.population)*100, 2),'%') as '% of Pop. Vaccinated'
from covid_vax_updated cv
	join covid_deaths cd on cd.location = cv.location
	and cd.date = cv.date
where cd.continent is not null
	and cv.people_fully_vaccinated is not null
group by cv.location, cd.population

Create View Percent_Fully_Vaccinated_by_Continent as

select
	cv.location, 
	format(cd.population, '#,#') as TotalPopulation,
	format(max(cast(cv.people_fully_vaccinated as bigint)), '#,#') as NumFullyVaccinated,
	concat(ROUND((max(cast(cv.people_fully_vaccinated as bigint))/cd.population)*100, 2),'%') as '% of Pop. Vaccinated'
from covid_vax_updated cv
	join covid_deaths cd on cd.location = cv.location
	and cd.date = cv.date
where cd.continent is null
	and cv.people_fully_vaccinated is not null
	and cv.location not like '%income%'
	and cv.location not in ('European Union','World')
group by cv.location, cd.population

Create View Percent_Fully_Vaccinated_World as

select
	cv.location, 
	format(cd.population, '#,#') as TotalPopulation,
	format(max(cast(cv.people_fully_vaccinated as bigint)), '#,#') as NumFullyVaccinated,
	concat(ROUND((max(cast(cv.people_fully_vaccinated as bigint))/cd.population)*100, 2),'%') as '% of Pop. Vaccinated'
from covid_vax_updated cv
	join covid_deaths cd on cd.location = cv.location
	and cd.date = cv.date
where cd.continent is null
	and cv.location = 'World'
group by cv.location, cd.population