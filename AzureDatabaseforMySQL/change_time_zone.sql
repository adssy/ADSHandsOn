SELECT NOW();

SET SQL_SAFE_UPDATES=0;
CALL mysql.az_load_timezone();
SET SQL_SAFE_UPDATES=1;

SELECT NOW();

SELECT name 
FROM mysql.time_zone_name;

# Asia/Seoul