# Interfaz Virtual JTAG para Desarrollo en FPGA

## Descripción del Proyecto

Este proyecto implementa una interfaz Virtual JTAG para FPGAs Intel/Altera utilizando Quartus Prime. El sistema proporciona un puente de comunicación entre una computadora host y el hardware FPGA a través de la cadena de escaneo de frontera JTAG, permitiendo el control en tiempo real de LEDs y la lectura del estado de switches DIP sin requerir pines externos para depuración.

## Autor

Abner Arroyo  
Estudiante de Ingeniería en Computadores
2025

## Descripción Técnica

El proyecto demuestra la implementación de un núcleo IP Virtual JTAG (VJTAG) integrado con módulos SystemVerilog personalizados para crear una interfaz de depuración de hardware. El sistema utiliza el protocolo estándar IEEE 1149.1 JTAG para establecer comunicación entre software ejecutándose en una computadora host y lógica digital implementada en la FPGA.

### Arquitectura del Sistema

El diseño consiste en tres componentes principales:

1. **Núcleo IP Virtual JTAG** (`vJtag.qsys`) - Núcleo IP de Intel que proporciona funcionalidad de controlador TAP JTAG
2. **Módulo Superior** (`top.sv`) - Envolvente SystemVerilog que conecta VJTAG a interfaces externas
3. **Módulo de Conexión** (`connect.sv`) - Manejador de protocolo JTAG que implementa conjunto de instrucciones personalizado

### Conjunto de Instrucciones JTAG

El sistema implementa un registro de instrucciones de 2 bits que soporta las siguientes operaciones:

- `00` (BYPASS) - Operación estándar de bypass JTAG
- `01` (DIP) - Leer estado de switches DIP de 4 bits
- `10` (LED) - Actualizar registro de salida de LEDs de 8 bits
- `11` (NO USADO) - Por defecto operación de bypass

## Requisitos de Hardware

- Tarjeta de desarrollo FPGA Intel/Altera (Cyclone V o compatible)
- 4 switches DIP conectados a los pines SW[3:0] (pueden ser los de la placa)
- 8 LEDs conectados a los pines LEDR[7:0] (pueden ser los de la placa)
- Cable de programación JTAG USB Blaster o simplemente el USB de la FPGA

## Requisitos de Software

- Intel Quartus Prime (versión 20.1 o posterior)
- Entorno de scripting Tcl
- Instalación de controladores USB Blaster

## Estructura de Archivos

```
GuiaJtag/
├── top.sv                  # Módulo SystemVerilog de nivel superior
├── connect.sv              # Controlador de interfaz JTAG
├── vJtag.qsys             # Configuración IP VJTAG de Platform Designer
├── vJTAG_example.qpf      # Archivo de proyecto Quartus
├── vJTAG_example.qsf      # Archivo de configuración Quartus
├── form.tcl               # Script Tcl para comunicación JTAG
├── c5_pin_model_dump.txt  # Referencia de asignación de pines
└── README.md              # Documentación del proyecto
```

## Detalles de Implementación

### Integración de Virtual JTAG

El núcleo IP VJTAG se configura a través de Platform Designer (Qsys) con los siguientes parámetros:
- ID de instancia: 0
- Ancho del registro de instrucciones: 2 bits
- Implementación de máquina de estados virtual habilitada

### Diseño de Módulos SystemVerilog

El módulo connect implementa una máquina de estados finitos sincronizada al reloj de prueba JTAG (TCK). Los registros de datos se actualizan durante estados específicos del TAP JTAG:
- Capture-DR: Muestreo de datos de entrada
- Shift-DR: Transferencia serial de datos
- Update-DR: Salida de datos en paralelo

### Estrategia de Asignación de Pines

Los pines de E/S externos deben estar apropiadamente restringidos en el Pin Planner de Quartus:
- Entrada de reloj: Pin de entrada PLL dedicado
- Reset: E/S de propósito general con pull-up apropiado
- Switches DIP: Entradas de propósito general con pull-ups internos
- LEDs: Salidas de propósito general con corriente de manejo apropiada

## Instrucciones de Compilación

1. Abrir Quartus Prime y cargar el archivo de proyecto `vJTAG_example.qpf`
2. Asegurar que todos los archivos fuente estén apropiadamente añadidos al proyecto
3. Generar el núcleo IP VJTAG desde el archivo Qsys si no está presente
4. Asignar pines físicos usando el Pin Planner
5. Compilar el diseño completo usando Análisis y Síntesis → Fitter → Assembler
6. Programar la FPGA usando el archivo SOF generado

## Pruebas y Verificación

### Prueba de Funcionalidad Básica

1. Programar la FPGA con el bitstream compilado
2. Ejecutar el script Tcl `form.tcl` en la consola Tcl de Quartus :PATH_DE_INSTALACION_QUARTUS/.../quartus_stp -t PATH_DEL_FORM
3. Verificar que la detección de cadena JTAG muestre la instancia Virtual JTAG
4. Probar la funcionalidad de lectura de switches DIP
5. Verificar el control de LEDs a través de comandos JTAG

### Procedimientos de Depuración

Si la interfaz JTAG no es detectada:
- Verificar conexión y controladores del USB Blaster
- Verificar la integridad de la cadena JTAG usando Quartus Programmer
- Confirmar que la compilación del núcleo IP VJTAG sea sin errores
- Validar que las asignaciones de pines coincidan con el hardware físico

## Aplicaciones Educativas

Este proyecto sirve como una introducción práctica a:
- Arquitectura y protocolos de escaneo de frontera JTAG
- Metodología de diseño HDL SystemVerilog
- Uso de cadena de herramientas de desarrollo FPGA
- Diseño de interfaz hardware-software
- Técnicas de depuración de sistemas digitales

## Referencias Técnicas

- IEEE Std 1149.1-2013: Estándar de Puerto de Acceso de Prueba y Arquitectura de Escaneo de Frontera
- Guía del Usuario del Núcleo IP Virtual JTAG de Altera
- Manual de Referencia del Lenguaje SystemVerilog IEEE 1800-2017
- Virtual JTAG Intel® FPGA IP Core User Guide

## Créditos
 - INTEL
 - https://github.com/xharrym/tk_jtag/blob/master/connect.v


## Licencia

Este proyecto está desarrollado con fines educativos como parte del curso de ingeniería en computadores. El código se proporciona tal como está para uso académico y aplicaciones de aprendizaje.
