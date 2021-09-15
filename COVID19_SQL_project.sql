/*
Covid19 Data Exploration 
From 01.01.2020 To Date
*/

Select  *
From ProjectSQL..CovidDeaths cd
Where cd.continent is not null
order by 3,4

-- Query that I will be using further 

Select cd.location, cd.date, cd.total_cases, cd.new_cases, cd.total_deaths, cd.population
From ProjectSQL..CovidDeaths cd
Where cd.continent is not null
Order by 1,2

-- Death percentage - Total deaths divided by total cases for each day in every country

Select cd.location, cd.date, cd.total_cases, cd.total_deaths, (cd.total_deaths/cd.total_cases)*100 as death_percentage
From ProjectSQL..CovidDeaths cd
Where cd.continent is not null
Order by 1,2

-- Death percentage - Total deaths divided by total cases for each day in every country
-- Rounded to 2 decimal places using CTE

	With rounded_percentage_values (locations, date, total_cases, total_deaths, death_percentage)
	as
	(
		Select cd.location, cd.date, cd.total_cases, cd.total_deaths, (cd.total_deaths/cd.total_cases)*100 as death_percentage
		From ProjectSQL..CovidDeaths cd
		Where cd.continent is not null
	)
Select locations, date, total_cases, total_deaths, ROUND(Death_Percentage,2) as death_percentage
From rounded_percentage_values

-- Total case vs Populations - what percentage of populations in each country were infected by covid


Select cd.location, cd.date, cd.population, cd.total_cases, (cd.total_cases/cd.population)*100 as percent_population_infected
From ProjectSQL..CovidDeaths cd
Where cd.continent is not null
Order by 1,2

-- Total case vs Populations - what percentage of populations in each country were infected by covid
-- Rounded to 2 decimal places using subquery

Select rou.location, rou.date, rou.population, rou.total_cases, ROUND(rou.percent_population_infected, 2) as percent_population_infected
From (
Select cd.location, cd.date, cd.population, cd.total_cases, (cd.total_cases/cd.population)*100 as percent_population_infected
From ProjectSQL..CovidDeaths cd
Where cd.continent is not null) As rou
Order by 1,2

-- Countries with highest deaths count

Select cd.location, MAX(CAST(cd.total_deaths as int)) as total_death_count
From ProjectSQL..CovidDeaths cd
Where cd.continent is not null
Group by cd.location
Order by total_death_count desc

-- Countries with highest ratio infections to population

Select cd.location, cd.population, MAX(cd.total_cases) as highest_infections_count, MAX(cd.total_cases/cd.population)*100 as percent_population_infected
From ProjectSQL..CovidDeaths cd
Where cd.continent is not null
Group by cd.location, cd.population
Order by percent_population_infected desc


-- Query which shows global numbers cases/deaths/%

Select SUM(cd.new_cases) as total_cases, SUM(CAST(cd.new_deaths as int)) as total_deaths, SUM(CAST(cd.new_deaths as int))/SUM(cd.new_cases)*100 as death_percentage
From ProjectSQL..CovidDeaths cd
where cd.continent is not null 


-- Total Population and rolling vaccinations by date
-- Shows cumulatively vaccinations for each country by date

Select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
, SUM(CONVERT(int,cv.new_vaccinations)) OVER (Partition by cd.location Order by cd.location, cd.date) as Rolling_People_Vaccination
From ProjectSQL..CovidDeaths cd
Join ProjectSQL..CovidVaccinations cv
	On cd.location = cv.location
	and cd.date = cv.date
where cd.continent is not null
Order by 2,3

-- Shows Percentage of Population that has recieved at least one Covid Vaccine
-- Using previous query and CTE

With Pop_vs_Vac(continent, location, date, population, new_vaccinations, Rolling_People_Vaccination)
as
(
Select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
, SUM(CONVERT(int,cv.new_vaccinations)) OVER (Partition by cd.location Order by cd.location, cd.date) as Rolling_People_Vaccination
From ProjectSQL..CovidDeaths cd
Join ProjectSQL..CovidVaccinations cv
	On cd.location = cv.location
	and cd.date = cv.date
where cd.continent is not null
)
Select *, ROUND((Rolling_People_Vaccination/population)*100,2) as Percentage_Rolling_People_Vaccinations
From Pop_vs_Vac

-- Using TEMP TABLE to the same query 

Drop table if exists #PercentPeopleVaccinated
Create table #PercentPeopleVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
Rolling_People_Vaccination float
)

Insert into #PercentPeopleVaccinated
Select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
, SUM(CONVERT(int,cv.new_vaccinations)) OVER (Partition by cd.location Order by cd.location, cd.date) as Rolling_People_Vaccination
From ProjectSQL..CovidDeaths cd
Join ProjectSQL..CovidVaccinations cv
	On cd.location = cv.location
	and cd.date = cv.date
where cd.continent is not null

Select *, ROUND((Rolling_People_Vaccination/population)*100,2) as Percentage_Rolling_People_Vaccinations
From #PercentPeopleVaccinated

-- Poland position on world if it comes to total covid cases
-- Using subquery
Select * 
From
(
Select location, SUM(new_cases) as total_cases, RANK() OVER(Order by SUM(new_cases) DESC) as rank
From ProjectSQL..CovidDeaths
where continent is not null
Group by location) as ranking
Where location = 'Poland'


--Creating View to store data for later visualisation

Create View PercentPopulationVaccinated as
Select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
, SUM(CONVERT(int,cv.new_vaccinations)) OVER (Partition by cd.location Order by cd.location, cd.date) as Rolling_People_Vaccination
From ProjectSQL..CovidDeaths cd
Join ProjectSQL..CovidVaccinations cv
	On cd.location = cv.location
	and cd.date = cv.date
where cd.continent is not null


