2022–2023: Exploratory Data Analysis (Part 2)

In [Part 1](https://github.com/Ezinnem/sql-layoffs-data-cleaning), I cleaned and standardized the raw tech layoffs dataset: removing duplicates, fixing null values, standardizing date formats, and staging it for analysis. With a clean table sitting in `layoffs_staging2`, it was time to actually dig in and ask the dataset some questions.

This post walks through that exploratory phase using SQL, and what the numbers revealed about one of the most turbulent stretches in recent tech history.

## Starting broad

Before slicing the data any particular way, I wanted the shape of it first.

```sql
SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_staging2;
```

The largest single layoff event in the dataset was [X employees], and at the extreme end, some companies laid off 100% of their staff, meaning they shut down entirely.

```sql
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY total_laid_off DESC;
```

[X] companies fall into that category, and the ones with the highest headcount losses were [list a few standout names].

## Which companies cut the deepest

```sql
SELECT company, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;
```

[Company X] led the dataset with [X] total layoffs, followed by [Company Y] and [Company Z]. Ranking by company alone is useful, but it flattens time, so I broke it down by year next.

## Industries and countries hit hardest

```sql
SELECT industry, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC;
```

[Industry X] absorbed the largest share of layoffs, which [makes sense/is surprising] given [your interpretation].

```sql
SELECT country, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;
```

Geographically, [Country X] was hit hardest, accounting for [X%] of total layoffs in the dataset.

## The timeline: when it actually happened

```sql
SELECT YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY 1 DESC;
```

Layoffs [increased/spiked/declined] from [year] to [year], with [year] standing out as the worst.

To see the trend more precisely, I broke it down by month and built a rolling total using a window function:

```sql
WITH Rolling_Total AS (
    SELECT SUBSTRING(`date`, 1, 7) AS `Month`, SUM(total_laid_off) AS total_off
    FROM layoffs_staging2
    WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
    GROUP BY `Month`
    ORDER BY 1 ASC
)
SELECT `Month`, total_off, SUM(total_off) OVER (ORDER BY `Month`) AS rolling_total
FROM Rolling_Total;
```

This rolling sum makes the cumulative scale of the crisis visible in a way a single month's number never could: by [end month/year], the running total had climbed past [X] layoffs industry-wide.

## Ranking the worst years, company by company

The last question I wanted to answer: which companies dominated the layoff headlines in any given year, not just overall?

```sql
WITH Company_Year (company, years, total_laid_off) AS (
    SELECT company, YEAR(`date`), SUM(total_laid_off)
    FROM layoffs_staging2
    GROUP BY company, YEAR(`date`)
),
Company_Year_Rank AS (
    SELECT *, DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS Ranking
    FROM Company_Year
    WHERE years IS NOT NULL
)
SELECT *
FROM Company_Year_Rank
WHERE Ranking <= 5;
```

Using `DENSE_RANK()` partitioned by year let me pull the top 5 companies for each year side by side. In [year], the top spot went to [Company X], while by [year], the picture had shifted to [Company Y] and [Company Z].

## What this taught me

Beyond the specific numbers, this project was a good exercise in a core analytical skill: moving from a single flat aggregate (SUM, MAX) toward layered, comparative questions using CTEs and window functions. The rolling total and the per-year ranking were the two queries that took the analysis from "here are some numbers" to "here's a story."

Next step: visualizing this in [Tableau/Power BI/Python] to make the trend and ranking findings easier to communicate to a non-technical audience. That'll be Part 3.
