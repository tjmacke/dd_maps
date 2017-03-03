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
	PRIMARY KEY (address_id ASC)
);

CREATE UNIQUE INDEX idx_addresses_address ON addresses (address);
