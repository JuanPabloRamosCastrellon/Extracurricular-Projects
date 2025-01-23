--SELECT *
--FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0',
--'Excel 12.0;Database="C:\Users\jpram\Downloads\CovidDeaths.xlsx";HDR=YES;',
--'SELECT * FROM [CovidDeaths$]');

-- Enable advanced options to allow changing more settings
--EXEC sp_configure 'show advanced options', 1;
--RECONFIGURE;

-- Enable the 'Ad Hoc Distributed Queries' feature
--EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
--RECONFIGURE;

--EXEC sp_configure 'Ad Hoc Distributed Queries';

--SELECT *
--FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0',
--'Excel 12.0;Database=C:\Users\jpram\Downloads\CovidVaccinations.xlsx;HDR=YES;IMEX=1;',
--'SELECT * FROM [CovidVaccinations$]');

--SELECT *
--INTO dbo.CovidDeaths
--FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0',
--'Excel 12.0;Database=C:\Users\jpram\Downloads\CovidDeaths.xlsx;HDR=YES;IMEX=1;',
--'SELECT * FROM [CovidDeaths$]');

--SELECT *
--INTO dbo.CovidVaccinations
--FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0',
--'Excel 12.0;Database=C:\Users\jpram\Downloads\CovidVaccinations.xlsx;HDR=YES;IMEX=1;',
--'SELECT * FROM [CovidVaccinations$]');

-------------------------------------------------------------------------------------------

-- Tables
select * from CovidDeaths
where continent is not null
order by 3, 4

select * from CovidVaccinations
where continent is not null
order by 3, 4

-- Data used
select location, date, total_cases, new_cases, total_deaths, population
from CovidDeaths
where continent is not null
order by 1, 2

-- Death rate in Mexico
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathRate
from CovidDeaths
where location like 'Mexico' and continent is not null
order by 1, 2

-- Infected population in Mexico
select location, date, population, total_cases, (total_cases/population)*100 as InfectedPopulation
from CovidDeaths
where location like 'Mexico' and continent is not null
order by 1, 2

-- Countries with highest infection rate compared to population
select location, population, max(total_cases) as HighestInfectionCount, max((total_cases/population))*100 as PercentInfectedPopulation
from CovidDeaths
group by location, population
order by PercentInfectedPopulation desc

-- Countries with highest death count per population
select location, max(cast(total_deaths as int)) as TotalDeathCount
from CovidDeaths
where continent is not null
group by location
order by TotalDeathCount desc

-- Continents with highest death count
select continent, max(cast(total_deaths as int)) as TotalDeathCount
from CovidDeaths
where continent is not null
group by continent
order by TotalDeathCount desc

-- Global numbers, total cases and deaths
select date, sum(new_cases) as totalCases, sum(cast(new_deaths as int)) as totalDeaths, sum(cast(new_deaths as int))/sum(new_cases)*100 as DeathRate
from CovidDeaths
where continent is not null
group by date
order by 1,2

-- Total population and vaccinations (CTE)
with PopulationVsVaccination (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(convert(int, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) RollingPeopleVaccinated
from CovidDeaths dea
join CovidVaccinations vac
on dea.location = vac.location and dea.date = vac.date
where dea.continent is not null
)
select *, (RollingPeopleVaccinated/population)*100 as VaccinationRate
from PopulationVsVaccination

-- Total population and vaccinations (Temp table)

drop table if exists #PercentPopulationVaccinated
create table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(convert(int, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) RollingPeopleVaccinated
from CovidDeaths dea
join CovidVaccinations vac
on dea.location = vac.location and dea.date = vac.date

select *, (RollingPeopleVaccinated/population)*100
from #PercentPopulationVaccinated

-- Percentage of population vaccinated as a view
create view PercentPopulationVaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(convert(int, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) RollingPeopleVaccinated
from CovidDeaths dea
join CovidVaccinations vac
on dea.location = vac.location and dea.date = vac.date
where dea.continent is not null

select * from PercentPopulationVaccinated