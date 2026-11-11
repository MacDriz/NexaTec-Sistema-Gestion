# NexaTec Soluciones S.A.

Sistema de Gestión Comercial y de Soporte — Segundo Avance, Grupo 5.

## Archivos

- `database.sql`: tablas y objetos PL/SQL.
- `main.py`: aplicación de consola.
- `README.md`: instrucciones de instalación y uso.

## Requisitos

- Oracle Database Free o XE y SQL Developer.
- Python 3.10 o superior.
- Driver de conexión: `pip install oracledb`.

## Instalación

1. Conectarse a Oracle desde SQL Developer con un usuario con permisos para crear el esquema.
2. Abrir `database.sql` y ejecutarlo con **F5**. Revisar los errores de compilación antes de continuar.
3. Configurar en `main.py` el usuario, contraseña, host, puerto y servicio de Oracle. Por ejemplo, `localhost`, `1521` y `FREEPDB1` (según la instalación).
4. Ejecutar:

```bash
python main.py
```

**Precaución:** si el SQL incluye `DROP USER NEXATEC CASCADE`, ejecutarlo elimina el esquema NEXATEC y sus datos. Utilizar únicamente en un entorno de pruebas.

## Funcionalidades

El menú de consola contiene 11 módulos: clientes, contactos, empleados, fabricantes, productos y servicios, cotizaciones, detalles de cotización, licencias, renovaciones, tiquetes de soporte y facturas. Las operaciones se realizan mediante procedimientos PL/SQL.

## Verificación

En SQL Developer, consultar los objetos del esquema:

```sql
SELECT object_type, COUNT(*) AS cantidad
FROM all_objects
WHERE owner = 'NEXATEC'
GROUP BY object_type
ORDER BY object_type;
```

Para identificar objetos que no compilaron:

```sql
SELECT object_name, object_type, status
FROM all_objects
WHERE owner = 'NEXATEC' AND status <> 'VALID';
```

