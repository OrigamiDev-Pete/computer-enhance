package main

import "core:log"
import "core:fmt"
import "core:math/bits"
import "core:os"
import "core:strings"

import "instructions"

TEST_FILE :: "listing_0037_single_register_mov"
TEST_DIR :: "../cmuratori_computer_enhance/perfaware/part1/";

main :: proc() {

    context.logger = log.create_console_logger()


    data, success := os.read_entire_file(TEST_DIR + TEST_FILE)
    if !success {
        log.error("Could not open file.", TEST_DIR + TEST_FILE)
        os.exit(1)
    }

    fmt.println("bits 16\n")

    using instructions

    instruction_string_builder : strings.Builder

    for i := 0; i < len(data); i += 1 {

        b := data[i]
        switch {
        case is_mov(b): // MOV
            fmt.print("mov ")

            d := bit_extract(b, 1)
            w := bit_extract(b, 0)

            i += 1 
            b = data[i]
            // mod reg r/m
            mod_field := bits.bitfield_extract(b, 6, 2)
            reg_field := bits.bitfield_extract(b, 3, 3)
            rm_field := bits.bitfield_extract(b, 0, 3)

            reg : string
            rm : string
            if w == 0 {
                reg = MOV_REG_TABLE[reg_field]
                rm = MOV_REG_TABLE[rm_field]
            } else { // wide
                reg = MOV_REG_TABLE_W[reg_field]
                rm = MOV_REG_TABLE_W[rm_field]
            }
            fmt.printf("%v, %v\n", rm, reg)
        }
    }

    strings.builder_destroy(&instruction_string_builder)
}

bit_extract :: proc(value: u8, offset: uint) -> u8 { return bits.bitfield_extract_u8(value, offset, 1) }