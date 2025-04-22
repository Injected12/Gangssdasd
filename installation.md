# SouthVale RP Gang System - Installation Guide

This comprehensive guide will walk you through the installation and setup process for the SouthVale RP Gang System for QBCore.

## Requirements

- QBCore Framework
- oxmysql

## Step 1: Resource Installation

1. Download the resource files
2. Place the folder in your server's resources directory
3. Ensure the folder is named `sv-gangs` (or update references if you choose a different name)

## Step 2: Database Setup

The script will automatically create the necessary database tables when the resource starts for the first time. However, you can manually create them if needed:

```sql
CREATE TABLE IF NOT EXISTS `gangs` (
    `gang` VARCHAR(50) NOT NULL,
    `label` VARCHAR(50) NOT NULL,
    `color` VARCHAR(10) NOT NULL DEFAULT '#3498db',
    `points` INT NOT NULL DEFAULT 0,
    PRIMARY KEY (`gang`)
);

CREATE TABLE IF NOT EXISTS `gang_turfs` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `gang` VARCHAR(50) NOT NULL,
    `location_x` FLOAT NOT NULL,
    `location_y` FLOAT NOT NULL,
    `location_z` FLOAT NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `last_captured` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    FOREIGN KEY (`gang`) REFERENCES `gangs`(`gang`)
    ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS `gang_ranks` (
    `gang` VARCHAR(50) NOT NULL,
    `grade` INT NOT NULL,
    `name` VARCHAR(50) NOT NULL,
    `level` INT NOT NULL,
    PRIMARY KEY (`gang`, `grade`),
    FOREIGN KEY (`gang`) REFERENCES `gangs`(`gang`)
    ON DELETE CASCADE ON UPDATE CASCADE
);
