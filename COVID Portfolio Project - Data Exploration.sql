-- Просмотреть все данные о смертях
Select *
From dbo.CovidDeaths
Where continent is not null 
order by 3,4;

SELECT 
	*,
	ROUND((RollingPeopleVaccinated / NULLIF(population,0)) * 100,2) AS PercantRollingPeopleVaccinated
FROM
	TEMP_PercantRollingPeopleVaccinated;

-- Общее количество зараженных и смертности по миру
SELECT 
	SUM(new_cases) AS total_new_cases,
	SUM(CAST(new_deaths AS INT)) AS total_new_deaths,
	SUM(CAST(new_deaths AS INT)) / SUM(new_cases) * 100 AS PercantageDeaths
FROM 
	dbo.CovidDeaths
WHERE 
	continent IS NOT NULL;


-- Анализ новых случаев и смертности от COVID-19 по континентам
SELECT 
	continent,  -- Название континента
	date,       -- Дата записи данных
	SUM(COALESCE(CAST(new_cases AS INT), 0)) AS total_new_cases,  -- Общее количество новых случаев, с заменой NULL на 0
	SUM(COALESCE(CAST(new_deaths AS INT), 0)) AS total_new_deaths,  -- Общее количество новых смертей, с заменой NULL на 0
	CASE 
		WHEN SUM(COALESCE(CAST(new_cases AS INT), 0)) = 0  -- Проверка, чтобы избежать деления на ноль
		THEN 0  -- Если общее количество новых случаев равно 0, вернуть 0
		ELSE ROUND(SUM(COALESCE(CAST(new_deaths AS REAL), 0)) / SUM(COALESCE(CAST(new_cases AS REAL), 0)) * 100, 2)  -- Вычисление процента смертей, округление до 2 знаков
	END AS PercantageDeaths
FROM 
	dbo.CovidDeaths  -- Таблица с данными о смертности от COVID
WHERE 
	continent IS NOT NULL  -- Исключение строк, где континент не указан
GROUP BY 
	continent,  -- Группировка по континенту
	date        -- Группировка по дате
ORDER BY
	continent;  -- Сортировка по континенту

--Показаны континенты с самым высоким показателем процентно смертности населения
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

-- В каких странах была самая высокая смертность людей
 /*Проанализировать страны с самой высокой смертностью и оценить,какие страны пострадали больше всего
					по сравнению с их населением в ходе пандемии COVID-19.*/

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


-- Запрос для определения стран с самым высоким уровнем инфекций COVID-19 
SELECT 
    location,                             -- Название страны
    population,                           -- Общее количество населения страны
    MAX(total_cases) AS MaxTotalInfected,  -- Максимальное количество случаев инфекции COVID-19 в стране
    (MAX(total_cases) / NULLIF(population, 0)) * 100 AS PercentPopulationInfected  -- Процент населения, инфицированного COVID-19
FROM 
    dbo.CovidDeaths
WHERE 
    continent IS NOT NULL
GROUP BY 
    location,
    population
ORDER BY
    PercentPopulationInfected DESC;  -- Сортировка по проценту инфицированных населения в порядке убывания

-- Отобразить общее количество случаев заражений COVID-19 в сравнении с численностью населения
SELECT 
	location,
	date,
	total_cases,
	population,
	(total_cases/population) * 100 AS PopulationPercantage -- Процент населения зараженные COVID-19
FROM 
	dbo.CovidDeaths
WHERE 
	LOWER(location) LIKE 'kazakh%'
ORDER BY
	1,2;

-- Запрос выполняет вычисление процента смертности от COVID-19 по местоположениям, начинающимся с "Kazakh", и сортирует данные по локации и дате.
-- Это показывает, что вероятность летального исхода при заражении COVID-19 в нашей стране остается низкой.
SELECT 
	location, 
	date, 
	total_cases, 
	total_deaths,
	(total_deaths/total_cases) * 100 AS DeathPercantage -- Процент смерти
FROM 
	dbo.CovidDeaths
WHERE 
	LOWER(location) LIKE 'kazakh%'
ORDER BY
	1,2;

--Анализ накопительной вакцинации от COVID-19 по местоположению и проценту вакцинированных
WITH rolling_percentage (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated) AS (
    SELECT
        dea.continent,  -- Название континента
        dea.location,   -- Местоположение (страна или регион)
        dea.date,       -- Дата записи данных
        dea.population, -- Население страны или региона
        vac.new_vaccinations,  -- Новые вакцинации за день
        SUM(CONVERT(REAL, vac.new_vaccinations)) OVER(
            PARTITION BY dea.location 
            ORDER BY dea.location, dea.date
        ) AS RollingPeopleVaccinated  -- Накопительное число вакцинированных людей по дате
    FROM 
        dbo.CovidVaccinations vac  -- Таблица с данными о вакцинации
    JOIN 
        dbo.CovidDeaths dea ON vac.location = dea.location
        AND vac.date = dea.date  -- Соединение по местоположению и дате
    WHERE 
        dea.continent IS NOT NULL  -- Исключение строк, где континент не указан
) -- Закрываем CTE rolling_percentage

SELECT 
    continent,
    location,
    date,
    population,
    new_vaccinations,
    RollingPeopleVaccinated,
    ROUND((RollingPeopleVaccinated / population) * 100, 2) AS PercantRollingPeopleVaccinated  -- Процент вакцинированных от общего населения
FROM 
    rolling_percentage  -- Использование CTE для извлечения накопительных данных
ORDER BY 
    2, 3;  -- Сортировка по местоположению и дате

-- Анализ зависимости между уровнем вакцинации и смертностью
WITH RollVac AS (
    SELECT 
        vac.location,
        DATEPART(YEAR, vac.date) AS Year,
        DATENAME(MONTH, vac.date) AS Month,         -- Название месяца
        DATEPART(DAY, vac.date) AS Day,             -- День месяца (число)
        DATENAME(WEEKDAY, vac.date) AS WeekdayName, -- Название дня недели
        dea.population,
        dea.new_deaths,
        vac.new_vaccinations,
        -- Кумулятивное количество вакцинированных с использованием оконной функции
        SUM(CAST(vac.new_vaccinations AS INT)) OVER(PARTITION BY vac.location ORDER BY vac.date) AS RollingVaccinations
    FROM
        [dbo].[CovidVaccinations] vac
    JOIN 
        [dbo].[CovidDeaths] dea ON vac.location = dea.location AND vac.date = dea.date AND dea.continent = vac.continent
    WHERE 
       dea.population > 1000000  AND vac.continent IS NOT NULL
) -- Закрываем CTE RollVac

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
    -- Процент вакцинированного населения
    ROUND((RollingVaccinations / CAST(population AS DECIMAL(15,2))) * 100, 2) AS VaccinatedPercent,
    -- Уровень смертности на миллион человек
    ROUND((CAST(new_deaths AS DECIMAL(15,2)) / CAST(population AS DECIMAL(15,2))) * 1000000, 2) AS DeathRatePerMillion
FROM 
    RollVac
ORDER BY
    location,
    Year,
    Month,
    Day;


-- Динамика смертности и вакцинации по континентам

-- Определяем временную таблицу для расчета смертности по месяцам и континентам
WITH MonthlyDeaths AS (
    SELECT 
        continent,  -- Указываем континент
        DATETRUNC(MONTH, date) AS MonthDeaths,  -- Обрезаем дату до первого числа месяца
        SUM(CAST(new_deaths AS INT)) AS total_deaths  -- Суммируем новые случаи смертей за месяц
    FROM 
        dbo.CovidDeaths
    WHERE 
        continent IS NOT NULL  -- Исключаем записи без указания континента
    GROUP BY 
        continent,  -- Группируем по континенту
        DATETRUNC(MONTH, date)  -- И по месяцу
),

-- Определяем временную таблицу для расчета вакцинаций по месяцам и континентам
MonthlyVaccinations AS (
    SELECT 
        continent,  -- Указываем континент
        DATETRUNC(MONTH, date) AS MonthlyVaccinations,  -- Обрезаем дату до первого числа месяца
        SUM(CAST(new_vaccinations AS INT)) AS total_vaccinations  -- Суммируем новые случаи вакцинации за месяц
    FROM 
        dbo.CovidVaccinations
    WHERE 
        continent IS NOT NULL  -- Исключаем записи без указания континента
    GROUP BY 
        continent,  -- Группируем по континенту
        DATETRUNC(MONTH, date)  -- И по месяцу
) -- Закрываем CTE MonthlyVaccinations

-- Основной запрос, объединяющий данные о смертности и вакцинации
SELECT 
    md.continent,  -- Выбираем континент
    COALESCE(md.MonthDeaths, mv.MonthlyVaccinations) AS MonthDeaths,  -- Месяц смертности, если есть, иначе месяц вакцинации
    COALESCE(md.total_deaths, 0) AS total_deaths,  -- Общее количество смертей; если нет данных, устанавливаем 0
    COALESCE(mv.MonthlyVaccinations, md.MonthDeaths) AS MonthlyVaccinations,  -- Месяц вакцинации, если есть, иначе месяц смертности
    COALESCE(mv.total_vaccinations, 0) AS total_vaccinations  -- Общее количество вакцинаций; если нет данных, устанавливаем 0
FROM 
    MonthlyDeaths md  -- Используем временную таблицу с данными о смертности
FULL OUTER JOIN 
    MonthlyVaccinations mv ON md.continent = mv.continent AND md.MonthDeaths = mv.MonthlyVaccinations  -- Объединяем данные по континентам и месяцам

-- Выявление стран с наибольшей/наименьшей скоростью вакцинации

WITH VaccinationSpeed AS (
    SELECT
        vac.location,  -- Локация, где проводятся вакцинации
        vac.date,      -- Дата вакцинации
        vac.new_vaccinations,  -- Новые вакцинации за день
        dea.new_deaths, -- Новые смерти за день
        dea.population,  -- Общая численность населения
        -- Предыдущее количество вакцинаций для вычисления разницы
        LAG(CAST(vac.total_vaccinations AS INT)) OVER (PARTITION BY vac.location ORDER BY vac.date) AS prev_total_vaccinations,
        -- Разница в вакцинациях за день (скорость вакцинации)
        CAST(vac.total_vaccinations AS INT) - 
        LAG(CAST(vac.total_vaccinations AS INT)) OVER (PARTITION BY vac.location ORDER BY vac.date) AS daily_vaccination_speed
    FROM 
        dbo.CovidVaccinations vac  -- Таблица вакцинаций
    JOIN 
        dbo.CovidDeaths dea ON vac.location = dea.location AND vac.date = dea.date  -- Соединение с таблицей смертей по дате и локации
    WHERE 
        vac.continent IS NOT NULL AND dea.population > 1000000  -- Фильтрация по континенту и численности населения
),
RankedVaccinationSpeed AS (
    SELECT
        location,
        date,
        daily_vaccination_speed,  -- Скорость вакцинации за день
        new_deaths,               -- Новые смерти
        population,               -- Численность населения
        -- Уровень смертности на миллион человек
        ROUND((CAST(new_deaths AS DECIMAL(15, 2)) / population) * 1000000, 2) AS death_rate_per_million,
        -- Нумерация строк по скорости вакцинации для каждой страны (в порядке убывания)
        ROW_NUMBER() OVER (PARTITION BY location ORDER BY daily_vaccination_speed DESC) AS rank_high_speed,
        -- Нумерация строк по скорости вакцинации для каждой страны (в порядке возрастания)
        ROW_NUMBER() OVER (PARTITION BY location ORDER BY daily_vaccination_speed ASC) AS rank_low_speed
    FROM
        VaccinationSpeed  -- Использование CTE для получения данных о вакцинации
    WHERE 
        daily_vaccination_speed IS NOT NULL  -- Исключение строк с NULL значениями
) -- Закрываем CTE RankedVaccinationSpeed

-- Выбор стран с самой высокой и самой низкой скоростью вакцинации
SELECT 
    location,
    date,
    daily_vaccination_speed,  -- Скорость вакцинации
    death_rate_per_million,   -- Уровень смертности на миллион человек
    -- Определение, является ли скорость вакцинации высокой или низкой
    CASE 
        WHEN rank_high_speed = 1 THEN 'Highly'  -- Если самая высокая скорость
        ELSE 'Slowly'                           -- Иначе, низкая скорость
    END AS Highly_Slowly
FROM 
    RankedVaccinationSpeed  -- Использование CTE для выбора данных
WHERE 
    rank_high_speed = 1 OR rank_low_speed = 1  -- Выбор только самых высоких и самых низких скоростей вакцинации
ORDER BY 
    location, daily_vaccination_speed DESC;  -- Сортировка по локации и скорости вакцинации

-- Определение критических точек по смертности
-- CTE (Common Table Expression) для объединения данных о вакцинациях и смертности
WITH DeathsAndVaccinations AS (   
    SELECT 
        vac.location,  -- Локация (страна или регион)
        vac.date,      -- Дата записи
        vac.new_vaccinations,  -- Новые вакцинации в данной дате
        dea.new_deaths,        -- Новые случаи смерти в данной дате
        -- Расчёт скользящей суммы новых смертей с учётом локации и даты
        SUM(CAST(dea.new_deaths AS INT)) OVER(PARTITION BY vac.location ORDER BY vac.date) AS RollingDeaths,
        -- Расчёт скользящей суммы новых вакцинаций с учётом локации и даты
        SUM(CAST(vac.new_vaccinations AS INT)) OVER(PARTITION BY vac.location ORDER BY vac.date) AS RollingVaccinations,
        -- Расчёт среднего значения новых смертей с учётом локации и даты
        AVG(CAST(dea.new_deaths AS INT)) OVER(PARTITION BY vac.location ORDER BY vac.date) AS AvgDeaths,
        -- Получение количества новых смертей за предыдущую дату с учётом локации
        LAG(CAST(dea.new_deaths AS INT)) OVER(PARTITION BY vac.location ORDER BY vac.date) AS PrevDeaths
    FROM
        dbo.CovidVaccinations vac  -- Таблица с данными о вакцинациях
    JOIN 
        dbo.CovidDeaths dea ON vac.location = dea.location AND vac.date = dea.date  -- Объединение по локации и дате
    WHERE
        vac.continent IS NOT NULL  -- Фильтрация по существующим континентам
),

-- CTE для анализа критических точек по смертности
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
        -- Определение критической точки по сравнению со значением предыдущей даты
        CASE	
            WHEN RollingDeaths > PrevDeaths * 1.5 THEN 'Critical Point'  -- Если новые смерти превышают 150% от предыдущих
            ELSE 'Normal'  -- В противном случае - нормальное состояние
        END AS DeathTrend
    FROM 
        DeathsAndVaccinations  -- Используем результаты из предыдущего CTE
)  -- Закрываем CTE CriticalDeathsPoints

-- Основной запрос для извлечения и сортировки данных
SELECT 
    *
FROM 
    CriticalDeathsPoints  -- Извлечение всех столбцов из анализа критических точек
ORDER BY 
    DeathTrend ASC;  -- Сортировка по типу тенденции смертности (критическая точка или нормальное состояние)

-- Создание временной таблицы для анализа процентного увеличения вакцинации
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

-- Создание представления для хранения данных для последующей визуализации
CREATE VIEW PercantageDeathsCont AS
SELECT 
	continent,  -- Название континента
	date,       -- Дата записи данных
	SUM(COALESCE(CAST(new_cases AS INT), 0)) AS total_new_cases,  -- Общее количество новых случаев, с заменой NULL на 0
	SUM(COALESCE(CAST(new_deaths AS INT), 0)) AS total_new_deaths,  -- Общее количество новых смертей, с заменой NULL на 0
	CASE 
		WHEN SUM(COALESCE(CAST(new_cases AS INT), 0)) = 0  -- Проверка, чтобы избежать деления на ноль
		THEN 0  -- Если общее количество новых случаев равно 0, вернуть 0
		ELSE ROUND(SUM(COALESCE(CAST(new_deaths AS REAL), 0)) / SUM(COALESCE(CAST(new_cases AS REAL), 0)) * 100, 2)  -- Вычисление процента смертей, округление до 2 знаков
	END AS PercantageDeaths
FROM 
	dbo.CovidDeaths  -- Таблица с данными о смертности от COVID
WHERE 
	continent IS NOT NULL  -- Исключение строк, где континент не указан
GROUP BY 
	continent,  -- Группировка по континенту
	date        -- Группировка по дате
--ORDER BY
--	continent;  -- Сортировка по континенту 
