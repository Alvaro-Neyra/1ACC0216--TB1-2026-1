# Universidad Peruana de Ciencias Aplicadas
## Fundamentos de Data Science - 1ACC0216-2610-16310

<p align="center">
  <img src="https://www.canvia.com/wp-content/uploads/2023/08/crymibfuwaapssb.png" alt="Logo UPC" width="200"/>
</p>

### Profesora
Nérida Isabel Manrique Tunque

---

# 1ACC0216 - TB1 - 2026-1  
## Análisis Exploratorio de Datos - Hotel Booking Demand

### Objetivo
El objetivo de este proyecto es realizar un Análisis Exploratorio de Datos (EDA) del conjunto de datos *Hotel Booking Demand* utilizando R/RStudio. Se busca identificar patrones, tendencias y comportamientos en las reservas de hoteles.

---

### Integrantes del Grupo
- Arapa Titi Victor Piero  
- Manrique Anaya Rai Jeferson  
- Neyra Salazar Alvaro Alberto  
- Laurente Castrejon Josue Froilan  

---

### Descripción del Dataset
El conjunto de datos utilizado es **Hotel Booking Demand**, originalmente obtenido de Kaggle y modificado con fines académicos.

Este dataset contiene información sobre:
- Tipo de hotel (Resort o City)
- Detalles de las reservas (fechas, duración, cancelaciones)
- Información de los huéspedes (adultos, niños, bebés)
- Servicios adicionales (como estacionamiento)

Nota: El dataset contiene valores faltantes (NA) y valores atípicos (outliers), los cuales serán tratados durante la etapa de preprocesamiento.

---

### Estructura del Repositorio
```bash
├── data/
├── code/
└── README.md
```

---

### Análisis Esperado
El análisis buscará responder preguntas como:
- ¿Qué tipo de hotel es más preferido?
- ¿Cómo evoluciona la demanda a lo largo del tiempo?
- ¿Cuáles son las temporadas con mayor número de reservas?
- ¿Qué factores influyen en las cancelaciones?

---

### Conclusiones
A partir del análisis del conjunto de datos Hotel Booking Demand, se identificaron los siguientes patrones y recomendaciones:

- Preferencia de Modelo de Negocio: existe una tendencia clara hacia el City Hotel, que concentra el mayor volumen de reservas efectivas en comparación con el Resort Hotel. Esto sugiere una demanda impulsada por el turismo urbano o de negocios.
- Comportamiento de la Estancia: el tipo de hotel se relaciona con la duración de la visita. Los City Hotels presentan estancias más breves y dinámicas, mientras que los Resort Hotels muestran un patrón de retención de huéspedes mucho más largo, lo que indica un uso más enfocado en vacaciones y descanso.
- Estacionalidad Marcada: la demanda no es uniforme a lo largo del año. Se identificaron meses con picos de saturación (Temporada Alta) y meses con caídas drásticas en el volumen de reservas, permitiendo clasificar el año en tres niveles operativos: Baja, Media y Alta.
- Perfil del Consumidor: la mayoría de las reservas corresponde a adultos sin niños. El segmento familiar (niños y bebés) representa una proporción menor, lo que evidencia una tendencia hacia un servicio más enfocado en parejas o viajeros individuales.
- Logística de Servicios: la demanda de estacionamiento es baja en términos porcentuales, lo que indica que muchos huéspedes utilizan medios de transporte alternativos para llegar a las instalaciones.

Recomendaciones:

- Optimización Operativa por Temporada: en Temporada Baja, implementar campañas de descuentos o paquetes promocionales para incentivar la demanda. En Temporada Alta, priorizar la gestión eficiente de inventarios y reforzar el personal operativo para evitar la degradación del servicio.
- Diferenciación de Servicios: para los Resort Hotels, potenciar servicios internos como spa, restaurantes y actividades recreativas para maximizar el ingreso por huésped. Para los City Hotels, priorizar la agilidad en los procesos de check-in y check-out.
- Marketing Segmentado: desarrollar ofertas específicas para reservas con niños, ya que el segmento familiar tiene representación moderada y podría expandirse con la infraestructura adecuada.
- Gestión de Espacios: evaluar la reconversión de áreas de parking infrautilizadas en servicios de mayor valor añadido, como espacios de coworking o zonas de esparcimiento.
- Políticas de Cancelación: revisar las políticas de reserva en los meses con mayores tasas de cancelación, considerando condiciones de prepago o depósitos no reembolsables para proteger la rentabilidad del hotel en periodos de alta volatilidad.

---

### Licencia
Este proyecto es de carácter académico y está destinado únicamente a fines educativos. Se permite su uso y consulta para actividades académicas, pero no se autoriza su explotación comercial sin el permiso expreso de los autores.