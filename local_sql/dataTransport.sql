DELIMITER //

-- 将appointmenttime中的离散日期进行合并并存储至appointmenttime_tmp临时表中
DROP PROCEDURE IF EXISTS `merge_discrete_app_date`//

CREATE PROCEDURE `merge_discrete_app_date`()
	BEGIN
		DECLARE no_more_record int DEFAULT 0;

		-- 游标映射字段
		DECLARE id_cur int;
		DECLARE appointmentid_cur int;
		DECLARE checkin_time_cur datetime;
		DECLARE checkout_time_cur datetime;
	
		-- 临时自增变量
		DECLARE id_group_first INT DEFAULT 0;
		DECLARE appointmentid_above INT DEFAULT 0;
		DECLARE checkout_time_above DATETIME DEFAULT '1970-01-01 00:00:00';
		
		-- appointmenttime_tmp 表使用
		DECLARE appointmentid_tmp INT;

		DECLARE count INT DEFAULT 0;

		-- 声明游标
		DECLARE cur CURSOR
		FOR
		SELECT a.id, a.appointmentid, FROM_UNIXTIME(a.checkintime, '%Y-%m-%d %T') as checkintime, FROM_UNIXTIME(a.checkouttime, '%Y-%m-%d %T') as checkouttime
		FROM appointmenttime a
		ORDER BY a.appointmentid ASC, a.checkintime ASC;

		-- 游标结尾标记
		DECLARE CONTINUE HANDLER FOR NOT FOUND SET no_more_record=1;
		OPEN cur;
		
		loop_label:WHILE no_more_record <> 1 DO
			FETCH cur into id_cur, appointmentid_cur, checkin_time_cur, checkout_time_cur;
				-- 退出循环条件
				IF no_more_record=1 THEN
					LEAVE loop_label;
				END IF;
				-- 信息插入之日表中
				SET count=count+1;

				IF appointmentid_above = appointmentid_cur THEN

					IF 1 = DATEDIFF(checkout_time_cur, checkout_time_above) THEN
						-- insert into yangmu_debug_log()checkout_time_cur, checkout_time_above, DATEDIFF(checkout_time_cur, checkout_time_above);
						-- 获取tmp临时表指定数据
						-- SELECT appointmentid INTO appointmentid_tmp FROM appointmenttime_tmp 
						-- WHERE id=id_group_first AND appointmentid=appointmentid_cur;

						SET checkout_time_above=checkout_time_cur;
						
					END IF;

					IF DATEDIFF(checkout_time_cur, checkout_time_above) > 1 THEN
						
						INSERT INTO appointmenttime_tmp(id, appointmentid, checkintime, checkouttime)
						VALUES (id_cur, appointmentid_cur, checkin_time_cur, checkout_time_cur);
						
						UPDATE appointmenttime_tmp SET checkouttime=checkout_time_above
						WHERE appointmentid=appointmentid_cur AND id=id_group_first;

						SET id_group_first=id_cur;
						SET checkout_time_above=checkout_time_cur;
						-- 这里appointmentid相同，因此不需要更新appointmentid_above

					END IF;

				END IF;

				IF appointmentid_above <> appointmentid_cur THEN
					-- 首次不能更新记录，因为tmp表中初始没有记录
					IF count>1 THEN
						-- 更新上一个appointmentid所对应的记录的其中的checkouttime字段为最后值
						UPDATE appointmenttime_tmp SET checkouttime=checkout_time_above
						WHERE id=id_group_first AND appointmentid=appointmentid_above;
					END IF;
					-- 将当前新的游标产生的记录插入到tmp表中，代表新的记录
					INSERT INTO appointmenttime_tmp(id, appointmentid, checkintime, checkouttime)
					VALUES(id_cur, appointmentid_cur, checkin_time_cur, checkout_time_cur);
					
					-- 更新临时变量为最新值
					SET appointmentid_above=appointmentid_cur;
					SET id_group_first=id_cur;
					SET checkout_time_above=checkout_time_cur;
				END IF;
				
			END WHILE;
		CLOSE cur;
	END //



-- 在appointmentlog表中追加相同appointmentid的记录
DROP PROCEDURE IF EXISTS `insert_into_appointmentlog` //

CREATE PROCEDURE `insert_into_appointmentlog`(IN old_appointment_id INT, IN new_appointment_id INT, IN log_id_in INT, OUT log_id_out INT)
BEGIN
	-- appointmentlog表游标结尾标记值
	DECLARE no_more_record_log INT DEFAULT 0;

	-- appointmentlog表游标映射字段
	DECLARE status_log_cur INT;
	DECLARE optype_log_cur INT;
	DECLARE modtime_log_cur INT;
	DECLARE comment_log_cur VARCHAR(512) charset 'utf8';

	DECLARE cur_log CURSOR FOR
	SELECT status, optype, modtime, comment
	FROM appointmentlog a
	WHERE a.appointmentid=old_appointment_id;
	
	DECLARE CONTINUE HANDLER FOR NOT FOUND
	SET no_more_record_log=1;
	
	OPEN cur_log;
	log_loop:WHILE no_more_record_log <> 1 DO

		FETCH cur_log INTO status_log_cur, optype_log_cur, modtime_log_cur, comment_log_cur;
		
		IF no_more_record_log=1 THEN
			LEAVE log_loop;
		END IF;

		-- select status_log_cur, optype, modtime, comment;

		INSERT INTO `appointmentlog`(id, appointmentid, status, optype, modtime, comment)
		VALUES(log_id_in, new_appointment_id, status_log_cur, optype_log_cur, modtime_log_cur, comment_log_cur);
		
		SET log_id_in=log_id_in+1;
	END WHILE;
	SET log_id_out=log_id_in;

	CLOSE cur_log;
END //



DROP PROCEDURE IF EXISTS `remove_hotelaptid_duplication` //

CREATE PROCEDURE `remove_hotelaptid_duplication`(OUT duplicated_aptid_apt_out INT, OUT duplicated_aptid_log_out INT)
BEGIN
	-- 游标结尾标记值
	DECLARE no_more_record INT DEFAULT 0;
		
	DECLARE appointmentid_above INT DEFAULT 0;
	
	-- 当appointmentid重复时将其插入hotel_apt_tmp与hotelappointmentlog_tmp表的末尾起始位置
	DECLARE duplicated_aptid_apt INT DEFAULT 10000;
	DECLARE duplicated_aptid_log INT DEFAULT 9000;

	-- hotel_apt_tmp游标映射字段
	DECLARE id_cur INT;
	DECLARE gmt_create_cur DATETIME;
	DECLARE gmt_modified_cur DATETIME;
	DECLARE apt_type_cur INT;
	DECLARE poi_id_cur INT;
	DECLARE room_type_cur VARCHAR(45) charset 'utf8';
	DECLARE room_count_cur INT;
	DECLARE checkin_time_cur DATETIME;
	DECLARE checkout_time_cur DATETIME;
	DECLARE order_type_cur INT;
	DECLARE order_id_cur VARCHAR(45) charset 'utf8';
	DECLARE order_source_cur VARCHAR(45) charset 'utf8';
	DECLARE coupon_ids_cur VARCHAR(512) charset 'utf8';
	DECLARE user_id_cur INT;
	DECLARE user_name_cur VARCHAR(45) charset 'utf8';
	DECLARE phone_cur VARCHAR(45) charset 'utf8';
	DECLARE comment_cur VARCHAR(1024) charset 'utf8';
	DECLARE status_cur INT;

	DECLARE out_tmp INT;

	-- hotel_apt_tmp游标
	DECLARE cur CURSOR FOR 
	SELECT a.id, FROM_UNIXTIME(a.addtime,'%Y-%m-%d %T') as gmt_create, FROM_UNIXTIME(a.addtime,'%Y-%m-%d %T') as gmt_modified, 0 as apt_type, 
		a.poiid as poi_id, a.type as room_type, a.quantity as room_count, b.checkintime as checkin_time, b.checkouttime as checkout_time,
		0 as order_type, a.orderid as order_id, a.dealid as order_source, NULL as coupon_ids, a.userid as user_id, a.username as user_name, 
		a.mobile as phone, a.comment as comment, a.status as status
	FROM hotelappointment a JOIN appointmenttime_tmp b
	ON a.id = b.appointmentid
	ORDER BY a.id asc;
	
	-- hotel_apt_tmp游标结束异常处理器
	DECLARE CONTINUE HANDLER FOR NOT FOUND 
	SET no_more_record=1;
	
	OPEN cur;

	loop_label:WHILE no_more_record <> 1 DO

			FETCH cur INTO id_cur, gmt_create_cur, gmt_modified_cur, apt_type_cur, poi_id_cur, room_type_cur, room_count_cur, checkin_time_cur, 
				checkout_time_cur, order_type_cur, order_id_cur, order_source_cur, coupon_ids_cur, user_id_cur, user_name_cur, phone_cur, comment_cur, 
				status_cur;

			IF no_more_record=1 THEN
				LEAVE loop_label;
			END IF;
		
			-- 出现重复appointmentid的情况，这时需要将这些重复appointmentid的记录插入到hotel_apt_tmp表的结尾, 起始id由程序指定
			IF id_cur=appointmentid_above THEN

				-- 处理hotel_apt_tmp表中自身的数据
				INSERT INTO `hotel_apt_tmp` 
				VALUES(duplicated_aptid_apt, gmt_create_cur, gmt_modified_cur, apt_type_cur, poi_id_cur, room_type_cur, room_count_cur,
						checkin_time_cur, checkout_time_cur, order_type_cur, order_id_cur, order_source_cur, coupon_ids_cur, user_id_cur, 
						user_name_cur, phone_cur, comment_cur, status_cur);

				-- 处理appointmentlog表中的数据
				CALL `insert_into_appointmentlog`(id_cur, duplicated_aptid_apt, duplicated_aptid_log, out_tmp);
				SET duplicated_aptid_log=out_tmp;

				SET duplicated_aptid_apt=duplicated_aptid_apt+1;

			-- 未出现重复appointmentid的情况
			ELSE
				-- 常规插入即可
				INSERT INTO `hotel_apt_tmp`
				VALUES(id_cur, gmt_create_cur, gmt_modified_cur, apt_type_cur, poi_id_cur, room_type_cur, room_count_cur,
						checkin_time_cur, checkout_time_cur, order_type_cur, order_id_cur, order_source_cur, coupon_ids_cur, 
						user_id_cur, user_name_cur, phone_cur, comment_cur, status_cur);
			END IF;

			-- 将appointmentid 重置为 刚访问过的id_cur值
			SET appointmentid_above=id_cur;

		END WHILE;
	CLOSE cur;
	
	-- 返回值
	SET duplicated_aptid_apt_out=duplicated_aptid_apt;
	SET duplicated_aptid_log_out=duplicated_aptid_log;
END //

CALL `merge_discrete_app_date`() //
CALL `remove_hotelaptid_duplication`(@apt_out, @log_out) //

SELECT @apt_out INTO OUTFILE '/tmp/apt_maxid.sql.dat' //
SELECT @log_out INTO OUTFILE '/tmp/log_maxid.sql.dat' //

DROP PROCEDURE IF EXISTS `merge_discrete_app_date` //
DROP PROCEDURE IF EXISTS `insert_into_appointmentlog` //
DROP PROCEDURE IF EXISTS `remove_hotelaptid_duplication` //

DELIMITER ;
