CREATE DATABASE shoeshop ;
USE shoeshop;

/*
Tabellen betyg består av id och beskrivning. Dessa beskrivningar kan fyllas i med t.ex
"Mycket nöjd", "Nöjd" osv.
*/
CREATE TABLE betyg (
  id int NOT NULL AUTO_INCREMENT,
  beskrivning varchar(45) NULL,
  sifferbetyg int NULL,
  PRIMARY KEY (id)
);
/*
Tabellen kategori är väldigt lik betyg tabellen i funktionalitet och användning.
*/
CREATE TABLE kategori (
  id int NOT NULL AUTO_INCREMENT,
  namn varchar(45) NULL,
  PRIMARY KEY (id)
);
/*
Tabellen kund innehåller inga foreign keys vilket gör att man alltid kan skapa en ny
kund utan att behöva förlita sig på annan data.
*/
CREATE TABLE kund (
  id int NOT NULL AUTO_INCREMENT,
  förnamn varchar(45) NULL,
  efternamn varchar(45) NULL,
  ort varchar(45) NULL,
  användarnamn varchar(45) NULL,
  lösenord varchar(45) NULL,
  PRIMARY KEY (id)
);
/*
Även tabellen produkt har inga foreign keys vilket gör att man lätt kan lägga till fler
produkter framöver. Valde även att göra priset av datatypen decimal även fast jag
för tillfället inte utnyttjar decimaler, men tänkte att det var mer logiskt och
kan komma till användning framöver.
*/
CREATE TABLE produkt (
  id int NOT NULL AUTO_INCREMENT,
  märke varchar(45) NULL,
  storlek int NULL,
  färg varchar(45) NULL,
  pris decimal(10,0) NULL,
  antal int NULL,
  PRIMARY KEY (id)
);
/*
Använder mig av foreign keys i denna sambandstabell för att säkerställa att
endast giltiga produkt IDn, kund IDn och betyg IDn används.
Referens integriteten gör även så att data som används på ett ställe i databasen
inte går att radera på ett annat ställe utan att det blir fel.
*/
CREATE TABLE produktbetyg (
  kundid int NOT NULL,
  produktid int NOT NULL,
  betygid int NOT NULL,
  kommentar varchar(500) NULL,
  PRIMARY KEY (kundid, produktid),
  FOREIGN KEY (betygid) REFERENCES betyg (id),
  FOREIGN KEY (kundid) REFERENCES kund (id),
  FOREIGN KEY (produktid) REFERENCES produkt (id)
);
/*
Använder mig även av foreign keys här för att para ihop varje produkt med en eller flera
kategorier.
*/
CREATE TABLE produktkategori (
  produktid int NOT NULL,
  kategoriid int NOT NULL,
  PRIMARY KEY (produktid,kategoriid),
  FOREIGN KEY (kategoriid) REFERENCES kategori (id),
  FOREIGN KEY (produktid) REFERENCES produkt (id)
);
/*
Använder en foreign key här eftersom varje beställning måste vara kopplad till en kund.
Detta gör även så att kunden inte kan raderas i efterhand utan att dennes information
finns kvar så länge beställningen finns kvar.
*/
CREATE TABLE beställning (
  id int NOT NULL AUTO_INCREMENT,
  datum date NULL,
  kundid int NOT NULL,
  PRIMARY KEY (id),
  FOREIGN KEY (kundid) REFERENCES kund (id)
);
/*
En beställning kan bestå av flera produkter, därför gjorde jag en beställningsrad
som parar ihop ett beställnings ID med en viss produkt och antal.
En beställning kan förekomma flera gånger i den här tabellen vilket då gör så att
en kund kan beställa olika varor i samma beställning.
*/
CREATE TABLE beställningsrad (
  beställningsid int NOT NULL,
  produktid int NOT NULL,
  antal int NULL,
  PRIMARY KEY (beställningsid,produktid),
  FOREIGN KEY (beställningsid) REFERENCES beställning (id),
  FOREIGN KEY (produktid) REFERENCES produkt (id)
);

CREATE TABLE slutilager (
  slutilagerid int NOT NULL AUTO_INCREMENT,
  produktid int NOT NULL,
  datum date NOT NULL,
  PRIMARY KEY (slutilagerid),
  FOREIGN KEY (produktid) REFERENCES produkt (id)
);

-- Jag har valt att implementera index så att man lätt kan söka på en kunds namn och en produkt av ett visst märke
CREATE INDEX ix_förnamn ON kund (förnamn);

CREATE INDEX ix_märke ON produkt(märke);

DELIMITER //
CREATE PROCEDURE AddToCart (
IN kID INT,
IN pID INT,
INOUT bID INT)
BEGIN

DECLARE EXIT HANDLER FOR SQLEXCEPTION
BEGIN
	ROLLBACK;
	RESIGNAL SET MESSAGE_TEXT = 'SQLEXCEPTION occured, rollback done';
END;

SET autocommit = 0;
START TRANSACTION;

IF EXISTS (SELECT * FROM beställning WHERE id = bID) THEN
	IF EXISTS (SELECT * FROM beställningsrad WHERE beställningsid = bID AND produktid = pID) THEN
		UPDATE beställningsrad SET antal = antal+1 WHERE beställningsid = bID AND produktid = pID;
    ELSE
		INSERT INTO beställningsrad (beställningsid, produktid, antal) VALUES (bID, pID, 1);
	END IF;
ELSE
	INSERT INTO beställning (datum, kundid) VALUES (curdate(), kID);
    SET bID = last_insert_id();
    INSERT INTO beställningsrad (beställningsid, produktid, antal) VALUES (bID, pID, 1);
END IF;
UPDATE produkt SET antal = antal-1 WHERE id = pID;
COMMIT;
SET autocommit = 1;
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE Rate(
IN kID INT,
IN pID INT,
IN bID INT,
IN betygKommentar varchar(100))
BEGIN

DECLARE duplicate_review CONDITION FOR SQLSTATE '45000';
DECLARE EXIT HANDLER FOR duplicate_review
BEGIN
	ROLLBACK;
    RESIGNAL SET MESSAGE_TEXT = 'Fel uppstod, kunden har redan betygsatt denna produkt';
END;

DECLARE EXIT HANDLER FOR SQLEXCEPTION
BEGIN
	ROLLBACK;
	RESIGNAL SET MESSAGE_TEXT = 'SQLEXCEPTION occured, rollback done';
END;

SET autocommit = 0;
START TRANSACTION;
	IF NOT EXISTS (SELECT * FROM produktbetyg WHERE kundid = kID AND produktid = pID) THEN
		INSERT INTO produktbetyg (kundid, produktid, betygid, kommentar) VALUES (kID, pID, bID, betygKommentar);
	ELSE
		SIGNAL duplicate_review;
	END IF;
COMMIT;
SET autocommit = 1;
END//
DELIMITER ;

DELIMITER //
CREATE TRIGGER After_produkt_update
	AFTER UPDATE ON produkt FOR EACH ROW
    BEGIN
		IF (new.antal = 0) THEN
			INSERT INTO slutilager (produktid, datum) VALUES (new.id, curdate());
		END IF;
	END//
DELIMITER ;

Delimiter //
CREATE FUNCTION getAverageScore( pID INT )
returns int
reads SQL data
BEGIN
	DECLARE averageScore int DEFAULT NULL;
         SELECT avg(sifferbetyg) INTO averageScore FROM produkt INNER JOIN produktbetyg ON produkt.id = produktbetyg.produktid INNER JOIN betyg ON produktbetyg.betygid = betyg.id
         WHERE produkt.id = pID;
         RETURN averageScore;
END//
Delimiter ;

CREATE VIEW medelbetyg
AS SELECT produkt.id, produkt.märke, produkt.storlek, produkt.pris, 
getAverageScore(produkt.id) AS 'medelbetyg',
(SELECT betyg.beskrivning FROM betyg WHERE betyg.sifferbetyg = getAverageScore(produkt.id)) AS 'betyg'
FROM produkt;

INSERT INTO betyg (id,beskrivning,sifferbetyg) VALUES (1,'Missnöjd', 1);
INSERT INTO betyg (id,beskrivning,sifferbetyg) VALUES (2,'Ganska nöjd', 2);
INSERT INTO betyg (id,beskrivning,sifferbetyg) VALUES (3,'Nöjd', 3);
INSERT INTO betyg (id,beskrivning,sifferbetyg) VALUES (4,'Mycket nöjd', 4);
INSERT INTO betyg (id,beskrivning,sifferbetyg) VALUES (5,'Aldrig varit nöjdare', 5);


INSERT INTO kategori (id,namn) VALUES (1,'Sandaler');
INSERT INTO kategori (id,namn) VALUES (2,'Sportskor');
INSERT INTO kategori (id,namn) VALUES (3,'Sneakers');
INSERT INTO kategori (id,namn) VALUES (4,'Tofflor');
INSERT INTO kategori (id,namn) VALUES (5,'Stövlar');
INSERT INTO kategori (id,namn) VALUES (6,'Barnskor');


INSERT INTO kund (id,förnamn,efternamn,ort,användarnamn,lösenord) VALUES (1,'Harald','Haraldsson','Stockholm','coolguy3','hej123');
INSERT INTO kund (id,förnamn,efternamn,ort,användarnamn,lösenord) VALUES (2,'Sven','Svensson','Malmö','sven31','rosaBoll');
INSERT INTO kund (id,förnamn,efternamn,ort,användarnamn,lösenord) VALUES (3,'Lina','Linasson','Stockholm','coolgirl3','hejdå123');
INSERT INTO kund (id,förnamn,efternamn,ort,användarnamn,lösenord) VALUES (4,'Moa','Moasson','Borås','trappa45','jojo45');
INSERT INTO kund (id,förnamn,efternamn,ort,användarnamn,lösenord) VALUES (5,'Ferdinand','Ferdsson','Gävle','doglover77','gullighäst');
INSERT INTO kund (id,förnamn,efternamn,ort,användarnamn,lösenord) VALUES (6,'Ivar','Ivarsson','Gävle','75ivar','ivarärbäst');
INSERT INTO kund (id,förnamn,efternamn,ort,användarnamn,lösenord) VALUES (7,'Mona','Monasson','Malmö','StortBord','telluS22');


INSERT INTO produkt (id,märke,storlek,färg,pris,antal) VALUES (1,'Nike',35,'Vit',499, 5);
INSERT INTO produkt (id,märke,storlek,färg,pris,antal) VALUES (2,'Ecco',40,'Brun',299, 3);
INSERT INTO produkt (id,märke,storlek,färg,pris,antal) VALUES (3,'Ecco',40,'Svart',399, 4);
INSERT INTO produkt (id,märke,storlek,färg,pris,antal) VALUES (4,'Ecco',38,'Svart',159, 2);
INSERT INTO produkt (id,märke,storlek,färg,pris,antal) VALUES (5,'Adidas',42,'Svart',399, 6);
INSERT INTO produkt (id,märke,storlek,färg,pris,antal) VALUES (6,'Adidas',36,'Röd',499, 2);
INSERT INTO produkt (id,märke,storlek,färg,pris,antal) VALUES (7,'Filippa K',40,'Svart',1399, 1);
INSERT INTO produkt (id,märke,storlek,färg,pris,antal) VALUES (8,'Filippa K',39,'Brun',1199, 4);
INSERT INTO produkt (id,märke,storlek,färg,pris,antal) VALUES (9,'Diesel',41,'Vit',899, 3);
INSERT INTO produkt (id,märke,storlek,färg,pris,antal) VALUES (10,'Diesel',40,'Svart',999, 2);


INSERT INTO produktkategori (produktid,kategoriid) VALUES (4,1);
INSERT INTO produktkategori (produktid,kategoriid) VALUES (3,2);
INSERT INTO produktkategori (produktid,kategoriid) VALUES (5,2);
INSERT INTO produktkategori (produktid,kategoriid) VALUES (10,2);
INSERT INTO produktkategori (produktid,kategoriid) VALUES (1,3);
INSERT INTO produktkategori (produktid,kategoriid) VALUES (6,3);
INSERT INTO produktkategori (produktid,kategoriid) VALUES (9,3);
INSERT INTO produktkategori (produktid,kategoriid) VALUES (2,4);
INSERT INTO produktkategori (produktid,kategoriid) VALUES (7,5);
INSERT INTO produktkategori (produktid,kategoriid) VALUES (8,5);
INSERT INTO produktkategori (produktid,kategoriid) VALUES (1,6);
INSERT INTO produktkategori (produktid,kategoriid) VALUES (6,6);


INSERT INTO beställning (id,datum,kundid) VALUES (1,'2020-01-04',1);
INSERT INTO beställning (id,datum,kundid) VALUES (2,'2020-03-19',1);
INSERT INTO beställning (id,datum,kundid) VALUES (3,'2020-03-22',2);
INSERT INTO beställning (id,datum,kundid) VALUES (4,'2020-03-28',3);
INSERT INTO beställning (id,datum,kundid) VALUES (5,'2020-04-13',3);
INSERT INTO beställning (id,datum,kundid) VALUES (6,'2020-06-28',2);
INSERT INTO beställning (id,datum,kundid) VALUES (7,'2020-09-15',4);
INSERT INTO beställning (id,datum,kundid) VALUES (8,'2020-09-22',5);
INSERT INTO beställning (id,datum,kundid) VALUES (9,'2020-11-07',5);
INSERT INTO beställning (id,datum,kundid) VALUES (10,'2020-12-14',6);
INSERT INTO beställning (id,datum,kundid) VALUES (11,'2020-12-20',1);


INSERT INTO beställningsrad (beställningsid,produktid,antal) VALUES (1,2,3);
INSERT INTO beställningsrad (beställningsid,produktid,antal) VALUES (1,4,1);
INSERT INTO beställningsrad (beställningsid,produktid,antal) VALUES (2,4,1);
INSERT INTO beställningsrad (beställningsid,produktid,antal) VALUES (3,7,1);
INSERT INTO beställningsrad (beställningsid,produktid,antal) VALUES (4,10,1);
INSERT INTO beställningsrad (beställningsid,produktid,antal) VALUES (5,4,1);
INSERT INTO beställningsrad (beställningsid,produktid,antal) VALUES (5,6,1);
INSERT INTO beställningsrad (beställningsid,produktid,antal) VALUES (6,9,1);
INSERT INTO beställningsrad (beställningsid,produktid,antal) VALUES (7,2,1);
INSERT INTO beställningsrad (beställningsid,produktid,antal) VALUES (7,5,1);
INSERT INTO beställningsrad (beställningsid,produktid,antal) VALUES (8,8,1);
INSERT INTO beställningsrad (beställningsid,produktid,antal) VALUES (9,4,1);
INSERT INTO beställningsrad (beställningsid,produktid,antal) VALUES (10,1,1);
INSERT INTO beställningsrad (beställningsid,produktid,antal) VALUES (11,9,1);

INSERT INTO produktbetyg (kundid,produktid,betygid,kommentar) VALUES(2,2,4,'Mycket bra');
INSERT INTO produktbetyg (kundid,produktid,betygid,kommentar) VALUES(1,2,3,'Väldigt bra');
INSERT INTO produktbetyg (kundid,produktid,betygid,kommentar) VALUES(4,2,2,'bra');
INSERT INTO produktbetyg (kundid,produktid,betygid,kommentar) VALUES(3,2,1,'oklart');
INSERT INTO produktbetyg (kundid,produktid,betygid,kommentar) VALUES(5,2,1,'Dåligt');
INSERT INTO produktbetyg (kundid,produktid,betygid,kommentar) VALUES(5,3,5,'Dåligt');
INSERT INTO produktbetyg (kundid,produktid,betygid,kommentar) VALUES(5,1,4,'Dåligt');
INSERT INTO produktbetyg (kundid,produktid,betygid,kommentar) VALUES(4,3,3,'Dåligt');