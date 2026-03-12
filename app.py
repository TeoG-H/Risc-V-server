from flask import Flask, request, render_template
import subprocess
from assembler import assemble, to_mem_hex
import os

app = Flask(__name__)

VERILOG_FILES = [
    "top_tb.v",
    "Procesor_top.v",
    "Fetch_Cycle.v",
    "Decode_Cycle.v",
    "Execute_cycle.v",
    "Memory_Cycle.v",
    "Writeback_Cycle.v",
    "Hazard_Unit.v",
    "Hazard_Detection_Unit.v",
    "single_cycle_components.v",
]

@app.route("/", methods=["GET", "POST"])
def index():
    output = ""
    memhex = ""
    error = ""

    if request.method == "POST":
        asm = request.form.get("code", "")

        try:
            instrs = assemble(asm)
            memhex = to_mem_hex(instrs)

            with open("program.mem", "w", encoding="utf-8") as f:
                f.write(memhex)

            # Pasul 1: compilează Verilog proaspăt pe Linux
            compile_result = subprocess.run(
                ["iverilog", "-g2012", "-o", "sim"] + VERILOG_FILES,
                capture_output=True, text=True
            )

            if compile_result.returncode != 0:
                output = "[Eroare compilare Verilog]\n" + compile_result.stderr
            else:
                # Pasul 2: rulează simularea
                result = subprocess.run(
                    ["vvp", "sim"],
                    capture_output=True, text=True
                )
                output = result.stdout
                if result.stderr:
                    output += "\n[stderr]\n" + result.stderr

        except Exception as e:
            error = str(e)

    return render_template("index.html", output=output, memhex=memhex, error=error)

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 10000))
    app.run(host="0.0.0.0", port=port)