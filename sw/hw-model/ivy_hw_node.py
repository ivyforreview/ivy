import math
import json
import os

INS_LIST=["pop_root","pop_leaf","push_root","push_leaf"]

class ivy_node:

    def __init__(self,parent):
        self.lvalue = math.inf
        self.rvalue = math.inf
        self.lchild = 0
        self.rchild = 0
        self.lchild_valid=False
        self.rchild_valid=False
        self.count = 0
        self.is_root = False
    
    def set_lvalue(self,value):
        self.lvalue = value
    def set_rvalue(self,value):
        self.rvalue = value
    
    def set_root(self,flag):
        self.is_root=flag
    
    def set_max(self,value):
        self.maxvalue=value
    def set_maxloc(self,flag):
        self.maxvalueloc=flag
    def get_min(self):
        if min(self.lvalue,self.rvalue) == self.lvalue:
            lflag=True
        else:
            lflag=False
        return min(self.lvalue,self.rvalue),lflag
    def set_lchild(self,child):
        self.lchild = child
    
    def set_rchild(self,child):
        self.rchild = child
    def set_lchild_valid(self,flag):
        self.lchild_valid=flag
    def set_rchild_valid(self,flag):
        self.rchild_valid=flag
    
    def set_count(self,count):
        self.count=count
    def inc_count(self):
        self.count+=1
    def dec_count(self):
        self.count-=1

class ivy_node_pool:

    def __init__(self,m,n):
        self.m=m
        self.n=n
        self.pool=[[ivy_node(None) for i in range(n)] for j in range(m)]

    def ivy_node_pool_dump(self,filename):

        json_data = []
        for i in range(self.m):
            for j in range(self.n):
                node = self.pool[i][j]
                if node.lvalue != math.inf or node.rvalue != math.inf: 
                    json_data.append({
                    "m": i,
                    "n": j,
                    "lvalue": node.lvalue,
                    "rvalue": node.rvalue,
                    "lchild": node.lchild,
                    "rchild": node.rchild,
                    "lchild_valid": node.lchild_valid,
                    "rchild_valid": node.rchild_valid,
                    "is_root": node.is_root,
                    "count": node.count
                    })
                elif node.lchild!=0 or node.rchild!=0:
                    json_data.append({
                    "m": i,
                    "n": j,
                    "lvalue": node.lvalue,
                    "rvalue": node.rvalue,
                    "lchild": node.lchild,
                    "rchild": node.rchild,
                    "lchild_valid": node.lchild_valid,
                    "rchild_valid": node.rchild_valid,
                    "is_root": node.is_root,
                    "count": node.count
                    })
        print(json_data)
        json.dump(json_data, open(filename, "w"),indent=4)
        print(f"{filename} dumped")
    def ivy_node_pool_load(self,filename):

        json_data = json.load(open(filename, "r"))
        for data in json_data:
            m = data["m"]
            n = data["n"]
            self.pool[m][n].set_lvalue(data["lvalue"])
            self.pool[m][n].set_rvalue(data["rvalue"])
            self.pool[m][n].set_lchild(data["lchild"])
            self.pool[m][n].set_rchild(data["rchild"])
            self.pool[m][n].set_lchild_valid(data["lchild_valid"])
            self.pool[m][n].set_rchild_valid(data["rchild_valid"])
            self.pool[m][n].set_root(data["is_root"])
            self.pool[m][n].count = data["count"]
        print(f"{filename} loaded")
    def ivy_node_read(self,m,n):

        return self.pool[m][n]
    def ivy_node_write(self,m,n,node):

        self.pool[m][n] = node
    
class basic_write:

    def __init__(self):
        self.ivy_node_pool = ivy_node_pool(4,9)
        ivy_node_0=self.ivy_node_pool.ivy_node_read(0,0)
        ivy_node_0.set_root(True)
        ivy_node_0.set_lvalue(10)
        ivy_node_0.set_rvalue(81)
        ivy_node_0.set_lchild(0)
        ivy_node_0.set_rchild(1)
        ivy_node_0.set_lchild_valid(True)
        ivy_node_0.set_rchild_valid(False)
        ivy_node_0.set_count(4)
        ivy_node_1=self.ivy_node_pool.ivy_node_read(1,0)
        ivy_node_1.set_root(False)
        ivy_node_1.set_lvalue(62)
        ivy_node_1.set_rvalue(57)
        ivy_node_1.set_lchild(0)
        ivy_node_1.set_rchild(1)
        ivy_node_1.count=0
        ivy_node_2=self.ivy_node_pool.ivy_node_read(2,0)
        ivy_node_2.set_root(False)
        ivy_node_2.set_lvalue(math.inf)
        ivy_node_2.set_rvalue(math.inf)
        ivy_node_2.set_lchild(0)
        ivy_node_2.set_rchild(1)
        print(self.ivy_node_pool.pool[1][0].lvalue,self.ivy_node_pool.pool[1][0].rvalue)
        self.ivy_node_pool.ivy_node_pool_dump("ivy_node_pool.json")
        print("basic_write done")
    
if __name__ == "__main__":

    bw_flag=True 
    
    if bw_flag:
        basic_write()

    my_ivy_node_pool = ivy_node_pool(4,9)
    my_ivy_node_pool.ivy_node_pool_load("ivy_node_pool.json")
    print(my_ivy_node_pool.pool[1][0].lvalue,my_ivy_node_pool.pool[1][0].rvalue)
    


    
