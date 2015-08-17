.data #Data declaration section

# IO declarations
enterprimeseed: .asciiz "\nEnter a number to find primes nearby:"
primenumbers: .asciiz "\nMiller Rabin Output:"
publicexponent: .asciiz "\nPublic Exponent:"
privateexponent: .asciiz "\nPrivate Exponent:"
totient: .asciiz "\nTotient:"
modulus: .asciiz "\nModulus:"
enterpublicexponent: .asciiz "\nEnter Public Exponent:"
entermessage: .asciiz "\nEnter Message to encrypt:"
pprime: .asciiz "\nP:"
qprime: .asciiz "\nQ:"
fileDialog: .asciiz "\nEn- and Decrypt file text.txt (0) / Real-time encryption-decryption from console (1) :"
fileName: .asciiz "text.txt"
fileNameOutput: .asciiz "output.txt"
multiplicativeexception: .asciiz "\n Your input is no multiplicative inverse to your totient - Aborting"


#Buffer declarations
decryptedtextbuffer: .space 100
plaintextbuffer: .space 100
ciphertextbuffer: .word 100

.globl main #Make main function globally accessible


.text #Code section

main:

la $a0,enterprimeseed
li $v0,4
syscall #Ask user for a seed to generate the primes from

li $v0, 5
syscall
move $a0, $v0 #Receive seed from user input and provide it to the function generateprimes as an input

jal generateprimes

move $s0,$v0  #Store prime P -> $s0
move $s1, $v1 #Store prime Q -> $s1

la $a0,pprime
li $v0,4
syscall 
move $a0, $s0
li $v0, 1
syscall #Print generated P to the user

la $a0,qprime
li $v0,4
syscall
move $a0, $s1
li $v0, 1
syscall #Print generated Q to the user



mul $s2, $s0, $s1 #Calculate modulus N = p*q and store it in $s2


la $a0,modulus
li $v0,4
syscall 
move $a0, $s2
li $v0, 1
syscall #Print calculated modulus to the user


move $a0, $s0 #Provide P as an inpute for calculatetotient
move $a1, $s1 #Provide Q as an inpute for calculatetotient

jal calculatetotient #Call calculatetotient, which calculates totient from P and Q 

move $s3, $v0 #Store calculated totient in $s3

la $a0,totient
li $v0,4
syscall 
move $a0, $s3
li $v0, 1
syscall #Print calculated totient to the user


la $a0,enterpublicexponent
li $v0,4
syscall 
li $v0, 5		
syscall #Ask user for public exponent, which should be a coprime to the totient
move $s4, $v0 #Store public exponent in $s4 

move $a0, $s4 #Provide public exponent as input for calculateprivateexponent
move $a1, $s3 #Provide totient as input for calculateprivateexponent

jal calculateprivateexponent #Calculate private exponent from public exp. and totient

move $s5, $v0 #Store calculated private exponent in $s5


la $a0,publicexponent
li $v0,4
syscall 
move $a0, $s4
li $v0, 1
syscall #Print public exponent to the user




la $a0,privateexponent
li $v0,4
syscall 
move $a0, $s5
li $v0, 1
syscall #Print private exponent to the user 
getmessageinput:

la $a0,fileDialog
li $v0,4
syscall

li $v0, 5		
syscall #Ask user for input type -- File or text
move $s6, $v0 #Store input type 

beq $zero, $v0, fileinput
j getfromconsole


fileinput:

la $a1, plaintextbuffer

jal readfile
j deencrypt

getfromconsole:
la $a0,entermessage
li $v0,4
syscall  
li $v0, 8
la $a0, plaintextbuffer #Entered message should be stored on allocated plaintextbuffer
li $a1, 100 #Max length of input
syscall #Get message to be encrypted from the user

la $t0 ,plaintextbuffer #get first byte of input
lb $t1, ($t0) #Load first byte
li $t2, 10

beq $t2, $t1, endprogram #if first byte is empty, end program execution

deencrypt:

la $a0, plaintextbuffer  #Provide base adress of the plaintextbuffer as input
move $a1, $s4   #Provide public exponent as input
move $a2, $s2   #Provide modulus as input 
la $a3, ciphertextbuffer #Provide base adress of the ciphertextbuffer as input

jal encrypt #Encrypt plaintextbuffer content and store it in ciphertextbuffer
la $a1, ciphertextbuffer
jal writefile

la $a0, ciphertextbuffer  #Provide ciphertextbuffer containing encrypted message as input
move $a1, $s5   #Provide private exponent as input
move $a2, $s2   #Provide modulus N as input
la $a3, decryptedtextbuffer #Provide decryptedtextbuffer as input

jal decrypt #Decrypt content of ciphertextbuffer using private exponent and store decrypted
#message in decryptedtextbuffer

la $a0, decryptedtextbuffer
li $v0, 4
syscall #Print out decrypted message, which should be the same as message entered by the user

la $a0, plaintextbuffer
li $a1, 100 

jal clearstringbuffer #Clear plaintextbuffer


la $a0, decryptedtextbuffer
li $a1, 100 

jal clearstringbuffer #Clear decryptedtextbuffer

la $a0, ciphertextbuffer #Clear ciphertextbuffer
li $a1, 400
jal clearstringbuffer


j getmessageinput #Input was not empty, wait for next message


 
endprogram:

li $v0, 10
syscall #Terminate the program





clearstringbuffer: #Fills a area in memory with zeroes
#$a0 -> Base adress of memory area
#$a1 -> Size of memory area

move $t0, $a0 #buffer base address
move $t1, $a1 #buffer size

li $t2, 1 #Store constant 1 to calculate offset to iterate

clearstringbufferloop:
  beq $zero, $t1, endclearstringbuffer
  sb $zero, ($t0) #fill byte with 0

  add $t0, $t0, 1 #Increment offset
  add $t1, $t1, -1 #decrement buffer size 
  j clearstringbufferloop #Redo until string is completely encrypted

endclearstringbuffer:
jr $ra


generateprimes:
#Input:
#$a0 -> prime seed n
#Output:
#$v0 -> Prime number p near n
#$v1 -> Prime number q near n

#Save Registers
addi $sp, $sp, -20
sw $ra, 0($sp)
sw $s0, 4($sp)
sw $s1, 8($sp)
sw $s2, 12($sp)
sw $s3, 16($sp)

move $s0, $a0 #Store prime seed in persistent reg.
li $s1, 1 #Store constant 1 for comparison


findploop: #Loop tests prime seed for primality and increments until a prime is found, which will be p
  move $a0, $s0 #Provide prime seed n as an input to check for primality
  
  jal checkprime #Check primality of prime seed n

  beq $v0, $s1, setp #If checkprime returned 1, n is very likely a prime -> P will be set on n

  addi $s0, $s0,1 #If n is not a prime, it will be incremented by 1 and tested again   //Optimization: Increment by 2 and make sure n is odd in the beginning
  j findploop

setp: 
move $s2, $s0 #Store freshly found P in $s2
addi $s0, $s0,1 #Increment n by 1 so that P is not found again as Q

findqloop: #Loop tests prime seed for primality and increments until a prime is found, which will be q
  move $a0, $s0 #Provide prime seed as input
  jal checkprime #Check primality of prime seed n
  beq $v0, $s1, setq #If checkprime returned 1, n is very likely prime -> Q will be set on n
  addi $s0, $s0, 1 #Else, increment n and try again
  j findqloop

setq:
move $s3, $s0 #Store Q in $s3


move $v0, $s2 #Store P in output register
move $v1, $s3 #Store Q in output register   // Optimization: Store Q directly in output reg.

#Restore Registers
lw $s3 16($sp)
lw $s2 12($sp)
lw $s1 8($sp)
lw $s0 4($sp)
lw $ra 0($sp)
addi $sp,$sp,20
jr $ra


encrypt:
#$a0 -> base adress of plaintext
#$a1 -> public exponent p
#$a2 -> modulus n
#$a3 -> base adress of ciphertext


#Save Registers
addi $sp, $sp, -32
sw $ra, 0($sp)
sw $s0, 4($sp)
sw $s1, 8($sp)
sw $s2, 12($sp)
sw $s3, 16($sp)
sw $s4, 20($sp)
sw $s5, 24($sp)
sw $s6, 28($sp)

la $s0, ($a0) #base address of plaintext
move $s1, $a1 #public exponent
move $s2, $a2 #modulus n
la $s3, ($a3) #base address of ciphertext

li $s4, 1 #Store constant 1 to calculate offset to iterate on string 
li $s6, 4 #Store constant 4 to calculate offset to iterate on ciphertext

iteratestring:
  lb $s5, ($s0) #load current character in string
  beq $s5, $zero, encrypted #check if its null, then end of string is reached and everything is encrypted
  move $a0,$s5 #Provide char as input for modmult
  move $a1, $s1 #Provide public exponent as input for modmult
  move $a2, $s2 #provide Modulus N as input for modmult

  jal modmult #Calculate c^p mod N where c is the current char and p the public exponent
  #This returnes a number, which encrypts the char c 

  sw $v0, ($s3) #store the number which encrypts char c


  addu $s3, $s3, $s6 #increment address on ciphertext to the next word
  addu $s0, $s0, $s4 #increment string position by 1 to get the next character
  j iteratestring #Redo until string is completely encrypted


encrypted: #if string is encrypted -> end

#Restore Registers
lw $s6 28($sp)
lw $s5 24($sp)
lw $s4 20($sp)
lw $s3 16($sp)
lw $s2 12($sp)
lw $s1 8($sp)
lw $s0 4($sp)
lw $ra 0($sp)
addi $sp,$sp,32
jr $ra

decrypt:
#$a0 -> base adress of ciphertext
#$a1 -> public exponent p
#$a2 -> modulus n
#$a3 -> base adress of decryptedtext


#Save Registers
addi $sp, $sp, -32
sw $ra, 0($sp)
sw $s0, 4($sp)
sw $s1, 8($sp)
sw $s2, 12($sp)
sw $s3, 16($sp)
sw $s4, 20($sp)
sw $s5, 24($sp)
sw $s6, 28($sp)

la $s0, ($a0) #base address of cipher
move $s1, $a1 #private exponent
move $s2, $a2 #modulus N
la $s3, ($a3) #base address of plain

li $s4, 1 #Constant for offset to iterate over string 
li $s6, 4 #Constant for iterating over ciphertext

iterateciphertext:
  lw $s5, ($s0) #load current ciphertext
  beq $s5, $zero, decrypted #If ciphertext is 0 -> exit, everything is decrypted
  move $a0,$s5 #Provide current ciphertext number as input to modmult
  move $a1, $s1 #Provide private exponent
  move $a2, $s2 #Provide modulus N

  jal modmult #Decipher cipher text number to obtain a char back

  move $t0, $v0 #Store char temporarily //Optimization: store directly
  
  sb $t0, ($s3) #Store char in decryptedtextbuffer
  
  
  add $s3, $s3, $s4 #Increment address of decryptedtextbuffer to have empty space to insert next decryption
  add $s0, $s0, $s6 #Increment address of ciphertextbuffer to iterate further
  j iterateciphertext


decrypted: #Message is decrypted and located at decryptedtextbuffer

#Restore Registers
lw $s6 28($sp)
lw $s5 24($sp)
lw $s4 20($sp)
lw $s3 16($sp)
lw $s2 12($sp)
lw $s1 8($sp)
lw $s0 4($sp)
lw $ra 0($sp)
addi $sp,$sp,32
jr $ra



modmult: #calculates iteratively x^k mod n using expotentiation by sqaring
#the exponent k is decremented until its smaller or equal 1
# mod n is executed at each iteration in order to avoid register overflow

#$a0: x
#$a1: k
#$v0: n
#$v1: x^k mod n

addi $sp, $sp, -20
sw $ra, 0($sp)
sw $s0, 4($sp)
sw $s1, 8($sp)
sw $s2, 12($sp)
sw $s3, 16($sp)

move $s0, $a0 #x
move $s1, $a1 #k
move $s2, $a2 #n

li $s3, 1 #Result
li $t1, 2 #Constant needed for trial division
li $t2, 1 #Constant needed for trial division

modloop:
  div $t3,$s1,$t1 # k % 2
  mfhi $t3 #get remainder
  beq $t3, $t2, oddexponent # if k % 2 == 1
  j continuemodloop #If exponent is not odd, proceed regularly

  oddexponent: #special case for oddexponent
    mul $t4, $s3, $s0 # result * x
    div $t3, $t4, $s2 # result * x % n
    mfhi $t3 
    move $s3, $t3 # result = result * a % n
    j continuemodloop


   continuemodloop:
   div $s1, $s1, $t1 # k = k / 2
   
   
   beq $zero, $s1, endmodloop #if exponent k is 0, end loop
   mul $t3, $s0, $s0 # t3 -> result^2
   div $t3, $t3, $s2 # $t3 -> result / n
   mfhi $t3 #get result mod n
   move $s0, $t3 #x = result mod n

   j modloop

  endmodloop:
  move $v0, $s3 #Provide result as output

  lw $s3 16($sp)
  lw $s2 12($sp)
  lw $s1 8($sp)
  lw $s0 4($sp)
  lw $ra 0($sp)
  addi $sp,$sp,20
  jr $ra


calculatetotient:
  #$a0 -> p
  #$a1 -> q

  move $t0, $a0
  move $t1, $a1
  
  addi $t0, $t0, -1 #calculate p-1
  addi $t1, $t1, -1 #calculate q-1
  
  mul $v0, $t0, $t1 #calculate totient = (p-1) * (q-1)

  jr $ra

modinv:
  #Calculate the modular inverse of a and m
  #If the modular inverse doesnt exist -> terminate program with an
  #error message to the user
  
  #$a0 -> a
  #$a1 -> m
 
  #Save Registers
  addi $sp, $sp, -36
  sw $ra, 0($sp)
  sw $s0, 4($sp)
  sw $s1, 8($sp)
  sw $s2, 12($sp)
  sw $s3, 16($sp)
  sw $s4, 20($sp)
  sw $s5, 24($sp)
  sw $s6, 28($sp)
  sw $s7, 32($sp)

  move $s0, $a0 #a
  move $s1, $a1 #m
  
  move $a0, $s0 #Provide a as input for eea
  move $a1, $s1 #Provide m as input for eea
 
  jal extendedeuklid #calculate greatest common divisor and coefficient for the smaller integer
  
  move $s2, $v0 #g -> $s3 --> greatest common divisor
  move $s3, $v1 #x -> $s3 --> coefficient of the smaller integer

  li $s7, 1 #Load constant 1 for comparison  //Optimization: Better use of registers
  bne $s2, $s7, modinvexception #If g is not 1 -> Terminate and error message
  add  $s3, $s3, $s1 #Add m to x  in order to avoid the negative modulo fail
  div $s6, $s3, $s1 #
  mfhi $s6 #get remainder of x / m
  move $v0, $s6  #Provide x % m as output
  j modinvexit
  
  modinvexception:

  la $a0,multiplicativeexception
  li $v0,4
  syscall #Print error message to the user

  li $v0, 10 #Exit program
  syscall
   
  modinvexit:
  #Restore Registers
  lw $s7 32($sp)
  lw $s6 28($sp)
  lw $s5 24($sp)
  lw $s4 20($sp)
  lw $s3 16($sp)
  lw $s2 12($sp)
  lw $s1 8($sp)
  lw $s0 4($sp)
  lw $ra 0($sp)
  addi $sp,$sp,36
  jr $ra


extendedeuklid: #Mips implementation of the extended euclidean algorithm
#Calculates the greatest common divisor and the coefficient for the smaller integer
#for two numbers a and b

  #Save Registers
  addi $sp, $sp, -36
  sw $ra, 0($sp)
  sw $s0, 4($sp)
  sw $s1, 8($sp)
  sw $s2, 12($sp)
  sw $s3, 16($sp)
  sw $s4, 20($sp)
  sw $s5, 24($sp)
  sw $s6, 28($sp)
  sw $s7, 32($sp)

  #Initialize start values
  li $s0, 0 #x -> $s0
  li $s1, 1 #y -> $s1
  li $s2, 1 #u -> $s2
  li $s3, 0 #v -> $s3
  
  move $s4, $a0 #a -> $s4
  move $s5, $a1 #b -> $s5
  
euklidloop:
  beq $s4, $zero, eukliddone
  div $t0, $s5, $s4 # q = b / a
  mfhi $t1 # r = b % a
  move $t2, $s0  #x
  mul $t3, $s2, $t0 # u*q
  sub $t6, $t2, $t3 # m = x - u*q
  mul $t3, $s3, $t0 # v * q
  sub $t4, $s1, $t3 # n = y - v * q
  move $s5, $s4 # b = a
  move $s4, $t1 # a = r
  move $s0, $s2 # x = u
  move $s1, $s3 # y = v
  move $s2, $t6 # u = m
  move $s3, $t4 # v = n 
  j euklidloop


eukliddone:

  move $v0, $s5 # Provide gcd as output
  move $v1, $s0 # Provide x, smaller integer coefficient as output
  
  #Restore Registers
  lw $s7 32($sp)
  lw $s6 28($sp)
  lw $s5 24($sp)
  lw $s4 20($sp)
  lw $s3 16($sp)
  lw $s2 12($sp)
  lw $s1 8($sp)
  lw $s0 4($sp)
  lw $ra 0($sp)
  addi $sp,$sp,36
  jr $ra



calculateprivateexponent: #calculate privateexponent using publicexponent and the
#totient

  #Save Registers
  addi $sp, $sp, -36
  sw $ra, 0($sp)
  sw $s0, 4($sp)
  sw $s1, 8($sp)
  sw $s2, 12($sp)
  sw $s3, 16($sp)
  sw $s4, 20($sp)
  sw $s5, 24($sp)
  sw $s6, 28($sp)
  sw $s7, 32($sp)

  move $s0, $a0 #public exponent -> $s0
  move $s1, $a1 #totient -> $s1

  move $a0, $s0 #Provide Public exponent as input
  move $a1, $s1 #Provide Totient as input

  jal modinv #Calculate modular multiplicative inverse of the former

  move $s2, $v0 
  move $v0, $s2 #Provide mod.mult.inv. as output

  
  #Restore Registers
  lw $s7 32($sp)
  lw $s6 28($sp)
  lw $s5 24($sp)
  lw $s4 20($sp)
  lw $s3 16($sp)
  lw $s2 12($sp)
  lw $s1 8($sp)
  lw $s0 4($sp)
  lw $ra 0($sp)
  addi $sp,$sp,36
  jr $ra




checkprime:
  #$a0: N is a number > 2 and should be tested for it's primality
  #$v0: 1 -> N is probably a prime; 0 -> N is definitly composite
  
  #Checks if a specified number is a prime using 30 Miller-Rabin Tests which
  #The probability that a number is NOT a prime and recognized as such is 1/(1/4)^30 

  #Save Registers
  addi $sp, $sp, -36
  sw $ra, 0($sp)
  sw $s0, 4($sp)
  sw $s1, 8($sp)
  sw $s2, 12($sp)
  sw $s3, 16($sp)
  sw $s4, 20($sp)
  sw $s5, 24($sp)
  sw $s6, 28($sp)
  sw $s7, 32($sp)


  move $s0, $a0 #Load N -> $s0
  li $s1, 2 #Load 2 -> $s1

  div $t1, $s0,$s1#Test if N % 2 == 0
  mfhi $t1
  beq $t1, $zero, isnotprime# If N % 2 == 0 -> isnoprime -> exit

  li $s2, 0 #s = 0 -> $s2
  addi $s3, $s0, -1 #d = n-1 -> $s3
  li $s4, 1 #For comparison in loop

rewriteloop: #Rewrite n-1 as 2^s * d
  div $t1, $s3, $s1
  mfhi $t2
  beq $t2, $s4, rewritten
  add $s2, $s2, 1
  move $s3, $t1
  j rewriteloop

rewritten:

li $s5, 30 #Number of tests -> $5
testloop: #Repeat as long there are still test left

  addi $a1, $s0, -2 #put n-1 as upper bound for random number a
  li $v0, 42
  syscall #get rnd number in $a0
  move $a3, $a0
  addi $a3, $a3, 2 #add 2 to get rnd number between 2 - n -> A
                   #tested - random number gen works for each pass a new number
                   #is generated

  move $a0, $s3 # Provide D as input 
  move $a1, $s0 # Provide N as input
  move $a2, $s2 # Provide S as input


  jal trycomposite #Check if The number is a composite number ( not a prime )

  beq $v0, $s4, isnotprime #if the Composite test returns 1, then n is a composite -> exit


  addi $s5, $s5, -1 #Reduce number of tests by 1
  beq $zero, $s5, isprime #If there are no tests left and n was still not composite, its probably a prime
  j testloop



  isprime: #Return 1 as n is very likely a prime
  li $v0, 1
  j exit

  isnotprime: #Return 0 as n is definitly composite
  li $v0, 0
  j exit

  exit:

  #Restore Registers
  lw $s7 32($sp)
  lw $s6 28($sp)
  lw $s5 24($sp)
  lw $s4 20($sp)
  lw $s3 16($sp)
  lw $s2 12($sp)
  lw $s1 8($sp)
  lw $s0 4($sp)
  lw $ra 0($sp)
  addi $sp,$sp,36
  jr $ra



trycomposite:
#$a0 -> D
#$a1 -> N
#$a2 -> S
#$a3 -> A

addi $sp, $sp, -36
sw $ra, 0($sp)
sw $s0, 4($sp)
sw $s1, 8($sp)
sw $s2, 12($sp)
sw $s3, 16($sp)
sw $s4, 20($sp)
sw $s5, 24($sp)
sw $s6, 28($sp)
sw $s7, 32($sp)

move $s0, $a0 # D -> $s0
move $s1, $a1 # N -> $s1
move $s2, $a2 # S -> $s2
move $s3, $a3 # A -> $s3




move $a0, $s3 # modmult(a,d,n)
move $a1, $s0
move $a2, $s1

jal modmult #Calculate modmult(a,d,n)

li $s4, 1 #For comparison if modmult(a,d,n)  == 1
beq $v0, $s4, notdetermined # If small fermat applies -> Its not determined

move $s5, $s2 # Loop counter i; initialized with s
addi $s7, $s1, -1 #n - 1 -> $s7

trycompositeloop:

  li $a0, 2
  move $a1, $s5


  jal pow #calculate 2^i

  move $s6, $v0 #temporary 2^i -> $s6
  mul $s6,$s6, $s0 # $s6 contains 2^i * d

  move $a0, $s3 #provide a as input 
  move $a1, $s6 #provide 2^i * d as input
  move $a2, $s1 #provide n as input

  jal modmult #calculate modmult(2, 2^i*d,n)

  beq $v0,$s7, notdetermined #modmult(2,2^i*d,n) == n-1 -> Its not determined

  beq $zero, $s5, definitlycomposite #If no case applied -> n is definitly composite
  addi $s5, $s5, -1

  j trycompositeloop


definitlycomposite: #N is def. composite -> return 1
li $v0, 1     
j trycompositeexit

notdetermined: #N is not proved to be composite -> return 0
li $v0, 0
j trycompositeexit

trycompositeexit:
lw $s7 32($sp)
lw $s6 28($sp)
lw $s5 24($sp)
lw $s4 20($sp)
lw $s3 16($sp)
lw $s2 12($sp)
lw $s1 8($sp)
lw $s0 4($sp)
lw $ra 0($sp)
addi $sp,$sp,36
jr $ra



pow: #calculates x^k in the same fashion as modmult calculates
#x^k mod n; but without the mod n
#$a0: x
#$a1: k
#$v0: n

addi $sp, $sp, -20
sw $ra, 0($sp)
sw $s0, 4($sp)
sw $s1, 8($sp)
sw $s2, 12($sp)
sw $s3, 16($sp)

move $s0, $a0 #x
move $s1, $a1 #k

li $s3, 1 #result
  li $t1, 2 #needed for trial division
  li $t2, 1 #needed for trial division

  powloop:
    div $t3,$s1,$t1 # k % 2
    mfhi $t3 #get remainder
    beq $t3, $t2, powoddexponent # if k % 2 == 1
    j continuepowloop

  powoddexponent:
    mul $t4, $s3, $s0 # r*x
    move $s3, $t4 #result = r* a %n
    j continuepowloop


   continuepowloop:
   div $s1, $s1, $t1 # k = k / 2
   
   
   beq $zero, $s1, endpowloop
   mul $t3, $s0, $s0
   move $s0, $t3

   j powloop

  endpowloop:
  move $v0, $s3



  lw $s3 16($sp)
  lw $s2 12($sp)
  lw $s1 8($sp)
  lw $s0 4($sp)
  lw $ra 0($sp)
  addi $sp,$sp,20
  jr $ra





readfile: # Reads a files content into a buffer
#$a0: filename 
#$a1: buffer to read contents in

addi $sp, $sp, -20
sw $ra, 0($sp)
sw $s0, 4($sp)
sw $s1, 8($sp)
sw $s2, 12($sp)
sw $s3, 16($sp)

move $s1, $a1 #buffer adress

li $v0, 13 #open file
la $a0, fileName #board file name
li $a1, 0 #open file for reading
li $a2, 0 
syscall
move $s0, $v0 #save filedescriptor

li $v0, 14 #read frome file
move $a0, $s0 #file descriptor
move $a1, $s1 #load in buffer
li $a2, 100
syscall
 



lw $s3 16($sp)
lw $s2 12($sp)
lw $s1 8($sp)
lw $s0 4($sp)
lw $ra 0($sp)
addi $sp,$sp,20
jr $ra



writefile: # Writes buffer content into file
#$a0: filename
#$a1: buffer to read contents in

addi $sp, $sp, -20
sw $ra, 0($sp)
sw $s0, 4($sp)
sw $s1, 8($sp)
sw $s2, 12($sp)
sw $s3, 16($sp)

move $s1, $a1 #buffer adress

li $v0, 13 #open file
la $a0, fileNameOutput #board file name
li $a1, 1 #open file for writing
li $a2, 0 
syscall
move $s0, $v0 #save filedescriptor

li $v0, 15 #write to file
move $a0, $s0 #file descriptor
move $a1, $s1 #write this buffer
li $a2, 10
syscall
 



lw $s3 16($sp)
lw $s2 12($sp)
lw $s1 8($sp)
lw $s0 4($sp)
lw $ra 0($sp)
addi $sp,$sp,20
jr $ra


