DELIMITER //
DROP PROCEDURE IF EXISTS `export_sql_data` //
CREATE PROCEDURE `export_sql_data`()
BEGIN
    DECLARE date_format VARCHAR(20) DEFAULT '%Y-%m-%d %T';
    -- roomstatus -> hotel_apt_room_status [export data]
    SELECT id as id, FROM_UNIXTIME(addtime, date_format) as gmt_create, FROM_UNIXTIME(addtime, date_format) as gmt_modified, poiid as poi_id, 0 as source_type, dealid as source_id, type as room_type, status as status, freenum as free_count, FROM_UNIXTIME(begintime, date_format) as start, FROM_UNIXTIME(endtime, date_format)
    FROM roomstatus INTO OUTFILE "/tmp/room_status.sql.dat";

    -- appointmentsetting -> hotel_apt_biz_settings
    SELECT id as id, FROM_UNIXTIME(addtime, date_format) as gmt_create, FROM_UNIXTIME(modtime, date_format) as gmt_modified, poiid as poi_id, attrid as attr_id, attrvalue as attr_value, status as status
    FROM appointmentsetting INTO OUTFILE "/tmp/biz_settings.sql.dat";
	
	-- appointmentlog -> hotel_apt_logs
	SELECT id as id, FROM_UNIXTIME(modtime, date_format) as gmt_create, FROM_UNIXTIME(modtime, date_format) as gmt_modified, appointmentid as apt_id, status as status, optype as op_type, comment as comment 
	FROM appointmentlog INTO outfile "/tmp/apt_log.sql.dat";

	-- hotel_apt_tmp -> hotel_apt
	SELECT * 
	FROM hotel_apt_tmp INTO OUTFILE "/tmp/apt.sql.dat";
END //

call `export_sql_data`() //

DROP PROCEDURE IF EXISTS `export_sql_data` //

DELIMITER ;
