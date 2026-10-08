# Exportación de datos legales del PAC

Base inspeccionada: `fe12` local, puerto 5432. Paquete `AD_Package_Exp_ID=1000002`, `com.cds.electronicbilling`.

La definición actual tiene seis detalles de tipo Menú y dos de Datos individuales (`AD_Package_Exp` y `AD_Package_Exp_Detail`). No incluye exportación de registros `FE_PAC`. Exportar tablas, columnas y campos de ventana no exporta automáticamente sus registros.

## Detalle propuesto

Añadir un único registro activo a `AD_Package_Exp_Detail`:

- Paquete: `1000002`.
- Línea: `100`, después del menú de Facturación Electrónica Panamá.
- Tipo: `DS` (Datos individuales).
- Tabla: `FE_PAC` (`AD_Table_ID=1000005` en esta base).
- Cliente y organización: `0`.
- Descripción: `Datos legales de proveedores PAC`.
- Procesando: `N`.
- ID: asignado por la secuencia estándar `AD_Package_Exp_Detail`; UUID nuevo.
- Sentencia SQL:

```sql
SELECT FE_PAC_ID, FE_PAC_UU, AD_Client_ID, AD_Org_ID,
       Name, Value, IsActive,
       FE_LegalName, TaxID, FE_Resolution, FE_ResolutionDate
FROM FE_PAC
WHERE AD_Client_ID = 0
ORDER BY FE_PAC_ID
```

El exportador de iDempiere permite seleccionar columnas explícitamente y omite las no seleccionadas. Se incluyen identidad/UUID, cliente/organización y nombres para identificar los PAC también en destino. No se exportan API keys, UUID de empresa, configuración por cliente ni credenciales.

La consulta devuelve seis PAC del catálogo de Sistema; tres tienen actualmente los datos legales completos (EBI, THEFACTORYHKA y FACTURA FACIL) y tres de demostración no los tienen.

## Exportación y verificación

1. Aprobar y crear el detalle; esto modifica solo la definición de exportación y su secuencia, no los datos `FE_PAC`.
2. Exportar el paquete desde el cliente Sistema (`AD_Client_ID=0`): el exportador de datos omite registros de otro cliente.
3. Usar una versión nueva del 2Pack si la versión anterior ya fue instalada; revisar el mecanismo de actualización usado en destino.
4. Inspeccionar `PackOut.xml`: verificar registros `FE_PAC`, UUID existentes y los cuatro valores legales; verificar ausencia de secretos.
5. Instalar en un entorno de prueba y leer de nuevo `FE_PAC` por UUID para confirmar los valores. Al importar, los valores legales incluidos pueden actualizar los PAC existentes. No acreditar instalación solo con la presencia de columnas.

No se ha modificado la base ni regenerado el paquete durante esta inspección.
