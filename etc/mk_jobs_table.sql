-- At some point, I may need to keep track of > 1 dasher.  If this happens
-- I need to add a field to the table
--	dasher_id integer NOT NULL
--	FOREIGN KEY (dasher_id) REFERENCES dashers (dasher_id)
--		ON DELETE CASCADE
-- and update the index
--	CREATE UNIQUE INDEX idx_jobs ON jobs (dasher_id, time_start, src_addr_id, dst_addr_id)
CREATE TABLE jobs (
	job_id integer NOT NULL,
	dash_id integer NOT NULL,
	time_start text NOT NULL,
	time_end text NOT NULL,
	src_addr_id integer NOT NULL,
	dst_addr_id integer NOT NULL,
	amount real NOT NULL,
	payment text NOT NULL,
	notes text,
	PRIMARY KEY (job_id ASC),
	FOREIGN KEY (dash_id) REFERENCES dashes (dash_id)
		ON DELETE CASCADE,
	FOREIGN KEY (src_addr_id) REFERENCES addresses (address_id)
		ON DELETE CASCADE,
	FOREIGN KEY (dst_addr_id) REFERENCES addresses (address_id)
		ON DELETE CASCADE
);

CREATE INDEX idx_src_addr_id ON jobs (src_addr_id);
CREATE INDEX idx_dst_addr_id ON jobs (dst_addr_id);
CREATE INDEX idx_dash_id ON jobs (dash_id);
CREATE UNIQUE INDEX idx_jobs ON jobs (time_start, src_addr_id, dst_addr_id);
