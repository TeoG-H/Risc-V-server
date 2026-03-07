from flask import Flask, request, render_template
import subprocess
from assembler import assemble, to_mem_hex
import os

app = Flask(__name__)

@app.route("/", methods=["GET", "POST"])
def index():
    output = ""  #ce produce simulatorul verilog
    memhex = ""  #codul masina generat
    error = ""   #mesaj de eroare

    if request.method == "POST": 
        asm = request.form.get("code", "")  #preia textul 

        try:
            instrs = assemble(asm)      #ia codul , il asambleaza in instructiuni
            memhex = to_mem_hex(instrs) #aici inst le transform in cod hexa
            
            with open("program.mem", "w", encoding="utf-8") as f:
                f.write(memhex)  # bag codul in in program.mem 

            result = subprocess.run(["vvp", "sim"], capture_output=True, text=True)
            output = result.stdout #rezultatul din subproces in pun in output 
            #daca exista erori le pun si pe ele in output
            if result.stderr:
                output += "\n[stderr]\n" + result.stderr

        except Exception as e:
            error = str(e)

    #trimit outpu-tul inapoi la pagina 
    return render_template("index.html", output=output, memhex=memhex, error=error)

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 10000))
    app.run(host="0.0.0.0", port=port)