
select *
from PortfolioProject.dbo.CovidDeaths
order by 3,4
;

select *
from PortfolioProject..CovidVaccinations
order by 3,4
;


--1. Select Data that we are going to be using

select location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject..CovidDeaths
order by 1,2
;

--2. Looking at Total Cases vs Total Deaths

select location, date, round(total_deaths/total_cases*100,2) as percent_deaths
from PortfolioProject..CovidDeaths
-- where location ='India'
where location like '%states%'
order by 3 desc
;

--3. Looking at Total cases vs population
select location, date, population,round(total_cases/population*100,2) as percent_cases
from PortfolioProject..CovidDeaths
where location ='India'
-- where location like '%states%'
order by 3 desc
;

--4. Looking at countries with highest infection rate compared to population
select location, MAX(total_cases) as highestInfectionCOunt, MAX(round(total_cases/population*100,2)) as max_cases_percent
from PortfolioProject..CovidDeaths
group by location
order by 3 desc
;

-- OR

select location,population, round(SUM(new_cases)/population*100,2) as max_cases_percent
from PortfolioProject..CovidDeaths
group by location,population
order by 3 desc
;

--5. Looking at countries with highest death count per population

select location, MAX(cast(total_deaths as int)) as highestDeathCount
from PortfolioProject..CovidDeaths
group by location
order by 2 desc
;

select location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject..CovidDeaths
order by 1,2
;

select location, MAX(cast(total_deaths as int)) as highestDeathCount
from PortfolioProject..CovidDeaths
where continent is not null
group by location
order by 2 desc
;

--6. Lets break things down by continent
select continent, MAX(cast(total_deaths as int)) as highestDeathCount
from PortfolioProject..CovidDeaths
where continent is not null
group by continent
order by 1
;

--7. Global numbers
select date, SUM(new_cases) as tot_new_cases, SUM(cast(new_deaths as int)) as tot_new_deaths, round(SUM(cast(new_deaths as int))/SUM(new_cases)*100,2) as deathPercent
from PortfolioProject..CovidDeaths
where continent is not null
group by date
order by 1
;

-- total for the whole world
select SUM(new_cases) as tot_new_cases, SUM(cast(new_deaths as int)) as tot_new_deaths, round(SUM(cast(new_deaths as int))/SUM(new_cases)*100,2) as deathPercent
from PortfolioProject..CovidDeaths
where continent is not null
;

--8. Joining
-- Looking at total vaccination vs total poulation eventually

-- with CTE
with cte (location, date , population, new_vaccinations, rolling_tot_vaccinations)
as
(
select d.location, d.date , d.population, v.new_vaccinations,
SUM(convert(int, v.new_vaccinations)) over (PARTITION BY d.location order by d.date) as rolling_tot_vaccinations
from PortfolioProject..CovidDeaths d
join PortfolioProject..CovidVaccinations v
on d.location = v.location 
and d.date = v.date
where d.continent is not null
)

select location ,population,
round(MAX(rolling_tot_vaccinations)/population*100,2) as tot_percent_vaccinated
from cte
group by location ,population
order by 1
;

--9. with Temp table
Drop table if exists #tt
CREATE TABLE #tt
(
location nvarchar(255), 
date datetime , 
population float, 
new_vaccinations int, 
rolling_tot_vaccinations int
);

Insert into #tt
select d.location, d.date , d.population, v.new_vaccinations,
SUM(convert(int, v.new_vaccinations)) over (PARTITION BY d.location order by d.date) as rolling_tot_vaccinations
from PortfolioProject..CovidDeaths d
join PortfolioProject..CovidVaccinations v
on d.location = v.location 
and d.date = v.date
where d.continent is not null
;

select location ,population,
round(MAX(rolling_tot_vaccinations)/population*100,2) as tot_percent_vaccinated
from #tt
group by location ,population
order by 1
;


-- 10. Create view to store data for later visualizations 
USE PortfolioProject;
GO 
Create View abc as
select d.location, d.date , d.population, v.new_vaccinations,
SUM(convert(int, v.new_vaccinations)) over (PARTITION BY d.location order by d.date) as rolling_tot_vaccinations
from PortfolioProject..CovidDeaths d
join PortfolioProject..CovidVaccinations v
on d.location = v.location 
and d.date = v.date
where d.continent is not null
;

select *
from PortfolioProject..abc
;