-- At some point, I may need to keep track on > 1 dasher.  If this happens
-- I need to add a field to the table
-- 	dasher_id integer NOT NULL
--	FOREIGN KEY (dasher_id) REFERENCES dashers (dasher_id)
--		ON DELETE CASCADE
-- and update the index
--	CREATE UNIQUE INDEX idx_dashes on dashes (dasher_id, time_start)
CREATE TABLE dashes (
	dash_id integer NOT NULL,
	time_start text NOT NULL,
	time_end text NOT NULL,
	miles_start NULL,
	miles_end NULL,
	deliveries integer NULL,
	hours real NULL,
	delivery_pay real NULL,
	boost_pay real NULL,
	tip_amount real NULL,
	deductions real NULL,
	extras real NULL,
	total_pay real NULL,
	PRIMARY KEY(dash_id ASC)
);

CREATE UNIQUE INDEX idx_dashes_time_start ON dashes (time_start);
