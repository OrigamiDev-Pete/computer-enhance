package main

import "core:log"
import "core:fmt"
import "core:math/bits"
import "core:os"
import "core:strings"

import "instructions"

TEST_FILE :: "listing_0038_many_register_mov"
TEST_DIR :: "../cmuratori_computer_enhance/perfaware/part1/";
OUTPUT_DIR :: "./test/"

main :: proc() {

    context.logger = log.create_console_logger()


    data, success := os.read_entire_file(TEST_DIR + TEST_FILE)
    if !success {
        log.error("Could not open file.", TEST_DIR + TEST_FILE)
        os.exit(1)
    }

    os.make_directory("./test")
    output_file, err := os.open(OUTPUT_DIR + "test_" + TEST_FILE, os.O_CREATE | os.O_WRONLY)
    os.write_string(output_file, "bits 16\n\n")

    using instructions

    instruction_string_builder : strings.Builder

    for i := 0; i < len(data); i += 1 {

        b := data[i]
        if is_mov(b) { // MOV
            strings.builder_init(&instruction_string_builder, context.temp_allocator)
            strings.write_string(&instruction_string_builder, "mov ")

            d := bit_extract(b, 1)
            w := bit_extract(b, 0)

            i += 1 
            b = data[i]
            // mod reg r/m
            mod_bits := bits.bitfield_extract(b, 6, 2)
            reg_bits := bits.bitfield_extract(b, 3, 3)
            rm_bits := bits.bitfield_extract(b, 0, 3)
            if w == 0 {
                reg := MOV_REG_TABLE[reg_bits]
                rm := MOV_REG_TABLE[rm_bits]

                strings.write_string(&instruction_string_builder, rm)
                strings.write_string(&instruction_string_builder, ", ")
                strings.write_string(&instruction_string_builder, reg)
            } else { // wide
                reg := MOV_REG_TABLE_W[reg_bits]
                rm := MOV_REG_TABLE_W[rm_bits]

                strings.write_string(&instruction_string_builder, rm)
                strings.write_string(&instruction_string_builder, ", ")
                strings.write_string(&instruction_string_builder, reg)
            }

            strings.write_byte(&instruction_string_builder, '\n')

            os.write_string(output_file, strings.to_string(instruction_string_builder))
        }
    }

    os.close(output_file)
    strings.builder_destroy(&instruction_string_builder)
}

bit_extract :: proc(value: u8, offset: uint) -> u8 { return bits.bitfield_extract_u8(value, offset, 1) }