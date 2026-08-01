-- ============================================
-- EXPLORATORY DATA ANALYSIS
-- Tech Layoffs 2022-2023 Dataset
-- Part 2: EDA (follows Part 1: Data Cleaning)
-- ============================================

SELECT *
FROM layoffs_staging2;

-- To see the maximum total laid off and max percentage laid off in the data
SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_staging2;

-- To see the layoffs that affected 100% of the company (i.e. company shut down)
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY total_laid_off DESC;

-- To see the sum of total laid off, by company
SELECT company, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;

-- To see the date range covered by the dataset
SELECT MIN(`date`), MAX(`date`)
FROM layoffs_staging2;

-- To see the industry that was hit the most during the layoffs
SELECT industry, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC;

-- To see the country that was hit the most
SELECT country, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;

-- To see the year that the layoffs affected the most
SELECT YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY 1 DESC;

-- To find the sum of layoffs based on the month
SELECT SUBSTRING(`date`, 1, 7) AS `Month`, SUM(total_laid_off)
FROM layoffs_staging2
WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
GROUP BY `Month`
ORDER BY 1 ASC;

-- To find the rolling (cumulative) total of layoffs based on the month
WITH Rolling_Total AS
(
    SELECT SUBSTRING(`date`, 1, 7) AS `Month`, SUM(total_laid_off) AS total_off
    FROM layoffs_staging2
    WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
    GROUP BY `Month`
    ORDER BY 1 ASC
)
SELECT `Month`, total_off, SUM(total_off) OVER (ORDER BY `Month`) AS rolling_total
FROM Rolling_Total;

-- To see each company's total laid off, broken down by year
SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
ORDER BY 3 DESC;

-- To rank the top 5 companies by total laid off, for each year
WITH Company_Year (company, years, total_laid_off) AS
(
    SELECT company, YEAR(`date`), SUM(total_laid_off)
    FROM layoffs_staging2
    GROUP BY company, YEAR(`date`)
),
Company_Year_Rank AS
(
    SELECT *, DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS Ranking
    FROM Company_Year
    WHERE years IS NOT NULL
)
SELECT *
FROM Company_Year_Rank
WHERE Ranking <= 5;
