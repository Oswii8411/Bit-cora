![Portada](public/img/portadabitacoraredes.png)

# INTRODUCCIÓN

En este documento se vera lo que es el desarrollo, la razón de haber creado una bitácora de redes, la guía de instalación, funcionamiento, justificación y capturas de pantalla que evidencien la existencia del programa.

# JUSTIFICACIÓN

El Instituto Tecnológico Superior de Uruapan cuenta con la tarea de administrar las redes en más de 5 edificios, dificultando la administración de la misma donde hasta el momento no se contaba con una aplicación para poder llevar acabo la tarea, con esta aplicación se busca facilitar la administración de la segmentación de redes y los equipos registrados dentro de la institución para el uso correcto de la red de la institución.

# GUÍA DE INSTALACIÓN Y EJECUCCIÓN
## REQUISITOS NECESARIOS
- Tener instalado Flutter SDK y Dart.
- Tener un IDE o editor de texto

Paso 1. Descargar o clonar el código del siguiente enlace:

**https://github.com/Oswii8411/Bit-cora**

Paso 2. Instalar dependencias con el siguiente comando en la terminal:

**flutter pub get**

Paso 3. Ejecutar la app:

**Flutter run**

# Capturas de funcionamiento

![Pantalla Principal](public/img/principal.png)

![Portada](public/img/inventario.png)

![Portada](public/img/auditoria.png)

![Portada](public/img/nuevared.png)

![Portada](public/img/segmentos.png)

![Portada](public/img/nuevoequipo.png)

# EVIDENCIAS CRUD 

![Portada](public/img/nuevared.png)

![Portada](public/img/filtro.png)

![Portada](public/img/editarequipo.png)

![Portada](public/img/eliminar.png)

# INVENTARIO

![Portada](public/img/inventario.png)

# BUSCADOR 

![Portada](public/img/filtro.png)

# REGISTRO DE INFORMACIÓN (INCIDENCIAS)

Captura del formulario de registro de una nueva incidencia sobre un equipo de la red.

![Nueva Incidencia](public/img/nueva_incidencia.png)

# CONSULTA DE REGISTROS (HISTORIAL)

Captura de la pantalla de Historial, donde se pueden consultar las incidencias reportadas junto con su estado, prioridad y responsable.

![Historial de Incidencias](public/img/historial_incidencias.png)

# EXPLICACIÓN DE PANTALLAS

- **Iniciar sesión**: Pantalla de acceso mediante correo y contraseña, validada contra Supabase Auth. Incluye un enlace para crear una cuenta nueva.
- **Crear cuenta**: Formulario de registro que solicita datos personales (nombre, apellido, correo), información laboral (departamento, cargo) y el rol solicitado (Técnico de red o Administrador). Al enviarse, crea el usuario en Supabase.
- **Infraestructura Global (Redes)**: Pantalla principal tras iniciar sesión. Muestra las redes/edificios registrados como tarjetas con su IP base y color asignado. Permite crear una nueva red (mediante un asistente que genera automáticamente sus segmentos) y eliminar una red existente.
- **Segmentos**: Al entrar a una red, muestra los segmentos (subredes) generados, con su rango de IPs utilizables. Permite renombrar o eliminar un segmento.
- **Inventario de equipos**: Lista todos los equipos agrupados por red y segmento, con buscador global (por nombre, IP, MAC, fabricante o ubicación). Permite agregar, editar y eliminar equipos.
- **Nuevo/Editar equipo**: Formulario para registrar un equipo dentro de un segmento, validando que la IP asignada pertenezca al rango del segmento y que la MAC tenga formato válido y no esté duplicada.
- **Nueva Incidencia**: Formulario para reportar una falla sobre un equipo existente (o uno nuevo escrito manualmente), indicando prioridad, estado y descripción del problema. Al editar una incidencia ya existente, agrega el cambio a un historial de intervenciones dentro del mismo reporte.
- **Historial y Bitácora**: Pantalla con dos pestañas: **Incidencias**, que lista todos los reportes con su estado, prioridad y responsable (y permite tocarlos para actualizarlos); y **Auditoría**, que muestra automáticamente cada acción (crear/editar/eliminar) realizada sobre redes, segmentos, equipos e incidencias.

# FUNCIONES TERMINADAS

- Autenticación de usuarios (inicio de sesión, registro y cierre de sesión) con Supabase Auth.
- Registro de rol solicitado (Técnico de red / Administrador) al crear una cuenta.
- CRUD de redes, con asistente que genera segmentos automáticamente a partir de una IP base.
- CRUD de segmentos (edición de nombre, eliminación).
- CRUD de equipos, con validación de IP dentro del rango del segmento y de MAC única con formato correcto.
- Buscador global de equipos por nombre, IP, MAC, fabricante o ubicación.
- Registro y actualización de incidencias, con historial de intervenciones por incidencia.
- Bitácora de auditoría automática de las acciones CREAR/EDITAR/ELIMINAR sobre redes, segmentos, equipos e incidencias.

# FUNCIONES PENDIENTES

- Recuperación de contraseña: el enlace "¿Olvidaste tu contraseña?" está presente en la pantalla de inicio de sesión, pero aún no tiene funcionalidad.
- Uso real de roles: el rol (Técnico de red / Administrador) se guarda al registrarse, pero todavía no se usa para restringir permisos ni vistas dentro de la aplicación.
- Aprobación de cuentas nuevas: el registro concede acceso inmediato; no existe un flujo de validación por un administrador antes de habilitar la cuenta.
- Renombrar una red ya creada (actualmente solo se puede eliminar).
- Notificaciones o alertas automáticas para incidencias de alta prioridad.

# CONCLUSIONES

## Gonzáles Oseguera Oswaldo Joel
El desarrollo de esta aplicación representó una valiosa oportunidad para dominar tecnologías modernas. Flutter nos dio la versatilidad de abarcar múltiples plataformas sin duplicar código, y Supabase garantizó una persistencia de datos rápida y disponible. A nivel metodológico, la implementación de GitHub marcó un antes y un después en nuestra dinámica de trabajo, consolidando el uso de ramas y solicitudes de extracción para coordinar nuestro esfuerzo colectivo.

## López Cortazar Bet-Sua
Mi experiencia en este proyecto se centró en comprender cómo desacoplar la lógica de la aplicación respecto a la interfaz. Gracias al motor de Flutter logramos un rendimiento fluido en distintas plataformas, mientras que Supabase nos brindó una infraestructura confiable y accesible en todo momento. Trabajar con GitHub por primera vez como equipo transformó la forma en que nos organizamos, permitiéndonos integrar cambios de forma segura y constante.

## Lucatero Farias Brandon Miguel
Aprender el ecosistema de Flutter desde cero fue un reto importante, pero la curva de aprendizaje se facilitó al ver la reactividad de la aplicación en tiempo real. La conexión con Supabase como backend nos dio una solución rápida para la gestión de datos sin complicar la arquitectura. Además, la colaboración mediante GitHub nos enseñó la importancia del control de versiones, la resolución de conflictos y la distribución equitativa de las tareas.

## Piedra Cos Ulises
En la primera parte de la elaboración del proyecto utilizamos por primera vez almenos la mayor parte del equipo github donde descubrimos la facilidad que ofrece la herramienta para trabajar en equipo y poder desenvolvernos de mejor manera en el desarrollo de esta app en la cual se utilizo supa base para el funcionamiento de la app en cualquier momento. Se aprendió Flutter y el desarrollo multiplataforma 

## Rios Cervantes Zabdiel
Durante este desarrollo me enfoqué en la adaptación de la interfaz y la integración con Supabase. El uso de Flutter me demostró la eficiencia del desarrollo multiplataforma, ya que un solo bloque de código nos sirvió para mantener una experiencia homogénea en cualquier dispositivo. A la par, adoptar un flujo de trabajo basado en Git y GitHub fue indispensable para mantener el repositorio limpio y evitar la pérdida de avances durante las entregas del equipo.
