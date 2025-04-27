-- Crear la base de datos:
CREATE DATABASE reseñas_vinos;
USE reseñas_vinos;

-- Carga de datos desde JupyterLab utilizando PyMySQL

-- Verificar carga de datos
SELECT COUNT(*) FROM tabla_reseñas_vinos;

-- Eliminar la columna 'Unnamed: 0' de 'tabla_reseñas_vinos'
ALTER TABLE tabla_reseñas_vinos
DROP COLUMN `Unnamed: 0`; -- Se debe encerrar en comillas invertidas para no tener errores

-- Verificar
DESCRIBE tabla_reseñas_vinos;
SELECT * FROM tabla_reseñas_vinos;


/*Las siguientes consultas crean las tablas para el modelo relacional, con sus respectivas claves primarias, 
claves foráneas y restricciones (constraints): 
*/

-- Crear tabla 'País'
CREATE TABLE IF NOT EXISTS `Country` (
  `idCountry` INT AUTO_INCREMENT PRIMARY KEY, -- Clave primaria autoincremental
  `country` TINYTEXT NULL
  );

 -- Crear tabla 'Provincia'
 CREATE TABLE IF NOT EXISTS `Province` (
  `idProvince` INT AUTO_INCREMENT PRIMARY KEY,
  `province` TINYTEXT NULL,
  `idCountry_FK` INT NOT NULL, -- Todas las columnas terminadas en _FK serán declaradas como claves foráneas
  CONSTRAINT fk_country FOREIGN KEY (`idCountry_FK`) REFERENCES `Country`(`idCountry`)
  ON DELETE CASCADE -- Elimina las filas en la tabla hija cuando se elimina una fila en la tabla padre.
  ON UPDATE CASCADE -- Actualiza las claves foráneas en la tabla hija cuando se actualiza la clave primaria en la tabla padre.
  );
  
  -- Crear tabla 'Región'
  CREATE TABLE IF NOT EXISTS `Region` (
  `idRegion` INT AUTO_INCREMENT PRIMARY KEY,
  `region_1` TINYTEXT NULL,
  `region_2` TINYTEXT NULL,
  `idProvince_FK` INT NOT NULL,
  CONSTRAINT fk_province FOREIGN KEY (`idProvince_FK`) REFERENCES `Province` (`idProvince`) 
  ON DELETE CASCADE
  ON UPDATE CASCADE
  );
  
-- Crear tabla 'Ubicación' 
  CREATE TABLE IF NOT EXISTS `Location` (
  `idLocation` INT AUTO_INCREMENT PRIMARY KEY,
  `idCountry_FK` INT NOT NULL,
  `idProvince_FK` INT NOT NULL,
  `idRegion_FK` INT NOT NULL,
  CONSTRAINT fk_country_loc FOREIGN KEY (`idCountry_FK`) REFERENCES `Country` (`idCountry`)
  ON DELETE CASCADE
  ON UPDATE CASCADE,
  CONSTRAINT fk_province_loc FOREIGN KEY (`idProvince_FK`) REFERENCES `Province` (`idProvince`)
  ON DELETE CASCADE
  ON UPDATE CASCADE,
  CONSTRAINT fk_region_loc FOREIGN KEY (`idRegion_FK`) REFERENCES `Region` (`idRegion`)
  ON DELETE CASCADE
  ON UPDATE CASCADE
  );

-- Crear tabla 'Bodega'
CREATE TABLE IF NOT EXISTS `Winery` (
  `idWinery` INT AUTO_INCREMENT PRIMARY KEY,
  `winery` TINYTEXT NULL
  );

-- Crear tabla 'Viñedo'
CREATE TABLE IF NOT EXISTS `Designation` (
  `idDesignation` INT AUTO_INCREMENT PRIMARY KEY,
  `designation` TINYTEXT NULL,
  `idWinery_FK` INT NOT NULL,
  CONSTRAINT fk_winery_dsg FOREIGN KEY (`idWinery_FK`) REFERENCES `Winery` (`idWinery`)
  ON DELETE CASCADE
  ON UPDATE CASCADE
);

-- Crear tabla 'Variedad'
CREATE TABLE IF NOT EXISTS `Variety`  (
`idVariety` INT AUTO_INCREMENT PRIMARY KEY,
`variety` TINYTEXT NULL
);

-- Crear tabla 'Vino'
CREATE TABLE IF NOT EXISTS `Wine` (
  `idWine` INT AUTO_INCREMENT PRIMARY KEY,
  `title` MEDIUMTEXT NULL,
  `idWinery_FK` INT NULL,
  `idVariety_FK` INT NULL,
  `idDesignation_FK` INT NULL,
  `price` FLOAT NULL,
  `points` INT NULL,
  `description` LONGTEXT NULL
);

-- Crear tabla 'Catador'
CREATE TABLE IF NOT EXISTS `Taster` (
  `idTaster` INT AUTO_INCREMENT PRIMARY KEY,
  `taster_name` TINYTEXT NULL,
  `taster_twitter_handle` TINYTEXT NULL
  );


-- Las siguientes transacciones imputan las tablas creadas anteriormente con los datos de 'tabla_reseñas_vinos':

-- Imputar tabla 'País'
INSERT INTO country (country)
SELECT distinct country FROM tabla_reseñas_vinos; -- Se utiliza 'distinct' para tener datos únicos
-- Verificar
SELECT * FROM country;

-- Imputar tabla 'Provincia'
INSERT INTO province (province, idCountry_FK) 
SELECT distinct tabla_reseñas_vinos.province, country.idCountry
FROM tabla_reseñas_vinos
JOIN country ON tabla_reseñas_vinos.country = country.country;
-- Verificar
SELECT * FROM province;

-- Imputar tabla 'Región'
INSERT INTO region (region_1, region_2, idProvince_FK) 
SELECT distinct tabla_reseñas_vinos.region_1, tabla_reseñas_vinos.region_2, province.idProvince
FROM tabla_reseñas_vinos
JOIN province ON tabla_reseñas_vinos.province = province.province;
-- Verificar
SELECT * FROM region;

-- Imputar tabla 'Ubicación'
INSERT INTO location (idCountry_FK, idProvince_FK, idRegion_FK)
SELECT distinct country.idCountry, province.idProvince, region.idRegion
FROM country
JOIN province ON country.idCountry = province.idCountry_FK
JOIN region ON province.idProvince = region.idProvince_FK;
-- Verificar
SELECT * FROM location;

-- Imputar tabla 'Bodega'
INSERT INTO winery (winery)
SELECT distinct winery FROM tabla_reseñas_vinos;
-- Verificar
SELECT * FROM winery;

-- Imputar tabla 'Viñedo'
INSERT INTO designation (designation, idWinery_FK)
SELECT distinct tabla_reseñas_vinos.designation, winery.idWinery
FROM tabla_reseñas_vinos 
JOIN winery ON tabla_reseñas_vinos.winery = winery.winery;
-- Verificar 
SELECT * FROM designation;

-- Imputar tabla 'Variedad'
INSERT INTO variety (variety)
SELECT distinct variety FROM tabla_reseñas_vinos;
-- Verificar
SELECT * FROM variety;

-- Imputar las columnas 'title, price, points, description' de la tabla 'Vinos'
INSERT INTO wine (title, price, points, description)
SELECT title, price, points, description FROM tabla_reseñas_vinos;

-- Se crean índices para agilizar los procesos
CREATE INDEX idx_title_wine ON wine(title(30));
CREATE INDEX idx_title_trv ON tabla_reseñas_vinos(title(30));
CREATE INDEX idx_variety ON variety(variety(50));
CREATE INDEX idx_designation ON designation(designation(50));
CREATE INDEX idx_winery ON winery(winery(50));

SET SQL_SAFE_UPDATES = 0; -- Se desactiva temporalmente para ejecutar los siguientes updates

-- Imputar la columna 'idWinery_FK' de la tabla 'Vinos'
UPDATE wine w
JOIN tabla_reseñas_vinos trv ON w.title = trv.title
JOIN winery wi ON trv.winery = wi.winery
SET w.idWinery_FK = wi.idWinery WHERE w.idWinery_FK IS NULL;

-- Imputar la columna 'idVariety_FK' de la tabla 'Vinos'
UPDATE wine w
JOIN tabla_reseñas_vinos trv ON w.title = trv.title
JOIN variety v ON trv.variety = v.variety
SET w.idVariety_FK = v.idVariety WHERE w.idVariety_FK IS NULL;

-- Imputar la columna 'idDesignation_FK' de la tabla 'Vinos'
UPDATE wine w
JOIN tabla_reseñas_vinos trv ON w.title = trv.title
JOIN designation d ON trv.designation = d.designation
SET w.idDesignation_FK = d.idDesignation WHERE w.idDesignation_FK IS NULL;

SET SQL_SAFE_UPDATES = 1; -- Se activa nuevamente

-- Verificar que todos los datos han sido cargados
SELECT * FROM wine;

-- Se declaran la claves foráneas luego de haber imputado los datos
ALTER TABLE wine
ADD CONSTRAINT fk_winery FOREIGN KEY (`idWinery_FK`) REFERENCES `winery`(`idWinery`)
ON DELETE CASCADE
ON UPDATE CASCADE;
ALTER TABLE wine
ADD CONSTRAINT fk_variety FOREIGN KEY (`idVariety_FK`) REFERENCES `variety`(`idVariety`)
ON DELETE CASCADE
ON UPDATE CASCADE; 
ALTER TABLE wine
ADD CONSTRAINT fk_designation FOREIGN KEY (`idDesignation_FK`) REFERENCES `designation`(`idDesignation`)
ON DELETE CASCADE
ON UPDATE CASCADE;

-- Imputar tabla 'Catador'
INSERT INTO taster (taster_name, taster_twitter_handle)
SELECT distinct taster_name, taster_twitter_handle
FROM tabla_reseñas_vinos;
-- Verificar
SELECT * FROM taster;


-- Posibles consultas SQL:

-- Consultar todos los vinos de una bodega específica
SELECT w.title, w.price, w.points
FROM wine w
JOIN winery wi ON w.idWinery_FK = wi.idWinery
WHERE wi.winery = 'Sweet Cheeks';

-- Obtener la cantidad de vinos por bodega
SELECT wi.winery, COUNT(w.idWine) AS total_vinos
FROM winery wi
JOIN wine w ON wi.idWinery = w.idWinery_FK
GROUP BY wi.winery;

-- Obtener el promedio de puntajes de los vinos por bodega
SELECT wi.winery, AVG(w.points) AS promedio_puntos
FROM winery wi
JOIN wine w ON wi.idWinery = w.idWinery_FK
GROUP BY wi.winery;

-- Contar cuántos vinos están en cada rango de puntuación
SELECT 
  CASE 
    WHEN points BETWEEN 80 AND 86 THEN '80-86'
    WHEN points BETWEEN 87 AND 93 THEN '87-93'
    WHEN points BETWEEN 94 AND 100 THEN '94-100'
    ELSE 'Otro'
  END AS rango_puntos,
  COUNT(*) AS cantidad_vinos
FROM wine
GROUP BY rango_puntos;

-- Consultar la cantidad de vinos por variedad de uva en cada viñedo
SELECT d.designation, v.variety, COUNT(w.idWine) AS cantidad_vinos
FROM wine w
JOIN designation d ON w.idDesignation_FK = d.designation
JOIN variety v ON w.idVariety_FK = v.idVariety
GROUP BY d.designation, v.variety;


-- Posibles consultas de análisis multidimensional:

-- Promedio de puntuaciones por bodega y variedad
SELECT wi.winery, v.variety, AVG(w.points) AS promedio_puntos
FROM wine w
JOIN winery wi ON w.idWinery_FK = wi.idWinery
JOIN variety v ON w.idVariety_FK = v.idVariety
GROUP BY wi.winery, v.variety;

-- Análisis de la relación entre el precio y la puntuación por variedad
SELECT v.variety, AVG(w.price) AS avg_price, AVG(w.points) AS avg_points
FROM wine w
JOIN variety v ON w.idVariety_FK = v.idVariety
GROUP BY v.variety
ORDER BY avg_price DESC, avg_points DESC;

-- Impacto de un viñedo en las puntuaciones
SELECT d.designation, AVG(w.points) AS avg_points
FROM wine w
JOIN designation d ON w.idDesignation_FK = d.idDesignation
GROUP BY d.designation
ORDER BY avg_points DESC;