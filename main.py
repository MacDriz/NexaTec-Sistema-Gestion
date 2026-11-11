import os
from datetime import datetime
import oracledb

DB = dict(user=os.getenv('DB_USER', 'NEXATEC'), password=os.getenv('DB_PASSWORD', 'NexaTec2026'),
          dsn=os.getenv('DB_DSN', 'localhost:1521/FREEPDB1'))

T = lambda nombre: (nombre, 'text')
N = lambda nombre: (nombre, 'int')
F = lambda nombre: (nombre, 'float')
D = lambda nombre: (nombre, 'date')
O = lambda nombre, tipo='int': (nombre, tipo + '?')

#Cada acción usa un procedimiento PLSQL
MODULOS = {
 'Clientes': ('PKG_CLIENTES', [
  ('Listar', 'OBTENER_CLIENTES', [], 'list'), ('Buscar por ID', 'OBTENER_CLIENTE_POR_ID', [N('ID')], 'list'),
  ('Buscar por nombre', 'BUSCAR_CLIENTES_POR_NOMBRE', [T('Nombre')], 'list'),
  ('Crear', 'CREAR_CLIENTE', [T('Identificación'), T('Nombre'), T('Teléfono'), T('Correo'), T('Dirección')], 'create'),
  ('Actualizar', 'ACTUALIZAR_CLIENTE', [N('ID'), T('Nombre'), T('Teléfono'), T('Correo'), T('Dirección')], 'write'),
  ('Desactivar', 'DESACTIVAR_CLIENTE', [N('ID')], 'write')]),
 'Contactos': ('PKG_CONTACTOS', [
  ('Listar', 'OBTENER_CONTACTOS', [], 'list'), ('Por cliente', 'OBTENER_CONTACTOS_POR_CLIENTE', [N('Cliente ID')], 'list'),
  ('Crear', 'CREAR_CONTACTO', [N('Cliente ID'), T('Nombre'), T('Cargo'), T('Teléfono'), T('Correo')], 'create'),
  ('Actualizar', 'ACTUALIZAR_CONTACTO', [N('ID'), T('Nombre'), T('Cargo'), T('Teléfono'), T('Correo')], 'write'),
  ('Eliminar', 'ELIMINAR_CONTACTO', [N('ID')], 'write')]),
 'Empleados': ('PKG_EMPLEADOS', [
  ('Listar', 'OBTENER_EMPLEADOS', [], 'list'), ('Por rol', 'OBTENER_EMPLEADOS_POR_ROL', [T('Rol')], 'list'),
  ('Crear', 'CREAR_EMPLEADO', [T('Nombre'), T('Correo'), T('Rol')], 'create'),
  ('Actualizar', 'ACTUALIZAR_EMPLEADO', [N('ID'), T('Nombre'), T('Correo'), T('Rol')], 'write'),
  ('Desactivar', 'DESACTIVAR_EMPLEADO', [N('ID')], 'write')]),
 'Fabricantes': ('PKG_FABRICANTES', [
  ('Listar', 'OBTENER_FABRICANTES', [], 'list'),
  ('Crear', 'CREAR_FABRICANTE', [T('Nombre'), T('Sitio web')], 'create'),
  ('Actualizar', 'ACTUALIZAR_FABRICANTE', [N('ID'), T('Nombre'), T('Sitio web')], 'write'),
  ('Desactivar', 'DESACTIVAR_FABRICANTE', [N('ID')], 'write')]),
 'Productos y servicios': ('PKG_PRODUCTOS', [
  ('Listar', 'OBTENER_PRODUCTOS', [], 'list'), ('Por ID', 'OBTENER_PRODUCTO_POR_ID', [N('ID')], 'list'),
  ('Por tipo', 'BUSCAR_PRODUCTOS_POR_TIPO', [T('Tipo')], 'list'),
  ('Crear', 'CREAR_PRODUCTO', [O('Fabricante ID'), T('Código'), T('Nombre'), T('Tipo'), T('Descripción'), F('Precio')], 'create'),
  ('Actualizar', 'ACTUALIZAR_PRODUCTO', [N('ID'), T('Nombre'), T('Descripción'), F('Precio')], 'write'),
  ('Desactivar', 'DESACTIVAR_PRODUCTO', [N('ID')], 'write')]),
 'Cotizaciones': ('PKG_COTIZACIONES', [
  ('Listar', 'OBTENER_COTIZACIONES', [], 'list'), ('Por cliente', 'OBTENER_COTIZACIONES_POR_CLIENTE', [N('Cliente ID')], 'list'),
  ('Por ID', 'OBTENER_COTIZACION_POR_ID', [N('ID')], 'list'),
  ('Crear', 'CREAR_COTIZACION', [N('Cliente ID'), N('Vendedor ID'), D('Vencimiento')], 'create'),
  ('Cambiar estado', 'CAMBIAR_ESTADO_COTIZACION', [N('ID'), T('Estado')], 'write'),
  ('Actualizar', 'ACTUALIZAR_COTIZACION', [N('ID'), D('Vencimiento'), T('Estado')], 'write')]),
 'Detalle de cotización': ('PKG_COTIZACIONES', [
  ('Listar detalles', 'OBTENER_DETALLES', [N('Cotización ID')], 'list'),
  ('Agregar', 'AGREGAR_DETALLE', [N('Cotización ID'), N('Producto ID'), N('Cantidad'), F('Precio unitario'), F('Descuento %')], 'create'),
  ('Eliminar', 'ELIMINAR_DETALLE', [N('Detalle ID')], 'write')]),
 'Licencias': ('PKG_LICENCIAS', [
  ('Listar', 'OBTENER_LICENCIAS', [], 'list'), ('Por cliente', 'OBTENER_LICENCIAS_POR_CLIENTE', [N('Cliente ID')], 'list'),
  ('Por vencer', 'OBTENER_LICENCIAS_POR_VENCER', [N('Días')], 'list'),
  ('Crear', 'CREAR_LICENCIA', [N('Cliente ID'), N('Producto ID'), O('Detalle ID'), T('Referencia'), D('Inicio'), D('Vencimiento')], 'create'),
  ('Cambiar estado', 'ACTUALIZAR_ESTADO_LICENCIA', [N('ID'), T('Estado')], 'write'),
  ('Cancelar', 'CANCELAR_LICENCIA', [N('ID')], 'write')]),
 'Renovaciones': ('PKG_RENOVACIONES', [
  ('Listar', 'OBTENER_RENOVACIONES', [], 'list'), ('Por licencia', 'OBTENER_RENOVACIONES_POR_LICENCIA', [N('Licencia ID')], 'list'),
  ('Crear', 'CREAR_RENOVACION', [N('Licencia ID'), D('Nuevo vencimiento')], 'create'),
  ('Cambiar estado', 'ACTUALIZAR_RENOVACION', [N('ID'), T('Estado')], 'write'),
  ('Cancelar', 'CANCELAR_RENOVACION', [N('ID')], 'write')]),
 'Tiquetes': ('PKG_TIQUETES', [
  ('Listar', 'OBTENER_TIQUETES', [], 'list'), ('Por cliente', 'OBTENER_TIQUETES_POR_CLIENTE', [N('Cliente ID')], 'list'),
  ('Por estado', 'OBTENER_TIQUETES_POR_ESTADO', [T('Estado')], 'list'),
  ('Crear', 'CREAR_TIQUETE', [N('Cliente ID'), O('Contacto ID'), O('Técnico ID'), T('Prioridad'), T('Asunto'), T('Descripción')], 'create'),
  ('Asignar técnico', 'ASIGNAR_TECNICO', [N('Tiquete ID'), N('Técnico ID')], 'write'),
  ('Cambiar estado', 'CAMBIAR_ESTADO_TIQUETE', [N('Tiquete ID'), T('Estado')], 'write'),
  ('Cerrar', 'CERRAR_TIQUETE', [N('Tiquete ID')], 'write'),
  ('Actualizar', 'ACTUALIZAR_TIQUETE', [N('ID'), T('Prioridad'), T('Asunto'), T('Descripción')], 'write')]),
 'Facturas': ('PKG_FACTURAS', [
  ('Listar', 'OBTENER_FACTURAS', [], 'list'), ('Por cliente', 'OBTENER_FACTURAS_POR_CLIENTE', [N('Cliente ID')], 'list'),
  ('Crear', 'CREAR_FACTURA', [N('Cliente ID'), O('Cotización ID'), T('Número de factura'), D('Vencimiento'), F('Total')], 'create'),
  ('Registrar pago', 'REGISTRAR_PAGO', [N('ID')], 'write'),
  ('Actualizar', 'ACTUALIZAR_FACTURA', [N('ID'), D('Vencimiento'), T('Estado')], 'write'),
  ('Anular', 'ANULAR_FACTURA', [N('ID')], 'write')])
}

def pedir(campo):
    nombre, tipo = campo
    opcional = tipo.endswith('?')
    tipo = tipo.rstrip('?')
    while True:
        valor = input(f'{nombre}{" (Enter = ninguno)" if opcional else ""}: ').strip()
        if not valor and opcional:
            return None
        try:
            if tipo == 'int': return int(valor)
            if tipo == 'float': return float(valor)
            if tipo == 'date': return datetime.strptime(valor, '%d/%m/%Y')
            if valor: return valor
        except ValueError:
            pass
        print('Valor inválido. Fechas: DD/MM/YYYY.')

def ejecutar(conn, paquete, accion):
    etiqueta, procedimiento, campos, modo = accion
    parametros = [pedir(c) for c in campos]
    if modo == 'write' and etiqueta in ('Eliminar', 'Desactivar', 'Cancelar', 'Anular'):
        if input('¿Confirmar? (S/N): ').strip().upper() != 'S': return
    with conn.cursor() as cursor:
        if modo == 'list':
            with conn.cursor() as resultado:
                cursor.callproc(f'NEXATEC.{paquete}.{procedimiento}', parametros + [resultado])
                print(' | '.join(c[0] for c in resultado.description))
                filas = resultado.fetchall()
                for fila in filas:
                    print(' | '.join(str(v) if v is not None else '' for v in fila))
                print(f'{len(filas)} registro(s)')
        elif modo == 'create':
            nuevo_id = cursor.var(oracledb.NUMBER)
            cursor.callproc(f'NEXATEC.{paquete}.{procedimiento}', parametros + [nuevo_id])
            conn.commit()
            print(f'Registro creado: {nuevo_id.getvalue()}')
        else:
            cursor.callproc(f'NEXATEC.{paquete}.{procedimiento}', parametros)
            conn.commit()
            print('Operación completada.')

def menu(conn, nombre, paquete, acciones):
    while True:
        print(f'\n--- {nombre.upper()} ---')
        for i, accion in enumerate(acciones, 1):
            print(f'{i}. {accion[0]}')
        print('0. Volver')
        opcion = input('Opción: ').strip()
        if opcion == '0': return
        if opcion.isdigit() and 1 <= int(opcion) <= len(acciones):
            try:
                ejecutar(conn, paquete, acciones[int(opcion) - 1])
            except oracledb.DatabaseError as error:
                conn.rollback()
                print(f'Error Oracle: {error}')
        else:
            print('Opción inválida.')

def main():
    try:
        with oracledb.connect(**DB) as conn:
            nombres = list(MODULOS)
            while True:
                print('\n=== NEXATEC SOLUCIONES S.A. ===')
                for i, nombre in enumerate(nombres, 1):
                    print(f'{i}. {nombre}')
                print('0. Salir')
                opcion = input('Opción: ').strip()
                if opcion == '0': return
                if opcion.isdigit() and 1 <= int(opcion) <= len(nombres):
                    nombre = nombres[int(opcion) - 1]
                    paquete, acciones = MODULOS[nombre]
                    menu(conn, nombre, paquete, acciones)
                else:
                    print('Opción inválida.')
    except oracledb.DatabaseError as error:
        print(f'No se pudo conectar a Oracle: {error}')
    except (KeyboardInterrupt, EOFError):
        print('\nSaliendo.')

if __name__ == '__main__':
    main()
