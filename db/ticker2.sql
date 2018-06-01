-- MySQL dump 10.13  Distrib 5.7.21, for Linux (x86_64)
--
-- Host: tickerdb    Database: currency
-- ------------------------------------------------------
-- Server version	5.7.19-log

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `ticker2`
--

DROP TABLE IF EXISTS `ticker2`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ticker2` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `ts` datetime NOT NULL,
  `exchange` varchar(64) NOT NULL,
  `base_currency` varchar(16) NOT NULL,
  `base_usd_rate` decimal(12,6) NOT NULL,
  `currency` varchar(16) NOT NULL,
  `status` varchar(16) DEFAULT NULL,
  `date` datetime NOT NULL,
  `date_minutes` bigint(20) unsigned NOT NULL,
  `highest_bid` double DEFAULT NULL,
  `lowest_ask` double DEFAULT NULL,
  `opening_price` double DEFAULT NULL,
  `closing_price` double DEFAULT NULL,
  `min_price` double DEFAULT NULL,
  `max_price` double DEFAULT NULL,
  `average_price` double DEFAULT NULL,
  `units_traded` double DEFAULT NULL,
  `volume_1day` double DEFAULT NULL,
  `volume_7day` double DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `exchange` (`exchange`,`currency`,`date`),
  KEY `date_minutes` (`date_minutes`,`exchange`,`currency`),
  KEY `exchange_2` (`exchange`,`currency`,`date_minutes`),
  KEY `ts` (`ts`,`exchange`),
  KEY `exchange_3` (`exchange`,`ts`)
) ENGINE=InnoDB AUTO_INCREMENT=50016991 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `exchange_currency_key`
--

DROP TABLE IF EXISTS `exchange_currency_key`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `exchange_currency_key` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `exchange` varchar(64) DEFAULT NULL,
  `currency_raw` varchar(50) DEFAULT NULL,
  `currency_in` varchar(16) DEFAULT NULL,
  `currency_out` varchar(16) DEFAULT NULL,
  `usd_coin` tinyint(1) DEFAULT '0',
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `exchange` (`exchange`,`currency_raw`,`currency_in`,`currency_out`),
  KEY `currency_clean` (`currency_in`,`currency_out`,`exchange`),
  KEY `currency_pair` (`currency_out`,`currency_in`,`exchange`),
  KEY `exchange_2` (`exchange`,`currency_raw`,`currency_out`)
) ENGINE=InnoDB AUTO_INCREMENT=2945 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `exchange_rates`
--

DROP TABLE IF EXISTS `exchange_rates`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `exchange_rates` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `source` varchar(255) DEFAULT NULL,
  `ts` datetime NOT NULL,
  `base` varchar(16) NOT NULL,
  `currency` varchar(16) NOT NULL,
  `date` datetime NOT NULL,
  `rate` double NOT NULL,
  PRIMARY KEY (`id`),
  KEY `base` (`base`,`currency`,`date`),
  KEY `base_2` (`base`,`currency`,`ts`)
) ENGINE=InnoDB AUTO_INCREMENT=23441 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2018-04-18 16:50:52
