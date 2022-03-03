const std = @import("std");
const mem = std.mem;
const assert = std.debug.assert;
const print = std.debug.print;
const err = std.log.err;
const warn = std.log.warn;

// Helper functions

/// Initialize registers
pub fn init_reg() [4]u32 {
    return [1]u32{ 0 } ** 4;
}

/// Warn that an operator is currently in todo
fn todo() void {
    warn("TODO", .{});
}

/// Opcodes
/// This is not written in the code, but documented here instead.
/// Here is the list of opcodes:
/// 0000: HALT
/// 1xkk: SET Vx, kk
/// 2ab[1-5]: [ADD, SUB, MUL, DIV, MOD] a, b -> a
/// 3x01: WRITE Vx
/// 3x02: READ Vx
/// 40nn: JMP nn
/// 5xy[1-6]: Comparison operators

/// PC (Program counter)
var pc: u32 = undefined;
/// Running flag (runs the program until this is false)
var running: bool = true;
/// VM
pub const VM = struct {
    reg: [4]u32,            // Registers
    program: []u32,         // Program

    /// Fetch the instruction from the program at PC
    fn fetch(self: VM) u32 {
        const instr = self.program[pc];
        pc = pc + 1;
        return instr;
    }

    /// Decode instruction
    fn decode(instr: u32) [4]u32 {
        var opcode = (instr & 0xF000) >> 12;
        var reg1   = (instr & 0xF00 ) >> 8;
        var reg2   = (instr & 0xF0  ) >> 4;
        var val    = (instr & 0xFF  );

        return [4]u32{opcode, reg1, reg2, val};
    }

    /// Debugging
    pub fn debug(self: VM) void {
        print("Registers: {X:0>4} ", .{self.reg});
        print("PC: {d}\n", .{pc});
    }

    /// Evaluate the decoded instruction
    fn eval(self: *VM) void {
        var instr = self.fetch();
        var decoded = decode(instr);
        var opcode = decoded[0];
        var reg1   = decoded[1];
        var reg2   = decoded[2];
        var val    = decoded[3];

        switch (opcode) {
            0 => { running = false; print("halt\n", .{}); },
            1 => { self.reg[reg1] = val; print("set r{d}, #{X} ({d})\n", .{reg1, val, val}); },
            2 => {
                var mode = (val & 0xF);
                switch (mode) {
                    1 => { self.reg[reg1] = self.reg[reg1] + self.reg[reg2]; print("add r{d}, r{d} -> r{d}\n", .{reg1, reg2, reg1}); },
                    2 => { self.reg[reg1] = self.reg[reg1] - self.reg[reg2]; print("sub r{d}, r{d} -> r{d}\n", .{reg1, reg2, reg1}); },
                    3 => { self.reg[reg1] = self.reg[reg1] * self.reg[reg2]; print("mul r{d}, r{d} -> r{d}\n", .{reg1, reg2, reg1}); },
                    4 => { self.reg[reg1] = self.reg[reg1] / self.reg[reg2]; print("div r{d}, r{d} -> r{d}\n", .{reg1, reg2, reg1}); },
                    5 => { self.reg[reg1] = self.reg[reg1] % self.reg[reg2]; print("mod r{d}, r{d} -> r{d}\n", .{reg1, reg2, reg1}); },
                    else => err("Unknown mode for opcode 2 => {d:0>2}", .{mode}),
                }
            },
            3 => {
                var mode = val;
                switch (mode) {
                    1 => { print("{d}\n", .{self.reg[reg1]}); print("write r{d}\n", .{reg1}); },
                    2 => todo(),
                    else => err("Unknown mode for opcode 3 => {d:0>2}", .{mode}),
                }
            },
            4 => { pc = val; print("jmp #{X:0>2} ({d})\n", .{val, val}); },
            else => err("Unknown opcode => {x}", .{opcode}),
        }
        self.debug(); // Print debug info after eval
    }

    /// Run the program
    pub fn run(self: *VM) void {
        while (running) {
            self.eval();
        }
    }
};

pub fn main() !void {
    // There will be CLI in here, but it is empty for now.
    var program = [_]u32{ 0x4002, 0x0000, 0x1064, 0x3001, 0x4001 };
    const sliced = program[0..program.len];
    var vm = VM{
        .reg = init_reg(),
        .program = sliced,
    };
    vm.run();
}
