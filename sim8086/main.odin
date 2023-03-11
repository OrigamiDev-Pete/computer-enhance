package main

import "core:log"
import "core:fmt"
import "core:math/bits"
import "core:mem"
import "core:os"
import "core:strconv"
import "core:strings"

import "instructions"

TEST_FILE :: "listing_0039_more_movs"
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

    using instructions

    for i < len(bytes) {

        b := advance()
        switch {
        /** MOV **/
        case is_instruction(b, .Mov_Register_Or_Memory_To_Or_From_Register): 
            fmt.print("mov ")

            d := bit_extract(b, 1)
            w := bit_extract(b, 0)

            b = advance()
            // mod reg r/m
            mod_field := bits.bitfield_extract(b, 6, 2)
            reg_field := bits.bitfield_extract(b, 3, 3)
            rm_field := bits.bitfield_extract(b, 0, 3)

            reg := MOV_REG_TABLE[reg_field] if w == 0 else MOV_REG_TABLE_W[reg_field]

            switch mod_field {
                case 0b00: // Effective Address
                    sb := strings.builder_make(context.temp_allocator)
                    // defer strings.builder_destroy(&sb)
                    
                    rm: string
                    if (rm_field == 0b110) { // Direct Addressing
                        data := extract_data(true)
                        rm = fmt.sbprintf(&sb, "[%v]", data)
                    } else {
                        rm = fmt.sbprintf(&sb, "[%v]", MOV_EFFECTIVE_ADDRESS_TABLE[rm_field])
                    }

                    if d == 0 {
                        fmt.printf("%v, %v\n", rm, reg)
                    } else {
                        fmt.printf("%v, %v\n", reg, rm)
                    }

                case 0b01: // Effective Address + D8
                    data := extract_data(false)

                    sb := strings.builder_make(context.temp_allocator)

                    rm := fmt.sbprintf(&sb, "[%v + %v]", MOV_EFFECTIVE_ADDRESS_TABLE[rm_field], data)

                    if d == 0 {
                        fmt.printf("%v, %v\n", rm, reg)
                    } else {
                        fmt.printf("%v, %v\n", reg, rm)
                    }

                case 0b10: // Effective Address + D16
                    data := extract_data(true)

                    sb := strings.builder_make(context.temp_allocator)
                    rm := fmt.sbprintf(&sb, "[%v + %v]", MOV_EFFECTIVE_ADDRESS_TABLE[rm_field], data)

                    if d == 0 {
                        fmt.printf("%v, %v\n", rm, reg)
                    } else {
                        fmt.printf("%v, %v\n", reg, rm)
                    }

                case 0b11: // Register to Register
                    rm := MOV_REG_TABLE[rm_field] if w == 0 else MOV_REG_TABLE_W[rm_field]
                    fmt.printf("%v, %v\n", rm, reg)
            }


        case is_instruction(b, .Mov_Immediate_To_Register_Or_Memory):
            fmt.print("mov ")

            w := bit_extract(b, 0)

            b = advance()
            mod_field := bits.bitfield_extract(b, 6, 2)
            rm_field := bits.bitfield_extract(b, 0, 3)
            
            data: u16
            rm: string
            if w == 0 {
                rm = MOV_REG_TABLE[rm_field]
            } else {
                rm = MOV_REG_TABLE_W[rm_field]
            }

        case is_instruction(b, .Mov_Immediate_To_Register):
            fmt.print("mov ")

            w := bit_extract(b, 3)
            reg_field := bits.bitfield_extract(b, 0, 3)
            reg: string
            data: u16
            if w == 0 {
                reg = MOV_REG_TABLE[reg_field]
                data = extract_data(false)
            } else { // wide
                reg = MOV_REG_TABLE_W[reg_field]
                data = extract_data(true)
            }

            fmt.printf("%v, %v\n", reg, data)

        case:
            fmt.println("Unknown instruction")
        }
    }
}


bit_extract :: proc(value: u8, offset: uint) -> u8 { return bits.bitfield_extract_u8(value, offset, 1) }

advance :: proc() -> (b: byte) {
    b = bytes[i]
    i += 1
    return
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