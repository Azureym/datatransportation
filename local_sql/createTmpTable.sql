-- 创建导出临时表脚本

-- 合并相同appointmentid所对应的离散时间区段临时存储表
DROP TABLE IF EXISTS `appointmenttime_tmp`;
CREATE TABLE `appointmenttime_tmp` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `appointmentid` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '预约记录id, 与hotelappoiment的id字段关联',
  `checkintime` datetime NOT NULL,
  `checkouttime` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


-- 经过处理后的hotel_apt的临时表
DROP TABLE IF EXISTS `hotel_apt_tmp`;
CREATE TABLE `hotel_apt_tmp` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `gmt_create` datetime NOT NULL,
  `gmt_modified` datetime NOT NULL,
  `apt_type` int(11) DEFAULT NULL COMMENT '预约类型：0 普通预约，1 担保预约',
  `poi_id` int(11)  DEFAULT NULL COMMENT '分店id',
  `room_type` varchar(45)  DEFAULT NULL COMMENT '房间类型, 跟编辑系统保持一直: OP=单人床 MPO=大床房 MPT=双床房 OTH=其他类型...',
  `room_count` int(11) DEFAULT NULL COMMENT '房间数',
  `checkin_time` datetime DEFAULT NULL COMMENT '入住时间',
  `checkout_time` datetime DEFAULT NULL COMMENT 'checkout时间',
  `order_type` int(11)  DEFAULT NULL COMMENT '订单类型，0团购订单',
  `order_id` varchar(45) DEFAULT NULL COMMENT '订单id',
  `order_source` varchar(45) DEFAULT NULL COMMENT '订单来源，如团购的dealid',
  `coupon_ids` varchar(512) DEFAULT NULL COMMENT '券ids',
  `user_id` int(11) DEFAULT NULL COMMENT '用户id',
  `user_name` varchar(45) DEFAULT NULL COMMENT '用户姓名',
  `phone` varchar(45) DEFAULT NULL COMMENT '电话',
  `comment` varchar(1024) DEFAULT NULL COMMENT '备注',
  `status` int(11) DEFAULT NULL COMMENT '预约状态:0=预约中 1=预约成功 2=预约失败 3=商家/客服取消预约 4=用户已退款',
  PRIMARY KEY(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- 删除之前插入遗留的记录
 DELETE FROM `appointmentlog` WHERE id >= 15000;

/*
-- 预约日志临时表，该表将多个appointmentid所对应的记录经过赋值之后插入表的末尾
DROP TABLE IF EXISTS `appointmentlog_tmp`;
CREATE TABLE `appointmentlog_tmp` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `gmt_create` datetime NOT NULL,
  `gmt_modified` datetime NOT NULL,
  `apt_id` int(11) NOT NULL COMMENT '预约id',
  `status` int(11) NOT NULL COMMENT '操作后状态：0=预约中 1=预约成功 2=预约失败 3=商家/客服取消预约 4=用户已退款 99=添加备注',
  `op_type` int(11) NOT NULL COMMENT '操作类型：0=用户修改 1=商家修改 2=客服修改',
  `comment` varchar(512) DEFAULT NULL COMMENT '备注',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
*/
