CREATE USER 'mysql'@'localhost' IDENTIFIED BY 'mysql';
CREATE DATABASE caldav_unit_test CHARACTER SET = UTF8;
GRANT ALL ON caldav_unit_test.* TO 'mysql'@'localhost';
CREATE DATABASE defaultbackend CHARACTER SET = UTF8;
GRANT ALL ON defaultbackend.* TO 'mysql'@'localhost';
CREATE DATABASE ischedulebackend CHARACTER SET = UTF8;
GRANT ALL ON ischedulebackend.* TO 'mysql'@'localhost';
CREATE DATABASE caldav CHARACTER SET = UTF8;
GRANT ALL ON caldav.* TO 'mysql'@'localhost';
CREATE DATABASE ischedule CHARACTER SET = UTF8;
GRANT ALL ON ischedule.* TO 'mysql'@'localhost';