-- �������� ��������� ������� ��� ������� ����������� ���������� ����������
DROP TABLE IF EXISTS TEMP_PercantRollingPeopleVaccinated;
CREATE TABLE TEMP_PercantRollingPeopleVaccinated
(
continent NVARCHAR(255), 
location NVARCHAR(255),
date DATETIME,
population FLOAT,
new_vaccinations NUMERIC,
RollingPeopleVaccinated NUMERIC
);
INSERT INTO TEMP_PercantRollingPeopleVaccinated
SELECT 
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS REAL)) OVER(PARTITION BY dea.location ORDER BY dea.location ,dea.date) AS RollingPeopleVaccinated
FROM 
	dbo.CovidVaccinations vac
JOIN 
	dbo.CovidDeaths dea ON vac.location = dea.location
	AND vac.date = dea.date
WHERE 
	dea.continent IS NOT NULL 

SELECT 
	*,
	ROUND((RollingPeopleVaccinated / NULLIF(population,0)) * 100,2) AS PercantRollingPeopleVaccinated
FROM
	TEMP_PercantRollingPeopleVaccinated;

-- ����� ���������� ���������� � ���������� �� ����
SELECT 
	SUM(new_cases) AS total_new_cases,
	SUM(CAST(new_deaths AS INT)) AS total_new_deaths,
	SUM(CAST(new_deaths AS INT)) / SUM(new_cases) * 100 AS PercantageDeaths
FROM 
	dbo.CovidDeaths
WHERE 
	continent IS NOT NULL;


-- ������ ����� ������� � ���������� �� COVID-19 �� �����������
SELECT 
	continent,  -- �������� ����������
	date,       -- ���� ������ ������
	SUM(COALESCE(CAST(new_cases AS INT), 0)) AS total_new_cases,  -- ����� ���������� ����� �������, � ������� NULL �� 0
	SUM(COALESCE(CAST(new_deaths AS INT), 0)) AS total_new_deaths,  -- ����� ���������� ����� �������, � ������� NULL �� 0
	CASE 
		WHEN SUM(COALESCE(CAST(new_cases AS INT), 0)) = 0  -- ��������, ����� �������� ������� �� ����
		THEN 0  -- ���� ����� ���������� ����� ������� ����� 0, ������� 0
		ELSE ROUND(SUM(COALESCE(CAST(new_deaths AS REAL), 0)) / SUM(COALESCE(CAST(new_cases AS REAL), 0)) * 100, 2)  -- ���������� �������� �������, ���������� �� 2 ������
	END AS PercantageDeaths
FROM 
	dbo.CovidDeaths  -- ������� � ������� � ���������� �� COVID
WHERE 
	continent IS NOT NULL  -- ���������� �����, ��� ��������� �� ������
GROUP BY 
	continent,  -- ����������� �� ����������
	date        -- ����������� �� ����
ORDER BY
	continent;  -- ���������� �� ����������

--�������� ���������� � ����� ������� ����������� ��������� ���������� ���������
SELECT 
	continent, 
	MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM
	dbo.CovidDeaths
WHERE
	continent IS NOT NULL
GROUP BY 
	continent
ORDER BY
	TotalDeathCount DESC;

-- � ����� ������� ���� ����� ������� ���������� �����
 /*���������������� ������ � ����� ������� ����������� � �������,����� ������ ���������� ������ �����
					�� ��������� � �� ���������� � ���� �������� COVID-19.*/

SELECT 
    location,
    MAX(CAST(total_deaths AS INT)) AS HighestDeaths,  
    MAX(COALESCE(CAST(total_deaths AS FLOAT), 0) / NULLIF(COALESCE(CAST(population AS BIGINT), 0), 0) * 100) AS DeathPercentage 
FROM 
    dbo.CovidDeaths
WHERE 
	continent IS NOT NULL
GROUP BY 
    location
ORDER BY
    HighestDeaths DESC;  


-- ������ ��� ����������� ����� � ����� ������� ������� �������� COVID-19 
SELECT 
    location,                             -- �������� ������
    population,                           -- ����� ���������� ��������� ������
    MAX(total_cases) AS MaxTotalInfected,  -- ������������ ���������� ������� �������� COVID-19 � ������
    (MAX(total_cases) / NULLIF(population, 0)) * 100 AS PercentPopulationInfected  -- ������� ���������, ��������������� COVID-19
FROM 
    dbo.CovidDeaths
WHERE 
    continent IS NOT NULL
GROUP BY 
    location,
    population
ORDER BY
    PercentPopulationInfected DESC;  -- ���������� �� �������� �������������� ��������� � ������� ��������

-- ���������� ����� ���������� ������� ��������� COVID-19 � ��������� � ������������ ���������
SELECT 
	location,
	date,
	total_cases,
	population,
	(total_cases/population) * 100 AS PopulationPercantage -- ������� ��������� ���������� COVID-19
FROM 
	dbo.CovidDeaths
WHERE 
	LOWER(location) LIKE 'kazakh%'
ORDER BY
	1,2;

-- ������ ��������� ���������� �������� ���������� �� COVID-19 �� ���������������, ������������ � "Kazakh", � ��������� ������ �� ������� � ����.
-- ��� ����������, ��� ����������� ���������� ������ ��� ��������� COVID-19 � ����� ������ �������� ������.
SELECT 
	location, 
	date, 
	total_cases, 
	total_deaths,
	(total_deaths/total_cases) * 100 AS DeathPercantage -- ������� ������
FROM 
	dbo.CovidDeaths
WHERE 
	LOWER(location) LIKE 'kazakh%'
ORDER BY
	1,2;

--������ ������������� ���������� �� COVID-19 �� �������������� � �������� ���������������
WITH rolling_percentage (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated) AS (
    SELECT
        dea.continent,  -- �������� ����������
        dea.location,   -- �������������� (������ ��� ������)
        dea.date,       -- ���� ������ ������
        dea.population, -- ��������� ������ ��� �������
        vac.new_vaccinations,  -- ����� ���������� �� ����
        SUM(CONVERT(REAL, vac.new_vaccinations)) OVER(
            PARTITION BY dea.location 
            ORDER BY dea.location, dea.date
        ) AS RollingPeopleVaccinated  -- ������������� ����� ��������������� ����� �� ����
    FROM 
        dbo.CovidVaccinations vac  -- ������� � ������� � ����������
    JOIN 
        dbo.CovidDeaths dea ON vac.location = dea.location
        AND vac.date = dea.date  -- ���������� �� �������������� � ����
    WHERE 
        dea.continent IS NOT NULL  -- ���������� �����, ��� ��������� �� ������
) -- ��������� CTE rolling_percentage

SELECT 
    continent,
    location,
    date,
    population,
    new_vaccinations,
    RollingPeopleVaccinated,
    ROUND((RollingPeopleVaccinated / population) * 100, 2) AS PercantRollingPeopleVaccinated  -- ������� ��������������� �� ������ ���������
FROM 
    rolling_percentage  -- ������������� CTE ��� ���������� ������������� ������
ORDER BY 
    2, 3;  -- ���������� �� �������������� � ����

-- ������ ����������� ����� ������� ���������� � �����������
WITH RollVac AS (
    SELECT 
        vac.location,
        DATEPART(YEAR, vac.date) AS Year,
        DATENAME(MONTH, vac.date) AS Month,         -- �������� ������
        DATEPART(DAY, vac.date) AS Day,             -- ���� ������ (�����)
        DATENAME(WEEKDAY, vac.date) AS WeekdayName, -- �������� ��� ������
        dea.population,
        dea.new_deaths,
        vac.new_vaccinations,
        -- ������������ ���������� ��������������� � �������������� ������� �������
        SUM(CAST(vac.new_vaccinations AS INT)) OVER(PARTITION BY vac.location ORDER BY vac.date) AS RollingVaccinations
    FROM
        [dbo].[CovidVaccinations] vac
    JOIN 
        [dbo].[CovidDeaths] dea ON vac.location = dea.location AND vac.date = dea.date AND dea.continent = vac.continent
    WHERE 
       dea.population > 1000000  AND vac.continent IS NOT NULL
) -- ��������� CTE RollVac

SELECT
    location,
    Year,
    Month,
    Day,
    WeekdayName,
    population,
    new_deaths,
    new_vaccinations,
    RollingVaccinations,
    -- ������� ���������������� ���������
    ROUND((RollingVaccinations / CAST(population AS DECIMAL(15,2))) * 100, 2) AS VaccinatedPercent,
    -- ������� ���������� �� ������� �������
    ROUND((CAST(new_deaths AS DECIMAL(15,2)) / CAST(population AS DECIMAL(15,2))) * 1000000, 2) AS DeathRatePerMillion
FROM 
    RollVac
ORDER BY
    location,
    Year,
    Month,
    Day;


-- �������� ���������� � ���������� �� �����������

-- ���������� ��������� ������� ��� ������� ���������� �� ������� � �����������
WITH MonthlyDeaths AS (
    SELECT 
        continent,  -- ��������� ���������
        DATETRUNC(MONTH, date) AS MonthDeaths,  -- �������� ���� �� ������� ����� ������
        SUM(CAST(new_deaths AS INT)) AS total_deaths  -- ��������� ����� ������ ������� �� �����
    FROM 
        dbo.CovidDeaths
    WHERE 
        continent IS NOT NULL  -- ��������� ������ ��� �������� ����������
    GROUP BY 
        continent,  -- ���������� �� ����������
        DATETRUNC(MONTH, date)  -- � �� ������
),

-- ���������� ��������� ������� ��� ������� ���������� �� ������� � �����������
MonthlyVaccinations AS (
    SELECT 
        continent,  -- ��������� ���������
        DATETRUNC(MONTH, date) AS MonthlyVaccinations,  -- �������� ���� �� ������� ����� ������
        SUM(CAST(new_vaccinations AS INT)) AS total_vaccinations  -- ��������� ����� ������ ���������� �� �����
    FROM 
        dbo.CovidVaccinations
    WHERE 
        continent IS NOT NULL  -- ��������� ������ ��� �������� ����������
    GROUP BY 
        continent,  -- ���������� �� ����������
        DATETRUNC(MONTH, date)  -- � �� ������
) -- ��������� CTE MonthlyVaccinations

-- �������� ������, ������������ ������ � ���������� � ����������
SELECT 
    md.continent,  -- �������� ���������
    COALESCE(md.MonthDeaths, mv.MonthlyVaccinations) AS MonthDeaths,  -- ����� ����������, ���� ����, ����� ����� ����������
    COALESCE(md.total_deaths, 0) AS total_deaths,  -- ����� ���������� �������; ���� ��� ������, ������������� 0
    COALESCE(mv.MonthlyVaccinations, md.MonthDeaths) AS MonthlyVaccinations,  -- ����� ����������, ���� ����, ����� ����� ����������
    COALESCE(mv.total_vaccinations, 0) AS total_vaccinations  -- ����� ���������� ����������; ���� ��� ������, ������������� 0
FROM 
    MonthlyDeaths md  -- ���������� ��������� ������� � ������� � ����������
FULL OUTER JOIN 
    MonthlyVaccinations mv ON md.continent = mv.continent AND md.MonthDeaths = mv.MonthlyVaccinations  -- ���������� ������ �� ����������� � �������

-- ��������� ����� � ����������/���������� ��������� ����������

WITH VaccinationSpeed AS (
    SELECT
        vac.location,  -- �������, ��� ���������� ����������
        vac.date,      -- ���� ����������
        vac.new_vaccinations,  -- ����� ���������� �� ����
        dea.new_deaths, -- ����� ������ �� ����
        dea.population,  -- ����� ����������� ���������
        -- ���������� ���������� ���������� ��� ���������� �������
        LAG(CAST(vac.total_vaccinations AS INT)) OVER (PARTITION BY vac.location ORDER BY vac.date) AS prev_total_vaccinations,
        -- ������� � ����������� �� ���� (�������� ����������)
        CAST(vac.total_vaccinations AS INT) - 
        LAG(CAST(vac.total_vaccinations AS INT)) OVER (PARTITION BY vac.location ORDER BY vac.date) AS daily_vaccination_speed
    FROM 
        dbo.CovidVaccinations vac  -- ������� ����������
    JOIN 
        dbo.CovidDeaths dea ON vac.location = dea.location AND vac.date = dea.date  -- ���������� � �������� ������� �� ���� � �������
    WHERE 
        vac.continent IS NOT NULL AND dea.population > 1000000  -- ���������� �� ���������� � ����������� ���������
),
RankedVaccinationSpeed AS (
    SELECT
        location,
        date,
        daily_vaccination_speed,  -- �������� ���������� �� ����
        new_deaths,               -- ����� ������
        population,               -- ����������� ���������
        -- ������� ���������� �� ������� �������
        ROUND((CAST(new_deaths AS DECIMAL(15, 2)) / population) * 1000000, 2) AS death_rate_per_million,
        -- ��������� ����� �� �������� ���������� ��� ������ ������ (� ������� ��������)
        ROW_NUMBER() OVER (PARTITION BY location ORDER BY daily_vaccination_speed DESC) AS rank_high_speed,
        -- ��������� ����� �� �������� ���������� ��� ������ ������ (� ������� �����������)
        ROW_NUMBER() OVER (PARTITION BY location ORDER BY daily_vaccination_speed ASC) AS rank_low_speed
    FROM
        VaccinationSpeed  -- ������������� CTE ��� ��������� ������ � ����������
    WHERE 
        daily_vaccination_speed IS NOT NULL  -- ���������� ����� � NULL ����������
) -- ��������� CTE RankedVaccinationSpeed

-- ����� ����� � ����� ������� � ����� ������ ��������� ����������
SELECT 
    location,
    date,
    daily_vaccination_speed,  -- �������� ����������
    death_rate_per_million,   -- ������� ���������� �� ������� �������
    -- �����������, �������� �� �������� ���������� ������� ��� ������
    CASE 
        WHEN rank_high_speed = 1 THEN 'Highly'  -- ���� ����� ������� ��������
        ELSE 'Slowly'                           -- �����, ������ ��������
    END AS Highly_Slowly
FROM 
    RankedVaccinationSpeed  -- ������������� CTE ��� ������ ������
WHERE 
    rank_high_speed = 1 OR rank_low_speed = 1  -- ����� ������ ����� ������� � ����� ������ ��������� ����������
ORDER BY 
    location, daily_vaccination_speed DESC;  -- ���������� �� ������� � �������� ����������

-- ����������� ����������� ����� �� ����������
-- CTE (Common Table Expression) ��� ����������� ������ � ����������� � ����������
WITH DeathsAndVaccinations AS (   
    SELECT 
        vac.location,  -- ������� (������ ��� ������)
        vac.date,      -- ���� ������
        vac.new_vaccinations,  -- ����� ���������� � ������ ����
        dea.new_deaths,        -- ����� ������ ������ � ������ ����
        -- ������ ���������� ����� ����� ������� � ������ ������� � ����
        SUM(CAST(dea.new_deaths AS INT)) OVER(PARTITION BY vac.location ORDER BY vac.date) AS RollingDeaths,
        -- ������ ���������� ����� ����� ���������� � ������ ������� � ����
        SUM(CAST(vac.new_vaccinations AS INT)) OVER(PARTITION BY vac.location ORDER BY vac.date) AS RollingVaccinations,
        -- ������ �������� �������� ����� ������� � ������ ������� � ����
        AVG(CAST(dea.new_deaths AS INT)) OVER(PARTITION BY vac.location ORDER BY vac.date) AS AvgDeaths,
        -- ��������� ���������� ����� ������� �� ���������� ���� � ������ �������
        LAG(CAST(dea.new_deaths AS INT)) OVER(PARTITION BY vac.location ORDER BY vac.date) AS PrevDeaths
    FROM
        dbo.CovidVaccinations vac  -- ������� � ������� � �����������
    JOIN 
        dbo.CovidDeaths dea ON vac.location = dea.location AND vac.date = dea.date  -- ����������� �� ������� � ����
    WHERE
        vac.continent IS NOT NULL  -- ���������� �� ������������ �����������
),

-- CTE ��� ������� ����������� ����� �� ����������
CriticalDeathsPoints AS (
    SELECT
        location,
        date,
        new_vaccinations,
        new_deaths,
        RollingDeaths,
        RollingVaccinations,
        AvgDeaths,
        PrevDeaths,
        -- ����������� ����������� ����� �� ��������� �� ��������� ���������� ����
        CASE	
            WHEN RollingDeaths > PrevDeaths * 1.5 THEN 'Critical Point'  -- ���� ����� ������ ��������� 150% �� ����������
            ELSE 'Normal'  -- � ��������� ������ - ���������� ���������
        END AS DeathTrend
    FROM 
        DeathsAndVaccinations  -- ���������� ���������� �� ����������� CTE
)  -- ��������� CTE CriticalDeathsPoints

-- �������� ������ ��� ���������� � ���������� ������
SELECT 
    *
FROM 
    CriticalDeathsPoints  -- ���������� ���� �������� �� ������� ����������� �����
ORDER BY 
    DeathTrend ASC;  -- ���������� �� ���� ��������� ���������� (����������� ����� ��� ���������� ���������)