--RESET TABLES--
DROP TABLE categories CASCADE CONSTRAINTS;
DROP TABLE company CASCADE CONSTRAINTS;
DROP TABLE game CASCADE CONSTRAINTS;
DROP TABLE type CASCADE CONSTRAINTS;
DROP TABLE users CASCADE CONSTRAINTS;
DROP TABLE login CASCADE CONSTRAINTS;
DROP TABLE premium CASCADE CONSTRAINTS;
DROP TABLE streamer CASCADE CONSTRAINTS;
DROP TABLE follow CASCADE CONSTRAINTS;
DROP TABLE payment_Method CASCADE CONSTRAINTS;
DROP TABLE stream CASCADE CONSTRAINTS;
DROP TABLE payment CASCADE CONSTRAINTS;
DROP TABLE playlist CASCADE CONSTRAINTS;
DROP TABLE watch CASCADE CONSTRAINTS;
DROP TABLE has CASCADE CONSTRAINTS;
DROP TABLE chat CASCADE CONSTRAINTS;
DROP TABLE message CASCADE CONSTRAINTS;

--TABLES--

--Entidades--
CREATE TABLE categories(
    genre VARCHAR2(15) PRIMARY KEY,
    min_age NUMBER(2,0) NOT NULL
);

CREATE TABLE company(
    uin NUMBER(11) PRIMARY KEY,
    ceo VARCHAR2(30) NOT NULL,
    c_name VARCHAR2(20) NOT NULL,
    foundation_date DATE NOT NULL
);

CREATE TABLE game(
    g_name VARCHAR2(30) PRIMARY KEY,
    realease_date DATE NOT NULL,
    description VARCHAR2(150),
    uin NUMBER(11) NOT NULL,
    FOREIGN KEY(uin) REFERENCES company(uin)
);

CREATE TABLE users (
    user_name VARCHAR2(15) PRIMARY KEY,
    email VARCHAR2(100) UNIQUE NOT NULL ,
    date_of_birth DATE NOT NULL,
    password VARCHAR2(255) NOT NULL,
    CHECK ( REGEXP_LIKE (email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+.[A-Za-z]{2,4}$'))
);

CREATE TABLE login (
    l_time TIMESTAMP,
    ip_address VARCHAR2(15) NOT NULL,
    location VARCHAR2(15) NOT NULL,
    user_name VARCHAR2(15),
    PRIMARY KEY (l_time,user_name),
    FOREIGN KEY (user_name) REFERENCES users(user_name),
    CHECK ( REGEXP_LIKE (ip_address,'^(([0-9]{1}|[0-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.){3}([0-9]{1}|[0-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])$' ))
);

CREATE TABLE premium (
    user_name VARCHAR2(15) PRIMARY KEY,
    FOREIGN KEY (user_name) REFERENCES users(user_name)
);

CREATE TABLE streamer (
    user_name VARCHAR2(15) PRIMARY KEY,
    channel_name VARCHAR2(15) UNIQUE NOT NULL,
    begin_date DATE NOT NULL,
    FOREIGN KEY (user_name) REFERENCES users(user_name)
);

CREATE TABLE payment_Method(
    type VARCHAR2(15) PRIMARY KEY
);

CREATE TABLE stream (
    streamer_name VARCHAR2(15),
    s_time TIMESTAMP,
    g_name VARCHAR2(15) NOT NULL,
    description VARCHAR2(300),
    link VARCHAR2(50) NOT NULL,
    PRIMARY KEY(streamer_name,s_time),
    FOREIGN KEY (streamer_name) REFERENCES streamer(user_name),
    FOREIGN KEY (g_name) REFERENCES game(g_name)
);

CREATE TABLE payment(
    reference NUMBER(12,0) PRIMARY KEY,
    payment_date DATE NOT NULL,
    amount NUMBER(5,2),check(amount > 0),
    user_name VARCHAR2(15) NOT NULL,
    type VARCHAR2(15) NOT NULL,
    FOREIGN KEY (user_name) REFERENCES premium(user_name),
    FOREIGN KEY (type) REFERENCES payment_Method(type)
);

CREATE TABLE playlist(
	id_p NUMBER(12,0) PRIMARY KEY,
	name_p VARCHAR2(20) NOT NULL,
	streamer_name VARCHAR2(15) NOT NULL,
	FOREIGN KEY (streamer_name) REFERENCES streamer(user_name)
);

	
CREATE TABLE chat(
	id_c NUMBER(12,0) PRIMARY KEY,
	streamer_name VARCHAR2(15) NOT NULL,
	FOREIGN KEY (streamer_name) REFERENCES streamer(user_name)
);

CREATE TABLE message(
	id_m NUMBER(12,0) PRIMARY KEY,
	m_time TIMESTAMP NOT NULL,
	id_c NUMBER(12,0) NOT NULL,
	user_name VARCHAR2(15) NOT NULL,
	text VARCHAR(250),
	FOREIGN KEY (id_c) REFERENCES chat(id_c),
	FOREIGN KEY (user_name) REFERENCES premium(user_name)
);
--Relacoes--

CREATE TABLE watch(
	user_name VARCHAR2(15),
    streamer_name VARCHAR2(15),
    s_time TIMESTAMP,
	PRIMARY KEY (user_name,streamer_name,s_time),
	FOREIGN KEY (user_name) REFERENCES users(user_name),
	FOREIGN KEY (streamer_name,s_time) REFERENCES stream(streamer_name,s_time),
    CHECK (user_name<>streamer_name)
);

CREATE TABLE has(
	id_p NUMBER(12,0),
	streamer_name VARCHAR2(15),
	s_time TIMESTAMP,
	PRIMARY KEY (id_p,streamer_name,s_time),
	FOREIGN KEY (s_time,streamer_name) REFERENCES stream(s_time,streamer_name),
	FOREIGN KEY (id_p) REFERENCES playlist(id_p)
);
CREATE TABLE type(
    g_name VARCHAR2(30),
    genre VARCHAR2(15),
    PRIMARY KEY(g_name,genre),
    FOREIGN KEY (g_name) references game(g_name),
    FOREIGN KEY (genre) references categories(genre)
); 

CREATE TABLE follow (
user_name VARCHAR2(15),
streamer_name VARCHAR2(15),
f_date TIMESTAMP NOT NULL,
PRIMARY KEY (user_name,streamer_name),
FOREIGN KEY (user_name) REFERENCES users(user_name),
FOREIGN KEY (streamer_name) REFERENCES streamer(user_name),
CHECK (user_name<>streamer_name)
);

--VIEWS--
CREATE OR REPLACE VIEW view_streamers AS( SELECT * FROM users NATURAL JOIN streamer);
CREATE OR REPLACE VIEW view_premium AS( SELECT * FROM users NATURAL JOIN premium);

--SEQUENCES--
DROP SEQUENCE seq_company;
CREATE SEQUENCE seq_company
START WITH 1
INCREMENT BY 1;

DROP SEQUENCE seq_payment;
CREATE SEQUENCE seq_payment
START WITH 1
INCREMENT BY 1;

DROP SEQUENCE seq_playlist;
CREATE SEQUENCE seq_playlist
START WITH 1
INCREMENT BY 1;

DROP SEQUENCE seq_chat;
CREATE SEQUENCE seq_chat
START WITH 1
INCREMENT BY 1;

DROP SEQUENCE seq_message;
CREATE SEQUENCE seq_message
START WITH 1
INCREMENT BY 1;



--TRIGGERS TO MANAGE view_streamers--
CREATE OR REPLACE TRIGGER insert_streamer INSTEAD OF INSERT ON view_streamers
FOR EACH ROW
BEGIN 
    INSERT INTO streamer values(:new.user_name,:new.channel_name,:new.begin_date);
END;
/

CREATE OR REPLACE TRIGGER delete_streamer INSTEAD OF DELETE ON view_streamers
FOR EACH ROW
BEGIN
    DELETE FROM streamer where user_name=:old.user_name;
END;
/

CREATE OR REPLACE TRIGGER update_streamer INSTEAD OF UPDATE on view_streamers
FOR EACH ROW
BEGIN
    UPDATE streamer
    SET
        channel_name=:new.channel_name
    where user_name=:new.user_name;
END;
/

--TRIGGERS TO MANAGE view_premium--
CREATE OR REPLACE TRIGGER insert_premium INSTEAD OF INSERT ON view_premium
FOR EACH ROW
BEGIN 
    INSERT INTO premium values(:new.user_name);
END;
/

CREATE OR REPLACE TRIGGER delete_premium INSTEAD OF DELETE ON view_premium
FOR EACH ROW
BEGIN
    DELETE FROM premium where user_name=:old.user_name;
END;
/

--TRIGGERS--
CREATE OR REPLACE TRIGGER canWatch BEFORE INSERT ON watch
FOR EACH ROW
DECLARE co NUMBER;last_login TIMESTAMP;

BEGIN 
    
    SELECT count(*) into co
    FROM login
    WHERE user_name=:new.user_name;
    
	select max(l_time) into last_login
	from login
	where user_name=:new.user_name;
	
    if co = 0 or  ((TRUNC(:new.s_time) - TRUNC(last_login))  >= 1 or (TRUNC(:new.s_time) - TRUNC(last_login)) <0)
    then Raise_Application_Error (-20100, 'User never logged in or login expired');
     end if;
END;
/

CREATE OR REPLACE TRIGGER canFollow BEFORE INSERT ON follow
FOR EACH ROW
DECLARE co NUMBER;last_login TIMESTAMP;

BEGIN 
    
    SELECT count(*) into co
    FROM login
    WHERE user_name=:new.user_name;
    
	select max(l_time) into last_login
	from login
	where user_name=:new.user_name;
	
    if co = 0 or  ((TRUNC(:new.f_date) - TRUNC(last_login))  >= 1 or (TRUNC(:new.f_date) - TRUNC(last_login)) <0)
    then Raise_Application_Error (-20100, 'User never logged in or login expired');
     end if;

END;
/

CREATE OR REPLACE TRIGGER canPay BEFORE INSERT ON payment
FOR EACH ROW
DECLARE co NUMBER;last_login TIMESTAMP;
BEGIN 
    
    SELECT count(*) into co
    FROM login
    WHERE user_name=:new.user_name;
    
	select max(l_time) into last_login
	from login
	where user_name=:new.user_name;
	
    if co = 0 or  ((TRUNC(:new.payment_date) - TRUNC(last_login))  >= 1 or (TRUNC(:new.payment_date) - TRUNC(last_login)) <0)
    then Raise_Application_Error (-20100, 'User never logged in or login expired');
     end if;

END;
/

CREATE OR REPLACE TRIGGER canSend BEFORE INSERT ON message
FOR EACH ROW
DECLARE co NUMBER;last_login TIMESTAMP;
BEGIN 
    
    SELECT count(*) into co
    FROM login
    WHERE user_name=:new.user_name;
    
	select max(l_time) into last_login
	from login
	where user_name=:new.user_name;
	
    if co = 0 or  ((TRUNC(:new.m_time) - TRUNC(last_login))  >= 1 or (TRUNC(:new.m_time) - TRUNC(last_login)) <0)
    then Raise_Application_Error (-20100, 'User never logged in or login expired');
     end if;
END;
/

CREATE OR REPLACE TRIGGER atLeastOneCategory AFTER INSERT ON game
FOR EACH ROW
DECLARE numb NUMBER;
BEGIN 
    SELECT count(unique genre) INTO numb
    FROM categories
    WHERE genre = 'DEFAULT';
	
    IF numb = 0
    THEN INSERT INTO CATEGORIES VALUES ('DEFAULT','0');
    END IF;
    
    INSERT INTO type VALUES (:new.g_name,'DEFAULT');
END;
/

CREATE OR REPLACE TRIGGER delDefault BEFORE INSERT ON type
FOR EACH ROW
DECLARE numb NUMBER;
BEGIN 
    Select count(*) into numb
    from type
    where g_name= :new.g_name ;
    
    IF numb = 1
    then Delete from type where g_name = :new.g_name and genre = 'DEFAULT';
    END IF;
END;
/

CREATE OR REPLACE TRIGGER firstPremium BEFORE INSERT ON payment
FOR EACH ROW
DECLARE id NUMBER;
BEGIN 
    SELECT  count(user_name) INTO id
    FROM premium 
    WHERE user_name = :new.user_name;
    
    IF id = 0 
    THEN INSERT INTO premium VALUES (:new.user_name);
    END IF;
END;
/

CREATE OR REPLACE TRIGGER checkAge  AFTER INSERT ON users
FOR EACH ROW
BEGIN 
    IF ((floor(months_between(SYSDATE, :new.date_of_birth) /12)) NOT BETWEEN 13 AND 125)
    THEN Raise_Application_Error (-20100, 'Error: Please Check birthdate ');
    END IF;
END;
/

CREATE OR REPLACE TRIGGER createChat  AFTER INSERT ON Streamer
FOR EACH ROW
BEGIN 
    Insert into chat values(seq_chat.nextval, :new.user_name);
END;
/

create or replace FUNCTION calc_subs(streamer VARCHAR2) 
        RETURN NUMBER IS totalsubs NUMBER; 
    BEGIN 
        SELECT count(user_name) INTO totalsubs
        FROM follow f
        WHERE f.streamer_name = streamer;
        RETURN totalsubs; 
END calc_subs;
/

PURGE RECYCLEBIN;

--CATEGORIES
INSERT INTO CATEGORIES VALUES ('Action','15');
INSERT INTO CATEGORIES VALUES ('Platform','14');
INSERT INTO CATEGORIES VALUES ('Shooter','18');
INSERT INTO CATEGORIES VALUES ('Fighting','10');
INSERT INTO CATEGORIES VALUES ('Stealth','11');
INSERT INTO CATEGORIES VALUES ('Survival','14');
INSERT INTO CATEGORIES VALUES ('Rhythm','11');
INSERT INTO CATEGORIES VALUES ('Metroidvania','15');
INSERT INTO CATEGORIES VALUES ('Adventure','15');
INSERT INTO CATEGORIES VALUES ('MMORPG','15');
INSERT INTO CATEGORIES VALUES ('Roguelikes','10');
INSERT INTO CATEGORIES VALUES ('Tactical','13');
INSERT INTO CATEGORIES VALUES ('Sandbox','5');
INSERT INTO CATEGORIES VALUES ('Choices','14');
INSERT INTO CATEGORIES VALUES ('Fantasy','16');
INSERT INTO CATEGORIES VALUES ('Simulation','10');
INSERT INTO CATEGORIES VALUES ('Strategy','13');
INSERT INTO CATEGORIES VALUES ('Artillery','18 ');
INSERT INTO CATEGORIES VALUES ('Wargame','18');
INSERT INTO CATEGORIES VALUES ('Sports','8');
INSERT INTO CATEGORIES VALUES ('Racing','15');
INSERT INTO CATEGORIES VALUES ('Competitive','15');
INSERT INTO CATEGORIES VALUES ('MMO','16');
INSERT INTO CATEGORIES VALUES ('Casual','16');
INSERT INTO CATEGORIES VALUES ('Party','16');
INSERT INTO CATEGORIES VALUES ('Programming','18');
INSERT INTO CATEGORIES VALUES ('Logic','15');
INSERT INTO CATEGORIES VALUES ('Trivia','15');
INSERT INTO CATEGORIES VALUES ('Board','15');
INSERT INTO CATEGORIES VALUES ('Idle','15');
INSERT INTO CATEGORIES VALUES ('Advergame','15');
INSERT INTO CATEGORIES VALUES ('Art','15');
INSERT INTO CATEGORIES VALUES ('Christian','15');
INSERT INTO CATEGORIES VALUES ('Educational','15');
INSERT INTO CATEGORIES VALUES ('Exergame','15');
INSERT INTO CATEGORIES VALUES ('Serious','15');
INSERT INTO CATEGORIES VALUES ('Scientific','15');

--Companies
INSERT INTO company values (seq_company.nextval,'Martelo Rebolo','Acclaim',TO_DATE('31-01-2000','DD-MM-YYYY'));
INSERT INTO company values (seq_company.nextval,'John Bigodes','Accolade',TO_DATE('23-02-1986 ','DD-MM-YYYY'));
INSERT INTO company values (seq_company.nextval,'Steve Trabalhos','StarControl',TO_DATE('01-02-1986  ','DD-MM-YYYY'));
INSERT INTO company values (seq_company.nextval,'Hamed','TestDrive',TO_DATE('01-02-1986  ','DD-MM-YYYY'));
INSERT INTO company values (seq_company.nextval,'Publican','AccessGames', TO_DATE('03-02-1988','DD-MM-YYYY'));
INSERT INTO company values (seq_company.nextval,'Dolores','Pandora', TO_DATE('03-02-1988','DD-MM-YYYY'));
INSERT INTO company values (seq_company.nextval,'Barry Allen','ACETeam',	TO_DATE('08-09-1991 ','DD-MM-YYYY'));
INSERT INTO company values (seq_company.nextval,'Cisco Ramon','AcesStudio', TO_DATE('07-07-1988','DD-MM-YYYY'));
INSERT INTO company values (seq_company.nextval,'Gipsy','Acheron',	TO_DATE('03-02-1988','DD-MM-YYYY'));
INSERT INTO company values (seq_company.nextval,'Harry Potter','Activision', TO_DATE('03-02-1988','DD-MM-YYYY'));
INSERT INTO company values (seq_company.nextval,'Hirmine','Crash', TO_DATE('03-02-1988','DD-MM-YYYY'));
INSERT INTO company values (seq_company.nextval,'Malfoy','Spyro', TO_DATE('03-02-1988','DD-MM-YYYY'));
INSERT INTO company values (seq_company.nextval,'Knorr','Tony', TO_DATE('03-02-1988','DD-MM-YYYY'));
INSERT INTO company values (seq_company.nextval,'Yornilindo','GuitarHero', TO_DATE('03-02-1988','DD-MM-YYYY'));
INSERT INTO company values (seq_company.nextval,'Ilisabet','Skylanders', TO_DATE('03-02-1988','DD-MM-YYYY'));
INSERT INTO company values (seq_company.nextval,'Yuppy','Adventure', TO_DATE('03-02-1988','DD-MM-YYYY'));
INSERT INTO company values (seq_company.nextval,'Snoopy','Akella', TO_DATE('03-02-1988','DD-MM-YYYY'));
INSERT INTO company values (seq_company.nextval,'GarlosM','Age', TO_DATE('03-02-1988','DD-MM-YYYY'));
INSERT INTO company values (seq_company.nextval,'Simpli','Sea', TO_DATE('03-02-1988','DD-MM-YYYY'));
INSERT INTO company values (seq_company.nextval,'Oliver','Aki'	, TO_DATE('03-02-1988','DD-MM-YYYY'));
INSERT INTO company values (seq_company.nextval,'Jorge','Alfa'	, TO_DATE('03-02-1988','DD-MM-YYYY'));	
INSERT INTO company values (seq_company.nextval,'Tiago','Amazon', TO_DATE('03-02-1988','DD-MM-YYYY'));
INSERT INTO company values (seq_company.nextval,'Jose','Ancient', TO_DATE('03-02-1988','DD-MM-YYYY'));
INSERT INTO company values (seq_company.nextval,'Joao','Anino', TO_DATE('03-02-1988','DD-MM-YYYY'));
INSERT INTO company values (seq_company.nextval,'Andre','Ankama Games', TO_DATE('03-02-1988','DD-MM-YYYY'));
INSERT INTO company values (seq_company.nextval,'Vasco','Dofus', TO_DATE('03-02-1988','DD-MM-YYYY'));
INSERT INTO company values (seq_company.nextval,'Joao','AppyEntertainment'	, TO_DATE('03-02-1988','DD-MM-YYYY'));
INSERT INTO company values (seq_company.nextval,'Maria','AQInteractive', TO_DATE('03-02-1988','DD-MM-YYYY'));
INSERT INTO company values (seq_company.nextval,'Carlos','Arc', TO_DATE('03-02-1988','DD-MM-YYYY'));
INSERT INTO company values (seq_company.nextval,'Mateus','BlazBlue', TO_DATE('03-02-1988','DD-MM-YYYY'));
INSERT INTO company values (seq_company.nextval,'Josefa','Arkane', TO_DATE('03-02-1988','DD-MM-YYYY'));
INSERT INTO company values (seq_company.nextval,'Jaquina','Dishonored', TO_DATE('03-02-1988','DD-MM-YYYY'));
INSERT INTO company values (seq_company.nextval,'DarthVader','Arkedo', TO_DATE('03-02-1988','DD-MM-YYYY'));
INSERT INTO company values (seq_company.nextval,'Carolina','ArenaNet', TO_DATE('03-02-1988','DD-MM-YYYY'));
INSERT INTO company values (seq_company.nextval,'CEO','GuildWars', TO_DATE('03-02-1988','DD-MM-YYYY'));

--GAMES
INSERT INTO GAME VALUES('Tetris',TO_DATE('23-02-1986 ','DD-MM-YYYY'),	'olaaaaaaaaaaaaaaasdasdasdaasssssdasdasdasdasdasdasdasdas',3);
INSERT INTO GAME VALUES('Metroid',TO_DATE('01-02-1986  ','DD-MM-YYYY'),	'olaaaaaaaaaaaaaaasdadlfmcfmdkmckdfdasdasdas',2);
INSERT INTO GAME VALUES('Mega Man',TO_DATE('03-02-1988','DD-MM-YYYY'),	'olaaaaaaaaaaaaaaasdadlfmcfmdkmckdfdasdasdas',3);
INSERT INTO GAME VALUES('Super Mario Bros',TO_DATE('03-02-1988','DD-MM-YYYY'),	'olaaaaaaaaaaaaaaasdadlfmcfmdkmckdfdasdasdas',4);
INSERT INTO GAME VALUES('Sonic the Hedgehog',TO_DATE('08-09-1991 ','DD-MM-YYYY'),	'olaaaaaaaaaaaaaaasdadlfmcfmdkmckdfdasdasdas',5);
INSERT INTO GAME VALUES('The Legend of Zelda',TO_DATE('07-07-1988','DD-MM-YYYY'),	'olaaaaaaaaaaaaaaasdadlfdskfdfdasdas',6);
INSERT INTO GAME VALUES('Street Fighter II' ,TO_DATE('03-02-1988','DD-MM-YYYY'),	'olaaaaaaaaaaaaaaasdadlfmcfmdkmckdfdasdasdas',7);
INSERT INTO GAME VALUES('DOOM ',TO_DATE('03-02-1988','DD-MM-YYYY'),	'olaaaaaaaaaaaaaaasdadlfmcfmdkmckdfdasdasdas',8);
INSERT INTO GAME VALUES('Star Wars: TIE Fighter',TO_DATE('03-02-1988','DD-MM-YYYY'),	'olaaaaaaaaaaaaaaasdadlfmcfmdkmckdfdasdasdas',9);
INSERT INTO GAME VALUES('Super Metroid',TO_DATE('03-02-1988','DD-MM-YYYY'),	'olaaaaaaaaaaaaaaasdadlfmcfmdkmckdfdasdasdas',10);
INSERT INTO GAME VALUES('Final Fantasy VI',TO_DATE('03-02-1988','DD-MM-YYYY'),	'olaaaaaaaaaaaaaaasdadlfmcfmdkmckdfdasdasdas',11);
INSERT INTO GAME VALUES('Castlevania',TO_DATE('03-02-1988','DD-MM-YYYY'),	'olaaaaaaaaaaaaaaasdadlfmcfmdkmckdfdasdasdas',12);
INSERT INTO GAME VALUES('Grim Fandango',TO_DATE('03-02-1988','DD-MM-YYYY'),	'olaaaaaaaaaaaaaaasdadlfmcfmdkmckdfdasdasdas',13);
INSERT INTO GAME VALUES('TheLegend',TO_DATE('03-02-1988','DD-MM-YYYY'),	'olaaaaaaaaaaaaaaasdadlfmcfmdkmckdfdasdasdas',14);
INSERT INTO GAME VALUES('StarCraft',TO_DATE('03-02-1988','DD-MM-YYYY'),	'olaaaaaaaaaaaaaaasdadlfmcfmdkmckdfdasdasdas',15);
INSERT INTO GAME VALUES('Halo: Combat Evolved',TO_DATE('03-02-1988','DD-MM-YYYY'),	'olaaa+aaaaaaaaaaaasdadlfmcfmdkmckdfdasdasdas',16);
INSERT INTO GAME VALUES('Grand Theft Auto III',TO_DATE('03-02-1988','DD-MM-YYYY'),	'olaaaaaaaaaaaaaaasdadlfmcfmdkmckdfdasdasdas',16);
INSERT INTO GAME VALUES('Counter-Strike',TO_DATE('03-02-1988','DD-MM-YYYY'),	'olaaaaaaaaaaaaaaasdadlfmcfmdkmckdfdasdasdas',17);
INSERT INTO GAME VALUES('Grim',TO_DATE('03-02-1988','DD-MM-YYYY'),	'olaaaaaaaaaaaaaaasdadlfmcfmdkmckdfdasdasdas',15);

--Type--
INSERT INTO TYPE VALUES ('Tetris','Action');
INSERT INTO TYPE VALUES ('Tetris','Educational');
INSERT INTO TYPE VALUES ('Sonic the Hedgehog','Casual');
INSERT INTO TYPE VALUES ('Sonic the Hedgehog','Party');
INSERT INTO TYPE VALUES ('Grim','Programming');
INSERT INTO TYPE VALUES ('Grim','Logic');

--USERS--
INSERT INTO USERS VALUES ('Doloe3SaasssDrs','asesaassd@hotmasil.com',TO_DATE('31-01-2000','DD-MM-YYYY'),'OLA_ADEUS');
INSERT INTO USERS VALUES ('Pessoa0','Pessoa0@hotmail.com',TO_DATE('31-01-2000','DD-MM-YYYY'),'e3w4sizg');
INSERT INTO USERS VALUES ('Pessoa1','Pessoa1@hotmail.com',TO_DATE('31-01-2000','DD-MM-YYYY'),'b3cpsnhl');
INSERT INTO USERS VALUES ('Pessoa2','Pessoa2@hotmail.com',TO_DATE('31-01-2000','DD-MM-YYYY'),'8ta5k357');
INSERT INTO USERS VALUES ('Pessoa3','Pessoa3@hotmail.com',TO_DATE('31-01-2000','DD-MM-YYYY'),'hssnbned');
INSERT INTO USERS VALUES ('Pessoa4','Pessoa4@hotmail.com',TO_DATE('31-01-2000','DD-MM-YYYY'),'fk72d8lj');
INSERT INTO USERS VALUES ('Pessoa5','Pessoa5@hotmail.com',TO_DATE('31-01-2000','DD-MM-YYYY'),'plmkyb0e');
INSERT INTO USERS VALUES ('Pessoa6','Pessoa6@hotmail.com',TO_DATE('31-01-2000','DD-MM-YYYY'),'dkkwyzws');
INSERT INTO USERS VALUES ('Pessoa7','Pessoa7@hotmail.com',TO_DATE('31-01-2000','DD-MM-YYYY'),'vhkx672t');
INSERT INTO USERS VALUES ('Pessoa8','Pessoa8@hotmail.com',TO_DATE('31-01-2000','DD-MM-YYYY'),'chjtwprr');
INSERT INTO USERS VALUES ('Pessoa9','Pessoa9@hotmail.com',TO_DATE('31-01-2000','DD-MM-YYYY'),'7m8v9oeb');
INSERT INTO USERS VALUES ('Pessoa10','Pessoa10@hotmail.com',TO_DATE('31-01-2000','DD-MM-YYYY'),'3an1jtpi');
INSERT INTO USERS VALUES ('Pessoa11','Pessoa11@hotmail.com',TO_DATE('31-01-2000','DD-MM-YYYY'),'2homcjm8');

--LOGIN--
INSERT INTO login VALUES(SYSDATE,'192.168.1.92','Lisboa','Pessoa1');
INSERT INTO login VALUES(SYSDATE,'192.165.1.87','Almada','Pessoa2');
INSERT INTO login VALUES(SYSDATE,'192.168.1.09','Setúbal','Pessoa3');
INSERT INTO login VALUES(SYSDATE,'192.153.1.92','Faro','Pessoa4');
INSERT INTO login VALUES(SYSDATE,'192.176.1.92','Caparica','Pessoa5');
INSERT INTO login VALUES(SYSDATE,'192.168.3.92','Porto','Pessoa6');
INSERT INTO login VALUES(SYSDATE,'192.154.1.92','Braga','Pessoa7');
INSERT INTO login VALUES(SYSDATE,'192.157.1.92','Braga','Pessoa10');

--PREMIUM--
INSERT INTO PREMIUM VALUES ('Pessoa5');
INSERT INTO PREMIUM VALUES ('Pessoa8');
INSERT INTO PREMIUM VALUES ('Pessoa0');
INSERT INTO PREMIUM VALUES ('Pessoa4');
INSERT INTO PREMIUM VALUES ('Pessoa3');
INSERT INTO PREMIUM VALUES ('Pessoa6');
INSERT INTO PREMIUM VALUES ('Pessoa2');
INSERT INTO PREMIUM VALUES ('Pessoa7');
INSERT INTO PREMIUM VALUES ('Pessoa9');
INSERT INTO PREMIUM VALUES ('Pessoa1');

--STREAMER--
INSERT INTO streamer VALUES('Pessoa10','azeite',SYSDATE);
INSERT INTO streamer VALUES('Pessoa7','+azeite',SYSDATE);
INSERT INTO streamer VALUES('Pessoa2','twitch',SYSDATE);

--FOLLOW--
INSERT INTO follow VALUES ('Pessoa10','Pessoa7',SYSDATE);
INSERT INTO follow VALUES ('Pessoa1','Pessoa10',SYSDATE);
INSERT INTO follow VALUES ('Pessoa5','Pessoa7',SYSDATE);

--STREAM--
INSERT INTO stream VALUES ('Pessoa10',TO_DATE('2012-03-28 11:10:00','yyyy/mm/dd hh24:mi:ss'),'Tetris','muito mas bastante muito ainda muito azeite','www.twitch/jorge.tv');
INSERT INTO stream VALUES ('Pessoa10',SYSDATE,'Tetris','muito mas bastante muito ainda muito azeite','www.twitch/jorge.tv');

--WATCH--
INSERT INTO watch VALUES ('Pessoa3','Pessoa10',TO_DATE('2018-05-19 17:00:16','yyyy/mm/dd hh24:mi:ss'));

--PAYMENT_METHOD--
INSERT INTO PAYMENT_METHOD VALUES('PayPal');
INSERT INTO PAYMENT_METHOD VALUES('MB Way');
INSERT INTO PAYMENT_METHOD VALUES('Apple Pay');
INSERT INTO PAYMENT_METHOD VALUES('BitCoin');
INSERT INTO PAYMENT_METHOD VALUES('Credit Card');
INSERT INTO PAYMENT_METHOD VALUES('Google Pay');

--PAYMENT--
INSERT INTO PAYMENT VALUES(SEQ_PAYMENT.NEXTVAL,SYSDATE,50,'Pessoa10','Google Pay');
INSERT INTO PAYMENT VALUES(SEQ_PAYMENT.NEXTVAL,SYSDATE,10,'Pessoa10','BitCoin');
INSERT INTO PAYMENT VALUES(SEQ_PAYMENT.NEXTVAL,SYSDATE,65,'Pessoa10','Credit Card');
INSERT INTO PAYMENT VALUES(SEQ_PAYMENT.NEXTVAL,SYSDATE,39,'Pessoa10','MB Way');
INSERT INTO PAYMENT VALUES(SEQ_PAYMENT.NEXTVAL,SYSDATE,534,'Pessoa10','Apple Pay');

--Playlist--

Insert into Playlist values(seq_playlist.nextval,'Playlist1','Pessoa10');
Insert into Playlist values(seq_playlist.nextval,'Playlist2','Pessoa110');
Insert into Playlist values(seq_playlist.nextval,'Playlist3','Pessoa10');
Insert into Playlist values(seq_playlist.nextval,'Ola1','Pessoa7');
Insert into Playlist values(seq_playlist.nextval,'Ola2','Pessoa7');
Insert into Playlist values(seq_playlist.nextval,'Fortnite clips','Pessoa7');
Insert into Playlist values(seq_playlist.nextval,'Pubg best moments','Pessoa2');


--Message--

Insert into message values(seq_message.nextval,sysdate,1,'Pessoa10','Nao gosto da tua stream');
Insert into message values(seq_message.nextval,sysdate,2,'Pessoa10','azeite muito azeite azeite++');
Insert into message values(seq_message.nextval,sysdate,1,'Pessoa2','PogChamp!!');
Insert into message values(seq_message.nextval,sysdate,1,'Pessoa7','CY@');
Insert into message values(seq_message.nextval,sysdate,2,'Pessoa10','azeite pouco azeite azeite--');

--has--




/*CREATE OR REPLACE TRIGGER addPlaylistToHas  AFTER INSERT ON Playlist
FOR EACH ROW
Declare time  TIMESTAMP;
BEGIN 

	select s_time into time
	from stream
	where streamer_name = :new.streamer_name
	
    Insert into has values(:new.id_p, :new.stream_name,);
END;
/*/












