CREATE TABLE `drug_creator` (
  `id` int(11) NOT NULL,
  `name` varchar(50) NOT NULL,
  `coords` text NOT NULL,
  `amount` int(11) NOT NULL,
  `health` int(11) DEFAULT 25,
  `armor` int(11) DEFAULT 25,
  `speed` float DEFAULT 1.1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

ALTER TABLE `drug_creator`
  ADD PRIMARY KEY (`id`);

ALTER TABLE `drug_creator`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
COMMIT;

ALTER TABLE drug_items MODIFY COLUMN speed FLOAT DEFAULT 1.0;
