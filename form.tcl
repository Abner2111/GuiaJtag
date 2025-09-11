# Función para enviar datos a los LEDs de la FPGA
# Esta función lee el estado de los checkboxes (d0-d7) y los envía como datos binarios
proc send_data {} {
	# Variables globales: d0-d7 representan el estado de los checkboxes, displayData muestra el resultado
	global d0 d1 d2 d3 d4 d5 d6 d7 displayData
	# String que contendrá el valor binario final
	set led ""
	# Representa bit 1
	set one 1
	# Representa bit 0
	set zero 0

	# Construir el string binario basado en el estado de cada checkbox
	# Si el checkbox está marcado (==1), agregar "1", sino agregar "0"
	if {$d0 == 1} {set led $led$one} else {set led $led$zero}
	if {$d1 == 1} {set led $led$one} else {set led $led$zero}
	if {$d2 == 1} {set led $led$one} else {set led $led$zero}
	if {$d3 == 1} {set led $led$one} else {set led $led$zero}
	if {$d4 == 1} {set led $led$one} else {set led $led$zero}
	if {$d5 == 1} {set led $led$one} else {set led $led$zero}
	if {$d6 == 1} {set led $led$one} else {set led $led$zero}
	if {$d7 == 1} {set led $led$one} else {set led $led$zero}

	# Actualizar el texto que se muestra en la interfaz
	set displayData "Data sent: $led"

	# Secuencia de comunicación JTAG con la FPGA
	# Abrir conexión con el dispositivo
	open_port
	# Bloquear dispositivo por 10 segundos máximo
	device_lock -timeout 10000
	# Cambiar a modo de escritura de LEDs (IR=2)
    # device_virtual_ir_shift es un comando específico de Quartus para cambiar el registro IR
	device_virtual_ir_shift -instance_index 0 -ir_value 2 -no_captured_ir_value
	# Enviar los 8 bits de datos a los LEDs
    #device_virtual_dr_shift es un comando específico de Quartus para cambiar el registro DR
	set l [device_virtual_dr_shift -dr_value $led -instance_index 0  -length 8]
	# Imprimir respuesta en consola
	puts $l
	# Regresar a modo inactivo (IR=0)
	device_virtual_ir_shift -instance_index 0 -ir_value 0 -no_captured_ir_value
	# Cerrar conexión
	close_port
}

# Función para leer el estado de los switches DIP de la FPGA
# Esta función se comunica con la FPGA para obtener el estado de 4 switches DIP
proc read_switch {} {
	# Secuencia de comunicación JTAG para leer switches
	# Abrir conexión con el dispositivo
	open_port
	# Bloquear dispositivo por 10 segundos máximo
	device_lock -timeout 10000
	# Cambiar a modo de lectura de switches (IR=1)
	device_virtual_ir_shift -instance_index 0 -ir_value 1 -no_captured_ir_value
	# Leer 4 bits de los switches DIP
	set dip [device_virtual_dr_shift -dr_value 0000 -instance_index 0 -length 4]
	
	# Regresar a modo inactivo (IR=0)
	device_virtual_ir_shift -instance_index 0 -ir_value 0 -no_captured_ir_value
	# Cerrar conexión
	close_port

	# Actualizar los checkboxes de switches según los datos leídos
	# Cada bit del string 'dip' representa el estado de un switch
	# Switch 0
	if {[string index $dip 0] == 1} {.chks0 select} else {.chks0 deselect}
	# Switch 1
	if {[string index $dip 1] == 1} {.chks1 select} else {.chks1 deselect}
	# Switch 2
	if {[string index $dip 2] == 1} {.chks2 select} else {.chks2 deselect}
	# Switch 3
	if {[string index $dip 3] == 1} {.chks3 select} else {.chks3 deselect}

}

# Función auxiliar para abrir la conexión con el dispositivo FPGA
# Utiliza las variables globales que contienen el nombre del hardware y dispositivo
proc open_port {} {
	# Nombre del hardware (USB-Blaster o DE-SoC)
	global usbblaster_name
	# Nombre del dispositivo específico (@2: ...)
	global test_device
	# Comando para abrir el dispositivo usando JTAG
    #open device es un comando específico de Quartus para abrir conexión JTAG
	open_device -hardware_name $usbblaster_name -device_name $test_device
}

# Función auxiliar para cerrar la conexión con el dispositivo FPGA
# Libera el bloqueo del dispositivo y cierra la conexión de manera segura
proc close_port {} {
	# Desbloquear dispositivo (con manejo de errores)
	catch {device_unlock}
	# Cerrar dispositivo (con manejo de errores)
	catch {close_device}
}

# Función principal para establecer conexión JTAG con la FPGA
# Busca y conecta automáticamente con dispositivos USB-Blaster o DE-SoC
proc connect_jtag {} {
	# Variable para almacenar el nombre del hardware encontrado
	global usbblaster_name
	# Variable para almacenar el nombre del dispositivo objetivo
	global test_device
	# Variable para mostrar el estado de conexión en la interfaz
	global displayConnect

	# Inicializar variables para evitar errores
	set usbblaster_name ""
	set test_device ""

	# Buscar hardware compatible (USB-Blaster o DE-SoC)
	# Iterar a través de todos los dispositivos de hardware disponibles
    #get_hardware_names es un comando específico de Quartus para listar hardware JTAG
	foreach hardware_name [get_hardware_names] {
		# Verificar si el nombre coincide con patrones conocidos
		if { [string match "USB-Blaster*" $hardware_name] || [string match "*DE-SoC*" $hardware_name] } {
			# Guardar el nombre del hardware encontrado
			set usbblaster_name $hardware_name
			# Salir del bucle una vez encontrado
			break
		}
	}

	# Verificar si se encontró hardware compatible
	if { $usbblaster_name == "" } {
		# Mostrar error si no se encuentra hardware
		set displayConnect "Error: No USB-Blaster or DE-SoC found!"
		# Salir de la función
		return
	}

	# Buscar el dispositivo específico en el hardware encontrado
	# Iterar a través de todos los dispositivos conectados al hardware
    #get_device_names es un comando específico de Quartus para listar dispositivos JTAG
	foreach device_name [get_device_names -hardware_name $usbblaster_name] {
		# Buscar dispositivos que empiecen con "@2" (nuestro dispositivo objetivo)
		if { [string match "@2*" $device_name] } {
			# Guardar el nombre del dispositivo encontrado
			set test_device $device_name
			# Salir del bucle una vez encontrado
			break
		}
	}

	# Verificar si se encontró el dispositivo objetivo
	if { $test_device == "" } {
		# Mostrar error específico
		set displayConnect "Error: No @2 device found on $usbblaster_name"
		# Salir de la función
		return
	}

	# Conexión exitosa - actualizar interfaz de usuario
	# Mostrar información de conexión
	set displayConnect "Connected: $usbblaster_name \n $test_device"
	# Deshabilitar botón de conexión
	.btnConn configure -state disabled
	# Habilitar botón de envío de datos
	.btnSend configure -state active
	# Habilitar botón de lectura de switches
	.btnRead configure -state active
}

# ==================================================================================
# SECCIÓN DE CONFIGURACIÓN Y VARIABLES GLOBALES
# ==================================================================================

# Variables globales para almacenar información de conexión
global usbblaster_name
global test_device

# Variables para la interfaz de usuario
# Texto que muestra el estado del envío de datos
set displayData "No Data Sent"
# Texto que muestra el estado de conexión
set displayConnect "Press Connect!"

# ==================================================================================
# CONFIGURACIÓN DE LA INTERFAZ GRÁFICA TKINTER
# ==================================================================================

# Cargar el paquete Tkinter para la interfaz gráfica
package require Tk
# Inicializar Tkinter
init_tk

# Configuración de la ventana principal
# Hacer visible la ventana
wm state . normal
# Establecer el título de la ventana
wm title . "FPGA Manager"

# ==================================================================================
# CREACIÓN DE FRAMES (SECCIONES) DE LA INTERFAZ
# ==================================================================================

# Frame para la sección de conexión
frame .frmConnection
# Etiqueta que muestra el estado de conexión
label .lblConn -textvariable displayConnect
# Botón para iniciar conexión
button .btnConn -text "Connect" -command "connect_jtag"

# Frame para la sección de control de LEDs (envío de datos)
frame .frmData
# Crear 8 checkboxes para controlar 8 LEDs (bits d0-d7)
# Checkbox para LED/bit 0
checkbutton .chk0 -variable d0
# Checkbox para LED/bit 1
checkbutton .chk1 -variable d1
# Checkbox para LED/bit 2
checkbutton .chk2 -variable d2
# Checkbox para LED/bit 3
checkbutton .chk3 -variable d3
# Checkbox para LED/bit 4
checkbutton .chk4 -variable d4
# Checkbox para LED/bit 5
checkbutton .chk5 -variable d5
# Checkbox para LED/bit 6
checkbutton .chk6 -variable d6
# Checkbox para LED/bit 7
checkbutton .chk7 -variable d7
# Botón para enviar datos a los LEDs
button .btnSend -text "Update LEDs" -command "send_data"
# Etiqueta que muestra el estado del envío
label .lblData -textvariable displayData

# Frame para la sección de lectura de switches DIP
frame .frmSwitch
# Crear 4 checkboxes para mostrar el estado de los switches DIP (solo lectura)
# Checkbox para mostrar estado del switch 0
checkbutton .chks0
# Checkbox para mostrar estado del switch 1
checkbutton .chks1
# Checkbox para mostrar estado del switch 2
checkbutton .chks2
# Checkbox para mostrar estado del switch 3
checkbutton .chks3
# Botón para leer switches
button .btnRead -text "Read Switches Value" -command "read_switch"

# ==================================================================================
# CONFIGURACIÓN DEL LAYOUT USANDO GRID (DISPOSICIÓN DE ELEMENTOS)
# ==================================================================================

# Posicionar el frame de conexión en la ventana principal
grid .frmConnection -in .  -row 1 -column 1 -columnspan 8
# Botón de conexión
grid .btnConn -in .frmConnection -row 1 -column 1
# Etiqueta de estado
grid .lblConn -in .frmConnection -row 2 -column 1

# Posicionar el frame de datos/LEDs en la ventana principal
grid .frmData -in .  -row 2 -column 1
# Colocar los 8 checkboxes de LEDs en una fila horizontal
grid .chk0 -in .frmData -row 1 -column 1
grid .chk1 -in .frmData -row 1 -column 2
grid .chk2 -in .frmData -row 1 -column 3
grid .chk3 -in .frmData -row 1 -column 4
grid .chk4 -in .frmData -row 1 -column 5
grid .chk5 -in .frmData -row 1 -column 6
grid .chk6 -in .frmData -row 1 -column 7
grid .chk7 -in .frmData -row 1 -column 8
# Colocar botón y etiqueta en la segunda fila
# Botón ocupa 4 columnas
grid .btnSend -in .frmData -row 2 -column 1 -columnspan 4
# Etiqueta ocupa 4 columnas
grid .lblData -in .frmData -row 2 -column 5 -columnspan 4

# Posicionar el frame de switches en la ventana principal
grid .frmSwitch -in .  -row 3 -column 1
# Colocar los 4 checkboxes de switches en una fila horizontal
grid .chks0 -in .frmSwitch -row 1 -column 1
grid .chks1 -in .frmSwitch -row 1 -column 2
grid .chks2 -in .frmSwitch -row 1 -column 3
grid .chks3 -in .frmSwitch -row 1 -column 4
# Botón de lectura
grid .btnRead -in .frmSwitch -row 1 -column 5 -columnspan 4

# ==================================================================================
# CONFIGURACIÓN INICIAL DE ESTADOS DE LOS CONTROLES
# ==================================================================================

# Deshabilitar botones que requieren conexión activa
# Botón de envío deshabilitado hasta conectar
.btnSend configure -state disabled
# Botón de lectura deshabilitado hasta conectar
.btnRead configure -state disabled

# Deshabilitar checkboxes de switches (solo para mostrar, no para interacción)
# Switch 0 solo lectura
.chks0 configure -state disabled
# Switch 1 solo lectura
.chks1 configure -state disabled
# Switch 2 solo lectura
.chks2 configure -state disabled
# Switch 3 solo lectura
.chks3 configure -state disabled

# Mantener la ventana abierta hasta que el usuario la cierre
tkwait window .