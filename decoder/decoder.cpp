#include <bitset>
#include <fstream>
#include <iostream>
#include <string>

using namespace std;

const int maxValue = (1 << 15) - 1;

// Opcodes
const string lui        = "01101";
const string auipc      = "00101";
const string jal        = "11011";
const string jalr       = "11001";
const string branch     = "11000";
const string load       = "00000";
const string store      = "01000";
const string immediate  = "00100";
const string register_  = "01100";
const string csr        = "11100";
// Funct3
const string beq        = "000";
const string bne        = "001";
const string blt        = "100";
const string bge        = "101";
const string bltu       = "110";
const string bgeu       = "111";
const string lb         = "000";
const string lh         = "001";
const string lw         = "010";
const string lbu        = "100";
const string lhu        = "101";
const string sb         = "000";
const string sh         = "001";
const string sw         = "010";
const string addi       = "000";
const string slti       = "010";
const string sltiu      = "011";
const string xori       = "100";
const string ori        = "110";
const string andi       = "111";
const string slli       = "001";
const string srli       = "101";
const string srai       = "101";
const string add        = "000";
const string sub        = "000";
const string sll        = "001";
const string slt        = "010";
const string sltu       = "011";
const string xor_       = "100";
const string srl        = "101";
const string sra        = "101";
const string or_        = "110";
const string and_       = "111";
const string csrrw      = "001";
const string csrrs      = "010";
const string csrrc      = "011";
const string csrrwi     = "101";
const string csrrsi     = "110";
const string csrrci     = "111";
// Funct12
const string mtvecAddr      = "0000001100000101";
const string mepcAddr       = "0000001101000001";
const string mcauseAddr     = "0000001101000010";
const string mstatusAddr    = "0000001100000000";

// decode next-pc select signals, active LOW
void decode1() {
    std::ofstream outfile("output/1-u33.bin", std::ios::out | std::ios::binary);

    for (int enumValue = 0; enumValue <= maxValue; enumValue++) {
        string bitStr = bitset<15>(enumValue).to_string();
        string opcode = bitStr.substr(2, 5);
        string funct3 = bitStr.substr(7, 3);
        string isZero = bitStr.substr(10, 1);
        string isLess = bitStr.substr(11, 1);
        string isLessU = bitStr.substr(12, 1);

        string selectBase = "11"; // regA(MSB), pc
        if (opcode == jalr) {
            selectBase = "10";
        } else {
            selectBase = "01";
        }

        string selectOffset = "1111"; // 4(MSB), immB, immI, immJ
        if (opcode == jal) {
            selectOffset = "1110";
        } else if (opcode == jalr) {
            selectOffset = "1101";
        } else if (opcode == branch) {
            if (funct3 == beq  && isZero  == "0" || funct3 == bne  && isZero  == "1" ||
                funct3 == blt  && isLess  == "0" || funct3 == bge  && isLess  == "1" ||
                funct3 == bltu && isLessU == "0" || funct3 == bgeu && isLessU == "1") {
                selectOffset = "1011";
            }
        } else {
            selectOffset = "0111";
        }

        string byte2writeStr = selectOffset + selectBase;
        char byte2write = (char)std::stoi(byte2writeStr, nullptr, 2);
        outfile.put(byte2write);
    }

    outfile.close();
}

// decode alu operands select signals, active LOW
void decode2() {
    std::ofstream outfile("output/1-u34.bin", std::ios::out | std::ios::binary);

    for (int enumValue = 0; enumValue <= maxValue; enumValue++) {
        string bitStr = bitset<15>(enumValue).to_string();
        string opcode = bitStr.substr(0, 5);
        string funct3 = bitStr.substr(5, 3);
        string funct7 = bitStr.substr(8, 1);

        string selectSrcA = "111"; // immU(MSB), regA, pc
        if (opcode == auipc || opcode == jal || opcode == jalr) {
            selectSrcA = "110";
        } else if (opcode == lui) {
            selectSrcA = "101";
        } else if (opcode == load || opcode == store || opcode == immediate || opcode == register_ || opcode == branch) {
            selectSrcA = "011";
        }

        string selectSrcB = "11111"; // regB(MSB), immS, immI, immU, 4
        if (opcode == jal || opcode == jalr) {
            selectSrcB = "11110";
        } else if (opcode == lui || opcode == auipc) {
            selectSrcB = "11101";
        } else if (opcode == load || opcode == immediate) {
            selectSrcB = "11011";
        } else if (opcode == store) {
            selectSrcB = "10111";
        } else if (opcode == register_ || opcode == branch) {
            selectSrcB = "01111";
        }

        string byte2writeStr = selectSrcB + selectSrcA;
        char byte2write = (char)std::stoi(byte2writeStr, nullptr, 2);
        outfile.put(byte2write);
    }

    outfile.close();
}

// decode alu-op, set-op, shift-op signals, active LOW
void decode3() {
    std::ofstream outfile("output/1-u35.bin", std::ios::out | std::ios::binary);

    for (int enumValue = 0; enumValue <= maxValue; enumValue++) {
        string bitStr = bitset<15>(enumValue).to_string();
        string opcode = bitStr.substr(0, 5);
        string funct3 = bitStr.substr(5, 3);
        string funct7 = bitStr.substr(8, 1);

        string aluop = "000"; // 74ls382 function select
        if (opcode == lui || opcode == auipc || opcode == jal || opcode == jalr || opcode == load || opcode == store) {
            aluop = "011";
        } else if (opcode == branch) {
            aluop = "010";
        } else if (opcode == immediate) {
            if (funct3 == addi) {
                aluop = "011";
            } else if (funct3 == xori) {
                aluop = "100";
            } else if (funct3 == ori) {
                aluop = "101";
            } else if (funct3 == andi) {
                aluop = "110";
            }
        } else if (opcode == register_) {
            if (funct3 == add && funct7 == "0") {
                aluop = "011";
            } else if (funct3 == sub && funct7 == "1") {
                aluop = "010";
            }else if (funct3 == xor_) {
                aluop = "100";
            } else if (funct3 == or_) {
                aluop = "101";
            } else if (funct3 == and_) {
                aluop = "110";
            }
        }

        string shiftop = "111"; // sll(MSB), srl, sra
        if (opcode == immediate) {
            if (funct3 == slli) {
                shiftop = "011";
            } else if (funct3 == srli && funct7 == "0") {
                shiftop = "101";
            } else if (funct3 == srai && funct7 == "1") {
                shiftop = "110";
            }
        } else if (opcode == register_) {
            if (funct3 == sll) {
                shiftop = "011";
            } else if (funct3 == srl && funct7 == "0") {
                shiftop = "101";
            } else if (funct3 == sra && funct7 == "1") {
                shiftop = "110";
            }
        }

        string setop = "11"; // slt(MSB), sltu
        if (opcode == immediate) {
            if (funct3 == slti) {
                setop = "01";
            } else if (funct3 == sltiu) {
                setop = "10";
            }
        } else if (opcode == register_) {
            if (funct3 == slt) {
                setop = "01";
            } else if (funct3 == sltu) {
                setop = "10";
            }
        }

        string byte2writeStr = setop + shiftop + aluop;
        char byte2write = (char)std::stoi(byte2writeStr, nullptr, 2);
        outfile.put(byte2write);
    }

    outfile.close();
}

// decode load-op and store-op signals, active LOW
void decode4() {
    std::ofstream outfile("output/1-u36.bin", std::ios::out | std::ios::binary);

    for (int enumValue = 0; enumValue <= maxValue; enumValue++) {
        string bitStr = bitset<15>(enumValue).to_string();
        string opcode = bitStr.substr(0, 5);
        string funct3 = bitStr.substr(5, 3);
        string funct7 = bitStr.substr(8, 1);

        string loadop = "11111"; // lhu(MSB), lbu, lw, lh, lb
        if (opcode == load) {
            if (funct3 == lhu) {
                loadop = "01111";
            } else if (funct3 == lbu) {
                loadop = "10111";
            } else if (funct3 == lw) {
                loadop = "11011";
            } else if (funct3 == lh) {
                loadop = "11101";
            } else if (funct3 == lb) {
                loadop = "11110";
            }
        }

        string storeop = "111"; // sw(MSB), sh, sb
        if (opcode == store) {
            if (funct3 == sw) {
                storeop = "011";
            } else if (funct3 == sh) {
                storeop = "101";
            } else if (funct3 == sb) {
                storeop = "110";
            }
        }

        string byte2writeStr = storeop + loadop;
        char byte2write = (char)std::stoi(byte2writeStr, nullptr, 2);
        outfile.put(byte2write);
    }

    outfile.close();
}

// decode csr-op signals, active LOW
void decode5() {
    std::ofstream outfile("output/1-u145.bin", std::ios::out | std::ios::binary);

    for (int enumValue = 0; enumValue <= maxValue; enumValue++) {
        string bitStr = bitset<15>(enumValue).to_string();
        string opcode = bitStr.substr(0, 5);
        string funct3 = bitStr.substr(5, 3);
        string funct12 = bitStr.substr(8, 2);
        string mstatus3 = bitStr.substr(10, 1);
        
        string csrop = "1111"; // csr_en(MSB), csrrw, csrrs, csrrc
        if (opcode == csr) {
            if (funct3 == csrrw || funct3 == csrrwi) {
                csrop = "0011";
            } else if (funct3 == csrrs || funct3 == csrrsi) {
                csrop = "0101";
            } else if (funct3 == csrrc || funct3 == csrrci) {
                csrop = "0110";
            }
        }

        string selectSrc = "11"; // imm(MSB), regA
        if (opcode == csr) {
            if (funct3 == csrrwi || funct3 == csrrsi || funct3 == csrrci) {
                selectSrc = "01";
            } else if (funct3 == csrrw || funct3 == csrrs || funct3 == csrrc) {
                selectSrc = "10";
            }
        }

        string csrExcep = "11"; // ebreak(MSB), ecall
        if (opcode == csr) {
            if (funct12 == "00" && mstatus3 == "1") { // ecall
                csrExcep = "10";
            } else if (funct12 == "01" && mstatus3 == "1") { // ebreak
                csrExcep = "01";
            }
        }

        string byte2writeStr = csrExcep + selectSrc + csrop;
        char byte2write = (char)std::stoi(byte2writeStr, nullptr, 2);
        outfile.put(byte2write);
    }

    outfile.close();
}

// decode external interupt and timer interrupt signals, active LOW
void decode6() {
    std::ofstream outfile("output/1-u146.bin", std::ios::out | std::ios::binary);

    for (int enumValue = 0; enumValue <= maxValue; enumValue++) {
        string bitStr = bitset<15>(enumValue).to_string();
        string opcode = bitStr.substr(0, 5);
        string funct3 = bitStr.substr(5, 3);
        string ti = bitStr.substr(8, 1);
        string ei = bitStr.substr(9, 1);
        string mstatus3 = bitStr.substr(10, 1);

        string tiEnable = "1";
        if (ti == "0" && mstatus3 == "1") {
            tiEnable = "0";
        }
        
        string eiEnable = "1";
        if (ei == "0" && mstatus3 == "1") {
            eiEnable = "0";
        }

        string mret = "1";
        if (opcode == csr && funct3 == "000" && mstatus3 == "0") {
            mret = "0";
        }
        string mret_n = (mret == "1") ? "0" : "1";

        string intHandle = "1";
        if (tiEnable == "0" || eiEnable == "0" || (opcode == csr && funct3 == "000" && mstatus3 == "1")) {
            intHandle = "0";
        }
        string intHandle_n = (intHandle == "1") ? "0" : "1";

        string intFlag = "1";
        if (intHandle == "0" || mret == "0") {
            intFlag = "0";
        }

        string byte2writeStr = intFlag + intHandle_n + intHandle + mret_n + mret + eiEnable + tiEnable;
        char byte2write = (char)std::stoi(byte2writeStr, nullptr, 2);
        outfile.put(byte2write);
    }

    outfile.close();
}

// decode csr data select signals, active LOW
void decode7() {
    std::ofstream outfile("output/1-u147.bin", std::ios::out | std::ios::binary);

    for (int enumValue = 0; enumValue <= maxValue; enumValue++) {
        string bitStr = bitset<15>(enumValue).to_string();
        string funct12 = bitStr.substr(0, 12);
        string csrEnable = bitStr.substr(12, 1);
        string intHandle = bitStr.substr(13, 1);
        string intFlag = bitStr.substr(14, 1);

        string mtvecWriteEnable = "1";
        if (csrEnable == "0" && funct12 == mtvecAddr) {
            mtvecWriteEnable = "0";
        }
        
        string mepcWriteEnable = "1";
        if ((csrEnable == "0" && funct12 == mepcAddr) || (intHandle == "0")) {
            mepcWriteEnable = "0";
        }

        string mcauseWriteEnable = "1";
        if (intHandle == "0") {
            mcauseWriteEnable = "0";
        }

        string mstatusWriteEnable = "1";
        if ((csrEnable == "0" && funct12 == mstatusAddr) || (intFlag == "0")) {
            mstatusWriteEnable = "0";
        }

        string mtvecOutputEnable = "1";
        if (csrEnable == "0" && funct12 == mtvecAddr) {
            mtvecOutputEnable = "0";
        }

        string mepcOutputEnable = "1";
        if (csrEnable == "0" && funct12 == mepcAddr) {
            mepcOutputEnable = "0";
        }

        string mcauseOutputEnable = "1";
        if (csrEnable == "0" && funct12 == mcauseAddr) {
            mcauseOutputEnable = "0";
        }

        string mstatusOutputEnable = "1";
        if (csrEnable == "0" && funct12 == mstatusAddr) {
            mstatusOutputEnable = "0";
        }

        string byte2writeStr = mstatusOutputEnable + mcauseOutputEnable + mepcOutputEnable + mtvecOutputEnable +
                               mstatusWriteEnable  + mcauseWriteEnable  + mepcWriteEnable  + mtvecWriteEnable;
        char byte2write = (char)std::stoi(byte2writeStr, nullptr, 2);
        outfile.put(byte2write);
    }

    outfile.close();
}

// decode general purpose register file data select signal, active LOW
void decode8() {
    std::ofstream outfile("output/1-u148.bin", std::ios::out | std::ios::binary);

    for (int enumValue = 0; enumValue <= maxValue; enumValue++) {
        string bitStr = bitset<15>(enumValue).to_string();
        string opcode = bitStr.substr(0, 5);
        string rd = bitStr.substr(5, 5);
        string funct3 = bitStr.substr(10, 3);
        string clk = bitStr.substr(13, 1);

        string gprSelectData = "11111"; // peripheral(MSB), shifter, mem, set, alu
        if (opcode == lui  || opcode == auipc ||
            opcode == jal  || opcode == jalr  || opcode == branch) {
            gprSelectData = "11110";
        } else if ((opcode == immediate && (funct3 == slti || funct3 == sltiu)) ||
                   (opcode == register_ && (funct3 == slt  || funct3 == sltu))) {
            gprSelectData = "11101";
        } else if (opcode == load && (funct3 == lb || funct3 == lh || funct3 == lw || funct3 == lbu || funct3 == lhu)) {
            gprSelectData = "11011";
        } else if ((opcode == immediate && (funct3 == slli || funct3 == srli || funct3 == srai)) ||
                   (opcode == register_ && (funct3 == sll  || funct3 == srl  || funct3 == sra))) {
            gprSelectData = "10111";
        } else {
            gprSelectData = "01111";
        }

        string gprWriteEnable = "1";
        if (clk == "0") {
            if (opcode == lui  || opcode == auipc ||
                opcode == jal  || opcode == jalr  ||
                opcode == load ||
                opcode == immediate ||
                opcode == register_ ||
                (opcode == csr && (funct3 == csrrwi || funct3 == csrrsi || funct3 == csrrci ||
                                   funct3 == csrrw  || funct3 == csrrs  || funct3 == csrrc))) {
                if (rd != "00000") {
                    gprWriteEnable = "0";
                }
            }
        }

        string byte2writeStr = gprWriteEnable + gprSelectData;
        char byte2write = (char)std::stoi(byte2writeStr, nullptr, 2);
        outfile.put(byte2write);
    }

    outfile.close();
}

// analyze alu result
void decode9() {
    std::ofstream outfile("output/2-u13.bin", std::ios::out);

    for (int enumValue = 0; enumValue <= maxValue; enumValue++) {
        string bitStr = bitset<15>(enumValue).to_string();
        string isByteZero = bitStr.substr(0, 4);
        string aluCarry = bitStr.substr(4, 1);
        string srcA31 = bitStr.substr(5, 1);
        string srcB31 = bitStr.substr(6, 1);
        string aluResult31 = bitStr.substr(7, 1);
        string slt = bitStr.substr(8, 1);
        string sltu = bitStr.substr(9, 1);

        string isZero = "1";
        if (isByteZero == "1111") {
            isZero = "0";
        }

        string isLess = "1";
        int s31 = std::stoi(aluResult31);
        int a31 = std::stoi(srcA31);
        int b31 = std::stoi(srcB31);
        if (s31 ^ ((a31 ^ b31) & (a31 ^ s31))) {
            isLess = "0";
        }

        string isLessU = "1";
        if (aluCarry == "1") {
            isLessU = "0";
        }

        string setVal = (isLess == "0" || isLessU == "0") ? "1" : "0";

        string byte2writeStr = setVal + isLessU + isLess + isZero;
        char byte2write = (char)std::stoi(byte2writeStr, nullptr, 2);
        outfile.put(byte2write);
    }

    outfile.close();
}

// decode shift operation
void decode10() {
    std::ofstream outfile("output/2-u54.bin", std::ios::out);

    for (int enumValue = 0; enumValue <= maxValue; enumValue++) {
        string bitStr = bitset<15>(enumValue).to_string();
        string srcB = bitStr.substr(0, 5);
        string srcA31 = bitStr.substr(5, 1);
        string sra = bitStr.substr(6, 1);
        string srl = bitStr.substr(7, 1);
        string sll = bitStr.substr(8, 1);

        string srcB_n = "11111";
        for (int i = 0; i < 5; i++) {
            srcB_n[i] = (srcB[i] == '1') ? '0' : '1';
        }

        string sll_n = (sll == "1") ? "0" : "1";

        string shiftSign = "0";
        if (sra == "0" && srcA31 == "1") {
            shiftSign = "1";
        }

        string byte2writeStr = shiftSign + sll_n + srcB_n;
        char byte2write = (char)std::stoi(byte2writeStr, nullptr, 2);
        outfile.put(byte2write);
    }

    outfile.close();
}

// decode ram enable signals, active LOW
void decode11() {
    std::ofstream outfile("output/2-u18.bin", std::ios::out);

    for (int enumValue = 0; enumValue <= maxValue; enumValue++) {
        string bitStr = bitset<15>(enumValue).to_string();
        string loadop = bitStr.substr(0, 5);    // lhu(MSB), lbu, lw, lh, lb
        string storeop = bitStr.substr(5, 3);   // sw(MSB), sh, sb
        string aluData0 = bitStr.substr(8, 2);  // data1(MSB), data0
        string aluData1 = bitStr.substr(10, 2); // data16(MSB), data15

        string ramWriteEnable = "1111"; // byte3(MSB), byte2, byte1, byte0
        if (storeop == "011") { // sw
            ramWriteEnable = "0000";
        } else if (storeop == "101") { // sh
            if (aluData0 == "00" || aluData0 == "01") {
                ramWriteEnable = "0011";
            } else if (aluData0 == "10" || aluData0 == "11") {
                ramWriteEnable = "1100";
            }
        } else if (storeop == "110") { // sb
            if (aluData0 == "00") {
                ramWriteEnable = "1110";
            } else if (aluData0 == "01") {
                ramWriteEnable = "1101";
            } else if (aluData0 == "10") {
                ramWriteEnable = "1011";
            } else if (aluData0 == "11") {
                ramWriteEnable = "0111";
            }
        }

        string ramOutputEnable = "1111"; // byte3(MSB), byte2, byte1, byte0
        if (loadop == "11011") { // lw
            ramOutputEnable = "0000";
        } else if (loadop == "11101" || loadop == "01111") { // lh or lhu
            if (aluData1 == "00" || aluData1 == "01") {
                ramOutputEnable = "0011";
            } else if (aluData1 == "10" || aluData1 == "11") {
                ramOutputEnable = "1100";
            }
        } else if (loadop == "11110" || loadop == "10111") { // lb or lbu
            if (aluData0 == "00") {
                ramOutputEnable = "1110";
            } else if (aluData0 == "01") {
                ramOutputEnable = "1101";
            } else if (aluData0 == "10") {
                ramOutputEnable = "1011";
            } else if (aluData0 == "11") {
                ramOutputEnable = "0111";
            }
        }

        string byte2writeStr = ramOutputEnable + ramWriteEnable;
        char byte2write = (char)std::stoi(byte2writeStr, nullptr, 2);
        outfile.put(byte2write);
    }

    outfile.close();
}

// decode mem data select signal, active LOW
void decode12() {
    std::ofstream outfile("output/2-u19.bin", std::ios::out);

    for (int enumValue = 0; enumValue <= maxValue; enumValue++) {
        string bitStr = bitset<15>(enumValue).to_string();
        string loadop = bitStr.substr(0, 5);    // lhu(MSB), lbu, lw, lh, lb
        string aluData7 = bitStr.substr(5, 1);  // data7
        string aluData15 = bitStr.substr(6, 1); // data15
        string aluData0 = bitStr.substr(7, 2);  // data1(MSB), data0

        // Select mem data 7-0
        string byteSelect = "1111"; // ram31-24(MSB), ram23-16, ram15-8, ram7-0
        // Select mem data 15-8
        string halfSelect = "1111"; // sign(MSB), sign, ram31-24, ram15-8
        // Select mem data 31-24 (MSB) and 23-16
        string wordSelect = "1111"; // sign(MSB), ram31-24, sign, ram23-16

        if (loadop == "11011") { // lw
            byteSelect = "1110";
            halfSelect = "1110";
            // wordSelect = "1010";
        } else if (loadop == "11101" || loadop == "01111") { // lh or lhu
            if (aluData0 == "00" || aluData0 == "01") {
                byteSelect = "1110";
                halfSelect = "1110";
                // wordSelect = "0101";
            } else if (aluData0 == "10" || aluData0 == "11") {
                byteSelect = "1011";
                halfSelect = "1101";
                // wordSelect = "0101";
            }
        } else if (loadop == "11110" || loadop == "10111") { // lb or lbu
            if (aluData0 == "00") {
                byteSelect = "1110";
                halfSelect = "1011";
                // wordSelect = "0101";
            } else if (aluData0 == "01") {
                byteSelect = "1101";
                halfSelect = "1011";
                // wordSelect = "0101";
            } else if (aluData0 == "10") {
                byteSelect = "1011";
                halfSelect = "0111";
                // wordSelect = "0101";
            } else if (aluData0 == "11") {
                byteSelect = "0111";
                halfSelect = "0111";
                // wordSelect = "0101";
            }
        }

        string byte2writeStr = halfSelect + byteSelect;
        char byte2write = (char)std::stoi(byte2writeStr, nullptr, 2);
        outfile.put(byte2write);
    }

    outfile.close();
}

// decode mem data select signal, active LOW
void decode13() {
    std::ofstream outfile("output/2-u20.bin", std::ios::out);
    
    for (int enumValue = 0; enumValue <= maxValue; enumValue++) {
        string bitStr = bitset<15>(enumValue).to_string();
        string loadop = bitStr.substr(0, 5);    // lhu(MSB), lbu, lw, lh, lb
        string aluData7 = bitStr.substr(5, 1);  // data7
        string aluData15 = bitStr.substr(6, 1); // data15
        string aluData0 = bitStr.substr(7, 2);  // data1(MSB), data0

        // Select mem data 7-0
        string byteSelect = "1111"; // ram31-24(MSB), ram23-16, ram15-8, ram7-0
        // Select mem data 15-8
        string halfSelect = "1111"; // sign(MSB), sign, ram31-24, ram15-8
        // Select mem data 31-24 (MSB) and 23-16
        string wordSelect = "1111"; // sign(MSB), ram31-24, sign, ram23-16

        if (loadop == "11011") { // lw
            // byteSelect = "1110";
            // halfSelect = "1110";
            wordSelect = "1010";
        } else if (loadop == "11101" || loadop == "01111") { // lh or lhu
            if (aluData0 == "00" || aluData0 == "01") {
                // byteSelect = "1110";
                // halfSelect = "1110";
                wordSelect = "0101";
            } else if (aluData0 == "10" || aluData0 == "11") {
                // byteSelect = "1011";
                // halfSelect = "1101";
                wordSelect = "0101";
            }
        } else if (loadop == "11110" || loadop == "10111") { // lb or lbu
            if (aluData0 == "00") {
                // byteSelect = "1110";
                // halfSelect = "1011";
                wordSelect = "0101";
            } else if (aluData0 == "01") {
                // byteSelect = "1101";
                // halfSelect = "1011";
                wordSelect = "0101";
            } else if (aluData0 == "10") {
                // byteSelect = "1011";
                // halfSelect = "0111";
                wordSelect = "0101";
            } else if (aluData0 == "11") {
                // byteSelect = "0111";
                // halfSelect = "0111";
                wordSelect = "0101";
            }
        }

        string byte2writeStr = wordSelect;
        char byte2write = (char)std::stoi(byte2writeStr, nullptr, 2);
        outfile.put(byte2write);
    }

    outfile.close();
}

// decode mem data select signal, active LOW
void decode14() {
    std::ofstream outfile("output/2-u21.bin", std::ios::out);

    for (int enumValue = 0; enumValue <= maxValue; enumValue++) {
        string bitStr = bitset<15>(enumValue).to_string();
        string loadop = bitStr.substr(0, 5);     // lhu(MSB), lbu, lw, lh, lb
        string aluData7 = bitStr.substr(5, 1);   // data7
        string aluData15 = bitStr.substr(6, 1);  // data15
        string aluData0 = bitStr.substr(7, 2);   // data1(MSB), data0
        string ramData7 = bitStr.substr(9, 1);   // data7
        string ramData15 = bitStr.substr(10, 1); // data15
        string ramData23 = bitStr.substr(11, 1); // data23
        string ramData31 = bitStr.substr(12, 1); // data31
        
        string memSign = "0";
        if (loadop == "11110") { // lb
            if (aluData0 == "00") {
                memSign = ramData7;
            } else if (aluData0 == "01") {
                memSign = ramData15;
            } else if (aluData0 == "10") {
                memSign = ramData23;
            } else if (aluData0 == "11") {
                memSign = ramData31;
            }
        } else if (loadop == "11101") { // lh
            if (aluData0 == "00" || aluData0 == "01") {
                memSign = ramData15;
            } else if (aluData0 == "10" || aluData0 == "11") {
                memSign = ramData31;
            }
        }

        string byte2writeStr = memSign;
        char byte2write = (char)std::stoi(byte2writeStr, nullptr, 2);
        outfile.put(byte2write);
    }

    outfile.close();
}

int main(int argc, char const *argv[]) {
    decode1();
    decode2();
    decode3();
    decode4();
    decode5();
    decode6();
    decode7();
    decode8();

    decode9();
    decode10();
    decode11();
    decode12();
    decode13();
    decode14();

    return 0;
}