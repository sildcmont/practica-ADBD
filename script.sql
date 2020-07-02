-- Autores:
--Darío de la Torre Guinaldo
--Óscar Ibáñez Garrido
--Silvia Montero Vega
--María Robles del Blanco

DROP TABLE SolicitudCesion;
DROP TABLE ReclamacionSugerencia;
DROP TABLE EntradaSalida;
DROP TABLE Vehiculo;
DROP TABLE AbonoReserva;
DROP TABLE Abono;
DROP TABLE SolicitudNoAbonada;
DROP TABLE PlazaResidencial;
DROP TABLE PlazaRotacional;
DROP TABLE Aparcamiento;
DROP TABLE Persona;
DROP TABLE TarifasMaximas;
DROP TYPE tipoTarifa;
DROP TYPE tipoReserva;
DROP TYPE tipoSinReserva;
DROP TYPE categoriaVehiculo;
DROP TYPE tipoAparcamiento;

CREATE DOMAIN tipoTarifa AS VARCHAR(50)
		CHECK (VALUE IN ('moto','coche','autocaravana'));
CREATE DOMAIN tipoReserva AS VARCHAR(50)
		CHECK (VALUE IN ('residentes','movilidadSostenible','cesionUso', 'cortoPlazo', '24h'));
CREATE DOMAIN tipoSinReserva AS VARCHAR(50)
		CHECK (VALUE IN ('diurno','nocturno'));
CREATE DOMAIN categoriaVehiculo AS VARCHAR(50)
		CHECK (VALUE IN ('ECO','CERO','B', 'C'));
CREATE DOMAIN tipoAparcamiento AS VARCHAR(50)
		CHECK (VALUE IN ('residencial','mixto','rotacional'));

CREATE TABLE TarifasMaximas (
	tarifaTurismo INTEGER not null,
	tarifaMoto INTEGER not null,
	tarifaAutocaravana INTEGER not null
);

CREATE TABLE Persona (
	nombreORazSoc CHAR(50) not null,
	DNIoCIF CHAR(50),
	domicilio CHAR(50) not null,
	PRIMARY KEY (DNIoCIF)
);

CREATE TABLE Aparcamiento (
	CIF CHAR(50),
	nombreAparcamiento CHAR(50),
	codigoAparcamiento CHAR(50),
	tipoAparcamiento tipoAparcamiento not null,
	numeroPlazas INTEGER not null,
	disuasorio BOOLEAN not null,
	tarifaCoche INTEGER,
	tarifaMoto INTEGER,
	tarifaAutocaravana INTEGER,
	PRIMARY KEY (codigoAparcamiento),
	FOREIGN KEY (CIF)
		REFERENCES Persona (DNIoCIF),
	UNIQUE (nombreAparcamiento),
	CONSTRAINT tarifaResidencialNula CHECK ((tipoAparcamiento <>'residencial') OR (tipoAparcamiento='residencial' AND tarifaCoche=null AND tarifaMoto=null AND tarifaAutocaravana=null)),
	CONSTRAINT noDisuasorioSiResidencial CHECK (disuasorio=FALSE OR (disuasorio=TRUE AND tipoAparcamiento<>'residencial')),
	CONSTRAINT numPlazasNegativo CHECK (numeroPlazas>0),
	CONSTRAINT tarifaCocheNoNegativas CHECK (tarifaCoche=null OR tarifaCoche>=0),
	CONSTRAINT tarifaMotoNoNegativas CHECK (tarifaMoto=null OR tarifaCoche>=0),
	CONSTRAINT tarifaAutocaravanaNoNegativas CHECK (tarifaAutocaravana=null OR tarifaCoche>=0)
	/*CREATE ASSERTION gestorNoPuedeSerCliente
	CHECK( CIF<>(SELECT SNA.DNI
			FROM SolicitudNoAbonada SNA)
		AND CIF<>(SELECT SC.DNI
			FROM SolicitudCesion SC)
		AND CIF<>(SELECT RS.DNI
			FROM ReclamacionSugerencia RS)
	);*/
);

/*
CREATE ASSERTION tarifasMaximasTurismo
	CHECK((SELECT T.tarifaTurismo FROM TarifasMaximas T ) >= (SELECT A.tarifaCoche FROM Aparcamiento A));
CREATE ASSERTION tarifasMaximasMoto
	CHECK((SELECT T.tarifaMoto FROM TarifasMaximas T ) >= (SELECT A.tarifaMoto FROM Aparcamiento A));
CREATE ASSERTION tarifasMaximasAutocaravana
	CHECK((SELECT T.tarifaAutocaravana FROM TarifasMaximas T ) >= (SELECT A.tarifaAutocaravana FROM Aparcamiento A)); */




CREATE TABLE PlazaRotacional (
	numeroPlaza INTEGER,
	codigoAparcamiento CHAR(50),
	operativa BOOLEAN not null,
	movilidadReducida BOOLEAN not null,
	plazaMoto BOOLEAN not null,
	servicioComplementario BOOLEAN not null,
	tipoServicio CHAR(50),
	PRIMARY KEY (numeroPlaza, codigoAparcamiento),
	FOREIGN KEY (codigoAparcamiento)
		REFERENCES Aparcamiento (codigoAparcamiento),
	CONSTRAINT numPlazaRotacional  CHECK (numeroPlaza>=0),
	CONSTRAINT plazasServicio CHECK ((servicioComplementario=FALSE AND tipoServicio=null) OR (servicioComplementario=TRUE AND tipoServicio<>null)),
	CONSTRAINT siMovilidadReducidaNoServicio CHECK (servicioComplementario=FALSE OR (servicioComplementario=TRUE AND movilidadReducida=FALSE)),
	CONSTRAINT siMovilidadReducidaNoMoto CHECK (movilidadReducida=FALSE OR (movilidadReducida=TRUE AND plazaMoto=FALSE)),
	CONSTRAINT siMotoNoServicio CHECK (plazaMoto=FALSE OR (plazaMoto=TRUE AND servicioComplementario=FALSE))
);

CREATE TABLE PlazaResidencial (
	numeroPlaza INTEGER,
	codigoAparcamiento CHAR(50),
	plazaElectrica BOOLEAN not null,
	cuotaElectricidad REAL,
	operativa BOOLEAN not null,
	movilidadReducida BOOLEAN not null,
	plazaMoto BOOLEAN not null,
	PRIMARY KEY (numeroPlaza, codigoAparcamiento),
	FOREIGN KEY (codigoAparcamiento)
		REFERENCES Aparcamiento (codigoAparcamiento),
	CONSTRAINT dineroNoNegativo CHECK (cuotaElectricidad>=0 OR cuotaElectricidad=null),
	CONSTRAINT numPlazaResidencial  CHECK (numeroPlaza>=0),
	CONSTRAINT plazasElectricas CHECK ((plazaElectrica=FALSE AND cuotaElectricidad=null) OR (plazaElectrica=TRUE AND cuotaElectricidad<>null))

);



CREATE TABLE SolicitudNoAbonada (
	numeroSolicitudAbono CHAR(50),
	fechaEmision DATE not null,
	aceptada BOOLEAN not null,
	tipoAbono CHAR(50) not null,
	DNIoCIF CHAR(50),
	codigoAparcamiento CHAR(50),
	PRIMARY KEY (numeroSolicitudAbono),
	FOREIGN KEY (DNIoCIF)
		REFERENCES Persona (DNIoCIF),
	FOREIGN KEY (codigoAparcamiento)
		REFERENCES Aparcamiento (codigoAparcamiento),
	CONSTRAINT fechaCoherenteEmision CHECK (fechaEmision>'1970-01-01')

);

CREATE TABLE Abono (
	numeroSolicitudAbono CHAR(50),
	fechaUltimoPago DATE,
	importe REAL not null,
	mensualidad BOOLEAN not null,
	fechaAceptacion DATE not null,
	fechaCaducidad DATE not null,
	codigoAparcamiento CHAR(50),
	tipoSinReserva tipoSinReserva,
	PRIMARY KEY (numeroSolicitudAbono),
	FOREIGN KEY (numeroSolicitudAbono)
		REFERENCES SolicitudNoAbonada (numeroSolicitudAbono),
	FOREIGN KEY (codigoAparcamiento)
		REFERENCES Aparcamiento (codigoAparcamiento),
	CONSTRAINT fechaCoherenteUltimoPago CHECK (fechaUltimoPago>'1970-01-01'),
	CONSTRAINT fechaCoherenteAceptacion CHECK (fechaAceptacion>'1970-01-01'),
	CONSTRAINT fechaCoherenteCaducidad CHECK (fechaCaducidad>fechaAceptacion)


);

CREATE TABLE AbonoReserva (
	numeroSolicitudAbono CHAR(50),
	tipo tipoReserva not null,
	numeroPlaza INTEGER,
	codigoAparcamiento CHAR(50),
	PRIMARY KEY (numeroSolicitudAbono),
	FOREIGN KEY (numeroSolicitudAbono)
		REFERENCES Abono (numeroSolicitudAbono),
	FOREIGN KEY (numeroPlaza,codigoAparcamiento)
		REFERENCES PlazaResidencial (numeroPlaza, codigoAparcamiento)
	/*CREATE ASSERTION vehiculoAbonoSostenible
		CHECK ( NOT EXISTS(SELECT (*)
		FROM Vehiculo V NATURAL JOIN AbonoReserva AR
		WHERE (V.modelo<>'CERO' OR V.modelo<>'ECO') AND AR.tipo='movilidadSostenible'));*/
);

CREATE TABLE Vehiculo (
	matricula CHAR(50),
	modelo CHAR(50),
	categoria categoriaVehiculo,
	movilidadReducida BOOLEAN not null,
	numeroAbono CHAR(50),
	numeroSolicitudAbono CHAR(50),
	PRIMARY KEY (matricula),
	FOREIGN KEY (numeroAbono)
		REFERENCES Abono (numeroSolicitudAbono),
	FOREIGN KEY (numeroSolicitudAbono)
		REFERENCES SolicitudNoAbonada (numeroSolicitudAbono),
	CHECK(numeroAbono=null OR numeroSolicitudAbono=null)
	/*CREATE ASSERTION limiteVehiculos CHECK(
	4>=ALL(SELECT COUNT(*)
		FROM Vehiculo V NATURAL JOIN Abono A
		GROUP BY A.numeroAbono))
	);*/
);


CREATE TABLE EntradaSalida (
	codigo CHAR(50),
	codigoAparcamiento CHAR(50),
	matricula CHAR(50),
	fechaEntrada DATE not null,
	fechaSalida DATE,
	horaEntrada TIME not null,
	horaSalida TIME,
	importe REAL,
	PRIMARY KEY (codigo),
	FOREIGN KEY (codigoAparcamiento)
		REFERENCES Aparcamiento (codigoAparcamiento),
	FOREIGN KEY (matricula)
		REFERENCES Vehiculo (matricula),
	CONSTRAINT fechaCoherenteEntrada CHECK (fechaEntrada>'1970-01-01'),
	CONSTRAINT fechaCoherenteSalida CHECK (fechaSalida>'1970-01-01'),
	CONSTRAINT horaCoherente CHECK (fechaSalida<>fechaEntrada OR (fechaSalida=fechaEntrada AND horaSalida>horaEntrada)),
	CONSTRAINT fechaCoherenteEntradaSalida CHECK (fechaSalida>=fechaEntrada),
	CONSTRAINT importeNoNegativo CHECK (importe=null OR importe>=0)

);

CREATE TABLE ReclamacionSugerencia (
	DNIoCIF CHAR(50),
	numeroReclamacion CHAR(50),
	texto CHAR(250) not null,
	PRIMARY KEY (numeroReclamacion),
	FOREIGN KEY (DNIoCIF)
		REFERENCES Persona (DNIoCIF)
);

CREATE TABLE SolicitudCesion (
	numeroSolicitudCesion CHAR(50),
	numeroSolicitudAbono CHAR(50),
	fechaEmision DATE not null,
	motivo CHAR(250) not null,
	DNI CHAR(50),
	fechaAceptacion DATE,
	PRIMARY KEY (numeroSolicitudCesion),
	FOREIGN KEY (numeroSolicitudAbono)
		REFERENCES Abono (numeroSolicitudAbono),
	FOREIGN KEY (DNI)
		REFERENCES Persona (DNIoCIF),
	CONSTRAINT fechaCoherenteEmision CHECK (fechaEmision>'1970-01-01')
	/*CREATE ASSERTION cesionANuevaPersona
	CHECK( (SELECT SNA.DNI
	FROM SolicitudCesion SC, SolicitudNoAbonada SNA,
	WHERE SC.numeroSolicitudAbono=SNA.numeroSolicitudAbono)
	 <> DNI);*/
);


INSERT INTO TarifasMaximas VALUES ( 5,6,7);

INSERT INTO Persona VALUES ('Pedro','12345678A','Calle calle');
INSERT INTO Persona VALUES('Laura','87654321B','Avenida avenida');
INSERT INTO Persona VALUES('AparcamientosSA','A12345678','Calle otraCalle');
INSERT INTO Persona VALUES('AparcamientoEmpresa','A99999999','Calle otraCalle');

INSERT INTO Aparcamiento VALUES ('A99999999','Aparc1','1','residencial',100,FALSE,null,null,null);
INSERT INTO Aparcamiento VALUES('A12345678','Aparc2','2','rotacional',200,TRUE,4,3,2);
INSERT INTO Aparcamiento VALUES('A99999999','Aparc3','3','mixto',300,FALSE,2,3,4);

INSERT INTO PlazaRotacional VALUES (10,'2',TRUE,FALSE,FALSE,FALSE,null);
INSERT INTO PlazaRotacional VALUES(20,'3',TRUE,FALSE,FALSE,TRUE,'Servicio de Limpieza');
INSERT INTO PlazaRotacional VALUES(30,'3',FALSE,TRUE,FALSE,FALSE,null);

INSERT INTO PlazaResidencial VALUES (10,'1',TRUE,1,TRUE,FALSE,TRUE);
INSERT INTO PlazaResidencial VALUES (20,'1',TRUE,2,TRUE,FALSE,FALSE);
INSERT INTO PlazaResidencial VALUES (30,'1',FALSE,null,TRUE,TRUE,FALSE);

INSERT INTO SolicitudNoAbonada VALUES ('1000','1-1-2019',TRUE, 'con Reserva Residente','12345678A','1');
INSERT INTO SolicitudNoAbonada VALUES ('2000','2-2-2019',TRUE, 'sin Reserva','87654321B','3');
INSERT INTO SolicitudNoAbonada VALUES ('3000','3-3-2019',FALSE, 'con Reserva Residente','12345678A','1');

INSERT INTO Abono VALUES ('1000','1-2-2019',5,TRUE,'1-2-2019','1-1-2020','1', null);
INSERT INTO Abono VALUES ('2000','1-2-2019',5,TRUE,'1-2-2019','1-1-2020','1', 'diurno');

INSERT INTO AbonoReserva VALUES ('1000', '24h', 10, '1');

INSERT INTO SolicitudCesion VALUES ('100','1000','1-3-2019','fallecimiento','12345678A', null);

INSERT INTO Vehiculo VALUES ('1111AAA',null,null,TRUE,null,null);
INSERT INTO Vehiculo VALUES ('2222BBB','A4','B',FALSE,null,'1000');
INSERT INTO Vehiculo VALUES ('2222BBC','A4','B',FALSE,'1000',null);

INSERT INTO EntradaSalida VALUES ('999','3','1111AAA','4-4-2019','5-4-2019','01:02:03','02:02:04',6);
INSERT INTO EntradaSalida VALUES ('998','3','1111AAA','6-7-2019','7-7-2019','10:02:30','11:02:40',null);


INSERT INTO ReclamacionSugerencia VALUES('12345678A' ,'555','Goteras en la plaza 100');



/*
Obtener los números de las solicitudes de abono de los abonos sin reserva de tipo diurno:  
SELECT A.NumeroSolicitudAbono 
FROM Abono A 
WHERE A.tipoSinReserva = 'diurno'; 

Obtener el código identificativo de los registros de Entrada/Salida que hayan sido realizados con carácter rotacional (tienen un ticket con un importe): 
SELECT E.codigo 
FROM EntradaSalida E, Vehiculo V 
WHERE E.matricula=V.matricula AND E.importe is not null;
*/