# SouthVale RP - QBCore Gang System

## Installation Guide

### Prerequisites
- QBCore Framework
- MySQL Database
- FiveM Server

### Step 1: Database Setup
Execute the following SQL commands in your database:

```sql
-- Create gangs table
CREATE TABLE IF NOT EXISTS `gangs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `gang` varchar(50) NOT NULL,
  `label` varchar(50) NOT NULL,
  `color` varchar(20) DEFAULT '#3498db',
  `points` int(11) DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `gang` (`gang`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Create gang ranks table
CREATE TABLE IF NOT EXISTS `gang_ranks` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `gang` varchar(50) NOT NULL,
  `grade` int(11) NOT NULL,
  `name` varchar(50) NOT NULL,
  `level` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `gang` (`gang`),
  CONSTRAINT `gang_ranks_ibfk_1` FOREIGN KEY (`gang`) REFERENCES `gangs` (`gang`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Create gang turfs table
CREATE TABLE IF NOT EXISTS `gang_turfs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `gang` varchar(50) NOT NULL,
  `location_x` float NOT NULL,
  `location_y` float NOT NULL,
  `location_z` float NOT NULL,
  `name` varchar(50) NOT NULL,
  `last_captured` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `gang` (`gang`),
  CONSTRAINT `gang_turfs_ibfk_1` FOREIGN KEY (`gang`) REFERENCES `gangs` (`gang`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### Step 2: Resource Installation

1. Download the resource and place it in your server's resources folder
2. Add `ensure sv-gangs` to your server.cfg file (adjust name if different)
3. Ensure it loads after qb-core

### Step 3: Configuration

Customize the `config.lua` file to fit your server's needs:

- Set proper admin permissions
- Adjust turf locations to match your map
- Configure keybinds and commands
- Set up default gang ranks and colors
- Enable or disable specific features

### Step 4: Initial Setup

After installation, use the `/gangadmin` command as an admin to:

1. Create initial gangs with custom names, colors, and ranks
2. Assign players to gangs through the admin panel

### Commands

- `/gangadmin` - Open the admin panel (admin only)
- `/gangpanel` - Open the gang management panel (gang leaders only)
- `/gangleaderboard` - View gang leaderboard (available to everyone)
- `/toggleganghud` - Toggle gang HUD display

### Keybinds (Default)

- `F6` - Open gang panel
- `F7` - Open gang leaderboard
- `F9` - Toggle gang HUD

### Features

- **Gang Management**
  - Create and manage gangs with custom names, colors and ranks
  - Control membership with promotion, demotion and removal capabilities
  - Invite new members to your gang

- **Territory Control**
  - Capture and control turf zones
  - Earn points for your gang by holding territories
  - Engage in turf wars with other gangs

- **Leaderboard System**
  - Track gang standings based on points and turf control
  - View which gangs are dominant on your server

- **Gang HUD**
  - Display gang affiliation and rank in the UI
  - Customize colors and appearance

### Support

For support or questions, contact the development team at SouthVale RP.