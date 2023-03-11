# Perfect Blue CTF 2023 (pbctf 2023) My-ECC-Service-2

Read the [writeup 1](https://github.com/AVDestroyer/CTF-Writeups/blob/main/pbctf/My-ECC-Service.md) and [writeup 2](https://github.com/t-firmware-section/pbctf2023_writeups/blob/main/my_ecc_service_1.sage) for My-ECC-Service first.


## Differences to My-ECC-Service-1

- State is 16 bytes long
- For each modulo a different nonce is used, no possibility to calculate with one nonce the other nonces without reversing sha256
- at least 15 of 16 nonces are required to create the next state


## Summery

Preparation
1. Find for each curve a list of possible b values, which makes the curve singular and save the common value, calc the singular point
2. Find a base_point with this b for all curves

Attack
3. Set this base_point in the remote MyECCService
4. Request the x values of the result points
5. Calculate y values for the result points
6. Calculate nonces (=factor)
7. Recreate the state of the server and set it on a local instance
8. Send the output of the local MyECCService.gen() to the server and get the flag


## Details

### Step 1

Criteria for a singular curve:
```
discriminant = -16*(4*a^3 + 27*b^2) mod p = 0
```
(taken from https://ecc.danil.co/tasks/singular/)

a is always -3 (see My-ECC-Service-1) and y^2 =  x^3 + a*x + b (mod p)

wanted: x,y,b such that discriminant = 0
for all p's the method `find_b_candidats` finds b = 2.
Remark: It is a solution over the integers, so it is also a solution mod a arbitrary number.

With the method `check_b_candidats` I check that sagemath says also that the curve is singular.

Calc the singular point, also.

### Step 2
The base_point must on y^2 = x^3 + a*x + b = x^3 -3*x + 2 mod p for all p's and 0 < x,y < 255 (for step 3).
I used (2,2) as one of multiple options see https://www.wolframalpha.com/input?i=solve+x%5E3+-3*x+%2B2+%3D+y%5E2+and+x+%3E+0+for+x+and+y+over+the+integers


### Step 3
Notice that the `verify` method of the MyECCService change the base_point. We will use that to set it to the base_point from step 2.
The key in the payload must be valid, so first request a valid payload with "G". Change the first two bytes of the payload to the base_point and send it. The response is false, but we don't care.

### Step 4
Request the x_values of result_point = nonce * ECPoint(self.BASE_POINT, mod) with "G".

### Step 5
Calculate the y values of all 16 result_points with mod_sqrt((result_point.x)^3 - 3*(result_point.x) + 2, p).

### Step 6
Now the core of the attack. Calculate the discrete logarithm in few secondes. This is only possible because the curve is singular. The background is provided in [3] and [4].

There are 3 sub steps:
- translate the curve and the points to a simpler curve
- translate points to numbers in the a+b*sqrt3 field
- solve the discrete logarithm in this field

### Step 7

Recreate the state of the server and set it on a local instance

### Step 8

Send the output of the local MyECCService.gen()  with "P" to the server and get the flag.

### Tools
- python 3.10.9
- sagemath 9.8
- pwn tools 4.9.0

### sources:
- [1](https://doc.sagemath.org/html/en/reference/arithmetic_curves/sage/schemes/elliptic_curves/constructor.html)
- [2](https://doc.sagemath.org/html/en/reference/finite_rings/sage/rings/finite_rings/integer_mod.html)
- [3](https://crypto.stackexchange.com/questions/61302/how-to-solve-this-ecdlp)
- [4](https://people.cs.nctu.edu.tw/~rjchen/ECC2012S/Elliptic%20Curves%20Number%20Theory%20And%20Cryptography%202n.pdf)


