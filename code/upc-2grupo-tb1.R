``{r carga_datos}
#install.packages('rstatix')
#install.packages("tinytex")# 1. Preparación del entorno
rm(list = ls(all= TRUE))
graphics.off()

# 2. Carga de librerías
library(tidyverse) 
library(patchwork)
library(rstatix)
library(paletteer)


# 3. Configuración de directorio 
# (Nota: En R Markdown el directorio por defecto es la ubicación del archivo .Rmd)
setwd("C:/Users/HP/Documents/r")


# 4. Validación del separador de CSV
primera_linea <- readLines("hotel_bookings.csv", n = 1)

if (grepl(",", primera_linea)) {
  print("Separador formato estándar inglés") 
} else if (grepl(";", primera_linea)) {
  print("Separador formato estándar hispano")
} else {
  print("Formato de separador desconocido")
}

# 5. Lectura del archivo
df <- read.csv("hotel_bookings.csv", header = TRUE, stringsAsFactors = FALSE)
```

### Inspeccion de datos
#### Verificar cantidad de columnas y filas
# Verificamos el número de columnas y filas 
dim(df)

#### Visualizar los datos iniciales
# Miramos un poco de los datos iniciales 
head(df)
### Visualizar los nombres de las columnas
La función names(df) permite listar los nombres de todas las variables presentes en el dataset. Esto es útil para identificar las columnas disponibles y facilitar su uso en posteriores procesos de análisis y manipulación.

# Miramos los nombres de las columnas
names(df)
### Visualizar la estructura general del dataset
# Exploramos los tipos de variables de las columnas
str(df)
# Vemos un resumen general de nuestros datos 
summary(df)

------------------------------------------------------------------------
  
  ##  PRE-PROCESAMIENTO: IDENTIFICACIÓN Y TRATAMIENTO DE DATOS FALTANTES
  
  ### Limpieza de datos
  
# Estandarizamos los textos vacíos a formato NA matemático
df <- df %>%
  mutate(across(where(is.character), ~na_if(na_if(.x, ""), "NULL")))

# Contamos todos los NAs reales de la tabla
valores_nulos <- colSums(is.na(df))

print("Columnas con valores nulos:")
print(valores_nulos[valores_nulos > 0])

# Aplicamos técnicas de imputación para no perder filas de información valiosa
df <- df %>%
  mutate(
    # Para la variable numérica 'children', imputamos con la mediana (0)
    children = replace_na(children, median(children, na.rm = TRUE)),
    
    # Para agent y company NA significa reserva directa. Rellenamos con "0"
    agent = replace_na(agent, "0"),
    company = replace_na(company, "0"),
    
    # Para country reemplazamos los vacíos con la etiqueta "Unknown"
    country = replace_na(country, "Unknown")
  )

# Verificamos que ya no queden NAs
print("Total de NAs restantes tras imputación:")
sum(is.na(df)) # Debería imprimir 0



------------------------------------------------------------------------
  
  ###Pre-procesamiento: Transformacion de varaibles
  
  # 1. Variables de texto e IDs que funcionan como Categorías (Factores)
  cols_chr_a_factor <- c("hotel", "arrival_date_month", "meal", "country", 
                         "market_segment", "distribution_channel", "reserved_room_type", 
                         "assigned_room_type", "deposit_type", "customer_type", 
                         "reservation_status", "agent", "company")

# 2. Variables numéricas que son Binarias o Periodos temporales finitos (Factores)
cols_int_a_factor <- c("is_canceled", "is_repeated_guest", "arrival_date_year", 
                       "arrival_date_week_number", "arrival_date_day_of_month")

# Aplicamos las transformaciones
df <- df %>%
  mutate(across(all_of(c(cols_chr_a_factor, cols_int_a_factor)), as.factor)) %>%
  mutate(reservation_status_date = as.Date(reservation_status_date))


### Selección de datos de interés
# Inspección de cardinalidad en variables categóricas
nlevels(df$agent)
nlevels(df$company)
nlevels(df$country)

# Inspección visual rápida
ggplot(df, aes(x = meal)) + 
  geom_bar(fill = "steelblue", color = "black") + 
  labs(title = "Distribución del Régimen de Alimentación", 
       x = "Tipo de Paquete", y = "Cantidad de Reservas") +
  theme_minimal()


# Cálculo de frecuencias y Gráfico Lollipop
df %>%
  count(reserved_room_type) %>%
  mutate(porcentaje = n / sum(n) * 100) %>%
  ggplot(aes(x = reorder(reserved_room_type, -porcentaje), y = porcentaje)) +
  
  geom_segment(aes(xend = reserved_room_type, y = 0, yend = porcentaje), 
               color = "darkgray", size = 1) +
  
  geom_point(color = "steelblue", size = 4) +
  # agregamos el texto del porcentaje  arriba del punto
  geom_text(aes(label = sprintf("%.1f%%", porcentaje)), vjust = -1.5, size = 3.5) +
  theme_minimal() +
  labs(
    title = "Preferencia de Infraestructura: Tipo de Habitación Reservada",
    subtitle = "Concentración porcentual de la demanda por categoría de cuarto",
    x = "Código de Habitación",
    y = "Porcentaje de Demanda (%)"
  ) +
  theme(plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust=0.5)) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.15)))

# Inspección de frecuencias relativas en porcentajes
round(prop.table(table(df$reserved_room_type)) * 100, 2)

# Cálculo de frecuencias y Gráfico de Barras Horizontales Condicionales
df %>%
  filter(!is.na(assigned_room_type)) %>%
  count(assigned_room_type) %>%
  mutate(porcentaje = n / sum(n) * 100) %>%
  # Creamos una regla: Si es A o D se pinta de un color, el resto de otro
  mutate(color_resalte = ifelse(assigned_room_type %in% c("A", "D"), "Principal", "Secundario")) %>%
  ggplot(aes(x = reorder(assigned_room_type, porcentaje), y = porcentaje, fill = color_resalte)) +
  geom_col(width = 0.7) +
  # Volteamos el gráfico para que las letras se lean de arriba hacia abajo
  coord_flip() + 
  geom_text(aes(label = sprintf("%.1f%%", porcentaje)), hjust = -0.2, size = 3.5) +
  scale_fill_manual(values = c("Principal" = "steelblue", "Secundario" = "lightgray")) +
  theme_minimal() +
  theme(legend.position = "none") + # Escondemos la leyenda de colores por limpieza
  labs(
    title = "Distribución Operativa: Tipo de Habitación Asignada",
    subtitle = "Frecuencia de entrega física de cuartos en recepción (Check-in)",
    x = "Código de Habitación Asignada",
    y = "Porcentaje de Asignación (%)"
  ) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.15)))

#  Solo reservas NO canceladas
df_exitosas <- df %>%
  filter(is_canceled == "0") %>% # Filtramos 
  count(reserved_room_type, assigned_room_type) %>%
  group_by(reserved_room_type) %>%
  mutate(porcentaje = n / sum(n) * 100) # Porcentaje de asignación por cada tipo reservado

# Generar el Heatmap
ggplot(df_exitosas, aes(x = assigned_room_type, y = reserved_room_type, fill = porcentaje)) +
  geom_tile(color = "white") +
  scale_fill_gradient(low = "#f1f7ff", high = "steelblue") +
  # Agregamos el texto del porcentaje en cada celda
  geom_text(aes(label = sprintf("%.1f%%", porcentaje)), 
            size = 3, color = ifelse(df_exitosas$porcentaje > 50, "white", "black")) +
  theme_minimal() +
  labs(
    title = "Matriz de Coincidencia: Habitación Reservada vs. Asignada",
    subtitle = "Análisis de lealtad al pedido original en reservas concretadas",
    x = "Habitación Asignada (Realidad)",
    y = "Habitación Reservada (Expectativa)",
    fill = "% de Casos"
  )+
  theme(plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust=0.5)) 
# Inspección de frecuencias relativas en Porcentajes
round(prop.table(table(df$assigned_room_type)) * 100, 2)
summary(df$arrival_date_week_number)

# Gráfico de  diario (Día del mes)
p_dia <- df %>%
  count(arrival_date_day_of_month) %>%
  mutate(dia = as.numeric(as.character(arrival_date_day_of_month))) %>%
  ggplot(aes(x = dia, y = n)) +
  geom_line(color = "darkgray", size = 1) +
  geom_point(color = "red", size = 2) +
  theme_minimal() +
  labs(
    title = "Histograma Dia de mes",
    subtitle = "Volatilidad por día del mes",
    x = "Día del Mes (1-31)",
    y = "Volumen de Reservas"
  )

# Gráfico de  semanal (Semana del año)
p_semana <- df %>%
  count(arrival_date_week_number) %>%
  mutate(semana = as.numeric(as.character(arrival_date_week_number))) %>%
  ggplot(aes(x = semana, y = n)) +
  geom_line(color = "darkgray", size = 1) +
  geom_point(color = "steelblue", size = 2) +
  theme_minimal() +
  labs(
    title = "Histograma num de semana del año",
    subtitle = "Volatilidad por semana del año",
    x = "Semana del Año (1-53)",
    y = "Volumen de Reservas"
  )

# Unir los gráficos 
p_dia + p_semana

# Demostración visual de redundancia estructural
df %>%
  # Etiquetamos el 0 y 1 temporalmente para que la leyenda del gráfico sea clara
  mutate(is_canceled_label = factor(is_canceled, labels = c("0 (Concretada)", "1 (Anulada)"))) %>%
  ggplot(aes(x = reservation_status, fill = is_canceled_label)) +
  # Usamos position = "dodge" para poner las barras lado a lado si hubiera mezcla
  geom_bar(position = "dodge", color = "white", alpha = 0.9) +
  scale_fill_manual(values = c("0 (Concretada)" = "steelblue", "1 (Anulada)" = "#BD1100")) +
  theme_minimal() +
  labs(
    title = "Estado Final vs. Variable Binaria",
    subtitle = "Demostración de superposición exacta entre ambas métricas",
    x = "Estado Final Operativo (reservation_status)",
    y = "Volumen de Reservas",
    fill = "Variable is_canceled"
  ) +
  theme(plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust=0.5)) 


summary(df$distribution_channel)

summary(df$market_segment)

summary(df$deposit_type)

summary (df$ customer_type)

summary(df$is_repeated_guest)

# Cruce de comprobación para ver dónde están los clientes
table(df$market_segment,df$distribution_channel)


df %>%
  # Agrupamos y contamos las intersecciones
  count(market_segment, distribution_channel) %>%
  ggplot(aes(x = distribution_channel, y = market_segment, fill = n)) +
  # Dibujamos los cuadrados
  geom_tile(color = "white") +
  # Escala de colores con paletteer
  scale_fill_gradientn(
    colors = paletteer_dynamic("cartography::wine.pal", 20),
    name = "Volumen"
  ) +
  # Agregamos los números exactos
  geom_text(aes(label = n),
            color = ifelse(df %>% count(market_segment, distribution_channel) %>% pull(n) > 20000,
                           "white", "black"),
            size = 3.5) +
  theme_minimal() +
  labs(
    title = "Matriz de Frecuencias Segmento vs. Canal de Distribución",
    subtitle = "Volumen absoluto de reservas por perfil de cliente y vía de ingreso",
    x = "distribution_channel",
    y = "market segment"
  ) +
  theme(plot.title = element_text(face = "bold", hjust = 0.5),
        plot.subtitle = element_text(hjust = 0.5))


summary(df$is_repeated_guest)

df %>%
  # contamos las combinaciones exactas de hotel y tipo de huésped
  count(hotel, is_repeated_guest) %>%
  # agrupamos por hotel 
  group_by(hotel) %>%
  mutate(
    tipo = ifelse(is_repeated_guest == 1, "Huésped Recurrente", "Huésped Nuevo"),
    porcentaje = n / sum(n) * 100
  ) %>%
  # desagrupamos para evitar errores en ggplot
  ungroup() %>%
  ggplot(aes(x = 2, y = porcentaje, fill = tipo)) +
  geom_col(color = "white", size = 1) +
  coord_polar(theta = "y") +
  # Redujimos un poco el tamaño de la letra (size = 3.5) porque ahora los círculos son más pequeños
  geom_text(aes(label = sprintf("%.1f%%", porcentaje)), 
            position = position_stack(vjust = 0.5), 
            color = "white", size = 3.5, fontface = "bold") +
  scale_fill_paletteer_d("ggthemes::excel_Badge") +
  # dividimos el gráfico en dos  por hotel
  facet_wrap(~ hotel) +
  theme_void() +
  labs(
    title = "Proporción de Retención por Tipo de Hotel",
    subtitle = "Distribución de clientes nuevos frente a visitantes recurrentes",
    fill = "Historial del Cliente"
  ) +
  theme(
    plot.title = element_text(face = "bold", hjust = 0.5, margin = margin(b = 5)),
    plot.subtitle = element_text(hjust = 0.5, margin = margin(b = 15)),
    legend.position = "bottom",
    # le damos formato a los títulos de arriba de cada círculo
    strip.text = element_text(face = "bold", size = 11) 
  )


print("Tipo de deposito")
summary(df$deposit_type)
print("Tipo de cliente")
summary(df$customer_type)



df %>%
  ggplot(aes(x = customer_type, fill = deposit_type)) +
  geom_bar(color = "white", alpha = 0.85) +
  coord_flip() +
  scale_fill_paletteer_d("ggpomological::pomological_palette") +
  theme_minimal() +
  labs(
    title = "Políticas de Depósito por Tipo de Cliente",
    subtitle = "Volumen total de reservas según el contrato y garantía exigida",
    x = "Tipo de Cliente",
    y = "Cantidad de Reservas",
    fill = "Tipo de Depósito"
  ) +
  theme(plot.title = element_text(face = "bold", hjust = 0.5),
        plot.subtitle = element_text(hjust = 0.5),
        legend.position = "bottom")



print("previas cancelacione")
factorr <- as.factor(df$previous_cancellations)
summary(factorr)
print("previas no canelaciones")
factorr2 <- as.factor(df$previous_bookings_not_canceled)
summary(factorr2)


df %>%
  select(previous_cancellations, previous_bookings_not_canceled) %>%
  pivot_longer(cols = everything(),
               names_to = "Variable",
               values_to = "Cantidad") %>%
  
  ggplot(aes(x = Variable, y = Cantidad, color = Variable)) +
  
  geom_jitter(width = 0.25, height = 0, alpha = 0.3, size = 1.5) +
  
  scale_color_manual(values = c(
    "previous_cancellations" = "#BD1100",
    "previous_bookings_not_canceled" = "steelblue"
  )) +
  
  theme_minimal() +
  theme(legend.position = "none") +
  
  labs(
    title = "Dispersión del Historial del Huésped",
    x = "Variable",
    y = "Cantidad"
  )+
  theme(plot.title = element_text(face = "bold", hjust = 0.5))

#visualizacion de boxplots de variables numericas 

# --- BLOQUE 1: Tiempos y Estancias ---
f1 <- ggplot(df, aes(x="", y = lead_time)) + geom_boxplot(fill = "gray",outlier.colour = "red") + 
  labs(title = "Anticipación", y="Días") + theme_minimal() + theme(plot.title = element_text(hjust = 0.5, face = "bold"))

f2 <- ggplot(df, aes(x="",y = stays_in_weekend_nights)) + geom_boxplot(fill = "gray", outlier.colour = "red") + 
  labs(title = "Noches Finde", y="Noches") + theme_minimal() + theme(plot.title = element_text(hjust = 0.5, face = "bold"))

f3 <- ggplot(df, aes(x="",y = stays_in_week_nights)) + geom_boxplot(fill = "gray", outlier.colour = "red") + 
  labs(title = "Noches Semana", y="Noches") + theme_minimal() + theme(plot.title = element_text(hjust = 0.5, face = "bold"))

f1 + f2 + f3 


# --- BLOQUE 2: Composición de Huéspedes ---
f4 <- ggplot(df, aes(x="",y = adults)) + geom_boxplot(fill = "gray", outlier.colour = "red") + 
  labs(title = "Adultos", y="Cantidad") + theme_minimal() + theme(plot.title = element_text(hjust = 0.5, face = "bold"))

f5 <- ggplot(df, aes(x="",y = children)) + geom_boxplot(fill = "gray", outlier.colour = "red") + 
  labs(title = "Niños", y="Cantidad") + theme_minimal() + theme(plot.title = element_text(hjust = 0.5, face = "bold"))

f6 <- ggplot(df, aes(x="",y = babies)) + geom_boxplot(fill = "gray", outlier.colour = "red") + 
  labs(title = "Bebés", y="Cantidad") + theme_minimal() + theme(plot.title = element_text(hjust = 0.5, face = "bold"))

f4 + f5 + f6 

# --- BLOQUE 3: Historial del Cliente ---
f7 <- ggplot(df, aes(x="",y = previous_cancellations)) + geom_boxplot(fill = "gray", outlier.colour = "red") + 
  labs(title = "Cancelaciones Previas") + theme_minimal() + theme(plot.title = element_text(hjust = 0.5, face = "bold"))

f8 <- ggplot(df, aes(x="",y = previous_bookings_not_canceled)) + geom_boxplot(fill = "gray", outlier.colour = "red") + 
  labs(title = "Reservas Exitosas") + theme_minimal() + theme(plot.title = element_text(hjust = 0.5, face = "bold"))

f9 <- ggplot(df, aes(x="",y = days_in_waiting_list)) + geom_boxplot(fill = "gray", outlier.colour = "red") + 
  labs(title = "Días en Espera") + theme_minimal() + theme(plot.title = element_text(hjust = 0.5, face = "bold"))

f7 + f8 + f9 

# --- BLOQUE 4: Reserva y Costos ---
f10 <- ggplot(df, aes(x="",y = booking_changes)) + geom_boxplot(fill = "gray", outlier.colour = "red") + 
  labs(title = "Cambios Reserva") + theme_minimal() + theme(plot.title = element_text(hjust = 0.5, face = "bold"))

f11 <- ggplot(df, aes(x="",y = required_car_parking_spaces)) + geom_boxplot(fill = "gray", outlier.colour = "red") + 
  labs(title = "Parqueos") + theme_minimal() + theme(plot.title = element_text(hjust = 0.5, face = "bold"))

f12 <- ggplot(df, aes(x="",y = total_of_special_requests)) + geom_boxplot(fill = "gray", outlier.colour = "red") + 
  labs(title = "Peticiones Especiales") + theme_minimal() + theme(plot.title = element_text(hjust = 0.5, face = "bold"))

f13 <- ggplot(df, aes(x="",y = adr)) + geom_boxplot(fill = "orange", outlier.colour = "red") + 
  labs(title = "Tarifa Diaria (ADR)") + theme_minimal() + theme(plot.title = element_text(hjust = 0.5, face = "bold"))

(f10 + f11) / (f12 + f13) 


#==============================================================================
# DETECCIÓN DE VALORES EXTREMOS aduolt , children babies 
# ==============================================================================
g_babies <- ggplot(df, aes(x = as.factor(babies))) +
  geom_bar(fill = "steelblue", color = "black") +
  labs(title = "Distribución de Bebés por Reserva",
       subtitle = "Detección de valores atípicos (frecuencias inusuales)",
       x = "Cantidad de Bebés",
       y = "Número de Reservas") +
  theme_minimal()

g_children <- ggplot(df, aes(x = as.factor(children))) +
  geom_bar(fill = "darkorange", color = "black") +
  labs(title = "Distribución de Niños por Reserva",
       subtitle = "Detección de valores atípicos",
       x = "Cantidad de Niños",
       y = "Número de Reservas") +
  theme_minimal()

# Gráfico para detectar anomalías en requerimiento de estacionamientos
g_parking <- ggplot(df, aes(x = as.factor(required_car_parking_spaces))) +
  geom_bar(fill = "olivedrab", color = "black") +
  scale_y_log10() + # Para que los valores pequeños (outliers) sean visibles
  labs(title = "Detección de Outliers en Estacionamientos",
       subtitle = "Uso de escala logarítmica para identificar pedidos inusuales",
       x = "Espacios de Estacionamiento Requeridos",
       y = "Conteo (Log10)") +
  theme_minimal()

df %>% 
  mutate(fila = row_number()) %>%
  identify_outliers(children) %>%
  select(fila, children, is.outlier, is.extreme) %>% 
  filter(children == 10)

# 1. Creación de la variable categórica para niños
df <- df %>%
  mutate(perfil_nino = if_else(children > 0, "Con Niños", "Sin Niños"))

# 2. Convertir a factor para el análisis
df$perfil_nino <- as.factor(df$perfil_nino)

# 3. Ver el conteo (notarás que 'Sin Niños' es la gran mayoría)
table(df$perfil_nino)


ggplot(df, aes(x = perfil_nino, fill = perfil_nino)) +
  geom_bar() +
  labs(title = "Distribución de Reservas: Presencia de Niños",
       subtitle = "Análisis de segmentación",
       x = "Segmento de Reserva",
       y = "Cantidad de Registros") +
  scale_fill_manual(values = c("Con Niños" = "#33a02c", "Sin Niños" = "#1f78b4")) +
  theme_minimal() +
  theme(legend.position = "none")

#Estacionamientos

df %>% 
  mutate(fila = row_number()) %>%
  identify_outliers(required_car_parking_spaces) %>%
  select(fila, required_car_parking_spaces, is.outlier, is.extreme) %>% 
  filter(required_car_parking_spaces == 8)

# Creación de la variable dicotómica
df <- df %>%
  mutate(perfil_estacionamiento = if_else(required_car_parking_spaces > 0, 
                                          "Con Estacionamiento", 
                                          "Sin Estacionamiento"))

# Convertir a factor
df$perfil_estacionamiento <- as.factor(df$perfil_estacionamiento)


table(df$perfil_estacionamiento)

# Gráfico comparativo: Con Estacionamiento vs Sin Estacionamiento
ggplot(df, aes(x = perfil_estacionamiento, fill = perfil_estacionamiento)) +
  geom_bar() +
  # Aplicamos escala logarítmica para que el segmento "Con Estacionamiento" sea visible
  labs(title = "Distribución de Reservas: Requerimiento de Estacionamiento",
       subtitle = "Comparación de volumen entre categorías",
       x = "Segmento de Estacionamiento",
       y = "Cantidad de Registros") +
  scale_fill_manual(values = c("Con Estacionamiento" = "#4daf4a", "Sin Estacionamiento" = "#984ea3")) +
  theme_minimal() +
  theme(legend.position = "none")

#Deteccion de las filas vacias
reservas_vacias <- df %>% 
  filter(adults == 0 & children == 0 & babies == 0)
reservas_vacias

#Eliminación de filas donde children,babies y adults son 0

df <- df %>% 
  filter(!(adults == 0 & children == 0 & babies == 0))

# 1. Calculamos la mediana de adultos (excluyendo los ceros para no sesgar la mediana)
mediana_adultos <- median(df$adults[df$adults > 0], na.rm = TRUE)

# 2. Aplicamos el cambio solo a quienes tienen 0 adultos pero 
df <- df %>%
  mutate(adults = case_when(
    adults == 0 ~ mediana_adultos,
    TRUE ~ adults # Mantener el valor original en los demás casos
  ))

#==============================================================================
# DETECCIÓN DE VALORES EXTREMOS (OUTLIERS) EN TARIFA DIARIA (ADR)
# ==============================================================================

# 1. Exploración general de la distribución de la variable
summary(df$adr)

# ==============================================================================
#  ANÁLISIS DEL LÍMITE SUPERIOR (VALORES MÁXIMOS ATÍPICOS)
# ==============================================================================

# Se detectó un registro anómalo con un precio de 5400.00
# Inspeccionamos las columnas clave para buscar una justificación comercial
df %>% 
  select(adr, customer_type, market_segment,stays_in_weekend_nights, stays_in_week_nights,assigned_room_type,
         reservation_status) %>% 
  filter(adr == 5400.00)

# Hallazgos de la auditoría manual:
# - Pertenece al mercado "Offline TA/TO".
# - Habitación asignada: Tipo "A" (estándar).
# - Cliente tipo "Transient" (no recurrente), para 1 noche (días de semana).
# - Cero espacios de estacionamiento.
# Conclusión preliminar: Las características no justifican una tarifa de lujo.
df %>% 
  filter(adr == 5400.00)

# Para confirmar el error, comparamos este caso con el precio de reservas similares 
# (habitaciones tipo A en el mismo segmento)
# Confirmación: Se evidencia una falta total de correlación entre el servicio 
# recibido y la tarifa cobrada de 5400.00. 
# Decisión: El registro de 5400.00 queda marcado para eliminación.
df %>% 
  select(adr, customer_type, market_segment, assigned_room_type, adults, required_car_parking_spaces) %>% 
  filter(adr > 126) %>% 
  arrange(desc(adr))

# ==============================================================================
#  ANÁLISIS DEL LÍMITE INFERIOR (VALORES NEGATIVOS)
# ==============================================================================

# El summary inicial reveló la existencia de tarifas negativas (imposibilidad financiera)
df %>% 
  select(adr, customer_type, market_segment) %>% 
  filter(adr == -6.38)

# Auditoría del registro negativo:
# - Reserva para 2 adultos.
# - Estadía total de 10 noches (6 en semana, 4 en fin de semana).
# Decisión: Al ser un error de sistema irrefutable (el hotel no paga al cliente por quedarse), 
# se procede con la eliminación de este registro.
df %>% 
  filter(adr == -6.38)

# ==============================================================================
#  ANÁLISIS DE TARIFAS NULAS (ADR = 0)
# ==============================================================================

# Se detectaron múltiples registros con precio exactamente igual a cero.
df %>% 
  select(adr, customer_type, market_segment) %>% 
  filter(adr < 69.50)

df %>% 
  select(adr, customer_type, market_segment, is_canceled, reservation_status, deposit_type) %>% 
  filter(adr == 0)

# Para auditar su validez, agrupamos los ceros por Segmento de Mercado.
# La premisa es que los ceros son válidos únicamente si el cliente es un invitado.
df %>%
  filter(adr == 0) %>%
  count(market_segment, name = "Cantidad_de_Ceros") %>%
  arrange(desc(Cantidad_de_Ceros))

# Hallazgo 1: Existen 665 reservas en el segmento "Complementary". 
# Decisión: Estos ceros tienen justificación comercial (cortesías/invitados). Se conservan.


# A continuación, analizamos los ceros restantes 1145  buscando patrones de cancelación.
# ¿Son clientes que reservaron sin depósito y luego cancelaron (por lo que nunca pagaron)?
df %>%
  filter(adr == 0, is_canceled == 1, deposit_type == "No Deposit") %>%
  count(market_segment, name = "Cantidad_de_Ceros") %>%
  arrange(desc(Cantidad_de_Ceros))

# Hallazgo 2: Existen 104 registros cancelados sin depósito previo. 
# Exploramos estos casos específicos excluyendo a los invitados ("Complementary").
df %>%
  filter(adr == 0, is_canceled == 1, deposit_type == "No Deposit", market_segment != "Complementary") %>%
  select(adr, customer_type, market_segment, is_canceled, reservation_status, deposit_type) 

# ==============================================================================
#  AISLAMIENTO DE ERRORES CRÍTICOS (CEROS INCOHERENTES)
# ==============================================================================

# El enfoque principal recae sobre clientes comerciales (no invitados) que sí 
# asistieron al hotel, sí hicieron "Check-Out", pero registraron un pago de 0.
df %>%
  filter(adr == 0, is_canceled == 0, market_segment != "Complementary", reservation_status == "Check-Out") %>%
  count(market_segment, name = "Cantidad_de_Ceros") %>%
  arrange(desc(Cantidad_de_Ceros))

# Resultado: Se aíslan 1041 casos anómalos.
# Visualizamos la estructura de estas reservas incoherentes:
df %>%
  filter(adr == 0, is_canceled == 0, market_segment != "Complementary", reservation_status == "Check-Out") %>% 
  select(adr, is_canceled, reservation_status, market_segment, stays_in_weekend_nights, stays_in_week_nights, adults)



# ==============================================================================
#  ELIMINACIÓN DE VALORES ATÍPICOS EN ADR
# ==============================================================================


df2 <- df %>%
  # 1. Eliminar el precio extremo superior (error de digitación)
  filter(adr != 5400.00) %>%
  
  # 2. Eliminar el precio negativo (imposibilidad física)
  filter(adr >= 0) %>%
  
  # 3. Eliminar los ceros incoherentes 
  # (Se quedan las filas donde ADR es mayor a 0, O donde el ADR es 0 pero son "Complementary")
  # Además, para asegurarnos de que los 104 que cancelaron sin depósito (ADR=0) tampoco ensucien el modelo de precios, 
  # la regla general más limpia es: Si el precio es cero, SOLO se salva si es cortesía.
  filter(adr > 0 | market_segment == "Complementary")

# Validación post-limpieza
summary(df2$adr)



df2 %>%
  filter(market_segment == "Complementary", adr ==0) %>%
  select(adr, customer_type, market_segment, is_canceled, reservation_status, deposit_type) 


df2graficp <- ggplot(df2, aes(x="",y = adr)) + geom_boxplot(fill = "gray", outlier.colour = "red") + 
  labs(title = "adr original despues de limpieza", y="Noches") + theme_minimal() + theme(plot.title = element_text(hjust = 0.5, face = "bold"))
df2graficp



#aun hay outlier 
summary(df2$adr)

#aplicamos winsorizacion o o tambien llamdocaping 

upper_bound_adr <- quantile(df$adr, 0.99, na.rm = TRUE)
df2 <- df2 %>%
  mutate(adr_capped22= ifelse(adr > upper_bound_adr, upper_bound_adr, adr))
summary(df2$adr_capped22)

#graficamos un antes y un despues 
df2graficp2 <- ggplot(df2, aes(x="",y = adr_capped22)) + geom_boxplot(fill = "gray", outlier.colour = "red") + 
  labs(title = "adr con esl caping", y="Noches") + theme_minimal() + theme(plot.title = element_text(hjust = 0.5, face = "bold"))
df2graficp2


df2graficp3 <- ggplot(df2, aes(x="",y = adr)) + geom_boxplot(fill = "gray", outlier.colour = "red") + 
  labs(title = "adr inicial ", y="Noches") + theme_minimal() + theme(plot.title = element_text(hjust = 0.5, face = "bold"))
df2graficp3 + df2graficp2

#aun que hay aun outlier ya no podemos aplicar winsorizacion solo un aves y al ser valores que ya no estan aislados como los anteriores los dejamos asi 






# ==============================================================================
#  TRATAMIENTO DE VALORES ATÍPICOS EN ANTICIPACIÓN DE RESERVA (LEAD TIME)
# ==============================================================================

# 1 Exploración visual y estadística de la variable original
summary(df2$lead_time)

gleadtime <- ggplot(df2, aes(x="",y = lead_time)) + geom_boxplot(fill = "gray", outlier.colour = "red") + 
  labs(title = "Anticipación de Reserva (Original)", y="Días") + theme_minimal() + theme(plot.title = element_text(hjust = 0.5, face = "bold"))
gleadtime

# 2 Calcular el límite exacto del Percentil 99
upper_bound_lead <- quantile(df2$lead_time, 0.99, na.rm = TRUE)
print(paste("El límite del Percentil 99 para lead_time es:", upper_bound_lead))

# 3 Aplicar Winsorización (Capping) en una NUEVA columna
df2 <- df2 %>%
  mutate(lead_time_capped = ifelse(lead_time > upper_bound_lead, upper_bound_lead, lead_time))

# 4 Validar la nueva distribución
summary(df2$lead_time_capped)

# 5 Comparación visual
gleadtime_capped <- ggplot(df2, aes(x="",y = lead_time_capped)) + geom_boxplot(fill = "gray", outlier.colour = "red") + 
  labs(title = "Anticipación de Reserva ", y="Días") + theme_minimal() + theme(plot.title = element_text(hjust = 0.5, face = "bold"))

# Mostrar ambos gráficos juntos para el informe
gleadtime + gleadtime_capped


# outliers week 
#  weekend y week night

#================================================================

# Clientes que pasaron 0 noches e hicieron Check-Out
df2 %>%
  filter(stays_in_week_nights == 0 & stays_in_weekend_nights == 0 & reservation_status == "Check-Out" ) %>% 
  select(stays_in_weekend_nights, stays_in_week_nights, reservation_status, is_canceled)
#Es justificable porque pueden haber clientes que pasaron en el hotel durante el dia pero no la noche. 

summary(df$stays_in_week_nights)

df2 %>%
  filter(adr > 126 ) %>% 
  arrange(desc(adr))

# Verificando los valores fuera del intercuartil de la variable de stays_in_week_nights
df2 %>%
  filter(stays_in_week_nights > 3) %>% 
  arrange(desc(stays_in_week_nights)) %>% 
  select(stays_in_weekend_nights, stays_in_week_nights, adr, reservation_status, is_canceled,assigned_room_type, adults)





summary(df$stays_in_weekend_nights)


#bosplot de ambas variales 

f2 <- ggplot(df2, aes(x="",y = stays_in_weekend_nights)) + geom_boxplot(fill = "gray", outlier.colour = "red") + 
  labs(title = "Noches Finde", y="Noches") + theme_minimal() + theme(plot.title = element_text(hjust = 0.5, face = "bold"))

f3 <- ggplot(df2, aes(x="",y = stays_in_week_nights)) + geom_boxplot(fill = "gray", outlier.colour = "red") + 
  labs(title = "Noches Semana", y="Noches") + theme_minimal() + theme(plot.title = element_text(hjust = 0.5, face = "bold"))

f2 + f3

# Tabla de frecuencias y porcentajes acumulados para validar el IQR
tabla_frecuencias_finde <- df2 %>%
  count(stays_in_weekend_nights) %>%
  arrange(stays_in_weekend_nights) %>% # Ordenamos por número de noches
  mutate(
    Porcentaje = round(n / sum(n) * 100, 2)) %>%
  rename(Noches_Finde = stays_in_weekend_nights, Frecuencia = n)

print(tabla_frecuencias_finde)

df %>%
  select(stays_in_weekend_nights, stays_in_week_nights, market_segment) %>%
  arrange(desc(stays_in_weekend_nights)) %>%
  head(20)


#Primera prueba:
df %>%
  filter(stays_in_weekend_nights ==1, stays_in_week_nights >=6 ) %>%
  select(stays_in_weekend_nights, stays_in_week_nights, hotel, market_segment)

#Segunda prueba:
df %>%
  filter(stays_in_weekend_nights ==2, stays_in_week_nights >=15 ) %>%
  select(stays_in_weekend_nights, stays_in_week_nights, hotel, market_segment)

#creamos un nueva variable para total de noche 
df3 <- df2 %>%
  mutate(total_nights = stays_in_weekend_nights + stays_in_week_nights)

# Se revisa el resumen estadístico de la nueva columna para buscar atípicos
summary(df3$total_nights)


# Grafico de estancias

grafico_estancias <- ggplot(df3, aes(x = total_nights)) +
  geom_bar(fill = "steelblue", color = "black") +
  scale_y_continuous(trans = "pseudo_log", 
                     breaks = c(0, 1, 10, 100, 1000, 10000, 30000),
                     labels = scales::label_comma()) +
  labs(
    title = "Frecuencia de Estancia Total (Escala Pseudo-Logarítmica)",
    subtitle = "Visualización de la 'cola' de distribución y estancias de larga duración",
    x = "Cantidad de Noches",
    y = "Número de Reservas (Log)"
  ) +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"))

grafico_estancias

# Tabla de frecuencia por el total de noches 

tabla_frecuencias_total <- df3 %>%
  count(total_nights) %>%
  arrange(total_nights) %>%
  mutate(
    Porcentaje = round(n / sum(n) * 100, 4)) %>%
  rename(Total_Noches = total_nights, Frecuencia = n)

print(tabla_frecuencias_total)

# Grafico de estancia por mercado

grafico_mercado_estancia <- ggplot(df3, aes(x = market_segment, y = total_nights, fill = hotel)) +
  geom_boxplot(outlier.colour = "red", outlier.alpha = 0.6) +
  labs(
    title = "Distribución de la Estancia Total por Segmento de Mercado y Hotel",
    x = "Segmento de Mercado",
    y = "Total de Noches",
    fill = "Tipo de Hotel"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold"),
    axis.text.x = element_text(angle = 45, hjust = 1) # Inclina el texto para mejor lectura
  )

grafico_mercado_estancia


# 1. Calculamos el límite superior (ejemplo con percentil 9)
limite_superior <- quantile(df3$total_nights, 0.99)

# 2. Creamos la nueva variable con la data winsorizada
df3 <- df3 %>%
  mutate(total_nights_clean = ifelse(total_nights > limite_superior, 
                                     limite_superior, 
                                     total_nights))

# 3. Verificamos el cambio
summary(df3$total_nights_clean)

# Tratamiento de las variables stays_in_weekend_nights y stays_in_week_nights

upper_bound_total <- quantile(df3$total_nights, 0.99)

df3$total_nights_capped <- ifelse(df3$total_nights > upper_bound_total, 
                                  upper_bound_total, 
                                  df3$total_nights)

par(mfrow = c(1,2))

b1 <- boxplot(df3$total_nights, 
              main = "Estancias con outliers", 
              col = "orange", 
              ylab = "Noches")

b2 <- boxplot(df3$total_nights_capped, 
              main = "Estancias con Winsorización", 
              col = "lightblue", 
              ylab = "Noches")

b1 + b2



# ==============================================================================
#  visualizacion para las preguntas 
# ==============================================================================
#Taza de cancelación por tipo hotel  
df %>%
  filter(is_canceled == 0) %>%
  ggplot(aes(x = hotel, fill = hotel)) +
  geom_bar() +
  labs(title = "Reservas por Tipo de Hotel (No Canceladas)",
       x = "Tipo de Hotel", y = "Total de Reservas") +
  theme_minimal()


#Demanda a traves del tiempo  
df %>%
  group_by(arrival_date_year, arrival_date_month) %>%
  summarise(total = n()) %>%
  ggplot(aes(x = arrival_date_month, y = total, group = arrival_date_year, color = as.factor(arrival_date_year))) +
  geom_line() + geom_point() +
  labs(title = "Evolución de la Demanda por Año",
       x = "Mes", y = "Cantidad de Reservas", color = "Año") +
  theme_light()


#Temporadas de reserva

df %>%
  count(arrival_date_month) %>%
  ggplot(aes(x = reorder(arrival_date_month, n), y = n)) +
  geom_col(fill = "steelblue") +
  coord_flip() +
  labs(title = "Temporadas de Reservas", x = "Mes", y = "Total de Reservas")


#Duración promedio de estancia

df %>%
  mutate(total_nights = stays_in_weekend_nights + stays_in_week_nights) %>%
  group_by(hotel) %>%
  summarise(promedio = mean(total_nights)) %>%
  ggplot(aes(x = hotel, y = promedio, fill = hotel)) +
  geom_col() +
  labs(title = "Promedio de Estancia por Hotel", y = "Noches Promedio")


#Reservas con niños o bebes

df %>%
  mutate(con_ninos = ifelse(children > 0 | babies > 0, "Con Niños/Bebés", "Solo Adultos")) %>%
  ggplot(aes(x = con_ninos, fill = con_ninos)) +
  geom_bar() +
  labs(title = "Distribución de Reservas por Composición Familiar")

#Importancia de los estacionamientos

df %>%
  mutate(necesita_parking = ifelse(required_car_parking_spaces > 0, "Sí", "No")) %>%
  count(necesita_parking) %>%
  ggplot(aes(x = "", y = n, fill = necesita_parking)) +
  geom_bar(stat = "identity", width = 1) +
  coord_polar("y") +
  labs(title = "Importancia de estacionamientos")


#Cancelaciones por mes

df %>%
  filter(is_canceled == 1) %>%
  ggplot(aes(x = arrival_date_month, fill = hotel)) +
  geom_bar(position = "dodge") +
  labs(title = "Cancelaciones de Reservas por Mes", x = "Mes") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# ¿Cuáles son las temporadas de reservas (alta, media, baja)?

df3$arrival_date_month <- factor(df3$arrival_date_month, 
                                 levels = c("January", "February", "March", "April", "May", "June","July", "August", "September", "October", "November", "December"))


df3 <- df3 %>%
  mutate(temporada = case_when(
    arrival_date_month %in% c("July", "August") ~ "Alta",
    arrival_date_month %in% c("May", "June", "September", "October") ~ "Media",
    TRUE ~ "Baja"
  ))

df3$temporada <- factor(df3$temporada, levels = c("Baja", "Media", "Alta"))

ggplot(df3, aes(x = arrival_date_month, fill = temporada)) +
  geom_bar() +
  geom_text(stat='count', aes(label=..count..), vjust=-0.5, size=3.5, fontface="bold") +
  scale_fill_manual(values = c("Baja" = "#76D7C4",   # Verde claro
                               "Media" = "#F7DC6F",  # Amarillo
                               "Alta" = "#EC7063")) + # Rojo/Coral
  labs(title = "Análisis de Estacionalidad: Temporada Alta, Media y Baja",
       subtitle = "Categorización basada en el volumen total de reservas",
       x = "Mes de Llegada",
       y = "Cantidad de Reservas",
       fill = "Temporada") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# ¿Cuál es la duración promedio de las estancias por tipo de hotel?

df_promedios <- df3 %>%
  group_by(hotel) %>%
  summarise(promedio_estancia = mean(total_nights_capped, na.rm = TRUE))

ggplot(df_promedios, aes(x = hotel, y = promedio_estancia, fill = hotel)) +
  geom_bar(stat = "identity", width = 0.6) +
  geom_text(aes(label = round(promedio_estancia, 2)), vjust = -0.5, fontface = "bold") +
  scale_fill_manual(values = c("City Hotel" = "#5DADE2", "Resort Hotel" = "#52BE80")) +
  labs(title = "Duración Promedio de Estancia por Tipo de Hotel",
       subtitle = "Basado en la variable tratada total_nights_capped",
       x = "Tipo de Establecimiento",
       y = "Promedio de Noches") +
  theme_minimal()



