from __future__ import annotations
import re
from dataclasses import dataclass
from typing import Dict, List, Tuple, Optional

ABI_REGS: Dict[str, int] = {
    "zero": 0, "ra": 1, "sp": 2, "gp": 3, "tp": 4,
    "t0": 5, "t1": 6, "t2": 7,
    "s0": 8, "fp": 8, "s1": 9,
    "a0": 10, "a1": 11, "a2": 12, "a3": 13, "a4": 14, "a5": 15, "a6": 16, "a7": 17,
    "s2": 18, "s3": 19, "s4": 20, "s5": 21, "s6": 22, "s7": 23, "s8": 24, "s9": 25, "s10": 26, "s11": 27,
    "t3": 28, "t4": 29, "t5": 30, "t6": 31,
}

def reg_num(token: str):
    t = token.strip().lower()
    if re.fullmatch(r"x([0-9]|[12][0-9]|3[01])", t): #verifica daca a scris x0, x1 mapeaza pe
        return int(t[1:]) #taie primul caracter si le transporma pe resutul in int
    if t in ABI_REGS:
        return ABI_REGS[t]
    raise ValueError(f"Registru necunoscut: '{token}'")

def parse_imm(token: str):
    t = token.strip().lower()
    if t.startswith("-0x"):
        return -int(t[3:], 16)
    if t.startswith("0x"):
        return int(t[2:], 16)
    return int(t, 10) # transforma t in baza zece in int

def check_range_signed(val: int, bits: int, what: str):
    lo = -(1 << (bits - 1))
    hi = (1 << (bits - 1)) - 1
    if not (lo <= val <= hi):
        raise ValueError(f"{what}={val} nu incape pe {bits} biti semnasi (range {lo}..{hi}).")

def u32(x: int):
    return x & 0xFFFFFFFF

def enc_r_type(funct7: int, rs2: int, rs1: int, funct3: int, rd: int, opcode: int):
    return u32((funct7 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode)

def enc_i_type(imm: int, rs1: int, funct3: int, rd: int, opcode: int):
    check_range_signed(imm, 12, "imm(I)")
    imm12 = imm & 0xFFF
    return u32((imm12 << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode)

def enc_s_type(imm: int, rs2: int, rs1: int, funct3: int, opcode: int):
    check_range_signed(imm, 12, "imm(S)")
    imm12 = imm & 0xFFF
    imm_hi = (imm12 >> 5) & 0x7F
    imm_lo = imm12 & 0x1F
    return u32((imm_hi << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (imm_lo << 7) | opcode)

def enc_b_type(offset_bytes: int, rs2: int, rs1: int, funct3: int, opcode: int):
    
    if offset_bytes % 2 != 0:
        raise ValueError(f"Offset BEQ trebuie să fie multiplu de 2 bytes, primit {offset_bytes}.")
    check_range_signed(offset_bytes, 13, "offset(B) bytes")
    imm = offset_bytes & 0x1FFF  # 13 bits
    imm12 = (imm >> 12) & 0x1
    imm10_5 = (imm >> 5) & 0x3F
    imm4_1 = (imm >> 1) & 0xF
    imm11 = (imm >> 11) & 0x1
    return u32(
        (imm12 << 31) |
        (imm10_5 << 25) |
        (rs2 << 20) |
        (rs1 << 15) |
        (funct3 << 12) |
        (imm4_1 << 8) |
        (imm11 << 7) |
        opcode
    )


COMMENT_RE = re.compile(r"(#|//).*")

def strip_comment(line: str):
    return COMMENT_RE.sub("", line).strip()

LABEL_RE = re.compile(r"^\s*([A-Za-z_][A-Za-z0-9_]*)\s*:\s*(.*)$")

@dataclass
class AsmLine:
    text: str
    pc: int

def tokenize_operands(op_str: str) -> List[str]:
    # spara dupa virgule operanzii
    return [t.strip() for t in op_str.split(",") if t.strip()]

MEM_RE = re.compile(r"^\s*([+-]?(?:0x[0-9a-fA-F]+|\d+))\s*\(\s*([A-Za-z0-9_]+)\s*\)\s*$")

def parse_mem_operand(s: str) -> Tuple[int, int]:
    m = MEM_RE.match(s)
    if not m:
        raise ValueError(f"Operand memorie invalid: '{s}'. Format corect: imm(rs1) ex: 0(sp) sau -4(s0)")
    imm = parse_imm(m.group(1))
    rs1 = reg_num(m.group(2))
    return imm, rs1


def assemble(text: str, base_addr: int = 0) -> List[int]:
    lines_raw = text.splitlines()
    labels: Dict[str, int] = {} #pt etichete
    instr_lines: List[AsmLine] = [] #pt instructiuni
    pc = base_addr

    for raw in lines_raw:
        line = strip_comment(raw) #sterg comentariile
        if not line:
            continue #ca pot sa am o linie doar cu un comnetariu
        while True:
            m = LABEL_RE.match(line)
            if not m:
                break #asta daca nu e un label 
            label = m.group(1)
            rest = m.group(2).strip()
            if label in labels:
                raise ValueError(f"Label duplicat: {label}")
            labels[label] = pc
            line = rest
            if not line:
                break
        if not line:
            continue
        instr_lines.append(AsmLine(text=line, pc=pc))
        pc += 4

    out: List[int] = []
    for item in instr_lines:
        inst = encode_line(item.text, item.pc, labels)
        out.append(inst)

    out.append(enc_b_type(0, 0, 0, 0b000, 0b1100011))


    return out

def encode_line(line: str, pc: int, labels: Dict[str, int]):
    parts = line.strip().split(None, 1)
    op = parts[0].lower() # instructiunea 
    ops = parts[1] if len(parts) > 1 else ""  
    operands = tokenize_operands(ops) #operanzii separati 

    OPC_R   = 0b0110011
    OPC_I   = 0b0010011
    OPC_LW  = 0b0000011
    OPC_SW  = 0b0100011
    OPC_BEQ = 0b1100011

    if op == "add":
        if len(operands) != 3:
            raise ValueError("Sintaxa: add rd, rs1, rs2")
        rd, rs1, rs2 = map(reg_num, operands)
        return enc_r_type(0b0000000, rs2, rs1, 0b000, rd, OPC_R)

    if op == "and":
        if len(operands) != 3:
            raise ValueError("Sintaxa: and rd, rs1, rs2")
        rd, rs1, rs2 = map(reg_num, operands)
        return enc_r_type(0b0000000, rs2, rs1, 0b111, rd, OPC_R)

    if op == "or":
        if len(operands) != 3:
            raise ValueError("Sintaxa: or rd, rs1, rs2")
        rd, rs1, rs2 = map(reg_num, operands)
        return enc_r_type(0b0000000, rs2, rs1, 0b110, rd, OPC_R)

    if op == "addi":
        if len(operands) != 3:
            raise ValueError("Sintaxa: addi rd, rs1, imm")
        rd = reg_num(operands[0])
        rs1 = reg_num(operands[1])
        imm = parse_imm(operands[2])
        return enc_i_type(imm, rs1, 0b000, rd, OPC_I)

    if op == "lw":
        if len(operands) != 2:
            raise ValueError("Sintaxa: lw rd, imm(rs1)")
        rd = reg_num(operands[0])
        imm, rs1 = parse_mem_operand(operands[1])
        return enc_i_type(imm, rs1, 0b010, rd, OPC_LW)

    if op == "sw":
        if len(operands) != 2:
            raise ValueError("Sintaxa: sw rs2, imm(rs1)")
        rs2 = reg_num(operands[0])
        imm, rs1 = parse_mem_operand(operands[1])
        return enc_s_type(imm, rs2, rs1, 0b010, OPC_SW)

    if op == "beq":
        if len(operands) != 3:
            raise ValueError("Sintaxa: beq rs1, rs2, label/imm")
        rs1 = reg_num(operands[0])
        rs2 = reg_num(operands[1])
        target = operands[2].strip()
        if re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", target):
            if target not in labels:
                raise ValueError(f"Label inexistent: {target}")
            target_pc = labels[target]
            offset = target_pc - pc
        else:
            offset = parse_imm(target)
        return enc_b_type(offset, rs2, rs1, 0b000, OPC_BEQ)

    raise ValueError(f"Instrutțiune nesuportata: '{op}'. Accept: add, addi, and, or, beq, lw, sw")

def to_mem_hex(instrs: List[int]) -> str:
    return "\n".join(f"{i:08x}" for i in instrs) + ("\n" if instrs else "")
