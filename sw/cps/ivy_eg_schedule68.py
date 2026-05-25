from schedule import ppl
import random
import numpy as np
import re
import numpy as np
import random
import re

class ieppl(ppl):
    def __init__(self, n, t):

        self.n = n
        self.t = t
        self.k = 1
        self.dt = np.dtype([('op', 'U10'), ('id', 'i4'), ('val', 'i4'), ('tid', 'i4')])
        self.array = np.zeros((t, n), dtype=self.dt)
        
        self.timer = []
        self.push_queue = []
        self.pop_queue = []
        

        self._generate_pushes()

    def _generate_pushes(self):

        raw = [f"push0,0"] + [f"push{random.randint(0, self.n-1)},{i}" for i in range(1, 1)]

        self.push_queue = sorted(raw, key=lambda x: self._parse_instr(x)[1], reverse=True)
        print(f"\n[k={self.k}] Pushes (Sorted by TID DESC): {self.push_queue}")

    def _generate_pops(self):

        raw = [f"pop0,0"] + [f"pop{random.randint(0, self.n-1)},{i}" for i in range(1, 1)]

        self.pop_queue = sorted(raw, key=lambda x: self._parse_instr(x)[1])
        print(f"[k={self.k}] Pops (Sorted by TID ASC): {self.pop_queue}")

    def _parse_instr(self, instr):

        nums = re.findall(r'\d+', instr)
        return int(nums[0]), int(nums[1])

    def ppl_add(self, t, p, op, id, val, tid):
        if t < self.t:
            self.array[t, p] = (op, id, val, tid)

    def process_step_eg(self, t):

        if self.k == 1:
            if self.push_queue:
                for instr in self.push_queue[:]:
                    p_id, p_tid = self._parse_instr(instr)
                    if self.array[t, p_id]['op'] == '':
                        self.ppl_add(t, p_id, 'push', p_id, random.randint(self.n-3,self.n+4), p_tid)
                        # self.ppl_add(t, p_id, 'push', p_id, self.n+4, p_tid)
                        self.push_queue.remove(instr)
                        print(f"[t={t}] k=1 Executed {instr}")
            

            if not self.push_queue:
                self.k += 1
                self._generate_pops()
                self._generate_pushes()
                return


        else:

            if self.pop_queue and len(self.timer) == 0:
                p_id, p_tid = self._parse_instr(self.pop_queue[0])
                if self.array[t, p_id]['op'] == '':
                    self.ppl_add(t, p_id, 'pop', p_id, random.randint(self.n-3,self.n+4), p_tid)
                    # self.ppl_add(t, p_id, 'pop', p_id, self.n+4, p_tid)
                    self.pop_queue.pop(0)
                    if self.pop_queue:
                        self.timer.append([t + 1, 0])
                    print(f"[t={t}] k={self.k} Pop Chain Started")


            for entry in self.timer[:]:
                target_t, idx = entry
                if t >= target_t:
                    if idx < len(self.pop_queue):
                        instr = self.pop_queue[idx]
                        p_id, p_tid = self._parse_instr(instr)
                        if self.array[t, p_id]['op'] == '':
                            self.ppl_add(t, p_id, 'pop', p_id, random.randint(self.n-3,self.n+4), p_tid)
                            # self.ppl_add(t, p_id, 'pop', p_id, self.n+4, p_tid)
                            print(f"[t={t}] k={self.k} Pop Chain Executed: {instr}")
                            self.pop_queue.pop(idx)
                            self.timer.remove(entry)
                            if idx < len(self.pop_queue):
                                self.timer.append([t + 1, idx])
                        else:
                            entry[0] += 1


            for instr in self.push_queue[:]:
                p_id, p_tid = self._parse_instr(instr)
                

                is_conflict = False
                if t > 0:
                    prev_cell = self.array[t-1, p_id]
                    if prev_cell['id'] == p_id and prev_cell['tid'] == p_tid and prev_cell['op'] == 'pop' and prev_cell['val'] > self.n-3:
                        is_conflict = True
                
                if not is_conflict and self.array[t, p_id]['op'] == '':
                    self.ppl_add(t, p_id, 'push', p_id, random.randint(self.n-3,self.n+4), p_tid)
                    # self.ppl_add(t, p_id, 'push', p_id, self.n + 4, p_tid)
                    self.push_queue.remove(instr)
                    print(f"[t={t}] k={self.k} Push Executed: {instr}")


            if not self.push_queue and not self.pop_queue and not self.timer:
                self.k += 1
                self._generate_pops()
                self._generate_pushes()
if __name__ == '__main__':
    model = ieppl(n=6, t=100000)
    model.process_step_eg(0)
    print(model.array[0])
    for t in range(99999):

        model.ppl_autoshift(t)
        model.process_step_eg(t+1)