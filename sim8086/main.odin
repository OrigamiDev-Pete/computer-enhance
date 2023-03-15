package main

import "core:log"
import "core:fmt"
import "core:math/bits"
import "core:mem"
import "core:os"
import "core:strconv"
import "core:strings"

import instr "instructions" 

TEST_FILE :: "listing_0041_add_sub_cmp_jnz"
// TEST_FILE :: "listing_0040_challenge_movs"
TEST_DIR :: "../cmuratori_computer_enhance/perfaware/part1/";

bytes: []u8
i: uint

main :: proc() {

    context.logger = log.create_console_logger()
    tracking_alloc: mem.Tracking_Allocator
    mem.tracking_allocator_init(&tracking_alloc, context.allocator)
    context.allocator = mem.tracking_allocator(&tracking_alloc)

    {
        success: bool
        bytes, success = os.read_entire_file(TEST_DIR + TEST_FILE)
        defer delete(bytes)
        if !success {
            log.error("Could not open file.", TEST_DIR + TEST_FILE)
            os.exit(1)
        }

        simulate()
    }

    for _, leak in tracking_alloc.allocation_map {
        log.warnf("%v leaked %v bytes\n", leak.location, leak.size)
    }
    for bad_free in tracking_alloc.bad_free_array {
        log.warnf("%v allocation %p was freed badly\n", bad_free.location, bad_free.memory)
    }
}

simulate :: proc() {
    fmt.println("bits 16\n")

    using instr

    for i < len(bytes) {

        b := advance()
        switch {
        /** MOV **/
        case is_instruction(b, .Mov_Register_Or_Memory_To_Or_From_Register):
            fmt.print("mov ")
            reg_mem_to_from_register(b)

        case is_instruction(b, .Add_Register_Or_Memory_With_Register_To_Either):
            fmt.print("add ")
            reg_mem_to_from_register(b)

        case is_instruction(b, .Sub_Register_Or_Memory_With_Register_To_Either):
            fmt.print("sub ")
            reg_mem_to_from_register(b)
            
        case is_instruction(b, .Mov_Immediate_To_Register_Or_Memory):
            fmt.print("mov ")
            imm_to_reg_mem(b, false)
        
        case is_instruction(b, .Immediate_To_Register_Or_Memory):
            // Check arithmetic type in following byte
            arithmetic_type_field := bits.bitfield_extract(peek(), 3, 3)
            fmt.printf("%v ", IMMEDIATE_TO_REGISTER_MEMORY_TABLE[arithmetic_type_field])
            imm_to_reg_mem(b)

        case is_instruction(b, .Mov_Immediate_To_Register):
            fmt.print("mov ")

            w := bit_extract(b, 3)

            reg_field := bits.bitfield_extract(b, 0, 3)
            reg: string
            if w == 0 {
                reg = MOV_REG_TABLE[reg_field]
            } else { // wide
                reg = MOV_REG_TABLE_W[reg_field]
            }

            data := extract_data(w == 1)

            fmt.printf("%v, %v\n", reg, data)
        
        case is_instruction(b, .Mov_Memory_To_Accumulator), is_instruction(b, .Mov_Accumulator_To_Memory):
            fmt.print("mov ")
            mem_to_acc(b)

        case is_instruction(b, .Add_Immediate_To_Accumulator):
            fmt.print("add ")
            imm_to_acc(b)

        case is_instruction(b, .Sub_Immediate_To_Accumulator):
            fmt.print("sub ")
            imm_to_acc(b)

        case:
            fmt.println("Unknown instruction")
        }
    }
}


bit_extract :: proc(value: u8, offset: uint) -> u8 { return bits.bitfield_extract_u8(value, offset, 1) }

advance :: proc(distance: uint = 1) -> (b: byte) {
    b = bytes[i]
    i += distance
    return
}

peek :: proc(distance: uint = 1) -> byte {
    return bytes[i + 1]
}

extract_data :: proc(wide: bool) -> (data: u16) {
    if wide {
        b := advance()
        data = bits.bitfield_insert(data, u16(b), 0, 8)
        b = advance()
        data = bits.bitfield_insert(data, u16(b), 8, 8)
    } else {
        b := advance()
        data = bits.bitfield_insert(data, u16(b), 0, 8)
    }
    return
}

reg_mem_to_from_register :: proc(b: byte) {
    d := bit_extract(b, 1)
    w := bit_extract(b, 0)

    b := advance()
    // mod reg r/m
    mod_field := bits.bitfield_extract(b, 6, 2)
    reg_field := bits.bitfield_extract(b, 3, 3)
    rm_field := bits.bitfield_extract(b, 0, 3)

    reg := instr.MOV_REG_TABLE[reg_field] if w == 0 else instr.MOV_REG_TABLE_W[reg_field]

    rm := parse_mod(mod_field, rm_field, w)

    if d == 0 {
        fmt.printf("%v, %v\n", rm, reg)
    } else {
        fmt.printf("%v, %v\n", reg, rm)
    }
}

imm_to_reg_mem :: proc(b: byte, check_signed := true) {
    s := bit_extract(b, 1)
    w := bit_extract(b, 0)

    b := advance()
    mod_field := bits.bitfield_extract(b, 6, 2)
    rm_field := bits.bitfield_extract(b, 0, 3)

    rm := parse_mod(mod_field, rm_field, w)

    data := extract_data(w == 1 && s == 0)
    buf : [8]u8
    data_string := strconv.itoa(buf[:], int(data))
    if (mod_field != 0b11) {
        if (w == 0) {
            data_string = strings.concatenate({"byte ", data_string}, context.temp_allocator)
        } else {
            data_string = strings.concatenate({"word ", data_string}, context.temp_allocator)
        }
    }

    fmt.printf("%v, %v\n", rm, data_string)
}

mem_to_acc :: proc(b: byte) {
    w := bit_extract(b, 0)
    acc := "ax" if w == 1 else "al"
    address := extract_data(w == 1)
    if (instr.is_instruction(b, .Mov_Accumulator_To_Memory)) {
        fmt.printf("[%v], %v\n", address, acc)
    } else {
        fmt.printf("%v, [%v]\n", acc, address)
    }
}

imm_to_acc :: proc(b: byte) {
    w := bit_extract(b, 0)
    acc := "ax" if w == 1 else "al"
    data := extract_data(w == 1)
    fmt.printf("%v, %v\n", acc, data)
}

parse_mod :: proc(mod_field, rm_field, w: u8) -> string {
    using instr
    rm: string
    switch mod_field {
        case 0b00: // Effective Address
            sb := strings.builder_make(context.temp_allocator)
            
            if (rm_field == 0b110) { // Direct Addressing
                disp := extract_data(true)
                rm = fmt.sbprintf(&sb, "[%v]", disp)
            } else {
                rm = fmt.sbprintf(&sb, "[%v]", MOV_EFFECTIVE_ADDRESS_TABLE[rm_field])
            }

        case 0b01: // Effective Address + D8
            disp := extract_data(false)

            sb := strings.builder_make(context.temp_allocator)
            rm = fmt.sbprintf(&sb, "[%v + %v]", MOV_EFFECTIVE_ADDRESS_TABLE[rm_field], disp)


        case 0b10: // Effective Address + D16
            disp := extract_data(true)

            sb := strings.builder_make(context.temp_allocator)
            rm = fmt.sbprintf(&sb, "[%v + %v]", MOV_EFFECTIVE_ADDRESS_TABLE[rm_field], disp)

        case 0b11: // R/M as register
            rm = instr.MOV_REG_TABLE[rm_field] if w == 0 else instr.MOV_REG_TABLE_W[rm_field]
    }
    return rm
}