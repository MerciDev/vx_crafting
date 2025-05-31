CREATE TABLE IF NOT EXISTS `player_crafting_recipes` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(50) NOT NULL,
    `recipe_id` VARCHAR(100) NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_player_recipe` (`citizenid`, `recipe_id`),
    CONSTRAINT `fk_player_citizenid` FOREIGN KEY (`citizenid`) REFERENCES `players` (`citizenid`) ON DELETE CASCADE ON UPDATE CASCADE
);
