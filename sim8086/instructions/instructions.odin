package instructions

Instruction :: enum u8 {
    // MOV
    Mov_Register_Or_Memory_To_Or_From_Register,
    Mov_Immediate_To_Register_Or_Memory,
    Mov_Immediate_To_Register,
    Mov_Memory_To_Accumulator,
    Mov_Accumulator_To_Memory,
    // ADD
    Add_Register_Or_Memory_With_Register_To_Either,
    Immediate_To_Register_Or_Memory,
    Add_Immediate_To_Accumulator, 

    // SUB
    Sub_Register_Or_Memory_With_Register_To_Either,
    Sub_Immediate_To_Accumulator,
}

instruction_table := []u8 {
    0b10001000, // Mov_Register_Or_Memory_To_Or_From_Register,
    0b11000110, // Mov_Immediate_To_Register_Or_Memory
    0b10110000, // Mov_Immediate_To_Register
    0b10100000, // Mov_Memory_To_Accumulator
    0b10100010, // Mov_Accumulator_To_Memory
    0b00000000, // Add_Register_Or_Memory_With_Register_To_Either
    0b10000000, // Immediate_To_Register_Or_Memory
    0b00000100, // Add_Immediate_To_Accumulator
    0b00101000, // Sub_Register_Or_Memory_With_Register_To_Either
    0b00101100, // Sub_Immediate_To_Accumulator
}

instruction_mask_table := []u8 {
    0b11111100, // Mov_Register_Or_Memory_To_Or_From_Register,
    0b11111110, // Mov_Immediate_To_Register_Or_Memory
    0b11110000, // Mov_Immediate_To_Register
    0b11111110, // Mov_Memory_To_Accumulator
    0b11111110, // Mov_Accumulator_To_Memory
    0b11111100, // Add_Register_Or_Memory_With_Register_To_Either
    0b11111100, // Immediate_To_Register_Or_Memory
    0b11111110, // Add_Immediate_To_Accumulator
    0b11111100, // Sub_Register_Or_Memory_With_Register_To_Either
    0b11111110, // Sub_Immediate_To_Accumulator
}

MOV_REG_TABLE   := []string{ "al", "cl", "dl", "bl", "ah", "ch", "dh", "bh" }
MOV_REG_TABLE_W := []string{ "ax", "cx", "dx", "bx", "sp", "bp", "si", "di" }

MOV_EFFECTIVE_ADDRESS_TABLE := []string{
    "bx + si",
    "bx + di",
    "bp + si",
    "bp + di",
    "si",
    "di",
    "bp",
    "bx",
}

IMMEDIATE_TO_REGISTER_MEMORY_TABLE := []string{
    "add",    // 000
    "or",     // 001
    "adc",    // 010
    "sbb",    // 011
    "and",    // 100
    "sub",    // 101
    "unused", // 110
    "cmp",    // 111
}

is_instruction :: proc(b: byte, instruction: Instruction) -> bool {
    return b & instruction_mask_table[instruction] == instruction_table[instruction]
}