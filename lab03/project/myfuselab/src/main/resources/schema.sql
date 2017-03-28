CREATE TABLE customerdemo (
	customerID varchar(10) NOT NULL,
	vipStatus varchar(10) NOT NULL ,  
	balance integer NOT NULL
);

INSERT INTO customerdemo (customerID,vipStatus,balance) VALUES ('A01','Diamond',1000);
INSERT INTO customerdemo (customerID,vipStatus,balance) VALUES ('A02','Gold',500);