package instructions

Instruction :: enum u8 {
    // MOV
    Mov_Register_Or_Memory_To_Or_From_Register,
    Mov_Immediate_To_Register_Or_Memory,
    Mov_Immediate_To_Register,
}

instruction_table := []u8 {
    0b10001000, // Mov_Register_Or_Memory_To_Or_From_Register,
    0b11000110, // Mov_Immediate_To_Register_Or_Memory
    0b10110000, // Mov_Immediate_To_Register
}

instruction_mask_table := []u8 {
    0b11111100, // Mov_Register_Or_Memory_To_Or_From_Register,
    0b11111110, // Mov_Immediate_To_Register_Or_Memory
    0b11110000, // Mov_Immediate_To_Register

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

is_instruction :: proc(b: byte, instruction: Instruction) -> bool {
    return b & instruction_mask_table[instruction] == instruction_table[instruction]
}