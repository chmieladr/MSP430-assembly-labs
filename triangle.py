from sys import stderr

periods = 2
quants = 75
step = 80
k = 0

for i in range(periods):
    for j in range(quants):
        if j > quants / 2:
            print(80 * (quants - j), end=', ')
        else:
            print(80 * j, end=', ')
        k += 1

print(f"Generated {k} quants of triangle form", file=stderr)