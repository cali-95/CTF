from challenge_local import ECPoint
from challenge_local import MyECCService

from pwn import *

import datetime


def find_b_candidats(p, a):
    P.<s,t,b> = GF(p)[]

    poly_1 = t**2 - s**3 - a*s - b
    poly_2 = -16* ( 4*a^3 + 27*b^2 )

    I = P.ideal(poly_1, poly_2)
    simple_poly_list = I.groebner_basis()
    #print(simple_poly_list)

    const = simple_poly_list[1].constant_coefficient()
    
    PP.<bb> = GF(p)[]
    sub2 = bb^2 + const
    simple_poly_root_list = sub2.roots()

    return simple_poly_root_list


def check_b_candidats(p, a, b_candidat_list):
    P.<x,y> = GF(p)[]

    a4 = a
    b_options = []
    for b_candidat in b_candidat_list:
        a6 = b_candidat[0]
        is_singluar = False
        try:
            E = EllipticCurve(P, [a4, a6])
        except ArithmeticError as e:
            is_singluar = True

        if is_singluar:
            b_options.append(a6)

    return b_options


def find_singular_points(p, a, b):
    P.<x> = GF(p)[]
    f = x^3 + a*x + b
    derivative_f = derivative(f, x)

    root_x_list = derivative_f.roots()

    singular_point_list = []
    for root_x in root_x_list:
        x = root_x[0]
        y = f(x)
        if (y == 0):
            singular_point_list.append((x,y))
    return singular_point_list


def solve_dlog(p, a, b, singular_point_x, base_point, result_point):

    P.<x> = GF(p)[]
    f = x^3 + a*x + b
    singular_point_x_with_type = GF(p)(singular_point_x)
    #print(f"{singular_point_x=}")
    f_ = f.subs(x=x+singular_point_x_with_type)

    base_point_ = (base_point[0] - singular_point_x, base_point[1])
    result_point_ = (result_point[0] - singular_point_x, result_point[1])

    t_candidat_list = []
    root_list = f_.roots()
    #print(f_)
    for root in root_list:
        if root[0] != 0:
            #print("root", root[0])
            t_list = (GF(p)(((-1)*root[0]))).square_root(all=False)
            t_candidat_list.append(t_list)

    #print(f"{t_candidat_list=}")
    P_ = base_point_
    Q_ = result_point_

    K = GF(p)[sqrt(3)]
    g = K.gen()

    KK = GF(p)

    P_ = (KK(base_point_[0]), KK(base_point_[1]))
    Q_ = (KK(result_point_[0]), KK(result_point_[1]))

    factor_list = []
    for t in t_candidat_list:
        t = g
        
        u = (P_[1] + t*P_[0])/(P_[1] - t*P_[0])
        v = (Q_[1] + t*Q_[0])/(Q_[1] - t*Q_[0])
        print(f"{u=}")
        print(f"{v=}")
        try:
            factor = v.log(u)
            print(f"{factor=}")
            factor_list.append(factor)
        except Exception as e:
            print(e)
            print("no dlog")

    return factor_list

def calc_points(x_value, p):
    y_squared_value = x_value**3 + a*x_value + b
    y_value_list = GF(p)(y_squared_value).square_root(all=True)

    # two, because y^2
    point_list = [(x_value, y_value_list[0]), (x_value, y_value_list[1])]
    
    return point_list

def calcFactor(payload_bytes, my_index, p, a, b, base_point, singular_point):
    length_x_in_bytes = 13
    start = (2+8) + length_x_in_bytes * my_index
    end = start + length_x_in_bytes
    result_point_x_bytes = payload_bytes[start:end]
    result_point_x = int.from_bytes(result_point_x_bytes, "big")
    #print(result_point_x)

    result_point_list = calc_points(result_point_x, p)

    factor_list_all = []
    for result_point in result_point_list:
        singular_point_x = singular_point[0]
        factor_list = solve_dlog(p, a, b, singular_point_x, base_point, result_point)
        factor_list_all.extend(factor_list)

    print(f"{factor_list_all=}")

    factor = min(factor_list_all)
    return factor

def find_b_candidats_for_all_mods(a, MODS):
    for p in MODS:
        b_candidat_list = find_b_candidats(p, a)
        verified_b_candidat_list = check_b_candidats(p, a, b_candidat_list)
        print(verified_b_candidat_list)

def set_base_point_and_get_payload_bytes(base_point, r):

    msg = r.recvuntil(b'> ')
    r.sendline(b"G")
    msg = r.recvline()
    r.recvuntil(b'> ')
    r.sendline(b"V")
    r.recvuntil(b'Payload: ')

    prefix = ""
    for i in range(2):
        prefix += int(base_point[i]).to_bytes(1, "big").hex()

    payload_to_change_base_point = prefix + msg.decode().replace("Payload:", "").strip()[4:]
    r.sendline(payload_to_change_base_point.encode())
    r.recvuntil(b'> ')
    r.sendline(b"G")
    payload = r.recvuntil(b'> ')
    payload_hex = payload.decode().replace("Payload: ", "").replace(">", "").strip()
    payload_bytes = bytes.fromhex(payload_hex)
    return payload_bytes

def find_singular_points_for_all_mods(MODS, a, b):
    for p in MODS:
        singular_point_list = find_singular_points(p, a, b)
        assert len(singular_point_list) == 1
        assert singular_point_list == [(1,0)] # for base_point = (2,2)

def get_flag(state, base_point):
    service = MyECCService()
    service.nonce_gen.state = state
    service.BASE_POINT = base_point
    payload = service.gen().hex().encode()

    r.sendline(b"P")
    r.recvuntil(b'Payload: ')
    r.sendline(payload)
    flag = r.recvall().decode()
    return flag


now = datetime.datetime.now()
print(now)

# copied
MODS = [
    942340315817634793955564145941,
    743407728032531787171577862237,
    738544131228408810877899501401,
    1259364878519558726929217176601,
    1008010020840510185943345843979,
    1091751292145929362278703826843,
    793740294757729426365912710779,
    1150777367270126864511515229247,
    763179896322263629934390422709,
    636578605918784948191113787037,
    1026431693628541431558922383259,
    1017462942498845298161486906117,
    734931478529974629373494426499,
    934230128883556339260430101091,
    960517171253207745834255748181,
    746815232752302425332893938923,
]

a = -3

#find_b_candidats_for_all_mods(a, MODS)
b = 2

#find_singular_points_for_all_mods(MODS, a, b)
singular_point = (1,0)

# choose a base_point
base_point = (2,2)
# base_point = (7, 18)
# base_point = (14, 52)

path = "challenge_server.py"
r = process(["python", path])
payload_bytes = set_base_point_and_get_payload_bytes(base_point, r)


state = b""
for my_index in range(len(MODS)):
    p = MODS[my_index]
    factor = calcFactor(payload_bytes, my_index, p, a, b, base_point, singular_point)
    state += int(factor).to_bytes(10, "big")

print(state.hex())

flag = get_flag(state, base_point)
print(flag)

now = datetime.datetime.now()
print(now)