package instructions

MOV      :: 0b10001000
MOV_MASK :: 0b11111100

MOV_REG_TABLE   := []string{ "al", "cl", "dl", "bl", "ah", "ch", "dh", "bh" }
MOV_REG_TABLE_W := []string{ "ax", "cx", "dx", "bx", "sp", "bp", "si", "di" }


is_mov :: proc(b: byte) -> bool {
    return b & MOV_MASK == MOV
}