import random
import os

random.seed(42)

OUTPUT = os.path.join(os.path.dirname(__file__), "inserts_defensa.sql")
LINES = []

def p(s=""):
    LINES.append(s)

def esc(s):
    return s.replace("'", "''")

# ── HEADER ──
p("-- ============================================================")
p("-- INSERTS PARA DEFENSA")
p("-- ============================================================")
p("-- LUEGO DE INSERTAR, CORRER ESTAS ETLs EN PENTAHO:")
p("--")
p("--   1. DIM_CLIENTE")
p("--   2. DIM_PRODUCTO")
p("--   3. DIM_CONTRATO")
p("--   4. DIM_SINIESTRO")
p("--   5. FACT_EVALUACION_SERVICIO")
p("--   6. FACT_REGISTRO_CONTRATO")
p("--   7. FACT_REGISTRO_SINIESTRO")
p("--")
p("-- (las dem\u00e1s no cambian, no hace falta ejecutarlas)")
p("-- ============================================================")
p("")
p("SET search_path TO SEGURO_G28310422;")
p("")

# ── DATA POOLS ──

first_names_m = [
    "Carlos","Luis","Jose","Manuel","Juan","Diego","Andres","Santiago","Mateo","Sebastian",
    "Samuel","Daniel","Gabriel","David","Pablo","Raul","Alberto","Ricardo","Oscar","Hector",
    "Ivan","Marco","Victor","Jorge","Fernando","Alejandro","Miguel","Eduardo","Francisco","Javier",
    "Rodrigo","Gustavo","Ramon","Alfredo","Christian","Moisés","Nelson","Reinaldo","Humberto","Saul",
    "Rafael","Cristian","Edgar","Jesus","Joaquin","Lorenzo","Oliver","Leonardo","Mauricio","Felipe"
]

first_names_f = [
    "Maria","Ana","Carmen","Sofia","Valentina","Isabella","Gabriela","Laura","Daniela","Andrea",
    "Paola","Camila","Natalia","Luciana","Martha","Elena","Silvia","Rosa","Diana","Veronica",
    "Yolanda","Patricia","Adriana","Alejandra","Monica","Beatriz","Liliana","Teresa","Julia","Claudia",
    "Susana","Mireya","Luisa","Cristina","Mariana","Ruth","Gloria","Irene","Angela","Leticia",
    "Brenda","Katherine","Michelle","Wendy","Lisbeth","Yuleima","Genesis","Fabiana","Zulay","Xiomara"
]

last_names = [
    "Rodriguez","Martinez","Garcia","Lopez","Hernandez","Gonzalez","Perez","Sanchez","Ramirez","Cruz",
    "Flores","Morales","Ortiz","Vargas","Castro","Reyes","Gutierrez","Mendoza","Molina","Ruiz",
    "Alvarez","Diaz","Romero","Contreras","Acosta","Castillo","Cabrera","Paredes","Moreno","Rivas",
    "Navarro","Torres","Medina","Cordero","Bravo","Leon","Ferrer","Blanco","Cardenas","Aguilar",
    "Jimenez","Salazar","Peña","Rondon","Guerrero","Vera","Carrillo","Rojas","Figueroa","Marquez"
]

ciudades = [
    "Av.","Calle","Carrera","Urbanizacion"
]
via_nombres = [
    "Bolivar","Paez","Sucre","Urdaneta","Miranda","Libertador","San Martin","La Paz",
    "El Carmen","Los Ilustres","Los Mangos","El Valle","Santa Rosa","Buenos Aires",
    "Las Flores","La Florida","San Cristobal","Las Acacias","El Paraiso","Bello Monte"
]
edif_tipos = ["Edif.","Torre","Res.","Quinta","Casa"]

sucursales = list(range(1, 13))

estados = ["activo","vencido","suspendido"]
estados_weights = [0.6, 0.3, 0.1]

# ── 1. PRODUCTOS (9 nuevos) ──
p("-- ============================================================")
p("-- NUEVOS PRODUCTOS")
p("-- ============================================================")
p("")

nuevos_productos = [
    (7,  "Viaje",                "Seguro de asistencia al viajero con cobertura m\u00e9dica, equipaje y cancelaci\u00f3n.",                                  1, 10),
    (8,  "Hogar Inteligente",    "Cobertura para hogares con dispositivos IoT, da\u00f1os el\u00e9ctricos y protecci\u00f3n smart.",                           3, 9),
    (9,  "Mascotas",             "Seguro veterinario, cirug\u00edas, medicamentos y responsabilidad civil por mascotas.",                                   2, 10),
    (10, "Ciberseguridad",       "Protecci\u00f3n contra ataques inform\u00e1ticos, ransomware, robo de identidad y p\u00e9rdida de datos.",                   4, 10),
    (11, "Deportes y Aventura",  "Seguro para actividades deportivas extremas y turismo de aventura con cobertura m\u00e9dica integral.",                  1, 9),
    (12, "Equipos Electr\u00f3nicos", "Cobertura contra robo, da\u00f1o accidental y p\u00e9rdida de equipos electr\u00f3nicos personales.",                      3, 6),
    (13, "Transporte de Mercanc\u00edas", "Seguro log\u00edstico para transporte de mercanc\u00edas con cobertura de da\u00f1os y p\u00e9rdidas.",                   4, 5),
    (14, "Bicicletas y Scooters","Seguro contra robo, da\u00f1os y responsabilidad civil para bicicletas y scooters el\u00e9ctricos.",                      2, 6),
    (15, "Maquinaria Agr\u00edcola",  "Protecci\u00f3n para maquinaria agr\u00edcola contra da\u00f1os, accidentes y robo.",                                     3, 5),
]

for prod in nuevos_productos:
    p(f"INSERT INTO PRODUCTO (cod_producto, nb_producto, descripcion, cod_tipo_producto, calificacion) VALUES ({prod[0]}, '{esc(prod[1])}', '{esc(prod[2])}', {prod[3]}, {prod[4]});")
p("")

# ── 2. CLIENTES (400: cod 201→600) ──
p("-- ============================================================")
p("-- NUEVOS CLIENTES (201 al 600)")
p("-- ============================================================")
p("")

def gen_phone():
    op = random.choice(["0412","0414","0416","0424","0426"])
    return f"'{op}-{random.randint(1000000,9999999)}'"

def gen_rif(ci_type):
    if ci_type == "V":
        num = random.randint(1000000, 99999999)
        return f"'V-{num}'"
    elif ci_type == "J":
        num1 = random.randint(10000000, 99999999)
        num2 = random.randint(0, 9)
        return f"'J-{num1}-{num2}'"
    else:
        num = random.randint(1000000, 99999999)
        return f"'E-{num}'"

def gen_address():
    if random.random() < 0.15:
        return "NULL"
    via = random.choice(ciudades)
    nombre = random.choice(via_nombres)
    tipo = random.choice(edif_tipos)
    nro = f"Nro {random.randint(100,9999)}"
    return f"'{esc(via)} {esc(nombre)}, {esc(tipo)} {nro}'"

def gen_email(nombre, apellido1):
    dominios = ["gmail.com","hotmail.com","yahoo.com","yahoo.es","cantv.net","outlook.com"]
    d = random.choice(dominios)
    user = f"{nombre.lower()}.{apellido1.lower()}{random.randint(1,999)}"
    return f"'{user}@{d}'"

random.shuffle(first_names_m)
random.shuffle(first_names_f)
m_idx = 0
f_idx = 0

for cod in range(201, 601):
    if random.random() < 0.48:
        nombre = first_names_m[m_idx % len(first_names_m)]
        sexo = "'M'"
        m_idx += 1
    else:
        nombre = first_names_f[f_idx % len(first_names_f)]
        sexo = "'F'"
        f_idx += 1
    ap1 = random.choice(last_names)
    ap2 = random.choice(last_names)
    while ap2 == ap1:
        ap2 = random.choice(last_names)
    nb = f"'{esc(nombre)} {esc(ap1)} {esc(ap2)}'"
    ci_type = random.choices(["V","J","E"], weights=[0.7, 0.2, 0.1])[0]
    ci = gen_rif(ci_type)
    if random.random() < 0.1:
        tel = "NULL"
    else:
        tel = gen_phone()
    dir = gen_address()
    if random.random() < 0.08:
        email = "NULL"
    else:
        email = gen_email(nombre, ap1)
    suc = random.choice(sucursales)
    p(f"INSERT INTO CLIENTE (cod_cliente, nb_cliente, ci_rif, telefono, direccion, sexo, email, cod_sucursal) VALUES ({cod}, {nb}, {ci}, {tel}, {dir}, {sexo}, {email}, {suc});")

p("")

# ── 3. CONTRATOS (1,200: nro 2001→3200) ──
p("-- ============================================================")
p("-- NUEVOS CONTRATOS (2001 al 3200)")
p("-- ============================================================")
p("")

tipos_contrato = [
    "P\u00f3liza de Seguro de Transporte Nro","Seguro de Vida Familiar Nro",
    "Contrato de Responsabilidad Civil Nro","P\u00f3liza de Cr\u00e9dito y Cauci\u00f3n Nro",
    "P\u00f3liza de Incendios Nro","P\u00f3liza de Asistencia M\u00e9dica Nro",
    "Contrato de Seguro Vehicular Nro","Seguro de Desgravamen Hipotecario Nro",
    "Contrato de Seguro de Hogar Nro","P\u00f3liza de Da\u00f1os Materiales Nro",
    "Seguro de Vida Individual Nro","P\u00f3liza de Cobertura Integral Nro",
    "P\u00f3liza de Salud Integral Nro","Contrato de Seguro Patrimonial Nro",
    "P\u00f3liza de Fianza y Cauci\u00f3n Nro","Contrato de Seguro de Autom\u00f3vil Nro",
    "P\u00f3liza de Cobertura M\u00e9dica Nro","P\u00f3liza de Incendio y Aliados Nro",
    "Seguro de Accidentes Personales Nro","Contrato de Seguro de Viaje Nro"
]

for nro in range(2001, 3201):
    desc = f"'{esc(random.choice(tipos_contrato))} {nro}'"
    p(f"INSERT INTO CONTRATO (nro_contrato, descrip_contrato) VALUES ({nro}, {desc});")

p("")

# ── 4. REGISTRO_CONTRATO (1,800) ──
p("-- ============================================================")
p("-- NUEVOS REGISTROS DE CONTRATO (1,800)")
p("-- ============================================================")
p("")

# Distribution: cod_producto → count
rc_dist = {
    1: 150, 2: 100, 3: 100, 4: 150, 5: 120, 6: 60,
    7: 250, 8: 200, 9: 200, 10: 200, 11: 120,
    12: 50, 13: 40, 14: 30, 15: 30
}
# Total = 1800 ✅

# Year distribution: year → count
year_dist_rc = {2021: 600, 2022: 750, 2023: 450}

# Build flat list of product assignments
product_list = []
for prod, cnt in rc_dist.items():
    product_list.extend([prod] * cnt)
random.shuffle(product_list)

# Build flat list of year assignments
year_list = []
for year, cnt in year_dist_rc.items():
    year_list.extend([year] * cnt)
random.shuffle(year_list)

# We need 1,800 entries. We have 1,200 contracts (nro 2001-3200).
# Some contracts will be used multiple times (different products).
# Most contracts used once, some used twice.
contract_nros = list(range(2001, 3201))
random.shuffle(contract_nros)

# Assign contracts: we need 1800 entries from 1200 contracts
# ~600 contracts will be used twice, ~600 once
used_contracts = []
for i in range(1800):
    if i < 1200:
        used_contracts.append(contract_nros[i])
    else:
        # Reuse a random contract from the first 1200
        used_contracts.append(random.choice(contract_nros[:1200]))

random.shuffle(used_contracts)  # shuffle so reuse isn't sequential

# Assign clients (201-600) randomly
client_pool = list(range(201, 601))

for i in range(1800):
    nro_contrato = used_contracts[i]
    cod_producto = product_list[i]
    cod_cliente = random.choice(client_pool)
    year = year_list[i]

    month = random.randint(1, 12)
    day = random.randint(1, 28)
    fecha_inicio = f"'{year}-{month:02d}-{day:02d}'"

    # fecha_fin: 1-24 months after start, can go into 2024+
    duration = random.randint(6, 24)
    # Simple: just set a fixed end date based on year
    if year == 2021:
        end_year = random.choice([2022, 2023])
        end_month = random.randint(1, 12)
    elif year == 2022:
        end_year = random.choice([2023, 2024])
        end_month = random.randint(1, 12)
    else:
        end_year = random.choice([2024, 2025])
        end_month = random.randint(1, 12)
    end_day = random.randint(1, 28)
    fecha_fin = f"'{end_year}-{end_month:02d}-{end_day:02d}'"

    monto = round(random.uniform(50.0, 5000.0), 2)
    estado = random.choices(estados, weights=estados_weights)[0]

    p(f"INSERT INTO REGISTRO_CONTRATO (nro_contrato, cod_producto, cod_cliente, fecha_inicio, fecha_fin, monto, estado_contrato) VALUES ({nro_contrato}, {cod_producto}, {cod_cliente}, {fecha_inicio}, {fecha_fin}, {monto}, '{estado}');")

p("")

# ── 5. SINIESTROS (600: nro 1501→2100) ──
p("-- ============================================================")
p("-- NUEVOS SINIESTROS (1501 al 2100)")
p("-- ============================================================")
p("")

desc_siniestros = [
    "Colisi\u00f3n de veh\u00edculo","Robo de veh\u00edculo","Incendio de vivienda",
    "Da\u00f1os por tormenta","Cancelaci\u00f3n de viaje","P\u00e9rdida de equipaje",
    "Emergencia m\u00e9dica en el extranjero","Ataque de ransomware","Fuga de datos personales",
    "Robo de identidad","Accidente deportivo","Lesi\u00f3n por mascota",
    "Robo de bicicleta","Da\u00f1o a terceros","Falla de maquinaria agr\u00edcola",
    "Robo de equipos electr\u00f3nicos","Da\u00f1os por inundaci\u00f3n","P\u00e9rdida de mercanc\u00eda",
    "Huelga y disturbios","Da\u00f1o el\u00e9ctrico en hogar","Rotura de tuber\u00edas",
    "Muerte accidental","Enfermedad grave","Robo en vivienda",
    "Da\u00f1o a propiedad ajena","Lesiones personales","Accidente de tr\u00e1nsito",
    "Rotura de cristales","Da\u00f1o por vandalismo","Robo de scooter el\u00e9ctrico"
]

for nro in range(1501, 2101):
    desc = f"'{esc(random.choice(desc_siniestros))} Nro {nro}'"
    p(f"INSERT INTO SINIESTRO (nro_siniestro, descripcion_siniestro) VALUES ({nro}, {desc});")

p("")

# ── 6. REGISTRO_SINIESTRO (600) ──
p("-- ============================================================")
p("-- NUEVOS REGISTROS DE SINIESTRO (600)")
p("-- ============================================================")
p("")

# Distribution by product (proportional to contracts)
rs_dist = {
    1: 50, 2: 33, 3: 33, 4: 50, 5: 40, 6: 20,
    7: 83, 8: 67, 9: 67, 10: 67, 11: 40,
    12: 17, 13: 13, 14: 10, 15: 10
}
# Total = 600 ✅

year_dist_rs = {2021: 180, 2022: 250, 2023: 170}

rs_product_list = []
for prod, cnt in rs_dist.items():
    rs_product_list.extend([prod] * cnt)
random.shuffle(rs_product_list)

rs_year_list = []
for year, cnt in year_dist_rs.items():
    rs_year_list.extend([year] * cnt)
random.shuffle(rs_year_list)

# Siniestros: nro 1501-2100 (600)
siniestro_nros = list(range(1501, 2101))
random.shuffle(siniestro_nros)

# Pick contracts from REGISTRO_CONTRATO that were inserted
# Use nro 2001-3200 as references
rc_contracts_pool = list(range(2001, 3201))

for i in range(600):
    nro_siniestro = siniestro_nros[i]
    nro_contrato = random.choice(rc_contracts_pool)
    year = rs_year_list[i]

    month = random.randint(1, 12)
    day = random.randint(1, 28)
    fecha_siniestro = f"'{year}-{month:02d}-{day:02d}'"

    # fecha_respuesta: always >= fecha_siniestro
    # Add 5-90 days to fecha_siniestro
    total_days_since = day + random.randint(5, 90)
    new_month = month
    new_year = year
    while total_days_since > 28:
        total_days_since -= 28
        new_month += 1
        if new_month > 12:
            new_month = 1
            new_year += 1
    resp_month = new_month
    resp_year = new_year
    resp_day = min(total_days_since, 28)
    if resp_day < 1:
        resp_day = 1
    fecha_respuesta = f"'{resp_year}-{resp_month:02d}-{resp_day:02d}'"

    id_rechazo = random.choices(["'SI'", "'NO'"], weights=[0.15, 0.85])[0]
    monto_solicitado = round(random.uniform(100.0, 8000.0), 2)
    if id_rechazo == "'SI'":
        monto_reconocido = "0.00"
    else:
        factor = random.uniform(0.3, 1.0)
        monto_reconocido = f"{round(monto_solicitado * factor, 2)}"

    p(f"INSERT INTO REGISTRO_SINIESTRO (nro_siniestro, nro_contrato, fecha_siniestro, fecha_respuesta, id_rechazo, monto_reconocido, monto_solicitado) VALUES ({nro_siniestro}, {nro_contrato}, {fecha_siniestro}, {fecha_respuesta}, {id_rechazo}, {monto_reconocido}, {round(monto_solicitado, 2)});")

p("")

# ── 7. RECOMIENDA (1,400) ──
p("-- ============================================================")
p("-- NUEVAS RECOMENDACIONES (1,400)")
p("-- ============================================================")
p("")

# Distribution by product
rec_dist = {
    1: 120, 2: 80, 3: 80, 4: 120, 5: 95, 6: 48,
    7: 190, 8: 155, 9: 155, 10: 155, 11: 95,
    12: 39, 13: 31, 14: 22, 15: 15
}
# Total = 1,400 ✅

rec_product_list = []
for prod, cnt in rec_dist.items():
    rec_product_list.extend([prod] * cnt)
random.shuffle(rec_product_list)

# Evaluaciones: 1-5, weighted toward high for new products
eval_for_product = {}
for prod in range(1, 16):
    if prod in [7,8,9,10,11]:
        # New attractive products: higher ratings
        eval_for_product[prod] = random.choices([1,2,3,4,5], weights=[0.02, 0.03, 0.1, 0.35, 0.5])
    elif prod in [12,13,14,15]:
        # Niche products: mixed
        eval_for_product[prod] = random.choices([1,2,3,4,5], weights=[0.1, 0.15, 0.3, 0.3, 0.15])
    else:
        # Existing: mix
        eval_for_product[prod] = random.choices([1,2,3,4,5], weights=[0.05, 0.1, 0.25, 0.35, 0.25])

# Use (client, product) pairs tracking to avoid PK duplicates
# PK is (cod_cliente, cod_evaluacion_servicio, cod_producto)
used_pairs = set()

for cod_producto in rec_product_list:
    # Try up to 50 times to find a unique pair
    for _ in range(50):
        cod_cliente = random.randint(201, 600)
        cod_eval = random.choices([1,2,3,4,5], weights=[0.02, 0.03, 0.1, 0.35, 0.5])[0]
        if (cod_cliente, cod_eval, cod_producto) not in used_pairs:
            used_pairs.add((cod_cliente, cod_eval, cod_producto))
            break
    
    recomienda = random.choices(["'SI'","'NO'"], weights=[0.8, 0.2])[0] if cod_eval >= 3 else random.choices(["'SI'","'NO'"], weights=[0.2, 0.8])[0]
    p(f"INSERT INTO RECOMIENDA (cod_cliente, cod_evaluacion_servicio, cod_producto, recomienda_amigo) VALUES ({cod_cliente}, {cod_eval}, {cod_producto}, {recomienda});")

p("")
p("-- ============================================================")
p("-- FIN - TOTAL INSERTS: 9 PRODUCTOS + 400 CLIENTES")
p("--                     + 1200 CONTRATOS + 1800 REG_CONTRATO")
p("--                     + 600 SINIESTROS + 600 REG_SINIESTRO")
p("--                     + 1400 RECOMIENDA = 6009 TOTAL")
p("-- ============================================================")

# ── WRITE ──
with open(OUTPUT, "w", encoding="utf-8") as f:
    f.write("\n".join(LINES))

# Count
counts = {
    "PRODUCTO": 0,
    "CLIENTE": 0,
    "CONTRATO": 0,
    "REGISTRO_CONTRATO": 0,
    "SINIESTRO": 0,
    "REGISTRO_SINIESTRO": 0,
    "RECOMIENDA": 0,
}
for line in LINES:
    for table in counts:
        if line.startswith(f"INSERT INTO {table}"):
            counts[table] += 1

print("Generated:", OUTPUT)
print("Counts:", counts)
print("Total:", sum(counts.values()))
