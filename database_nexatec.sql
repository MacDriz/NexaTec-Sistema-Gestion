BEGIN
  EXECUTE IMMEDIATE 'DROP USER NEXATEC CASCADE';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -1918 THEN RAISE; END IF;
END;
/
CREATE USER NEXATEC IDENTIFIED BY "NexaTec2026" DEFAULT TABLESPACE USERS QUOTA UNLIMITED ON USERS;
GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW, CREATE PROCEDURE, CREATE SEQUENCE, CREATE TRIGGER TO NEXATEC;
ALTER SESSION SET CURRENT_SCHEMA = NEXATEC;

CREATE SEQUENCE NEXATEC.SEQ_CLIENTES;
CREATE SEQUENCE NEXATEC.SEQ_CONTACTOS;
CREATE SEQUENCE NEXATEC.SEQ_EMPLEADOS;
CREATE SEQUENCE NEXATEC.SEQ_FABRICANTES;
CREATE SEQUENCE NEXATEC.SEQ_PRODUCTOS;
CREATE SEQUENCE NEXATEC.SEQ_COTIZACIONES;
CREATE SEQUENCE NEXATEC.SEQ_DETALLE_COT;
CREATE SEQUENCE NEXATEC.SEQ_LICENCIAS;
CREATE SEQUENCE NEXATEC.SEQ_RENOVACIONES;
CREATE SEQUENCE NEXATEC.SEQ_TIQUETES;
CREATE SEQUENCE NEXATEC.SEQ_FACTURAS;

CREATE TABLE NEXATEC.CLIENTES (
    cliente_id     NUMBER          CONSTRAINT pk_clientes PRIMARY KEY,
    identificacion VARCHAR2(20)    NOT NULL,
    nombre         VARCHAR2(150)   NOT NULL,
    telefono       VARCHAR2(20),
    correo         VARCHAR2(100),
    direccion      VARCHAR2(250),
    estado         VARCHAR2(10)    DEFAULT 'ACTIVO'
                   CONSTRAINT ck_clientes_estado CHECK (estado IN ('ACTIVO','INACTIVO'))
);

CREATE TABLE NEXATEC.CONTACTOS (
    contacto_id NUMBER        CONSTRAINT pk_contactos PRIMARY KEY,
    cliente_id  NUMBER        NOT NULL,
    nombre      VARCHAR2(150) NOT NULL,
    cargo       VARCHAR2(100),
    telefono    VARCHAR2(20),
    correo      VARCHAR2(100),
    CONSTRAINT fk_contactos_cliente FOREIGN KEY (cliente_id) REFERENCES NEXATEC.CLIENTES(cliente_id)
);

CREATE TABLE NEXATEC.EMPLEADOS (
    empleado_id NUMBER        CONSTRAINT pk_empleados PRIMARY KEY,
    nombre      VARCHAR2(150) NOT NULL,
    correo      VARCHAR2(100),
    rol         VARCHAR2(20)  NOT NULL
                CONSTRAINT ck_empleados_rol CHECK (rol IN ('VENDEDOR','TECNICO','ADMIN')),
    estado      VARCHAR2(10)  DEFAULT 'ACTIVO'
                CONSTRAINT ck_empleados_estado CHECK (estado IN ('ACTIVO','INACTIVO'))
);

CREATE TABLE NEXATEC.FABRICANTES (
    fabricante_id NUMBER        CONSTRAINT pk_fabricantes PRIMARY KEY,
    nombre        VARCHAR2(150) NOT NULL,
    sitio_web     VARCHAR2(200),
    estado        VARCHAR2(10)  DEFAULT 'ACTIVO'
                  CONSTRAINT ck_fabricantes_estado CHECK (estado IN ('ACTIVO','INACTIVO'))
);

CREATE TABLE NEXATEC.PRODUCTOS_SERVICIOS (
    producto_id   NUMBER          CONSTRAINT pk_productos PRIMARY KEY,
    fabricante_id NUMBER,
    codigo        VARCHAR2(50)    NOT NULL,
    nombre        VARCHAR2(200)   NOT NULL,
    tipo          VARCHAR2(20)    NOT NULL
                  CONSTRAINT ck_productos_tipo CHECK (tipo IN ('PRODUCTO','SERVICIO','LICENCIA')),
    descripcion   VARCHAR2(500),
    precio_base   NUMBER(14,2)    NOT NULL,
    estado        VARCHAR2(10)    DEFAULT 'ACTIVO'
                  CONSTRAINT ck_productos_estado CHECK (estado IN ('ACTIVO','INACTIVO')),
    CONSTRAINT fk_productos_fabricante FOREIGN KEY (fabricante_id) REFERENCES NEXATEC.FABRICANTES(fabricante_id)
);

CREATE TABLE NEXATEC.COTIZACIONES (
    cotizacion_id    NUMBER        CONSTRAINT pk_cotizaciones PRIMARY KEY,
    cliente_id       NUMBER        NOT NULL,
    vendedor_id      NUMBER        NOT NULL,
    fecha            DATE          DEFAULT SYSDATE,
    fecha_vencimiento DATE,
    estado           VARCHAR2(20)  DEFAULT 'BORRADOR'
                     CONSTRAINT ck_cot_estado CHECK (estado IN ('BORRADOR','ENVIADA','APROBADA','RECHAZADA','VENCIDA')),
    total            NUMBER(14,2)  DEFAULT 0,
    CONSTRAINT fk_cot_cliente  FOREIGN KEY (cliente_id)  REFERENCES NEXATEC.CLIENTES(cliente_id),
    CONSTRAINT fk_cot_vendedor FOREIGN KEY (vendedor_id) REFERENCES NEXATEC.EMPLEADOS(empleado_id)
);

CREATE TABLE NEXATEC.DETALLE_COTIZACION (
    detalle_id     NUMBER        CONSTRAINT pk_detalle PRIMARY KEY,
    cotizacion_id  NUMBER        NOT NULL,
    producto_id    NUMBER        NOT NULL,
    cantidad       NUMBER(10)    NOT NULL,
    precio_unitario NUMBER(14,2) NOT NULL,
    descuento      NUMBER(5,2)   DEFAULT 0,
    subtotal       NUMBER(14,2),
    CONSTRAINT fk_det_cotizacion FOREIGN KEY (cotizacion_id) REFERENCES NEXATEC.COTIZACIONES(cotizacion_id),
    CONSTRAINT fk_det_producto   FOREIGN KEY (producto_id)   REFERENCES NEXATEC.PRODUCTOS_SERVICIOS(producto_id)
);

CREATE TABLE NEXATEC.LICENCIAS (
    licencia_id       NUMBER        CONSTRAINT pk_licencias PRIMARY KEY,
    cliente_id        NUMBER        NOT NULL,
    producto_id       NUMBER        NOT NULL,
    detalle_id        NUMBER,
    referencia        VARCHAR2(100),
    fecha_inicio      DATE          NOT NULL,
    fecha_vencimiento DATE          NOT NULL,
    estado            VARCHAR2(20)  DEFAULT 'ACTIVA'
                      CONSTRAINT ck_lic_estado CHECK (estado IN ('ACTIVA','VENCIDA','CANCELADA','POR_VENCER')),
    CONSTRAINT fk_lic_cliente   FOREIGN KEY (cliente_id)  REFERENCES NEXATEC.CLIENTES(cliente_id),
    CONSTRAINT fk_lic_producto  FOREIGN KEY (producto_id) REFERENCES NEXATEC.PRODUCTOS_SERVICIOS(producto_id),
    CONSTRAINT fk_lic_detalle   FOREIGN KEY (detalle_id)  REFERENCES NEXATEC.DETALLE_COTIZACION(detalle_id)
);

CREATE TABLE NEXATEC.RENOVACIONES (
    renovacion_id             NUMBER        CONSTRAINT pk_renovaciones PRIMARY KEY,
    licencia_id               NUMBER        NOT NULL,
    fecha_renovacion          DATE          DEFAULT SYSDATE,
    fecha_vencimiento_anterior DATE,
    nueva_fecha_vencimiento   DATE,
    estado                    VARCHAR2(20)  DEFAULT 'COMPLETADA'
                              CONSTRAINT ck_ren_estado CHECK (estado IN ('PENDIENTE','COMPLETADA','CANCELADA')),
    CONSTRAINT fk_ren_licencia FOREIGN KEY (licencia_id) REFERENCES NEXATEC.LICENCIAS(licencia_id)
);

CREATE TABLE NEXATEC.TIQUETES (
    tiquete_id    NUMBER        CONSTRAINT pk_tiquetes PRIMARY KEY,
    cliente_id    NUMBER        NOT NULL,
    contacto_id   NUMBER,
    tecnico_id    NUMBER,
    fecha_apertura DATE         DEFAULT SYSDATE,
    prioridad     VARCHAR2(10)  DEFAULT 'MEDIA'
                  CONSTRAINT ck_tiq_prioridad CHECK (prioridad IN ('BAJA','MEDIA','ALTA','CRITICA')),
    estado        VARCHAR2(20)  DEFAULT 'ABIERTO'
                  CONSTRAINT ck_tiq_estado CHECK (estado IN ('ABIERTO','EN_PROCESO','RESUELTO','CERRADO')),
    asunto        VARCHAR2(250) NOT NULL,
    descripcion   VARCHAR2(2000),
    fecha_cierre  DATE,
    CONSTRAINT fk_tiq_cliente   FOREIGN KEY (cliente_id)  REFERENCES NEXATEC.CLIENTES(cliente_id),
    CONSTRAINT fk_tiq_contacto  FOREIGN KEY (contacto_id) REFERENCES NEXATEC.CONTACTOS(contacto_id),
    CONSTRAINT fk_tiq_tecnico   FOREIGN KEY (tecnico_id)  REFERENCES NEXATEC.EMPLEADOS(empleado_id)
);

CREATE TABLE NEXATEC.FACTURAS (
    factura_id       NUMBER        CONSTRAINT pk_facturas PRIMARY KEY,
    cliente_id       NUMBER        NOT NULL,
    cotizacion_id    NUMBER,
    numero_factura   VARCHAR2(30)  NOT NULL,
    fecha_emision    DATE          DEFAULT SYSDATE,
    fecha_vencimiento DATE,
    total            NUMBER(14,2)  NOT NULL,
    estado_pago      VARCHAR2(20)  DEFAULT 'PENDIENTE'
                     CONSTRAINT ck_fac_estado CHECK (estado_pago IN ('PENDIENTE','PAGADA','VENCIDA','ANULADA')),
    CONSTRAINT fk_fac_cliente      FOREIGN KEY (cliente_id)    REFERENCES NEXATEC.CLIENTES(cliente_id),
    CONSTRAINT fk_fac_cotizacion   FOREIGN KEY (cotizacion_id) REFERENCES NEXATEC.COTIZACIONES(cotizacion_id)
);

-- CLIENTES
CREATE OR REPLACE PACKAGE NEXATEC.P_CLIENTES AS
  PROCEDURE crear(, p_id OUT NUMBER);
  PROCEDURE listar(p_resultado OUT SYS_REFCURSOR);
  PROCEDURE obtener(p_id IN NUMBER, p_resultado OUT SYS_REFCURSOR);
  PROCEDURE actualizar(p_id IN NUMBER, );
  PROCEDURE eliminar(p_id IN NUMBER);
END;
/
CREATE OR REPLACE PACKAGE BODY NEXATEC.P_CLIENTES AS
  PROCEDURE crear(, p_id OUT NUMBER) AS
  BEGIN
    p_id := NEXATEC.SEQ_CLIENTES.NEXTVAL;
    INSERT INTO NEXATEC.CLIENTES (cliente_id)
    VALUES (p_id);
  END;
  PROCEDURE listar(p_resultado OUT SYS_REFCURSOR) AS
  BEGIN
    OPEN p_resultado FOR SELECT * FROM NEXATEC.CLIENTES ORDER BY cliente_id;
  END;
  PROCEDURE obtener(p_id IN NUMBER, p_resultado OUT SYS_REFCURSOR) AS
  BEGIN
    OPEN p_resultado FOR SELECT * FROM NEXATEC.CLIENTES WHERE cliente_id = p_id;
  END;
  PROCEDURE actualizar(p_id IN NUMBER, ) AS
  BEGIN
    UPDATE NEXATEC.CLIENTES SET
      
    WHERE cliente_id = p_id;
    IF SQL%ROWCOUNT = 0 THEN RAISE_APPLICATION_ERROR(-20001, 'Registro no encontrado'); END IF;
  END;
  PROCEDURE eliminar(p_id IN NUMBER) AS
  BEGIN
    DELETE FROM NEXATEC.CLIENTES WHERE cliente_id = p_id;
    IF SQL%ROWCOUNT = 0 THEN RAISE_APPLICATION_ERROR(-20001, 'Registro no encontrado'); END IF;
  END;
END P_CLIENTES;
/

-- CONTACTOS
CREATE OR REPLACE PACKAGE NEXATEC.P_CONTACTOS AS
  PROCEDURE crear(p_cliente_id IN NUMBER, p_id OUT NUMBER);
  PROCEDURE listar(p_resultado OUT SYS_REFCURSOR);
  PROCEDURE obtener(p_id IN NUMBER, p_resultado OUT SYS_REFCURSOR);
  PROCEDURE actualizar(p_id IN NUMBER, p_cliente_id IN NUMBER);
  PROCEDURE eliminar(p_id IN NUMBER);
END;
/
CREATE OR REPLACE PACKAGE BODY NEXATEC.P_CONTACTOS AS
  PROCEDURE crear(p_cliente_id IN NUMBER, p_id OUT NUMBER) AS
  BEGIN
    p_id := NEXATEC.SEQ_CONTACTOS.NEXTVAL;
    INSERT INTO NEXATEC.CONTACTOS (contacto_id, cliente_id)
    VALUES (p_id, p_cliente_id);
  END;
  PROCEDURE listar(p_resultado OUT SYS_REFCURSOR) AS
  BEGIN
    OPEN p_resultado FOR SELECT * FROM NEXATEC.CONTACTOS ORDER BY contacto_id;
  END;
  PROCEDURE obtener(p_id IN NUMBER, p_resultado OUT SYS_REFCURSOR) AS
  BEGIN
    OPEN p_resultado FOR SELECT * FROM NEXATEC.CONTACTOS WHERE contacto_id = p_id;
  END;
  PROCEDURE actualizar(p_id IN NUMBER, p_cliente_id IN NUMBER) AS
  BEGIN
    UPDATE NEXATEC.CONTACTOS SET
      cliente_id = p_cliente_id
    WHERE contacto_id = p_id;
    IF SQL%ROWCOUNT = 0 THEN RAISE_APPLICATION_ERROR(-20001, 'Registro no encontrado'); END IF;
  END;
  PROCEDURE eliminar(p_id IN NUMBER) AS
  BEGIN
    DELETE FROM NEXATEC.CONTACTOS WHERE contacto_id = p_id;
    IF SQL%ROWCOUNT = 0 THEN RAISE_APPLICATION_ERROR(-20001, 'Registro no encontrado'); END IF;
  END;
END P_CONTACTOS;
/

-- EMPLEADOS
CREATE OR REPLACE PACKAGE NEXATEC.P_EMPLEADOS AS
  PROCEDURE crear(, p_id OUT NUMBER);
  PROCEDURE listar(p_resultado OUT SYS_REFCURSOR);
  PROCEDURE obtener(p_id IN NUMBER, p_resultado OUT SYS_REFCURSOR);
  PROCEDURE actualizar(p_id IN NUMBER, );
  PROCEDURE eliminar(p_id IN NUMBER);
END;
/
CREATE OR REPLACE PACKAGE BODY NEXATEC.P_EMPLEADOS AS
  PROCEDURE crear(, p_id OUT NUMBER) AS
  BEGIN
    p_id := NEXATEC.SEQ_EMPLEADOS.NEXTVAL;
    INSERT INTO NEXATEC.EMPLEADOS (empleado_id)
    VALUES (p_id);
  END;
  PROCEDURE listar(p_resultado OUT SYS_REFCURSOR) AS
  BEGIN
    OPEN p_resultado FOR SELECT * FROM NEXATEC.EMPLEADOS ORDER BY empleado_id;
  END;
  PROCEDURE obtener(p_id IN NUMBER, p_resultado OUT SYS_REFCURSOR) AS
  BEGIN
    OPEN p_resultado FOR SELECT * FROM NEXATEC.EMPLEADOS WHERE empleado_id = p_id;
  END;
  PROCEDURE actualizar(p_id IN NUMBER, ) AS
  BEGIN
    UPDATE NEXATEC.EMPLEADOS SET
      
    WHERE empleado_id = p_id;
    IF SQL%ROWCOUNT = 0 THEN RAISE_APPLICATION_ERROR(-20001, 'Registro no encontrado'); END IF;
  END;
  PROCEDURE eliminar(p_id IN NUMBER) AS
  BEGIN
    DELETE FROM NEXATEC.EMPLEADOS WHERE empleado_id = p_id;
    IF SQL%ROWCOUNT = 0 THEN RAISE_APPLICATION_ERROR(-20001, 'Registro no encontrado'); END IF;
  END;
END P_EMPLEADOS;
/

-- FABRICANTES
CREATE OR REPLACE PACKAGE NEXATEC.P_FABRICANTES AS
  PROCEDURE crear(, p_id OUT NUMBER);
  PROCEDURE listar(p_resultado OUT SYS_REFCURSOR);
  PROCEDURE obtener(p_id IN NUMBER, p_resultado OUT SYS_REFCURSOR);
  PROCEDURE actualizar(p_id IN NUMBER, );
  PROCEDURE eliminar(p_id IN NUMBER);
END;
/
CREATE OR REPLACE PACKAGE BODY NEXATEC.P_FABRICANTES AS
  PROCEDURE crear(, p_id OUT NUMBER) AS
  BEGIN
    p_id := NEXATEC.SEQ_FABRICANTES.NEXTVAL;
    INSERT INTO NEXATEC.FABRICANTES (fabricante_id)
    VALUES (p_id);
  END;
  PROCEDURE listar(p_resultado OUT SYS_REFCURSOR) AS
  BEGIN
    OPEN p_resultado FOR SELECT * FROM NEXATEC.FABRICANTES ORDER BY fabricante_id;
  END;
  PROCEDURE obtener(p_id IN NUMBER, p_resultado OUT SYS_REFCURSOR) AS
  BEGIN
    OPEN p_resultado FOR SELECT * FROM NEXATEC.FABRICANTES WHERE fabricante_id = p_id;
  END;
  PROCEDURE actualizar(p_id IN NUMBER, ) AS
  BEGIN
    UPDATE NEXATEC.FABRICANTES SET
      
    WHERE fabricante_id = p_id;
    IF SQL%ROWCOUNT = 0 THEN RAISE_APPLICATION_ERROR(-20001, 'Registro no encontrado'); END IF;
  END;
  PROCEDURE eliminar(p_id IN NUMBER) AS
  BEGIN
    DELETE FROM NEXATEC.FABRICANTES WHERE fabricante_id = p_id;
    IF SQL%ROWCOUNT = 0 THEN RAISE_APPLICATION_ERROR(-20001, 'Registro no encontrado'); END IF;
  END;
END P_FABRICANTES;
/

-- PRODUCTOS_SERVICIOS
CREATE OR REPLACE PACKAGE NEXATEC.P_PRODUCTOS_SERVICIOS AS
  PROCEDURE crear(p_fabricante_id IN NUMBER, p_precio_base IN NUMBER, p_id OUT NUMBER);
  PROCEDURE listar(p_resultado OUT SYS_REFCURSOR);
  PROCEDURE obtener(p_id IN NUMBER, p_resultado OUT SYS_REFCURSOR);
  PROCEDURE actualizar(p_id IN NUMBER, p_fabricante_id IN NUMBER, p_precio_base IN NUMBER);
  PROCEDURE eliminar(p_id IN NUMBER);
END;
/
CREATE OR REPLACE PACKAGE BODY NEXATEC.P_PRODUCTOS_SERVICIOS AS
  PROCEDURE crear(p_fabricante_id IN NUMBER, p_precio_base IN NUMBER, p_id OUT NUMBER) AS
  BEGIN
    p_id := NEXATEC.SEQ_PRODUCTOS.NEXTVAL;
    INSERT INTO NEXATEC.PRODUCTOS_SERVICIOS (producto_id, fabricante_id, precio_base)
    VALUES (p_id, p_fabricante_id, p_precio_base);
  END;
  PROCEDURE listar(p_resultado OUT SYS_REFCURSOR) AS
  BEGIN
    OPEN p_resultado FOR SELECT * FROM NEXATEC.PRODUCTOS_SERVICIOS ORDER BY producto_id;
  END;
  PROCEDURE obtener(p_id IN NUMBER, p_resultado OUT SYS_REFCURSOR) AS
  BEGIN
    OPEN p_resultado FOR SELECT * FROM NEXATEC.PRODUCTOS_SERVICIOS WHERE producto_id = p_id;
  END;
  PROCEDURE actualizar(p_id IN NUMBER, p_fabricante_id IN NUMBER, p_precio_base IN NUMBER) AS
  BEGIN
    UPDATE NEXATEC.PRODUCTOS_SERVICIOS SET
      fabricante_id = p_fabricante_id,
      precio_base = p_precio_base
    WHERE producto_id = p_id;
    IF SQL%ROWCOUNT = 0 THEN RAISE_APPLICATION_ERROR(-20001, 'Registro no encontrado'); END IF;
  END;
  PROCEDURE eliminar(p_id IN NUMBER) AS
  BEGIN
    DELETE FROM NEXATEC.PRODUCTOS_SERVICIOS WHERE producto_id = p_id;
    IF SQL%ROWCOUNT = 0 THEN RAISE_APPLICATION_ERROR(-20001, 'Registro no encontrado'); END IF;
  END;
END P_PRODUCTOS_SERVICIOS;
/

-- COTIZACIONES
CREATE OR REPLACE PACKAGE NEXATEC.P_COTIZACIONES AS
  PROCEDURE crear(p_cliente_id IN NUMBER, p_vendedor_id IN NUMBER, p_fecha IN DATE, p_fecha_vencimiento IN DATE, p_total IN NUMBER, p_id OUT NUMBER);
  PROCEDURE listar(p_resultado OUT SYS_REFCURSOR);
  PROCEDURE obtener(p_id IN NUMBER, p_resultado OUT SYS_REFCURSOR);
  PROCEDURE actualizar(p_id IN NUMBER, p_cliente_id IN NUMBER, p_vendedor_id IN NUMBER, p_fecha IN DATE, p_fecha_vencimiento IN DATE, p_total IN NUMBER);
  PROCEDURE eliminar(p_id IN NUMBER);
END;
/
CREATE OR REPLACE PACKAGE BODY NEXATEC.P_COTIZACIONES AS
  PROCEDURE crear(p_cliente_id IN NUMBER, p_vendedor_id IN NUMBER, p_fecha IN DATE, p_fecha_vencimiento IN DATE, p_total IN NUMBER, p_id OUT NUMBER) AS
  BEGIN
    p_id := NEXATEC.SEQ_COTIZACIONES.NEXTVAL;
    INSERT INTO NEXATEC.COTIZACIONES (cotizacion_id, cliente_id, vendedor_id, fecha, fecha_vencimiento, total)
    VALUES (p_id, p_cliente_id, p_vendedor_id, p_fecha, p_fecha_vencimiento, p_total);
  END;
  PROCEDURE listar(p_resultado OUT SYS_REFCURSOR) AS
  BEGIN
    OPEN p_resultado FOR SELECT * FROM NEXATEC.COTIZACIONES ORDER BY cotizacion_id;
  END;
  PROCEDURE obtener(p_id IN NUMBER, p_resultado OUT SYS_REFCURSOR) AS
  BEGIN
    OPEN p_resultado FOR SELECT * FROM NEXATEC.COTIZACIONES WHERE cotizacion_id = p_id;
  END;
  PROCEDURE actualizar(p_id IN NUMBER, p_cliente_id IN NUMBER, p_vendedor_id IN NUMBER, p_fecha IN DATE, p_fecha_vencimiento IN DATE, p_total IN NUMBER) AS
  BEGIN
    UPDATE NEXATEC.COTIZACIONES SET
      cliente_id = p_cliente_id,
      vendedor_id = p_vendedor_id,
      fecha = p_fecha,
      fecha_vencimiento = p_fecha_vencimiento,
      total = p_total
    WHERE cotizacion_id = p_id;
    IF SQL%ROWCOUNT = 0 THEN RAISE_APPLICATION_ERROR(-20001, 'Registro no encontrado'); END IF;
  END;
  PROCEDURE eliminar(p_id IN NUMBER) AS
  BEGIN
    DELETE FROM NEXATEC.COTIZACIONES WHERE cotizacion_id = p_id;
    IF SQL%ROWCOUNT = 0 THEN RAISE_APPLICATION_ERROR(-20001, 'Registro no encontrado'); END IF;
  END;
END P_COTIZACIONES;
/

-- DETALLE_COTIZACION
CREATE OR REPLACE PACKAGE NEXATEC.P_DETALLE_COTIZACION AS
  PROCEDURE crear(p_cotizacion_id IN NUMBER, p_producto_id IN NUMBER, p_cantidad IN NUMBER, p_precio_unitario IN NUMBER, p_descuento IN NUMBER, p_subtotal IN NUMBER, p_id OUT NUMBER);
  PROCEDURE listar(p_resultado OUT SYS_REFCURSOR);
  PROCEDURE obtener(p_id IN NUMBER, p_resultado OUT SYS_REFCURSOR);
  PROCEDURE actualizar(p_id IN NUMBER, p_cotizacion_id IN NUMBER, p_producto_id IN NUMBER, p_cantidad IN NUMBER, p_precio_unitario IN NUMBER, p_descuento IN NUMBER, p_subtotal IN NUMBER);
  PROCEDURE eliminar(p_id IN NUMBER);
END;
/
CREATE OR REPLACE PACKAGE BODY NEXATEC.P_DETALLE_COTIZACION AS
  PROCEDURE crear(p_cotizacion_id IN NUMBER, p_producto_id IN NUMBER, p_cantidad IN NUMBER, p_precio_unitario IN NUMBER, p_descuento IN NUMBER, p_subtotal IN NUMBER, p_id OUT NUMBER) AS
  BEGIN
    p_id := NEXATEC.SEQ_DETALLE_COT.NEXTVAL;
    INSERT INTO NEXATEC.DETALLE_COTIZACION (detalle_id, cotizacion_id, producto_id, cantidad, precio_unitario, descuento, subtotal)
    VALUES (p_id, p_cotizacion_id, p_producto_id, p_cantidad, p_precio_unitario, p_descuento, p_subtotal);
  END;
  PROCEDURE listar(p_resultado OUT SYS_REFCURSOR) AS
  BEGIN
    OPEN p_resultado FOR SELECT * FROM NEXATEC.DETALLE_COTIZACION ORDER BY detalle_id;
  END;
  PROCEDURE obtener(p_id IN NUMBER, p_resultado OUT SYS_REFCURSOR) AS
  BEGIN
    OPEN p_resultado FOR SELECT * FROM NEXATEC.DETALLE_COTIZACION WHERE detalle_id = p_id;
  END;
  PROCEDURE actualizar(p_id IN NUMBER, p_cotizacion_id IN NUMBER, p_producto_id IN NUMBER, p_cantidad IN NUMBER, p_precio_unitario IN NUMBER, p_descuento IN NUMBER, p_subtotal IN NUMBER) AS
  BEGIN
    UPDATE NEXATEC.DETALLE_COTIZACION SET
      cotizacion_id = p_cotizacion_id,
      producto_id = p_producto_id,
      cantidad = p_cantidad,
      precio_unitario = p_precio_unitario,
      descuento = p_descuento,
      subtotal = p_subtotal
    WHERE detalle_id = p_id;
    IF SQL%ROWCOUNT = 0 THEN RAISE_APPLICATION_ERROR(-20001, 'Registro no encontrado'); END IF;
  END;
  PROCEDURE eliminar(p_id IN NUMBER) AS
  BEGIN
    DELETE FROM NEXATEC.DETALLE_COTIZACION WHERE detalle_id = p_id;
    IF SQL%ROWCOUNT = 0 THEN RAISE_APPLICATION_ERROR(-20001, 'Registro no encontrado'); END IF;
  END;
END P_DETALLE_COTIZACION;
/

-- LICENCIAS
CREATE OR REPLACE PACKAGE NEXATEC.P_LICENCIAS AS
  PROCEDURE crear(p_cliente_id IN NUMBER, p_producto_id IN NUMBER, p_detalle_id IN NUMBER, p_fecha_inicio IN DATE, p_fecha_vencimiento IN DATE, p_id OUT NUMBER);
  PROCEDURE listar(p_resultado OUT SYS_REFCURSOR);
  PROCEDURE obtener(p_id IN NUMBER, p_resultado OUT SYS_REFCURSOR);
  PROCEDURE actualizar(p_id IN NUMBER, p_cliente_id IN NUMBER, p_producto_id IN NUMBER, p_detalle_id IN NUMBER, p_fecha_inicio IN DATE, p_fecha_vencimiento IN DATE);
  PROCEDURE eliminar(p_id IN NUMBER);
END;
/
CREATE OR REPLACE PACKAGE BODY NEXATEC.P_LICENCIAS AS
  PROCEDURE crear(p_cliente_id IN NUMBER, p_producto_id IN NUMBER, p_detalle_id IN NUMBER, p_fecha_inicio IN DATE, p_fecha_vencimiento IN DATE, p_id OUT NUMBER) AS
  BEGIN
    p_id := NEXATEC.SEQ_LICENCIAS.NEXTVAL;
    INSERT INTO NEXATEC.LICENCIAS (licencia_id, cliente_id, producto_id, detalle_id, fecha_inicio, fecha_vencimiento)
    VALUES (p_id, p_cliente_id, p_producto_id, p_detalle_id, p_fecha_inicio, p_fecha_vencimiento);
  END;
  PROCEDURE listar(p_resultado OUT SYS_REFCURSOR) AS
  BEGIN
    OPEN p_resultado FOR SELECT * FROM NEXATEC.LICENCIAS ORDER BY licencia_id;
  END;
  PROCEDURE obtener(p_id IN NUMBER, p_resultado OUT SYS_REFCURSOR) AS
  BEGIN
    OPEN p_resultado FOR SELECT * FROM NEXATEC.LICENCIAS WHERE licencia_id = p_id;
  END;
  PROCEDURE actualizar(p_id IN NUMBER, p_cliente_id IN NUMBER, p_producto_id IN NUMBER, p_detalle_id IN NUMBER, p_fecha_inicio IN DATE, p_fecha_vencimiento IN DATE) AS
  BEGIN
    UPDATE NEXATEC.LICENCIAS SET
      cliente_id = p_cliente_id,
      producto_id = p_producto_id,
      detalle_id = p_detalle_id,
      fecha_inicio = p_fecha_inicio,
      fecha_vencimiento = p_fecha_vencimiento
    WHERE licencia_id = p_id;
    IF SQL%ROWCOUNT = 0 THEN RAISE_APPLICATION_ERROR(-20001, 'Registro no encontrado'); END IF;
  END;
  PROCEDURE eliminar(p_id IN NUMBER) AS
  BEGIN
    DELETE FROM NEXATEC.LICENCIAS WHERE licencia_id = p_id;
    IF SQL%ROWCOUNT = 0 THEN RAISE_APPLICATION_ERROR(-20001, 'Registro no encontrado'); END IF;
  END;
END P_LICENCIAS;
/

-- RENOVACIONES
CREATE OR REPLACE PACKAGE NEXATEC.P_RENOVACIONES AS
  PROCEDURE crear(p_licencia_id IN NUMBER, p_fecha_renovacion IN DATE, p_fecha_vencimiento_anterior IN DATE, p_nueva_fecha_vencimiento IN DATE, p_id OUT NUMBER);
  PROCEDURE listar(p_resultado OUT SYS_REFCURSOR);
  PROCEDURE obtener(p_id IN NUMBER, p_resultado OUT SYS_REFCURSOR);
  PROCEDURE actualizar(p_id IN NUMBER, p_licencia_id IN NUMBER, p_fecha_renovacion IN DATE, p_fecha_vencimiento_anterior IN DATE, p_nueva_fecha_vencimiento IN DATE);
  PROCEDURE eliminar(p_id IN NUMBER);
END;
/
CREATE OR REPLACE PACKAGE BODY NEXATEC.P_RENOVACIONES AS
  PROCEDURE crear(p_licencia_id IN NUMBER, p_fecha_renovacion IN DATE, p_fecha_vencimiento_anterior IN DATE, p_nueva_fecha_vencimiento IN DATE, p_id OUT NUMBER) AS
  BEGIN
    p_id := NEXATEC.SEQ_RENOVACIONES.NEXTVAL;
    INSERT INTO NEXATEC.RENOVACIONES (renovacion_id, licencia_id, fecha_renovacion, fecha_vencimiento_anterior, nueva_fecha_vencimiento)
    VALUES (p_id, p_licencia_id, p_fecha_renovacion, p_fecha_vencimiento_anterior, p_nueva_fecha_vencimiento);
  END;
  PROCEDURE listar(p_resultado OUT SYS_REFCURSOR) AS
  BEGIN
    OPEN p_resultado FOR SELECT * FROM NEXATEC.RENOVACIONES ORDER BY renovacion_id;
  END;
  PROCEDURE obtener(p_id IN NUMBER, p_resultado OUT SYS_REFCURSOR) AS
  BEGIN
    OPEN p_resultado FOR SELECT * FROM NEXATEC.RENOVACIONES WHERE renovacion_id = p_id;
  END;
  PROCEDURE actualizar(p_id IN NUMBER, p_licencia_id IN NUMBER, p_fecha_renovacion IN DATE, p_fecha_vencimiento_anterior IN DATE, p_nueva_fecha_vencimiento IN DATE) AS
  BEGIN
    UPDATE NEXATEC.RENOVACIONES SET
      licencia_id = p_licencia_id,
      fecha_renovacion = p_fecha_renovacion,
      fecha_vencimiento_anterior = p_fecha_vencimiento_anterior,
      nueva_fecha_vencimiento = p_nueva_fecha_vencimiento
    WHERE renovacion_id = p_id;
    IF SQL%ROWCOUNT = 0 THEN RAISE_APPLICATION_ERROR(-20001, 'Registro no encontrado'); END IF;
  END;
  PROCEDURE eliminar(p_id IN NUMBER) AS
  BEGIN
    DELETE FROM NEXATEC.RENOVACIONES WHERE renovacion_id = p_id;
    IF SQL%ROWCOUNT = 0 THEN RAISE_APPLICATION_ERROR(-20001, 'Registro no encontrado'); END IF;
  END;
END P_RENOVACIONES;
/

-- TIQUETES
CREATE OR REPLACE PACKAGE NEXATEC.P_TIQUETES AS
  PROCEDURE crear(p_cliente_id IN NUMBER, p_contacto_id IN NUMBER, p_tecnico_id IN NUMBER, p_fecha_apertura IN DATE, p_fecha_cierre IN DATE, p_id OUT NUMBER);
  PROCEDURE listar(p_resultado OUT SYS_REFCURSOR);
  PROCEDURE obtener(p_id IN NUMBER, p_resultado OUT SYS_REFCURSOR);
  PROCEDURE actualizar(p_id IN NUMBER, p_cliente_id IN NUMBER, p_contacto_id IN NUMBER, p_tecnico_id IN NUMBER, p_fecha_apertura IN DATE, p_fecha_cierre IN DATE);
  PROCEDURE eliminar(p_id IN NUMBER);
END;
/
CREATE OR REPLACE PACKAGE BODY NEXATEC.P_TIQUETES AS
  PROCEDURE crear(p_cliente_id IN NUMBER, p_contacto_id IN NUMBER, p_tecnico_id IN NUMBER, p_fecha_apertura IN DATE, p_fecha_cierre IN DATE, p_id OUT NUMBER) AS
  BEGIN
    p_id := NEXATEC.SEQ_TIQUETES.NEXTVAL;
    INSERT INTO NEXATEC.TIQUETES (tiquete_id, cliente_id, contacto_id, tecnico_id, fecha_apertura, fecha_cierre)
    VALUES (p_id, p_cliente_id, p_contacto_id, p_tecnico_id, p_fecha_apertura, p_fecha_cierre);
  END;
  PROCEDURE listar(p_resultado OUT SYS_REFCURSOR) AS
  BEGIN
    OPEN p_resultado FOR SELECT * FROM NEXATEC.TIQUETES ORDER BY tiquete_id;
  END;
  PROCEDURE obtener(p_id IN NUMBER, p_resultado OUT SYS_REFCURSOR) AS
  BEGIN
    OPEN p_resultado FOR SELECT * FROM NEXATEC.TIQUETES WHERE tiquete_id = p_id;
  END;
  PROCEDURE actualizar(p_id IN NUMBER, p_cliente_id IN NUMBER, p_contacto_id IN NUMBER, p_tecnico_id IN NUMBER, p_fecha_apertura IN DATE, p_fecha_cierre IN DATE) AS
  BEGIN
    UPDATE NEXATEC.TIQUETES SET
      cliente_id = p_cliente_id,
      contacto_id = p_contacto_id,
      tecnico_id = p_tecnico_id,
      fecha_apertura = p_fecha_apertura,
      fecha_cierre = p_fecha_cierre
    WHERE tiquete_id = p_id;
    IF SQL%ROWCOUNT = 0 THEN RAISE_APPLICATION_ERROR(-20001, 'Registro no encontrado'); END IF;
  END;
  PROCEDURE eliminar(p_id IN NUMBER) AS
  BEGIN
    DELETE FROM NEXATEC.TIQUETES WHERE tiquete_id = p_id;
    IF SQL%ROWCOUNT = 0 THEN RAISE_APPLICATION_ERROR(-20001, 'Registro no encontrado'); END IF;
  END;
END P_TIQUETES;
/

-- FACTURAS
CREATE OR REPLACE PACKAGE NEXATEC.P_FACTURAS AS
  PROCEDURE crear(p_cliente_id IN NUMBER, p_cotizacion_id IN NUMBER, p_fecha_emision IN DATE, p_fecha_vencimiento IN DATE, p_total IN NUMBER, p_id OUT NUMBER);
  PROCEDURE listar(p_resultado OUT SYS_REFCURSOR);
  PROCEDURE obtener(p_id IN NUMBER, p_resultado OUT SYS_REFCURSOR);
  PROCEDURE actualizar(p_id IN NUMBER, p_cliente_id IN NUMBER, p_cotizacion_id IN NUMBER, p_fecha_emision IN DATE, p_fecha_vencimiento IN DATE, p_total IN NUMBER);
  PROCEDURE eliminar(p_id IN NUMBER);
END;
/
CREATE OR REPLACE PACKAGE BODY NEXATEC.P_FACTURAS AS
  PROCEDURE crear(p_cliente_id IN NUMBER, p_cotizacion_id IN NUMBER, p_fecha_emision IN DATE, p_fecha_vencimiento IN DATE, p_total IN NUMBER, p_id OUT NUMBER) AS
  BEGIN
    p_id := NEXATEC.SEQ_FACTURAS.NEXTVAL;
    INSERT INTO NEXATEC.FACTURAS (factura_id, cliente_id, cotizacion_id, fecha_emision, fecha_vencimiento, total)
    VALUES (p_id, p_cliente_id, p_cotizacion_id, p_fecha_emision, p_fecha_vencimiento, p_total);
  END;
  PROCEDURE listar(p_resultado OUT SYS_REFCURSOR) AS
  BEGIN
    OPEN p_resultado FOR SELECT * FROM NEXATEC.FACTURAS ORDER BY factura_id;
  END;
  PROCEDURE obtener(p_id IN NUMBER, p_resultado OUT SYS_REFCURSOR) AS
  BEGIN
    OPEN p_resultado FOR SELECT * FROM NEXATEC.FACTURAS WHERE factura_id = p_id;
  END;
  PROCEDURE actualizar(p_id IN NUMBER, p_cliente_id IN NUMBER, p_cotizacion_id IN NUMBER, p_fecha_emision IN DATE, p_fecha_vencimiento IN DATE, p_total IN NUMBER) AS
  BEGIN
    UPDATE NEXATEC.FACTURAS SET
      cliente_id = p_cliente_id,
      cotizacion_id = p_cotizacion_id,
      fecha_emision = p_fecha_emision,
      fecha_vencimiento = p_fecha_vencimiento,
      total = p_total
    WHERE factura_id = p_id;
    IF SQL%ROWCOUNT = 0 THEN RAISE_APPLICATION_ERROR(-20001, 'Registro no encontrado'); END IF;
  END;
  PROCEDURE eliminar(p_id IN NUMBER) AS
  BEGIN
    DELETE FROM NEXATEC.FACTURAS WHERE factura_id = p_id;
    IF SQL%ROWCOUNT = 0 THEN RAISE_APPLICATION_ERROR(-20001, 'Registro no encontrado'); END IF;
  END;
END P_FACTURAS;
/

CREATE OR REPLACE VIEW NEXATEC.V_CLIENTES_ACTIVOS AS SELECT * FROM CLIENTES WHERE estado = 'ACTIVO';
CREATE OR REPLACE VIEW NEXATEC.V_EMPLEADOS_ACTIVOS AS SELECT * FROM EMPLEADOS WHERE estado = 'ACTIVO';
CREATE OR REPLACE VIEW NEXATEC.V_PRODUCTOS_ACTIVOS AS SELECT * FROM PRODUCTOS_SERVICIOS WHERE estado = 'ACTIVO';
CREATE OR REPLACE VIEW NEXATEC.V_COTIZACIONES_CLIENTE AS SELECT c.cotizacion_id, cl.nombre cliente, c.estado, c.total FROM COTIZACIONES c JOIN CLIENTES cl ON cl.cliente_id=c.cliente_id;
CREATE OR REPLACE VIEW NEXATEC.V_DETALLES_PRODUCTO AS SELECT d.detalle_id, p.nombre producto, d.cantidad, d.subtotal FROM DETALLE_COTIZACION d JOIN PRODUCTOS_SERVICIOS p ON p.producto_id=d.producto_id;
CREATE OR REPLACE VIEW NEXATEC.V_LICENCIAS_POR_VENCER AS SELECT * FROM LICENCIAS WHERE estado='ACTIVA' AND fecha_vencimiento BETWEEN SYSDATE AND SYSDATE+30;
CREATE OR REPLACE VIEW NEXATEC.V_RENOVACIONES_LICENCIA AS SELECT r.renovacion_id, l.referencia, r.nueva_fecha_vencimiento FROM RENOVACIONES r JOIN LICENCIAS l ON l.licencia_id=r.licencia_id;
CREATE OR REPLACE VIEW NEXATEC.V_TIQUETES_ABIERTOS AS SELECT * FROM TIQUETES WHERE estado IN ('ABIERTO','EN_PROCESO');
CREATE OR REPLACE VIEW NEXATEC.V_FACTURAS_PENDIENTES AS SELECT * FROM FACTURAS WHERE estado_pago='PENDIENTE';
CREATE OR REPLACE VIEW NEXATEC.V_CLIENTES_TIQUETES AS SELECT c.cliente_id, c.nombre, COUNT(t.tiquete_id) cantidad FROM CLIENTES c LEFT JOIN TIQUETES t ON t.cliente_id=c.cliente_id GROUP BY c.cliente_id,c.nombre;
CREATE OR REPLACE FUNCTION NEXATEC.F_TOTAL_CLIENTES RETURN NUMBER AS
  CURSOR c IS SELECT cliente_id FROM NEXATEC.CLIENTES;
  v_total NUMBER := 0;
BEGIN
  FOR r IN c LOOP v_total := v_total + 1; END LOOP;
  RETURN v_total;
END;
/
CREATE OR REPLACE FUNCTION NEXATEC.F_TOTAL_CONTACTOS RETURN NUMBER AS
  CURSOR c IS SELECT contacto_id FROM NEXATEC.CONTACTOS;
  v_total NUMBER := 0;
BEGIN
  FOR r IN c LOOP v_total := v_total + 1; END LOOP;
  RETURN v_total;
END;
/
CREATE OR REPLACE FUNCTION NEXATEC.F_TOTAL_EMPLEADOS RETURN NUMBER AS
  CURSOR c IS SELECT empleado_id FROM NEXATEC.EMPLEADOS;
  v_total NUMBER := 0;
BEGIN
  FOR r IN c LOOP v_total := v_total + 1; END LOOP;
  RETURN v_total;
END;
/
CREATE OR REPLACE FUNCTION NEXATEC.F_TOTAL_FABRICANTES RETURN NUMBER AS
  CURSOR c IS SELECT fabricante_id FROM NEXATEC.FABRICANTES;
  v_total NUMBER := 0;
BEGIN
  FOR r IN c LOOP v_total := v_total + 1; END LOOP;
  RETURN v_total;
END;
/
CREATE OR REPLACE FUNCTION NEXATEC.F_TOTAL_PRODUCTOS_SERVICIOS RETURN NUMBER AS
  CURSOR c IS SELECT producto_id FROM NEXATEC.PRODUCTOS_SERVICIOS;
  v_total NUMBER := 0;
BEGIN
  FOR r IN c LOOP v_total := v_total + 1; END LOOP;
  RETURN v_total;
END;
/
CREATE OR REPLACE FUNCTION NEXATEC.F_TOTAL_COTIZACIONES RETURN NUMBER AS
  CURSOR c IS SELECT cotizacion_id FROM NEXATEC.COTIZACIONES;
  v_total NUMBER := 0;
BEGIN
  FOR r IN c LOOP v_total := v_total + 1; END LOOP;
  RETURN v_total;
END;
/
CREATE OR REPLACE FUNCTION NEXATEC.F_TOTAL_DETALLE_COTIZACION RETURN NUMBER AS
  CURSOR c IS SELECT detalle_id FROM NEXATEC.DETALLE_COTIZACION;
  v_total NUMBER := 0;
BEGIN
  FOR r IN c LOOP v_total := v_total + 1; END LOOP;
  RETURN v_total;
END;
/
CREATE OR REPLACE FUNCTION NEXATEC.F_TOTAL_LICENCIAS RETURN NUMBER AS
  CURSOR c IS SELECT licencia_id FROM NEXATEC.LICENCIAS;
  v_total NUMBER := 0;
BEGIN
  FOR r IN c LOOP v_total := v_total + 1; END LOOP;
  RETURN v_total;
END;
/
CREATE OR REPLACE FUNCTION NEXATEC.F_TOTAL_RENOVACIONES RETURN NUMBER AS
  CURSOR c IS SELECT renovacion_id FROM NEXATEC.RENOVACIONES;
  v_total NUMBER := 0;
BEGIN
  FOR r IN c LOOP v_total := v_total + 1; END LOOP;
  RETURN v_total;
END;
/
CREATE OR REPLACE FUNCTION NEXATEC.F_TOTAL_TIQUETES RETURN NUMBER AS
  CURSOR c IS SELECT tiquete_id FROM NEXATEC.TIQUETES;
  v_total NUMBER := 0;
BEGIN
  FOR r IN c LOOP v_total := v_total + 1; END LOOP;
  RETURN v_total;
END;
/
CREATE OR REPLACE FUNCTION NEXATEC.F_TOTAL_FACTURAS RETURN NUMBER AS
  CURSOR c IS SELECT factura_id FROM NEXATEC.FACTURAS;
  v_total NUMBER := 0;
BEGIN
  FOR r IN c LOOP v_total := v_total + 1; END LOOP;
  RETURN v_total;
END;
/
CREATE OR REPLACE FUNCTION NEXATEC.F_CLIENTES_INACTIVOS RETURN NUMBER AS
  CURSOR c IS SELECT 1 FROM NEXATEC.CLIENTES WHERE estado='INACTIVO';
  v_total NUMBER := 0;
BEGIN
  FOR r IN c LOOP v_total := v_total + 1; END LOOP;
  RETURN v_total;
END;
/
CREATE OR REPLACE FUNCTION NEXATEC.F_LICENCIAS_VENCIDAS RETURN NUMBER AS
  CURSOR c IS SELECT 1 FROM NEXATEC.LICENCIAS WHERE fecha_vencimiento < SYSDATE;
  v_total NUMBER := 0;
BEGIN
  FOR r IN c LOOP v_total := v_total + 1; END LOOP;
  RETURN v_total;
END;
/
CREATE OR REPLACE FUNCTION NEXATEC.F_FACTURAS_PAGADAS RETURN NUMBER AS
  CURSOR c IS SELECT 1 FROM NEXATEC.FACTURAS WHERE estado_pago='PAGADA';
  v_total NUMBER := 0;
BEGIN
  FOR r IN c LOOP v_total := v_total + 1; END LOOP;
  RETURN v_total;
END;
/
CREATE OR REPLACE FUNCTION NEXATEC.F_TIQUETES_CERRADOS RETURN NUMBER AS
  CURSOR c IS SELECT 1 FROM NEXATEC.TIQUETES WHERE estado='CERRADO';
  v_total NUMBER := 0;
BEGIN
  FOR r IN c LOOP v_total := v_total + 1; END LOOP;
  RETURN v_total;
END;
/
CREATE OR REPLACE TRIGGER NEXATEC.TR_PRECIO
BEFORE INSERT OR UPDATE ON NEXATEC.PRODUCTOS_SERVICIOS
FOR EACH ROW
BEGIN
  IF :NEW.precio_base < 0 THEN RAISE_APPLICATION_ERROR(-20030, 'El precio no puede ser negativo'); END IF;
END;
/
CREATE OR REPLACE TRIGGER NEXATEC.TR_CANTIDAD
BEFORE INSERT OR UPDATE ON NEXATEC.DETALLE_COTIZACION
FOR EACH ROW
BEGIN
  IF :NEW.cantidad <= 0 THEN RAISE_APPLICATION_ERROR(-20030, 'Cantidad invalida'); END IF;
END;
/
CREATE OR REPLACE TRIGGER NEXATEC.TR_DESCUENTO
BEFORE INSERT OR UPDATE ON NEXATEC.DETALLE_COTIZACION
FOR EACH ROW
BEGIN
  IF descuento < 0 OR :NEW.descuento > 100 THEN RAISE_APPLICATION_ERROR(-20030, 'Descuento invalido'); END IF;
END;
/
CREATE OR REPLACE TRIGGER NEXATEC.TR_LIC_FECHA
BEFORE INSERT OR UPDATE ON NEXATEC.LICENCIAS
FOR EACH ROW
BEGIN
  IF fecha_vencimiento <= :NEW.fecha_inicio THEN RAISE_APPLICATION_ERROR(-20030, 'Fechas invalidas'); END IF;
END;
/
CREATE OR REPLACE TRIGGER NEXATEC.TR_FAC_TOTAL
BEFORE INSERT OR UPDATE ON NEXATEC.FACTURAS
FOR EACH ROW
BEGIN
  IF :NEW.total < 0 THEN RAISE_APPLICATION_ERROR(-20030, 'Total invalido'); END IF;
END;
/

-- Verificación
SELECT object_type, status, COUNT(*) cantidad FROM all_objects WHERE owner = 'NEXATEC' GROUP BY object_type, status ORDER BY object_type, status;
SELECT name, type, line, text FROM all_errors WHERE owner = 'NEXATEC' ORDER BY name, sequence;
