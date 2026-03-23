CREATE DATABASE IF NOT EXISTS mc_auto_starting_development;
CREATE DATABASE IF NOT EXISTS mc_auto_starting_test;
GRANT ALL PRIVILEGES ON mc_auto_starting_development.* TO 'app'@'%';
GRANT ALL PRIVILEGES ON mc_auto_starting_test.* TO 'app'@'%';
FLUSH PRIVILEGES;
