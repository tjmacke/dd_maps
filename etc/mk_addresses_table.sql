CREATE TABLE addresses (
	address_id integer NOT NULL,
	a_stat text NOT NULL,
	as_reason text NOT NULL,
	address text NOT NULL,
	a_type text NULL,
	qry_address text NULL,
	rply_address text NULL,
	lat double NULL,
	lng double NULL,
-- Deal with address management
--	date_first_use text NULL,	-- If this DB is recreated, then this field should NOT NULL
--	date_geo_set text NULL,
--	date_geo_checked text NULL,
	PRIMARY KEY (address_id ASC)
);

CREATE UNIQUE INDEX idx_addresses_address ON addresses (address);
