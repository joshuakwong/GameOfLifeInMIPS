import sys
import subprocess
import random
import re
from os.path import isfile

lifec = """#include <stdio.h>
#include <stdlib.h>

#include "test_board.h"

int neighbours(int, int);
void copyBackAndShow();

int main(void)
{
    int maxiters;
    printf("# Iterations: ");
    scanf("%d", &maxiters);
    for (int n = 1; n <= maxiters; n++) {
      for (int i = 0; i < N; i++) {
         for (int j = 0; j < N; j++) {
            int nn = neighbours(i,j);
            if (board[i][j] == 1) {
               if (nn < 2)
                  newboard[i][j] = 0;
               else if (nn ==2 || nn == 3)
                  newboard[i][j] = 1;
               else
                  newboard[i][j] = 0;
            }
            else if (nn == 3)
               newboard[i][j] = 1;
            else
               newboard[i][j] = 0;
         }
      }
      printf("=== After iteration %d ===\\n", n);
      copyBackAndShow();
   }
   return 0;
}

int neighbours(int i, int j)
{
    int nn = 0;
   for (int x = -1; x <= 1; x++) {
      for (int y = -1; y <= 1; y++) {
         if (i+x < 0 || i+x > N-1) continue;
         if (j+y < 0 || j+y > N-1) continue;
         if (x == 0 && y == 0) continue;
         if (board[i+x][j+y] == 1) nn++;
        }
    }
   return nn;
}

void copyBackAndShow()
{
   for (int i = 0; i < N; i++) {
      for (int j = 0; j < N; j++) {
         board[i][j] = newboard[i][j];
         if (board[i][j] == 0)
            putchar('.');
         else
            putchar('#');
      }
      putchar('\\n');
   }
}
"""

# Generate and write a random board.
def generate_test(dim):
    cboard = bytearray()
    mboard = bytearray()

    curly_boye = '{'.encode('utf-8')
    comma = ', '.encode('utf-8')
    byte_byte = '.byte '.encode('utf-8')
    curly_boye_2 = '}'.encode('utf-8')
    eol = '\n'.encode('utf-8')
    end_curly_boye = '};'.encode('utf-8')

    cboard.extend(curly_boye)
    for i in range(0, dim):
        cboard.extend(curly_boye)
        mboard.extend(byte_byte)
        for j in range(0, dim):
            n = random.randint(0, 1)
            cboard.extend(str(n).encode('utf-8'))
            mboard.extend(str(n).encode('utf-8'))
            if j != dim - 1:
                cboard.extend(comma)
                mboard.extend(comma)
        cboard.extend(curly_boye_2)
        cboard.extend(comma)
        mboard.extend(eol)
    cboard.extend(end_curly_boye)

    with open("test_board.h", 'w') as bfile:
        bfile.write("#define NN " + str(dim) + "\n")
        bfile.write("int N = NN;")
        bfile.write("char board[NN][NN] = ")
        bfile.write(cboard.decode('utf-8'))
        bfile.write("char newboard[NN][NN];")
        bfile.close()

    with open("test_life.s", 'w') as bfile:
        bfile.write(".data\n")
        bfile.write("N: .word " + str(dim) + "\n")
        bfile.write("board:\n")
        bfile.write(mboard.decode('utf-8'))
        bfile.write("newBoard: .space " + str(dim*dim))
        with open("prog.s", 'r') as pfile:
            asm_prog = pfile.read()
            bfile.write(asm_prog)
            pfile.close()
        bfile.close()

def compile():
    subprocess.run(["gcc", "-std=c99", "-o", "test_life", "test_life.c"])

def clean():
    subprocess.run(["rm", "test_life"])
    subprocess.run(["rm", "test_life.c"])
    subprocess.run(["rm", "test_life.s"])
    subprocess.run(["rm", "test_board.h"])

def run_tests(iters):
    encoded_in = str(iters).encode('utf-8')
    expected = subprocess.run(["./test_life"], stdout=subprocess.PIPE, input=encoded_in).stdout.decode('utf-8')
    received = subprocess.run(["spim", "-file", "test_life.s"], stdout=subprocess.PIPE, input=encoded_in).stdout.decode('utf-8')

    received = re.sub(r'^.*exceptions\.s.', '', received, flags=re.S)

    if expected != received:
        with open('out_exp.txt', 'w') as efile:
            efile.write(expected)
            efile.close()
        with open('out.txt', 'w') as ofile:
            ofile.write(received)
            ofile.close()
            return False
    return True

def main():
    usage = "Usage: python3 check_life.py num_tests [seed]"
    num_args = len(sys.argv)
    if not (2 <=num_args <= 3):
        print(usage)
        sys.exit()
    try:
        n_tests = int(sys.argv[1])
    except ValueError:
        if (sys.argv[1] == "clean"):
            clean()
        else:
            print(usage)
        sys.exit()

    if num_args == 3:
        try:
            random.seed(int(sys.argv[1]))
        except ValueError:
            print(usage)
            sys.exit()

    if not isfile('prog.s'):
        print("prog.s doesn't appear to be in the working directory.")
        sys.exit()

    with open("test_life.c", 'w') as tfile:
        tfile.write(lifec)
        tfile.close()

    for i in range(1, n_tests+1):
        dim = random.randint(2, 50)
        print ("Generating a " + str(dim) + "*" + str(dim) + " board...")
        generate_test(dim)
        compile()
        iters = random.randint(2, 100)
        print ("Running " + str(iters) + " iterations...")
        res = run_tests(iters)
        if not res:
            print("Test " + str(i) + " failed. Check output at out_exp.txt and out.txt")
            sys.exit()
        else:
            print("Test " + str(i) + " passed.")

    clean()

if __name__ == "__main__":
    main()
