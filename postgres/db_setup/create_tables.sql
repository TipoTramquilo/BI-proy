-- ============================================================================
--                                         RELACIONAL
-- ============================================================================


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
    cod_pais INT NOT NULL,
    CONSTRAINT FK_CIUDAD_PAIS FOREIGN KEY (cod_pais) REFERENCES PAIS(cod_pais)
);

-- 3. Crear tabla SUCURSAL
CREATE TABLE SUCURSAL (
    cod_sucursal INT PRIMARY KEY,
    nb_sucursal VARCHAR(100) NOT NULL,
    cod_ciudad INT NOT NULL,
    CONSTRAINT FK_SUCURSAL_CIUDAD FOREIGN KEY (cod_ciudad) REFERENCES CIUDAD(cod_ciudad)
);

-- 4. Crear tabla TIPO_PRODUCTO
CREATE TABLE TIPO_PRODUCTO (
    cod_tipo_producto INT PRIMARY KEY,
    nb_tipo_producto VARCHAR(100) NOT NULL,
    CONSTRAINT CHK_TIPO_PRODUCTO CHECK (nb_tipo_producto IN ('Prestación de Servicios', 'Personales', 'Daños', 'Patrimoniales'))
);

-- 5. Crear tabla PRODUCTO
CREATE TABLE PRODUCTO (
    cod_producto INT PRIMARY KEY,
    nb_producto VARCHAR(100) NOT NULL,
    cod_tipo_producto INT NOT NULL,
    calificacion VARCHAR(50),
    descripcion TEXT,
    CONSTRAINT FK_PRODUCTO_TIPO FOREIGN KEY (cod_tipo_producto) REFERENCES TIPO_PRODUCTO(cod_tipo_producto)
);

-- 6. Crear tabla CLIENTE
CREATE TABLE CLIENTE (
    cod_cliente INT PRIMARY KEY,
    cod_sucursal INT NOT NULL,
    nb_cliente VARCHAR(150) NOT NULL,
    ci_rif VARCHAR(20) NOT NULL,
    telefono VARCHAR(20),
    direccion TEXT,
    sexo CHAR(1),
    email VARCHAR(100),
    CONSTRAINT FK_CLIENTE_SUCURSAL FOREIGN KEY (cod_sucursal) REFERENCES SUCURSAL(cod_sucursal),
    CONSTRAINT CHK_CLIENTE_SEXO CHECK (sexo IN ('M', 'F'))
);

-- 7. Crear tabla EVALUACION_SERVICIO
CREATE TABLE EVALUACION_SERVICIO (
    cod_evaluacion_servicio INT PRIMARY KEY,
    nb_descripcion VARCHAR(50) NOT NULL,
    CONSTRAINT CHK_EVALUACION_RANGO CHECK (cod_evaluacion_servicio BETWEEN 1 AND 5),
    CONSTRAINT CHK_EVALUACION_DESC CHECK (nb_descripcion IN ('Malo', 'Regular', 'Bueno', 'Muy Bueno', 'Excelente'))
);

-- 8. Crear tabla RECOMIENDA
CREATE TABLE RECOMIENDA (
    cod_cliente INT,
    cod_evaluacion_servicio INT,
    cod_producto INT,
    recomienda_amigo VARCHAR(2),
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
    estado_contrato VARCHAR(20),
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
    nro_siniestro INT,
    nro_contrato INT,
    fecha_siniestro DATE NOT NULL,
    fecha_respuesta DATE,
    id_rechazo CHAR(2),
    monto_reconocido DECIMAL(14, 2),
    monto_solicitado DECIMAL(14, 2) NOT NULL,
    PRIMARY KEY (nro_siniestro, nro_contrato, fecha_siniestro),
    CONSTRAINT FK_REGISTRO_SINIESTRO_BASE FOREIGN KEY (nro_siniestro) REFERENCES SINIESTRO(nro_siniestro),
    CONSTRAINT FK_REGISTRO_SINIESTRO_CONTRATO FOREIGN KEY (nro_contrato) REFERENCES CONTRATO(nro_contrato),
    CONSTRAINT CHK_SINIESTRO_RECHAZO CHECK (id_rechazo IN ('SI', 'NO')),
    CONSTRAINT CHK_FECHAS_SINIESTRO CHECK (fecha_respuesta >= fecha_siniestro)
);

-- ============================================================================
--                                         DW
--  Si el schema del Data Warehouse ya existe, se borrara con CASCADE
-- ============================================================================

drop schema if exists seguro_dw_g28310422 cascade;
create schema if not exists seguro_dw_g28310422;
set search_path to seguro_dw_g28310422;

-- ============================================================================
-- 1. CREACIÓN DE LAS DIMENSIONES CONFORMADAS
-- ============================================================================

-- dimensión tiempo
create table DIM_TIEMPO (
    sk_dim_tiempo int primary key,
    cod_annio int not null,
    cod_mes int not null,
    cod_dia int not null,
    desc_mes varchar(20) not null,
    desc_trimestre varchar(10) not null,
    desc_semestre varchar(10) not null,
    fecha_completa date not null -- obligatorio según requerimiento del negocio
);

-- dimensión cliente
create table DIM_CLIENTE (
    sk_dim_cliente serial primary key,
    cod_cliente int not null, -- nk numérico sincronizado con el origen transaccional
    nb_cliente varchar(150) not null,
    ci_rif varchar(45) not null,
    telefono varchar(45),
    direccion varchar(150),
    sexo char(1),
    email varchar(100),
    constraint chk_dim_cliente_sexo check (sexo in ('M', 'F'))
);

-- dimensión producto
create table DIM_PRODUCTO (
    sk_dim_producto serial primary key,
    cod_producto int not null, -- nk numérico
    nb_producto varchar(100) not null,
    descrip_producto varchar(255),
    cod_tipo_producto int,
    nb_tipo_producto varchar(100),
    calificacion int
);

-- dimensión contrato
create table DIM_CONTRATO (
    sk_dim_contrato serial primary key,
    nro_contrato int not null, -- nk numérico
    descrip_contrato varchar(255)
);

-- dimensión sucursal
create table DIM_SUCURSAL (
    sk_dim_sucursal serial primary key,
    cod_sucursal int not null, -- nk numérico
    nb_sucursal varchar(100) not null,
    cod_ciudad int,
    nb_ciudad varchar(100),
    cod_pais int,
    nb_pais varchar(100)
);

-- dimensión estado contrato
create table DIM_ESTADO_CONTRATO (
    sk_dim_estado_contrato serial primary key,
    cod_estado varchar(20) not null,
    descrip_estado varchar(50)
);

-- dimensión evaluacion servicio
create table DIM_EVALUACION_SERVICIO (
    sk_dim_evaluacion_servicio serial primary key,
    cod_evaluacion int not null, -- nk numérico
    nb_descrip varchar(50) not null
);

-- dimensión siniestro
create table DIM_SINIESTRO (
    sk_dim_siniestro serial primary key,
    nro_siniestro int not null, -- nk numérico
    descrip_siniestro varchar(255)
);


-- ============================================================================
-- 2. CREACIÓN DE LAS TABLAS DE HECHOS (CON JUSTIFICACIÓN TÉCNICA)
-- ============================================================================

-- fact_registro_contrato
create table FACT_REGISTRO_CONTRATO (
    -- pk propia: evita un índice compuesto pesado de 6 columnas, mejorando el rendimiento de carga (etl) y facilitando relaciones en herramientas bi.
    sk_fact_registro_contrato serial primary key, 
    sk_dim_tiempo_fecha_inicio int not null,
    sk_dim_tiempo_fecha_fin int not null,
    sk_dim_cliente int not null,
    sk_dim_contrato int not null,
    sk_dim_producto int not null,
    sk_dim_estado_contrato int not null,
    monto real,
    cantidad int default 1,
    cantidad_cliente int,
    cantidad_producto int,
    cantidad_contrato int,
    constraint fk_fact_contrato_inicio foreign key (sk_dim_tiempo_fecha_inicio) references DIM_TIEMPO(sk_dim_tiempo),
    constraint fk_fact_contrato_fin foreign key (sk_dim_tiempo_fecha_fin) references DIM_TIEMPO(sk_dim_tiempo),
    constraint fk_fact_contrato_cliente foreign key (sk_dim_cliente) references DIM_CLIENTE(sk_dim_cliente),
    constraint fk_fact_contrato_contrato foreign key (sk_dim_contrato) references DIM_CONTRATO(sk_dim_contrato),
    constraint fk_fact_contrato_producto foreign key (sk_dim_producto) references DIM_PRODUCTO(sk_dim_producto),
    constraint fk_fact_contrato_estado foreign key (sk_dim_estado_contrato) references DIM_ESTADO_CONTRATO(sk_dim_estado_contrato)
);

-- fact_registro_siniestro
create table FACT_REGISTRO_SINIESTRO (
    -- pk propia: permite registrar siniestros activos/pendientes manteniendo "sk_fecha_respuesta" como opcional (null) sin violar restricciones de clave primaria.
    sk_fact_registro_siniestro serial primary key, 
    sk_fecha_siniestro int not null,
    sk_fecha_respuesta int, -- null permitido mientras el siniestro esté abierto
    sk_dim_cliente int not null,
    sk_dim_contrato int not null,
    sk_dim_sucursal int not null,
    sk_dim_producto int not null,
    sk_dim_siniestro int not null,
    cantidad int default 1,
    monto_reconocido real,
    monto_solicitado real,
    id_rechazo char(2),
    constraint fk_fact_siniestro_fecha foreign key (sk_fecha_siniestro) references DIM_TIEMPO(sk_dim_tiempo),
    constraint fk_fact_siniestro_resp foreign key (sk_fecha_respuesta) references DIM_TIEMPO(sk_dim_tiempo),
    constraint fk_fact_siniestro_cliente foreign key (sk_dim_cliente) references DIM_CLIENTE(sk_dim_cliente),
    constraint fk_fact_siniestro_contrato foreign key (sk_dim_contrato) references DIM_CONTRATO(sk_dim_contrato),
    constraint fk_fact_siniestro_sucursal foreign key (sk_dim_sucursal) references DIM_SUCURSAL(sk_dim_sucursal),
    constraint fk_fact_siniestro_producto foreign key (sk_dim_producto) references DIM_PRODUCTO(sk_dim_producto),
    constraint fk_fact_siniestro_siniestro foreign key (sk_dim_siniestro) references DIM_SINIESTRO(sk_dim_siniestro),
    constraint chk_id_rechazo check (id_rechazo in ('SI', 'NO'))
);

-- fact_evaluacion_servicio
create table FACT_EVALUACION_SERVICIO (
    -- pk propia: permite que un cliente recurrente evalúe y califique el mismo producto en contratos diferentes a lo largo del tiempo (evita la colisión cliente-producto).
    sk_fact_eval_servicio serial primary key, 
    sk_dim_cliente int not null,
    sk_dim_producto int not null,
    sk_dim_evaluacion_servicio int not null,
    cantidad int default 1,
    recomienda_amigo real,
    constraint fk_fact_eval_cliente foreign key (sk_dim_cliente) references DIM_CLIENTE(sk_dim_cliente),
    constraint fk_fact_eval_producto foreign key (sk_dim_producto) references DIM_PRODUCTO(sk_dim_producto),
    constraint fk_fact_eval_eval foreign key (sk_dim_evaluacion_servicio) references DIM_EVALUACION_SERVICIO(sk_dim_evaluacion_servicio)
);

-- fact_metas
create table FACT_METAS (
    -- pk propia: optimiza el proceso de actualización y sobrescritura (upserts) de metas anuales importadas periódicamente desde archivos externos de excel.
    sk_fact_metas serial primary key, 
    sk_dim_fecha_inicio_meta int not null,
    sk_dim_fecha_fin_meta int not null,
    sk_dim_cliente int not null,
    sk_dim_producto int not null,
    sk_dim_contrato int not null,
    monto_meta_ingreso real,
    meta_renovacion int,
    meta_asegurados int,
    constraint fk_fact_metas_inicio foreign key (sk_dim_fecha_inicio_meta) references DIM_TIEMPO(sk_dim_tiempo),
    constraint fk_fact_metas_fin foreign key (sk_dim_fecha_fin_meta) references DIM_TIEMPO(sk_dim_tiempo),
    constraint fk_fact_metas_cliente foreign key (sk_dim_cliente) references DIM_CLIENTE(sk_dim_cliente),
    constraint fk_fact_metas_producto foreign key (sk_dim_producto) references DIM_PRODUCTO(sk_dim_producto),
    constraint fk_fact_metas_contrato foreign key (sk_dim_contrato) references DIM_CONTRATO(sk_dim_contrato)
);