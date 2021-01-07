CREATE DATABASE  IF NOT EXISTS `sqlgraph` 
USE `sqlgraph`;


DROP TABLE IF EXISTS `employee`;
CREATE TABLE `employee` (
  `ID` int(11) NOT NULL,
  `Name` varchar(45) DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

LOCK TABLES `employee` WRITE;
INSERT INTO `employee` VALUES (1,'Luis B.'),(2,'Rimma N.'),(3,'Andrew L.'),(4,'New Person');
UNLOCK TABLES;

DROP TABLE IF EXISTS `employee_group`;
CREATE TABLE `employee_group` (
  `ID` int(11) NOT NULL,
  `EmployeeID` int(11) DEFAULT NULL,
  `GroupID` int(11) DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

LOCK TABLES `employee_group` WRITE;
INSERT INTO `employee_group` VALUES (1,1,1),(2,2,2),(3,3,1),(4,3,2),(5,1,3),(6,1,3),(7,1,3),(8,4,2),(9,4,3),(10,1,4),(11,2,4),(12,3,4),(13,4,4);
UNLOCK TABLES;


DROP TABLE IF EXISTS `employee_reportemployee`;
CREATE TABLE `employee_reportemployee` (
  `ID` int(11) NOT NULL,
  `EmployeeID` int(11) DEFAULT NULL,
  `ReportEmployeeID` int(11) DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

LOCK TABLES `employee_reportemployee` WRITE;
INSERT INTO `employee_reportemployee` VALUES (1,2,1),(2,2,3),(3,2,4);
UNLOCK TABLES;

DROP TABLE IF EXISTS `group`;
CREATE TABLE `group` (
  `ID` int(11) NOT NULL,
  `Name` varchar(45) DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

LOCK TABLES `group` WRITE;
INSERT INTO `group` VALUES (1,'Sales'),(2,'Engineering'),(3,'Azure'),(4,'Microsoft');
UNLOCK TABLES;

DROP TABLE IF EXISTS `groups`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `groups` (
  `ID` int(11) NOT NULL,
  `GroupID` int(11) DEFAULT NULL,
  `NestedGroupID` int(11) DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

LOCK TABLES `groups` WRITE;
INSERT INTO `groups` VALUES (1,1,3),(2,2,3),(3,3,4),(4,1,4),(5,2,4);