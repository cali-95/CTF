import time
from sage.functions.log import logb

def newtonIteration(p, J, xIn):
    try:
        JInverse = (J(*xIn)).inverse()
    except ZeroDivisionError:
        print("ERROR: increase m and t")
        exit()
    return xIn - JInverse * p(*xIn)


# script for 3 blocks of unknown bits


# ----------- start input ------------------------------------------------------

# unknown values
p = None
q = None

y1 = None # root of f_bar
y2 = None
y3 = None

base = 2

case = 1
if case == 0:
    # example with known p and q

    # gen with random_prime(2^512-1, false, 2^511)
    p = 5877728072697145184672552644549481492604433873754883557527808272948974806670543640363401432326510709006645037104670155439980753752218655196090124533528227
    print("p:", p)

    # gen like p, but smaller
    q = 1409498275625141174506577354621087281343292552557940036720447019759466467960100402505524548311974751953824396895528612144818003862802558165337475292437161

    N = p*q

    # 20, works with m=4 and t=1, my LLL runtime 1s
    # 0,  works with m=6 and t=1, my LLL runtime 60s
    diff = 0

    m = 6
    t = 1

    startIndexOne = 20
    endIndexOne = 60 - diff
    startIndexTwo = 240
    endIndexTwo = 270 - diff
    startIndexThree = 350
    endIndexThree = 390 - diff

    factorOne = base^startIndexOne
    factorTwo = base^startIndexTwo
    factorThree = base^startIndexThree

    higherOne = p % (base^endIndexOne)
    y1 = higherOne // factorOne
    print("y1:", y1)


    higherTwo = p % (base^endIndexTwo)
    y2 = higherTwo // factorTwo
    print("y2:", y2)


    higherThree = p % (base^endIndexThree)
    y3 = higherThree // factorThree
    print("y3:", y3)

    p0 = p - factorOne * y1 - factorTwo * y2 - factorThree * y3

if case == 1:
    # picoCTF

    # practically
    # m=7 and t=1 are working, LLL runtime: 286s

    m = 7
    t = 1

    # from key_info
    N = int("c20d4f0792f162e3f3486f47c2c5b05696ba5c81ec09f5386bf741b7289b85e2d744559825a23b0ae094da214f3158344e5d5ba86fb1ecd1f40c8682a7bee55021eba772e23793001a38b9cccbfdc1d9316cccc3b79acd045c512b44e0f3697383958113a280791e17c23fe80fa38099e4907f70f4d228285aac69ed2d3bcf99", 16)


    # from key_info
    p0 = int("fe8984407b0816cc28e5ccc6bb73790000000000ca3806dd2cfdfc8d616b000000006109a4dbe3876b8d1b8adc9175dfba0e1ef318801648d60000000000a05b", 16)
    #print("p0 in base2:", "{0:b}".format(p0))

    # from p0 in Base2
    startIndexOne = 16
    endIndexOne = 57
    startIndexTwo = 239
    endIndexTwo = 272
    startIndexThree = 352
    endIndexThree = 392

    factorOne = base^startIndexOne
    factorTwo = base^startIndexTwo
    factorThree = base^startIndexThree


print("N:", N)
print("p0", p0)

print("m:", m, "  t:", t)

beta = logb(p0, 2) / logb(N, 2)
print("beta:", beta.n(50))
if beta < 0.5:
    print("WARN, swap p and q")


X1 = base^(endIndexOne-startIndexOne)
X2 = base^(endIndexTwo-startIndexTwo)
X3 = base^(endIndexThree-startIndexThree)

# ----------- end input ------------------------------------------------------
# ----------- start gen f ------------------------------------------------------
R = ZZ['x1,x2,x3']
x1 = R.0
x2 = R.1
x3 = R.2
countVariables = 3

# polynom with f_bar(y1,y2,y3) = p
f_bar = p0 + factorOne * x1 + factorTwo * x2 + factorThree * x3
print("f_bar:", f_bar)

# make polynom monic, which means one coefficient is 1
f = (inverse_mod(factorOne, N) * f_bar) % N
print("f:", f)

if p != None:
    print("f(r1Real, r2Real, r3Real) % p:", f(y1, y2, y3) % p) # must be 0

gBarList = []
for k in range(0,m+1): # 0...m
    for i in range(0,m+1):
        for j in range(0,m+1):
            if i+j <= m-k:
                fExpK = (f(x1, x2, x3))^k

                # gBar(y1,y2,y3) = 0 % N
                gBar = x2^i * x3^j * fExpK * N^max(t-k,0)
                gBarList.append(gBar)


gList = []
for gBar in gBarList:
    gList.append(gBar(x1*X1, x2*X2, x3*X3))
print("len(gList)", len(gList))

# ----------- end gen g's ------------------------------------------------------
# ----------- start gen A ------------------------------------------------------
monomialList = []
for g in gList:
    for monomial in g.monomials():
        if monomial not in monomialList:
            monomialList.append(monomial)
print("lenght of monomialList:", len(monomialList))

A = matrix(IntegerRing(), len(gList), len(monomialList))
print("A.ncols:", A.ncols(), " A.nrows:", A.nrows())

for index, g in enumerate(gList):
    A[index] = [g.monomial_coefficient(mon) for mon in monomialList]
# ----------- end gen A ------------------------------------------------------
# ----------- start gen B ------------------------------------------------------

myDelta = 0.99 # default 0.99
myEta = 0.501 # default 0.501
#print("myDelta:", myDelta, " myEta:", myEta)

print("start LLL", time.localtime())
startLLL = time.time()
B = A.LLL(delta=myDelta, eta=myEta)
endLLL = time.time()
print("LLL in seconds", endLLL - startLLL)

# ----------- end gen B ------------------------------------------------------
# ----------- start gen h's ------------------------------------------------------
weightList = [monomial(X1,X2,X3) for monomial in monomialList]

hList = []
for i in range(len(gList)):
    h = sum(R(b/w)*mon for b,mon,w in zip(B[i],monomialList,weightList))
    if not h.is_constant():
        hList.append(h)

if p != None:
    hListCheck = []
    hListCheck.extend(hList[0:10]) # ten h with the smallest norm
    hListCheck.extend(hList[-10:]) # ten h with the largest norm

    for h in hListCheck:
        hValue = h(y1, y2, y3)
        if hValue == 0:
            # that is the goal for first 3
            bits = "value is zero"
        else:
            bits = logb(hValue, 2).n(50)

        print("h at real zeros without mod in bits:", bits)
# ----------- end gen h's ------------------------------------------------------
# ----------- start solve zeros of h's ------------------------------------------------------
if len(hList) < countVariables:
    print("ERROR: need 3 polynoms, because 3 variables")
    exit()

# start newton
hListVector = vector(hList[0:3])
J = jacobian(hListVector, (x1,x2,x3))

# start values from paper
# because of 0.0001, the newtonIterations are over the real not over the integers, which is much faster
xStart = vector([X1 + 0.0001, X2, X3])

tol = 10.0^(-30)

zerosApprox = xStart
for i in range(1000): # pervent endless loop
    zerosApproxNew = newtonIteration(hListVector, J, zerosApprox)
    diff = abs(zerosApprox[0] - zerosApproxNew[0])
    if diff <= tol:
        print("rounds of newton:", i)
        break

    zerosApprox = zerosApproxNew

print(zerosApprox)
# ----------- end solve zeros of h's ------------------------------------------------------
# ----------- start check zeros of h's ------------------------------------------------------

# make zeros integers
zeros = ((zerosApprox[0] + 0.1).floor(), (zerosApprox[1] + 0.1).floor(), (zerosApprox[2] + 0.1).floor())
print(zeros)

candiateP = f_bar(zeros[0], zeros[1], zeros[2])

factor = None
if candiateP > 1 and candiateP < N:
    if N % candiateP == 0:
        factor = candiateP

print("factor:", factor)
if factor != None:
    print("---------- succes -----------")
else:
    print("fail")
