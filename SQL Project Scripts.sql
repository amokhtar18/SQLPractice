--Q1? MediaType year Over Year Growth in sales-----
SELECT *
	, vw.sales_current_Year / sales_previous_Year - 1 "Change%"
FROM (
	SELECT mt.Name MediaType
		, sum(CASE WHEN strftime('%Y', i.InvoiceDate) = (
						SELECT max(strftime('%Y', DATE (
										i2.InvoiceDate
										, '-1 Year'
										)))
						FROM Invoice i2
						) THEN il.UnitPrice * il.Quantity ELSE 0 END) sales_previous_Year
		, sum(CASE WHEN strftime('%Y', i.InvoiceDate) = (
						SELECT max(strftime('%Y', i2.InvoiceDate))
						FROM Invoice i2
						) THEN il.UnitPrice * il.Quantity ELSE 0 END) sales_current_Year
	FROM InvoiceLine il
	JOIN Invoice i ON il.InvoiceId = i.InvoiceId
	JOIN Track t ON il.TrackId = t.TrackId
	JOIN MediaType mt ON t.MediaTypeId = mt.MediaTypeId
	GROUP BY 1
	) vw
ORDER BY 3 DESC;

---- Q2  Correlating Song Length by sales frequency    ---------
SELECT CASE WHEN (t.Milliseconds / 1000 / 60) <= 5 THEN "A-Less Than 5" WHEN (t.Milliseconds / 1000 / 60) <= 15 THEN "B-Between 5 - 15" WHEN (t.Milliseconds / 1000 / 60) <= 30 THEN "C-Between 15 - 30" ELSE "D- Greater Than 30" END SongDurationIntervals
	, count(i.InvoiceId) NumberOfInvoices
FROM InvoiceLine il
JOIN Invoice i ON il.InvoiceId = i.InvoiceId
JOIN Track t ON il.TrackId = t.TrackId
GROUP BY 1;

---- Q3 Most prefered Artists (Tracks in multiple playlists) -- 
SELECT a2.Name Artist
	, count(DISTINCT pt.PlaylistId) no_of_playlists
FROM Track t
LEFT JOIN PlaylistTrack pt ON t.TrackId = pt.TrackId
JOIN Playlist p ON pt.PlaylistId = p.PlaylistId
JOIN Album a ON t.AlbumId = a.AlbumId
JOIN Artist a2 ON a.ArtistId = a2.ArtistId
GROUP BY 1
HAVING count(DISTINCT pt.PlaylistId) >= 6
ORDER BY 2 DESC

------ Q4 Top spending customer by the top 5 countries ----
SELECT 
	 vw2.Country
	, vw2.TotalSpent
FROM (
	SELECT *
		, rank() OVER (
			PARTITION BY vw.Country ORDER BY vw.TotalSpent DESC
			) CustomerRank
		, avg(vw.TotalSpent) OVER (PARTITION BY vw.Country) AvgSpending
	FROM (
		SELECT c.FirstName || ' ' || c.LastName CustomerFullName
			, i.BillingCountry Country
			, sum(Quantity * UnitPrice) TotalSpent
		FROM InvoiceLine il
		JOIN Invoice i ON il.InvoiceId = i.InvoiceId
		JOIN Customer c ON i.CustomerId = c.CustomerId
		GROUP BY 1
			, 2
		ORDER BY 2
			, 3 DESC
		) vw
	) vw2
WHERE vw2.CustomerRank = 1 AND vw2.Country IN (
		SELECT vw3.Country
		FROM (
			SELECT i.BillingCountry Country
				, sum(il.Quantity * il.UnitPrice) Amount
			FROM InvoiceLine il
			JOIN Invoice i ON il.InvoiceId = i.InvoiceId
			GROUP BY 1
			ORDER BY 2 DESC limit 5
			) vw3
		)