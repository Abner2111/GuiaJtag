//=============================================================================
// Top Module - JTAG LEDs and DIP Switch Interface
// Autor: Abner Arroyo
// Descripción: Módulo principal que conecta Virtual JTAG con LEDs y switches
// Fecha: 2025
//=============================================================================

module top (
    // Clock and Reset
    input  logic        CLOCK_50,      // Clock de 50MHz de la placa
    input  logic        reset_n,       // Reset asíncrono (activo bajo)
    
    // DIP Switches (entradas)
    input  logic [3:0]  SW,            // 4 switches DIP
    
    // LEDs (salidas)
    output logic [7:0]  LEDR           // 8 LEDs rojos
);

    //=========================================================================
    // Señales internas para conectar VJTAG con el módulo connect
    //=========================================================================
    
    // Señales de JTAG del Virtual JTAG IP
    logic        tck;                  // JTAG Test Clock
    logic        tdi;                  // JTAG Test Data Input  
    logic        tdo;                  // JTAG Test Data Output
    logic [1:0]  ir_in;                // Instruction Register
    logic [1:0]  ir_out;               // Instruction Register Output
    logic        virtual_state_cdr;    // Virtual Capture Data Register
    logic        virtual_state_sdr;    // Virtual Shift Data Register  
    logic        virtual_state_e1dr;   // Virtual Exit1 Data Register
    logic        virtual_state_pdr;    // Virtual Pause Data Register
    logic        virtual_state_e2dr;   // Virtual Exit2 Data Register
    logic        virtual_state_udr;    // Virtual Update Data Register
    logic        virtual_state_cir;    // Virtual Capture Instruction Register
    logic        virtual_state_uir;    // Virtual Update Instruction Register
    
    //=========================================================================
    // Instanciación del VJTAG IP Core generado por QSYS
    //=========================================================================
    
    vJtag vjtag_inst (
        // Señales de entrada al VJTAG desde el módulo connect
        .tdo                    (tdo),                      // JTAG Test Data Output
        
        // Señales de salida del VJTAG hacia el módulo connect
        .tdi                    (tdi),                      // JTAG Test Data Input
        .tck                    (tck),                      // JTAG Test Clock
        .ir_in                  (ir_in),                    // Instruction Register (2 bits)
        .ir_out                 (ir_out),                   // Instruction Register Output
        .virtual_state_cdr      (virtual_state_cdr),        // Capture Data Register
        .virtual_state_sdr      (virtual_state_sdr),        // Shift Data Register
        .virtual_state_e1dr     (virtual_state_e1dr),       // Exit1 Data Register
        .virtual_state_pdr      (virtual_state_pdr),        // Pause Data Register
        .virtual_state_e2dr     (virtual_state_e2dr),       // Exit2 Data Register
        .virtual_state_udr      (virtual_state_udr),        // Update Data Register
        .virtual_state_cir      (virtual_state_cir),        // Capture Instruction Register
        .virtual_state_uir      (virtual_state_uir)         // Update Instruction Register
    );
    
    //=========================================================================
    // Instanciación del módulo connect (interfaz JTAG con LEDs y switches)
    //=========================================================================
    
    connect jtag_interface (
        // Señales de JTAG (conectadas al Virtual JTAG)
        .tck                    (tck),                      // Clock JTAG
        .tdi                    (tdi),                      // Data Input JTAG
        .aclr                   (reset_n),                 // Reset asíncrono (activo bajo)
        .ir_in                  (ir_in),                    // Registro de instrucción
        .v_sdr                  (virtual_state_sdr),        // Virtual Shift DR
        .v_udr                  (virtual_state_udr),        // Virtual Update DR
        .v_cdr                  (virtual_state_cdr),        // Virtual Capture DR
        .v_uir                  (virtual_state_uir),        // Virtual Update IR
        
        // Interfaces físicas
        .switches               (SW),                       // Switches DIP de entrada
        .tdo                    (tdo),                      // Data Output JTAG
        .leds                   (LEDR)                      // LEDs de salida
    );
    
    //=========================================================================
    // Opcional: Lógica adicional o señales de debug
    //=========================================================================
    
    // Aquí puedes agregar lógica adicional si es necesaria
    // Por ejemplo, acondicionamiento de señales, debug, etc.
    
endmodule

//=============================================================================
// Notas de uso:
//
// 1. Este módulo top conecta:
//    - vJtag IP Core (generado por QSYS desde vJtag.qsys)
//    - Módulo connect (tu módulo personalizado SystemVerilog)
//    - Pines físicos de la FPGA (switches y LEDs)
//
// 2. Archivos requeridos en el proyecto Quartus:
//    - top.sv (este archivo)
//    - connect.sv (tu módulo de interfaz JTAG)
//    - vJtag.qsys (sistema QSYS con Virtual JTAG IP)
//    - Archivos generados: vJtag.v, vJtag_bb.v, etc.
//
// 3. Para configurar en Quartus:
//    - Agrega todos los archivos .sv y .v al proyecto
//    - Configura los pines SW[3:0] y LEDR[7:0] en Pin Planner
//    - El Virtual JTAG se detectará automáticamente via el IP QSYS
//
// 4. Para probar:
//    - Compila el diseño completo
//    - Programa la FPGA
//    - Usa el script TCL (form.tcl) para comunicarte via JTAG
//    - El dispositivo aparecerá como @2 en la lista de dispositivos JTAG
//
// 5. Verificación de señales:
//    - Si las señales del VJTAG no coinciden, revisa vJtag_inst.v
//    - Ajusta los nombres de las señales según tu IP generado
//    - Algunas versiones usan prefijos diferentes (jtag_, source_, etc.)
//
//=============================================================================