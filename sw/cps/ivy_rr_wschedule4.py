from schedule import ppl
import random
import numpy as np
import re
import numpy as np
import random
import re

class ieppl(ppl):
    def __init__(self, n, t,layer):

        self.n = n
        self.t = t
        self.layer = layer
        self.k = 1
        self.dt = np.dtype([('op', 'U10'), ('id', 'i4'), ('val', 'i4'), ('tid', 'i4')])
        self.array = np.zeros((t, n), dtype=self.dt)
        self.root_num = 1
        self.buf_num = 4
        self.timer = []
        self.push_queue = []
        self.push_queues = [[] for _ in range(n)]
        self.pop_queues = [[] for _ in range(n)]
        self.rr_flag = [0] * n
        self.pfirst_flag = [0] * n
        self.pop_queue = []
        self.sum=0

        self._generate_pushes()

    def _generate_pushes(self):

        raw = [f"push0,0"] + [f"push{random.randint(0, self.n-1)},{i}" for i in range(1, self.layer)]

        self.push_queue = sorted(raw, key=lambda x: self._parse_instr(x)[1], reverse=True)
        # print(self.push_queue)
        for i in self.push_queue:
            num=self._parse_instr(i)[0]
            # print(num)
            self.push_queues[num].append(i)
        print(f"\n[k={self.k}] Pushes (Sorted by TID DESC): {self.push_queue}")
        self.root_num += 1


    def _generate_pops(self,l):
        # raw = [f"pop0,0"] + [f"pop{random.randint(0, self.n-1)},{i}" for i in range(1, 2)]
        # self.pop_queue.append(f"pop{random.randint(0, self.n-1)},{i}" for i in range(0, 2))
        if l==0:
            self.pop_queue=["pop0,0"]
        else:
            self.pop_queue=[f"pop{random.randint(0, self.n-1)},{l}"]
        print(f"\n[k={self.k}] Pops (Sorted by TID ASC): {self.pop_queue}")
        for i in self.pop_queue:
            num=self._parse_instr(i)[0]
            self.pop_queues[num].append(i)
        
    def _parse_instr(self, instr):

        nums = re.findall(r'\d+', instr)
        return int(nums[0]), int(nums[1])

    def ppl_add(self, t, p, op, id, val, tid):
        # if t < self.t:
        self.array[t, p] = (op, id, val, tid)

    def process_step_eg(self, t):
        ##Push: root_num<=buf_num, then a push is generated;
        ##Pop: root_num>0, then a pop is generated;
        # print("t",t)
        if self.root_num <= self.buf_num:
            self._generate_pushes()
        if self.root_num > 0:
            self._generate_pops(0)
        # for i in range(0,self.n):
            # print(self.array[t, i])
        for i in range(0, self.n):
            if self.array[t, i]['op']=='pop' and self.pfirst_flag[i]:
                if self.array[t,i]['tid']<self.layer-1:
                    self._generate_pops(self.array[t,i]['tid']+1)
                else:
                    self.root_num -= 1
                    self.k+=1
            if self.array[t, i]['op']=='push' and self.pfirst_flag[i]:
                if self.array[t,i]['tid']==0:
                    self.root_num += 1
                
        for i in range(0, self.n):
            if i==0:
                new_ins=self.array[t, self.n-1]
            else:
                new_ins=self.array[t,i-1]
            poe=len(self.pop_queues[i])
            pue=len(self.push_queues[i])
            por=199 if poe==0 else self._parse_instr(self.pop_queues[i][0])[1]
            pur=199 if pue==0 else self._parse_instr(self.push_queues[i][0])[1]
            if new_ins['val']>0:
                # old_ins=self.array[t, i]
                self.ppl_add(t+1,i,new_ins['op'],new_ins['id'],new_ins['val']-1,new_ins['tid'])
                # new_ins=old_ins
                self.pfirst_flag[i]=0
            elif self.array[t,i]['op']=='pop' and ((por==self.array[t,i]['tid']) and pur==self.array[t,i]['tid']):
                self.sum+=1
                self.pfirst_flag[i]=0
                self.ppl_add(t+1,i,'Nop',0,0,0)
            else:
                rs=False
                if poe==0 and pue==0:
                    self.ppl_add(t+1,i,'Nop',0,0,0)
                elif poe==0:
                    self.ppl_add(t+1,i,'push',self._parse_instr(self.push_queues[i][0])[0],self.n+2,self._parse_instr(self.push_queues[i][0])[1])
                    self.push_queues[i].pop(0)
                    self.rr_flag[i]=True
                    self.pfirst_flag[i]=1
                elif pue==0:
                    self.ppl_add(t+1,i,'pop',self._parse_instr(self.pop_queues[i][0])[0],self.n+2,self._parse_instr(self.pop_queues[i][0])[1])
                    self.pop_queues[i].pop(0)
                    self.rr_flag[i]=False
                    self.pfirst_flag[i]=1
                elif self.rr_flag[i]==False:
                    self.ppl_add(t+1,i,'push',self._parse_instr(self.push_queues[i][0])[0],self.n+2,self._parse_instr(self.push_queues[i][0])[1])
                    self.push_queues[i].pop(0)
                    self.rr_flag[i]=True
                    self.pfirst_flag[i]=1
                else:
                    self.ppl_add(t+1,i,'pop',self._parse_instr(self.pop_queues[i][0])[0],self.n+2,self._parse_instr(self.pop_queues[i][0])[1])
                    self.pop_queues[i].pop(0)
                    self.rr_flag[i]=False
                    self.pfirst_flag[i]=1
                

                    

if __name__ == '__main__':
    model = ieppl(n=6, t=50000, layer=6)
    # model.process_step_eg(0)
    # print(model.array[0])
    for t in range(0,49999):
        # model.ppl_autoshift(t)
        model.process_step_eg(t)
        print(model.k)
    print(model.sum)