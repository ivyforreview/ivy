import numpy as np
import random
import re
class ppl:
    def __init__(self, n,t):
        dt = np.dtype([('op', 'U5'), ('id', 'i4'), ('val', 'i4')])
        self.array = np.zeros((t,n), dtype=dt)
        self.n=n
        self.k = 1

        # self.instructions = self._get_reset_instructions()
        # self.instructions = self._get_reset_random_instructions()

        self.timer = []
        self._reset_round()
    def _get_reset_instructions(self):
        """重置 6 条指令"""
        return {
            'push0', 'push1', 'push2', 'push3'
            'pop0', 'pop1', 'pop2', 'pop3'
        }
    
    def _reset_round(self):
        """重置指令池并进行预排序"""
        raw_instrs = [
        'push0', f'push{random.randint(0, self.n-1)}', f'push{random.randint(0, self.n-1)}', f'push{random.randint(0, self.n-1)}',
        'pop0', f'pop{random.randint(0, self.n-1)}', f'pop{random.randint(0, self.n-1)}',f'pop{random.randint(0, self.n-1)}'
        ]
    

        def get_id(s):

            nums = re.findall(r'\d+', s)
            return int(nums[0]) if nums else 0


        self.push_queue = sorted(
            [i for i in raw_instrs if i.startswith('push')],
            key=get_id, reverse=True
        )
        

        self.pop_queue = sorted(
            [i for i in raw_instrs if i.startswith('pop')],
            key=get_id
        )
        
        print(f"\n>>> Round k={self.k} Start | Pushes: {self.push_queue} | Pops: {self.pop_queue}")
    def ppl_add(self, t, p, op,id,val):
        self.array[t][p] = (op,id,val)
    
    def process_step_ivy_max(self, t):

        if not self.push_queue and not self.pop_queue:
            self.k += 1
            self._reset_round()

        if self.push_queue:
            for instr in self.push_queue[:]:

                p_id = int(instr[4:])
                
                if self.array[t, p_id]['op'] == '':
                    self.ppl_add(t, p_id, 'push', p_id, random.randint(self.n - 2,self.n+1))
                    self.push_queue.remove(instr)
                    print(f"[t={t}] Executed {instr}")

        else:

            if self.pop_queue and len(self.timer) == 0:
                if self.array[t, 0]['op'] == '':
                    self.ppl_add(t, 0, 'pop', 0, random.randint(self.n - 2,self.n+1))
                    self.pop_queue.pop(0)

                    self.timer.append([t + 2, 0]) # 这里的 0 代表 pop_queue 剩余部分的第 0 个
                    print(f"[t={t}] Executed pop0, timer set for next pop at t+2")

            for entry in self.timer[:]:
                target_t, seq_idx = entry
                
                if t >= target_t:

                    if seq_idx < len(self.pop_queue):
                        instr = self.pop_queue[seq_idx]
                        p_id = int(instr[3:])
                        
                        if self.array[t, p_id]['op'] == '':
                            self.ppl_add(t, p_id, 'pop', p_id, random.randint(self.n - 2,self.n+1))
                            self.pop_queue.pop(seq_idx)
                            self.timer.remove(entry)
                            print(f"[t={t}] Timer Executed {instr}")
                            

                            if seq_idx < len(self.pop_queue):
                                self.timer.append([t + 2, seq_idx])
                        else:

                            entry[0] += 1 
                    else:

                        self.timer.remove(entry)
    def process_step(self, t):

        if not self.instructions:
            self.k += 1
            self.instructions = self._get_reset_instructions()
            # self.instructions = self._get_reset_random_instructions()
            print(f"--- Round Reset: k is now {self.k} ---")


        remaining_pushes = [i for i in self.instructions if i.startswith('push')]

        if remaining_pushes:

            for i in [3, 2, 1, 0]:
                instr_name = f'push{i}'
                if instr_name in self.instructions:

                    if self.array[t, i]['op'] == '':
                        self.ppl_add(t, i, 'push', i, self.n - 1)
                        self.instructions.remove(instr_name)
                        print(f"[t={t}] Executed {instr_name}")
        else:

            if 'pop0' in self.instructions:
                if self.array[t, 0]['op'] == '':
                    self.ppl_add(t, 0, 'pop', 0, self.n - 1)
                    self.instructions.remove('pop0')
                    self.timer.append([t + 2, 1])
                    print(f"[t={t}] Executed pop0, set timer for id:1 at t:{t+2}")

            for entry in self.timer[:]:
                timer_t, timer_id = entry
                if timer_t == t:
                    if timer_id == 1:
                        if 'pop1' in self.instructions and self.array[t, 1]['op'] == '':
                            self.ppl_add(t, 1, 'pop', 1, self.n - 1)
                            self.instructions.remove('pop1')
                            self.timer.append([t + 2, 2])
                            self.timer.remove(entry)
                            print(f"[t={t}] Timer: Executed pop1, set timer for id:2")
                        else:

                            entry[0] += 1
                    elif timer_id == 2:
                        print(self.instructions,self.array[t, 2])
                        if 'pop2' in self.instructions and self.array[t, 2]['op'] == '':
                            self.ppl_add(t, 2, 'pop', 2, self.n - 1)
                            self.instructions.remove('pop2')
                            self.timer.remove(entry)
                            print(f"[t={t}] Timer: Executed pop2")
                        else:

                            entry[0] += 1

    def ppl_autoshift(self,t):
        current_layer=self.array[t]
        mask = (current_layer['op'] != '') & (current_layer['val'] > 0)

        indices = np.where(mask)[0]

        if len(indices) > 0:
            new_indices = (indices + 1) % self.n

            self.array[t + 1, new_indices] = current_layer[indices]
            self.array['val'][t + 1, new_indices] -= 1
        
if __name__ == '__main__':
    model = ppl(n=11, t=100000)
    model.process_step_ivy_max(0)
    print(model.array[0])
    for t in range(99999):

        model.ppl_autoshift(t)
        model.process_step_ivy_max(t+1)


