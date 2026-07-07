DROP SCHEMA IF EXISTS SEGURO_G28310422 CASCADE;
CREATE SCHEMA IF NOT EXISTS SEGURO_G28310422;
SET search_path TO SEGURO_G28310422;

-- 1. Crear tabla PAIS
CREATE TABLE PAIS (
    cod_pais INT PRIMARY KEY,
    nb_pais VARCHAR(100) NOT NULL
);

-- 2. Crear tabla CIUDAD
CREATE TABLE CIUDAD (
    cod_ciudad INT PRIMARY KEY,
    nb_ciudad VARCHAR(100) NOT NULL,
    cod_pais INT,
    CONSTRAINT FK_CIUDAD_PAIS FOREIGN KEY (cod_pais) REFERENCES PAIS(cod_pais)
);

-- 3. Crear tabla SUCURSAL
CREATE TABLE SUCURSAL (
    cod_sucursal INT PRIMARY KEY,
    nb_sucursal VARCHAR(100) NOT NULL, -- Ej. de nb_sucursal : Sucursal Caracas, Sucursal Zulia, Sucursal Guayana, entre otras.
    cod_ciudad INT,
    CONSTRAINT FK_SUCURSAL_CIUDAD FOREIGN KEY (cod_ciudad) REFERENCES CIUDAD(cod_ciudad)
);

-- 4. Crear tabla TIPO_PRODUCTO
CREATE TABLE TIPO_PRODUCTO (
    cod_tipo_producto INT PRIMARY KEY,
    nb_tipo_producto VARCHAR(100) NOT NULL, -- Los tipos de producto pueden ser: Prestación de Servicios, Personales, Daños o Patrimoniales
    CONSTRAINT CHK_TIPO_PRODUCTO CHECK (nb_tipo_producto IN ('Prestación de Servicios', 'Personales', 'Daños', 'Patrimoniales'))
);

-- 5. Crear tabla PRODUCTO
CREATE TABLE PRODUCTO (
    cod_producto INT PRIMARY KEY,
    nb_producto VARCHAR(100) NOT NULL, -- Los nb_producto pueden ser: Automóvil, Crédito y Caución, Incendios, Salud, entre otros.
    descripcion TEXT,
    cod_tipo_producto INT,
    calificacion VARCHAR(50),
    CONSTRAINT FK_PRODUCTO_TIPO FOREIGN KEY (cod_tipo_producto) REFERENCES TIPO_PRODUCTO(cod_tipo_producto)
);

-- 6. Crear tabla CLIENTE
CREATE TABLE CLIENTE (
    cod_cliente INT PRIMARY KEY,
    nb_cliente VARCHAR(150) NOT NULL,
    ci_rif VARCHAR(20) NOT NULL, -- ci_rif/Cedula
    telefono VARCHAR(20),
    direccion TEXT,
    sexo CHAR(1), -- sexo
    email VARCHAR(100),
    cod_sucursal INT,
    CONSTRAINT FK_CLIENTE_SUCURSAL FOREIGN KEY (cod_sucursal) REFERENCES SUCURSAL(cod_sucursal),
    CONSTRAINT CHK_CLIENTE_SEXO CHECK (sexo IN ('M', 'F'))
);

-- 7. Crear tabla EVALUACION_SERVICIO
CREATE TABLE EVALUACION_SERVICIO (
    cod_evaluacion_servicio INT PRIMARY KEY,
    nb_descripcion VARCHAR(50) NOT NULL, -- (1.- Malo/2.-Regular/3.-Bueno, 4.-Muy Bueno, 5.-Excelente)
    CONSTRAINT CHK_EVALUACION_RANGO CHECK (cod_evaluacion_servicio BETWEEN 1 AND 5),
    CONSTRAINT CHK_EVALUACION_DESC CHECK (nb_descripcion IN ('Malo', 'Regular', 'Bueno', 'Muy Bueno', 'Excelente'))
);

-- 8. Crear tabla RECOMIENDA
CREATE TABLE RECOMIENDA (
    cod_cliente INT,
    cod_evaluacion_servicio INT,
    cod_producto INT,
    recomienda_amigo VARCHAR(2), -- recomienda_amigo (Si/No)
    PRIMARY KEY (cod_cliente, cod_evaluacion_servicio, cod_producto),
    CONSTRAINT FK_RECOMIENDA_CLIENTE FOREIGN KEY (cod_cliente) REFERENCES CLIENTE(cod_cliente),
    CONSTRAINT FK_RECOMIENDA_EVALUACION FOREIGN KEY (cod_evaluacion_servicio) REFERENCES EVALUACION_SERVICIO(cod_evaluacion_servicio),
    CONSTRAINT FK_RECOMIENDA_PRODUCTO FOREIGN KEY (cod_producto) REFERENCES PRODUCTO(cod_producto),
    CONSTRAINT CHK_RECOMIENDA_AMIGO CHECK (recomienda_amigo IN ('SI', 'NO'))
);

-- 9. Crear tabla CONTRATO
CREATE TABLE CONTRATO (
    nro_contrato INT PRIMARY KEY,
    descrip_contrato TEXT
);

-- 10. Crear tabla REGISTRO_CONTRATO
CREATE TABLE REGISTRO_CONTRATO (
    nro_contrato INT,
    cod_producto INT,
    cod_cliente INT,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    monto DECIMAL(14, 2) NOT NULL,
    estado_contrato VARCHAR(20), -- El estado del contrato por producto puede ser: activo, vencido, suspendido.
    PRIMARY KEY (nro_contrato, cod_producto, cod_cliente),
    CONSTRAINT FK_REGISTRO_CONTRATO FOREIGN KEY (nro_contrato) REFERENCES CONTRATO(nro_contrato),
    CONSTRAINT FK_REGISTRO_PRODUCTO FOREIGN KEY (cod_producto) REFERENCES PRODUCTO(cod_producto),
    CONSTRAINT FK_REGISTRO_CLIENTE FOREIGN KEY (cod_cliente) REFERENCES CLIENTE(cod_cliente),
    CONSTRAINT CHK_ESTADO_CONTRATO CHECK (estado_contrato IN ('activo', 'vencido', 'suspendido')),
    CONSTRAINT CHK_FECHAS_CONTRATO CHECK (fecha_fin >= fecha_inicio)
);

-- 11. Crear tabla SINIESTRO
CREATE TABLE SINIESTRO (
    nro_siniestro INT PRIMARY KEY,
    descripcion_siniestro TEXT
);

-- 12. Crear tabla REGISTRO_SINIESTRO
CREATE TABLE REGISTRO_SINIESTRO (
    nro_siniestro INT PRIMARY KEY,
    nro_contrato INT,
    fecha_siniestro DATE NOT NULL,
    fecha_respuesta DATE,
    id_rechazo CHAR(2), -- id_rechazo (SI/NO)
    monto_reconocido DECIMAL(14, 2),
    monto_solicitado DECIMAL(14, 2) NOT NULL,
    CONSTRAINT FK_REGISTRO_SINIESTRO_BASE FOREIGN KEY (nro_siniestro) REFERENCES SINIESTRO(nro_siniestro),
    CONSTRAINT FK_REGISTRO_SINIESTRO_CONTRATO FOREIGN KEY (nro_contrato) REFERENCES CONTRATO(nro_contrato),
    CONSTRAINT CHK_SINIESTRO_RECHAZO CHECK (id_rechazo IN ('SI', 'NO')),
    CONSTRAINT CHK_FECHAS_SINIESTRO CHECK (fecha_respuesta >= fecha_siniestro)
);