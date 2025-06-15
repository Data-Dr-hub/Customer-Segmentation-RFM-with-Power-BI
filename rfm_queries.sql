WITH 
dated_dataset AS(
    SELECT *,
    CAST('2011-12-01' AS DATE) AS reference_date
    FROM `tc-da-1.turing_data_analytics.rfm` 
    WHERE (DATE(InvoiceDate) BETWEEN '2010-12-01' AND '2011-12-01') AND Quantity >= 0 AND UnitPrice >= 0 AND CustomerID IS NOT NULL
),
rfm_values AS(
    SELECT  
        CustomerID,
        MAX(InvoiceDate) AS last_purchase_date,
        COUNT(DISTINCT InvoiceNo) AS frequency,
        SUM(UnitPrice * Quantity) AS monetary,
        DATE_DIFF(MAX(reference_date), DATE(MAX(InvoiceDate)), DAY) AS recency
    FROM dated_dataset
    GROUP BY CustomerID ORDER BY recency
),
rfm_scores AS (
    SELECT 
        CustomerID, recency, frequency, monetary,
        -- Recency quartiles (lower recency = better, so reverse the NTILE order)
        NTILE(4) OVER (ORDER BY recency DESC) AS r_score,
        -- Frequency quartiles (higher frequency = better)
        NTILE(4) OVER (ORDER BY frequency) AS f_score,
        -- Monetary quartiles (higher monetary value = better)
        NTILE(4) OVER (ORDER BY monetary) AS m_score,
    FROM rfm_values
    order by CustomerID
),   
fm_Average AS (
    SELECT 
        *, 
        CAST(ROUND((f_score + m_score) / 2, 0) AS INT64) AS fm_score --average f and m-scores
    FROM rfm_scores
)

SELECT 
    *,
    CASE 
        -- Best Customers: Most recent purchases with a high FM score
        WHEN r_score >= 3 AND fm_score >= 3 THEN 'Best Customers'         
        -- Loyal Customers: Recent to moderately recent purchases with moderate to high FM score
        WHEN r_score >= 2 AND fm_score >= 2 THEN 'Loyal Customers'        
        -- Big Spenders: High FM score, regardless of recency
        WHEN fm_score = 4 THEN 'Big Spenders'                            
        -- At Risk: Low R score (not recent) and low to moderate FM score
        WHEN r_score <= 2 AND fm_score <= 2 THEN 'At Risk' 
        -- Lost Customers: Lowest R score, indicating they haven't purchased recently
        WHEN r_score = 1 THEN 'Lost Customers'                           
        -- Default category for any uncategorized customers
        ELSE 'Other Categories'                                                   
    END AS customer_segment
FROM fm_Average    






