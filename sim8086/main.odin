package main

import "core:log"
import "core:fmt"
import "core:math/bits"
import "core:os"
import "core:strings"

import "instructions"

TEST_FILE :: "listing_0039_more_movs"
TEST_DIR :: "../cmuratori_computer_enhance/perfaware/part1/";

bytes: []u8
i: uint

main :: proc() {

    context.logger = log.create_console_logger()

    success: bool
    bytes, success = os.read_entire_file(TEST_DIR + TEST_FILE)
    if !success {
        log.error("Could not open file.", TEST_DIR + TEST_FILE)
        os.exit(1)
    }

    fmt.println("bits 16\n")

    using instructions

    instruction_string_builder : strings.Builder

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

            reg: string
            rm: string
            if w == 0 {
                reg = MOV_REG_TABLE[reg_field]
                rm = MOV_REG_TABLE[rm_field]
            } else { // wide
                reg = MOV_REG_TABLE_W[reg_field]
                rm = MOV_REG_TABLE_W[rm_field]
            }
            fmt.printf("%v, %v\n", rm, reg)

        case is_instruction(b, .Mov_Immediate_To_Register_Or_Memory): 
        case is_instruction(b, .Mov_Immediate_To_Register):
            fmt.print("mov ")

            w := bit_extract(b, 3)
            reg_field := bits.bitfield_extract(b, 0, 3)
            reg: string
            data: u16
            if w == 0 {
                reg = MOV_REG_TABLE[reg_field]
                b = advance()
                data = bits.bitfield_insert(data, u16(b), 0, 8)
            } else { // wide
                reg = MOV_REG_TABLE_W[reg_field]
                b = advance()
                data = bits.bitfield_insert(data, u16(b), 0, 8)
                b = advance()
                data = bits.bitfield_insert(data, u16(b), 8, 8)
            }



            fmt.printf("%v, %v\n", reg, data)

        case:
            fmt.println("Unknown instruction")
        }
    }

    strings.builder_destroy(&instruction_string_builder)
}

bit_extract :: proc(value: u8, offset: uint) -> u8 { return bits.bitfield_extract_u8(value, offset, 1) }

advance :: proc() -> (b: byte) {
    b = bytes[i]
    i += 1
    return
}