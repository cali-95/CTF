import time

# inspired from https://github.com/Mr-Aur0ra/RSA/blob/master/03.Factoring%20with%20high%20bits%20known%20Attack

# runtime 70min

#p = 13322982649641977390224385483872045264359729282097657111441019208182037816814525855811983512980239406945576946513381098098911742672886155864760962773101117
#p = 12352299772928703855160238121887945161442393988013200834953509028897739288347195129742437008585322382253799054501001229179049324979062498801108786483612261
#print("p:", p)
#print("p in hex:", hex(p))


#q = 9201271076298374841274145334894685041798982869968486800185333976374004749486862685932740518504323289926265034878410290987559978594055615142042714457036511
#q = 8572189665114116831292477386284914354586513279461678758142425029838223516805430803354840413074124056252624728526168160216712735681147223766599998800817141
#print("q:", q)

#n = p*q
n = int("00b8cb1cca99b6ac41876c18845732a5cbfc875df346ee9002ce608508b5fcf6b60a5ac7722a2d64ef74e1443a338e70a73e63a303f3ac9adf198595699f6e9f30c009d219c7d98c4ec84203610834029c79567efc08f66b4bc3f564bfb571546a06b7e48fb35bb9ccea9a2cd44349f829242078dfa64d525927bfd55d099c024f", 16)
print("n:", n)
print("n in bits with log:", (log(n) / log(2)).n(50))
print("n in bits:", int(n).bit_length())


bitsUnkown = 256
bitsLLL = 246 # good compromise between rumtime and working with a lot of unknown bits
#pbar = p - p % 2^(bitsUnkown)
pbar = int("00e700568ff506bd5892af92592125e06cbe9bd45dfeafe931a333c13463023d4f0000000000000000000000000000000000000000000000000000000000000000", 16)
print("pBar in hex:", hex(pbar))

#bigBlock = (p % 2^bitsUnkown)
#igood = bigBlock - bigBlock % 2^bitsLLL
#igood = igood // 2^bitsLLL
#print("igood:", igood)

temp =  log(pbar) / log(n)
print("temp:", temp.n(50))

PR.<x> = PolynomialRing(Zmod(n))
start = 0
#start = 775 #shortcut

# brute force all bits between bitsUnkown and bitsLLL
for i in range(start, 2^(bitsUnkown-bitsLLL)):
    if i % 100 == 0:
        print("i:", i)
        print(time.gmtime())
    p0 = pbar + i * 2^(bitsLLL)
    print("p0 in hex:", hex(p0))
    f = x + p0

    #start = time.time()
    #print(time.gmtime())
    rootListTemp = f.small_roots(X=2^(bitsLLL), beta=0.4, epsilon=0.01)
    if len(rootListTemp) > 0:
        x0 = rootListTemp[0]
        print("x0:", x0)
        print("x0 in hex:", hex(x0))

        fcantidate = int(p0 + x0)
        print("fcantidate in hex", hex(fcantidate))
        mod = n % fcantidate

        if fcantidate > 1 and fcantidate < n and mod == 0:
            factor = fcantidate
            #d = time.time() - start
            #print("d in sec:", d)
            print("factor in hex", hex(factor))
            print("factor", factor)
            break
