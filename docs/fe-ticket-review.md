# Revisión de impresión CAFE

Se añade configuración PAC por sesión, encabezado DGI y pie PAC condicionales, y traducciones español/inglés. La condición de impresión es configuración aplicable y URL FE no vacía; no sustituye una validación fiscal del estado del documento.

## Datos pendientes del backend

- Fecha/hora real del protocolo: FE_InvoiceResponseLog no tiene un campo explícito; Created no se utiliza como sustituto.
- Fecha límite de transmisión y leyendas de contingencia/autorización posterior.
- Descuento total, importe pagado y vuelto fiscales: no hay una fuente confirmada en la respuesta inspeccionada. No se calculan a partir de pagos de la orden. Si el backend proporciona DiscountAmt, TotalPaid o ChangeAmt se muestran; su ausencia se registra.
- TaxAmt por línea: se muestra cuando existe; no se estima el impuesto fiscal de la factura usando el impuesto de la orden.
- Identificación completa del emisor y receptor: depende de la configuración de impresión y de los datos de la factura. No se acredita correspondencia con el XML firmado.
- PAC histórico: la leyenda usa la configuración actual de sesión; no existe una relación verificada al PAC que procesó cada factura histórica.

Los tickets de regalo conservan su comportamiento. Las pruebas usan respuestas simuladas; no acreditan permisos REST del rol real, impresión física ni cumplimiento fiscal completo.
