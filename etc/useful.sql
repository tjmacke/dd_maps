-- ${X} is a parameter

-- INSERT stmts
-- add a new address
INSERT INTO addresses (a_stat, as_reason, address, a_type, qry_address, date_first_use, date_last_use)
	VALUES (V, ..., V) ;

-- add a new dash
INSERT INTO dashes (time_start, time_end, deliveries, hours, delivery_pay, boost_pay, tip_amount, deductions, extra, total_pay)
	VALUES (V, ..., V) ;

-- add a new job.  Job table references both the dashes and addresses tables
PRAGMA foreign_keys = ON ;
INSERT INTO jobs (dash_id, time_start, time_end, src_addr_id, dst_addr_id, amount, payment, notes)
	VALUES (V, ..., V) ; 

-- SELECT stmts
-- select addresses w/geo to test that fwd canonicalization (qry_address) = bck canonicaliztion (rply_address)
PRAGMA foreign_keys = ON ;
SELECT as_reason, address, a_type, qry_address, rply_address
	FROM addresses
	WHERE as_reason LIKE 'geo.ok.%' ;

-- find geo aliases: addresses w/different names, qualifiers, etc but w/same (lng, lat)
PRAGMA foreign_keys = ON ;
SELECT address, lng, lat
	FROM addresses
	WHERE a_stat = 'G' AND as_reason LIKE 'geo.ok.%'
	ORDER BY lng, lat ;

-- find query aliases: address w/different address but the same qry_address
PRAGMA foreign_keys = ON ;
SELECT qry_address, address
	FROM addresses
	WHERE qry_address != ''
	ORDER BY qry_address, address ;

-- get new properly formed addresses w/o geo
PRAGMA foreign_keys = ON ;
SELECT *
	FROM addresses
	WHERE a_stat = 'G' AND as_reason = 'new' ;

-- get all addresses w/first & last used dates
PRAGMA foreign_keys = ON ;
SELECT address, date_first_use, date_last_use
	FROM addresses ;

-- get the time_start for all dashes
PRAGMA foreign_keys = ON ;
SELECT time_start
	FROM dashes ;

-- get all jobs as time_start, src, dst, where src, dst are addresses entered in the src, dst fields of runs files
PRAGMA foreign_keys = ON ;
SELECT time_start, src.address, dst.address
	FROM jobs
	INNER JOIN addresses src ON src.address_id = jobs.src_addr_id
	INNER JOIN addresses dst ON dst.address-id = jobs.dst_addr_id ;

-- get the address_id for address ${A}
PRAGMA foreign_keys = ON ;
SELECT  address_id
	FROM addresses
	WHERE address = ${A} ;

-- get the dash_id's for this a date (D = Y:M:D); use script to select right one based on time_start, time_end
PRAGMA foreign_keys = ON ;
SELECT dash_id, time_start, time_end
	FROM dashes
	WHERE date(time_start) = ${D} ;

-- get distinct source addresses
PRAGMA foreign_keys = ON ;
SELECT src.address
	FROM jobs
	INNER JOIN addresses src ON src.address_id = jobs.src_addr_id ;

-- get distinct destination addresses
PRAGMA foreign_keys = ON ;
SELECT dst.address
	FROM jobs
	INNER JOIN addresses dst ON dst.address_id = jobs.dst_addr_id ;

-- Get the count and most recent use date of a job address (A = src, dst). For destination addr gs/src/dst/g
-- use strftime('%Y-%m-%d', MAX(time_start)) to limit datetime precision to the date:w
PRAGMA foreign_keys = ON ;
SELECT COUNT(${A}.address), MAX(time_start), ${A}.address
	FROM jobs 
	INNER JOIN addresses ${A} ON src.address_id = ${A}_addr_id
	GROUP BY address 
	ORDER BY count(${A}.address) DESC ;

-- get the total pay for an app for a year (Y = Y:M:D) and app (A)
PRAGMA foreign_keys = ON ;
SELECT SUM(total_pay)
FROM dashes
WHERE dash_id IN (
	SELECT DISTINCT dash_id
	FROM jobs
	WHERE DATE(time_start) = ${Y} AND payment = ${A}
} ;

-- Used this to check that bug fix for job in dash work
SELECT DATE(j.time_start) j_date, j.dash_id, j.payment
FROM jobs j
WHERE j_date IN (
	SELECT d_date
	FROM (
		SELECT COUNT(*) AS count, DATE(time_start) AS d_date, dash_id
		FROM dashes
		GROUP BY d_date
		HAVING count > 1
	)
)
ORDER BY j_date ;

-- UPDATE stmts
-- Add geo to a known address
PRAGMA foreign_keys = ON ;
UPDATE addresses
	SET a_stat = V, as_reason = V, lng = V, lat = V, rply_address = V, date_geo_checked = V
	WHERE address = A ;

-- Add geo error info to a known address
PRAGMA foreign_keys = ON ;
UPDATE addresses
	SET a_stat = V, as_reason = V, date_geo_checked = V
	WHERE address = A ;

-- update the date of last use of an address
UPDATE addresses
	SET date_liast_use = D
	WHERE address = A ;

-- update the date of first use.  I added date_first_use, date_last_use after I started the table,
-- so this was needed; shouldn't ever be used again
UPDATE addresses
	SET date_first_use = D
	WHERE address = A ;

-- DELETE stmts
-- Delete unused addresses ; done after addresses are corrected
PRAGMA foreign_keys = ON ;
DELETE FROM addresses
	WHERE address = A ;

-- Used this to remove jobs that had bee incorrectly assigned to dashes
-- This happened when we did two shifts in the same day, the count > 1
DELETE FROM jobs
WHERE DATE(time_start) IN (
	SELECT date
	FROM (
		SELECT COUNT(*) AS count, DATE(time_start) as date
		FROM dashes
		GROUP BY date
		HAVING count > 1
		ORDER BY date
	)
) ;

-- Used this (a cte no less!) to find days when the number of deliveries in
-- shift.data does not agree with the number of jobs in fp.*.log

.headers on
.mode tabs
WITH dd(d_id, d_date, d_count) AS (
	SELECT dash_id, DATE(time_start) AS d_date, SUM(deliveries) AS d_count
	FROM dashes
	GROUP BY d_date
),
	jd(j_date, j_count) AS (
	SELECT DATE(time_start) AS j_date, COUNT(DATE(time_start)) AS j_count
	FROM jobs
	GROUP BY j_date
)
SELECT dd.d_id, dd.d_date, dd.d_count, jd.j_count
FROM dd 
INNER JOIN jd ON jd.j_date = dd.d_date AND jd.j_count != dd.d_count ;
