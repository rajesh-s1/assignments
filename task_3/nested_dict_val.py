d={'a':{'b':{'c':'d'}}}

keyss=[]
valuess=[]
s=""
while True:
    for k,v in d.items():
        #print(k, type(k))
        keyss.append(k)
        valuess.append(v)
        #print(v, type(v))
        if type(v) is dict:
            d=v
            #print(d)
        elif type(v) is str:
            #print(v)
            s=s+v
            #print(s)
            break
    if len(s) != 0:
        break


print("Final value is: ", s)
print("All the available keys: ",keyss)
print("keys: ", "/".join(keyss))
print("All the available values: ", valuess)


#OUTPUT
#"C:\Users\Rajesh S\Downloads\python-prac\venv\Scripts\python.exe" "C:\Users\Rajesh S\Downloads\python-prac\test.py" 
#Final value is:  c
#All the available keys:  ['a', 'b', 'b1']
#All the available values:  [{'b': {'b1': 'c'}}, {'b1': 'c'}, 'c']

#Process finished with exit code 0






d={'x':{'y':{'z':'a'}}}

keyss=[]
valuess=[]
s=""
while True:
    for k,v in d.items():
        #print(k, type(k))
        keyss.append(k)
        valuess.append(v)
        #print(v, type(v))
        if type(v) is dict:
            d=v
            #print(d)
        elif type(v) is str:
            #print(v)
            s=s+v
            #print(s)
            break
    if len(s) != 0:
        break


print("Final value is: ", s)
print("All the available keys: ",keyss)
print("keys: ", "/".join(keyss))
print("All the available values: ", valuess)


#"C:\Users\Rajesh S\Downloads\python-prac\venv\Scripts\python.exe" "C:\Users\Rajesh S\Downloads\python-prac\test.py" 
#Final value is:  a
#All the available keys:  ['x', 'y', 'z']
#keys:  x/y/z
#All the available values:  [{'y': {'z': 'a'}}, {'z': 'a'}, 'a']