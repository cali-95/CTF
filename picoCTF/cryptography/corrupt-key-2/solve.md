# picoCTF

## corrupt-key-2 write-up

### analyse key

```
openssl rsa -noout -text -in private.key > key_info
```

information over the private key:

- 2 primes (classic RSA)
- only N and p are not zero
- N is 1024 Bit and p 512 Bit long
- p has 3 blocks of 0 (=unknown bits)
- (512 - (41+33+40)) / 512 = 0.7773-fraction of bits of p are known

### search

google search yields [Solving Linear Equations Modulo Divisors:
On Factoring Given Any Bits](http://imperia.rz.rub.de:8032/imperia/md/content/may/paper/ac08_divisor.pdf)

### check abstract

we need a 0.694-fraction of bits of p to be known, we know more  
n (count of blocks) = 3, which is small enought for polynomial runtime

### read paper and implemention

implemention only for n=3 using python 3.10 and sagemath 9.5  
run programm with

```
sage three_unknown_parts.sage
```
and it yields p

### decrypt

normal RSA decryption of msg.enc
