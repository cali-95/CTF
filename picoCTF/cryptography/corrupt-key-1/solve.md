# picoCTF

## corrupt-key-1 write-up

### analyse key

```
openssl rsa -noout -text -in private.key > key_info
```

information over the private key:

- 2 primes (classic RSA)
- only N and p are not zero
- N is 1024 Bit and p 512 Bit long
- only the 256 MSB of p are known

### search

search "factoring with MSB" yields https://github.com/Mr-Aur0ra/RSA/blob/master/03.Factoring%20with%20high%20bits%20known%20Attack

but it does not work with 256 unknown bits. Solution is bruteforce 10 bits

### implemention

using python 3.10 and sagemath 9.5

run with

```
sage solve_loop.sage
```

and it yields p

### decrypt

normal RSA decryption of msg.enc
