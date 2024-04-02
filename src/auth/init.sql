CREATE OR REPLACE USER 'auth_user'@'localhost' IDENTIFIED BY 'Auth123';

CREATE OR REPLACE DATABASE auth;

GRANT ALL PRIVILEGES ON auth.* TO 'auth_user'@'localhost';

USE auth;

CREATE OR REPLACE TABLE user (
  id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(255) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL
);

INSERT INTO user (email, password) VALUES ('farjadi_amin@yahoo.com', 'Admin123');
