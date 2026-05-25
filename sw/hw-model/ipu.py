import math
import os
from ivy_hw_node import ivy_node_pool,ivy_node

# Worklog
# Problem: PUSH-POP



INS_LIST=['NOP','POP_ROOT','POP_LEAF','PUSH_ROOT','PUSH_LEAF']
# NOP = no operation
# POP_ROOT = pop from root node, Rs: node addr, Rd: Out addr (POP Rs to Rd)
# POP_LEAF = pop from leaf node, Rs: node addr, Rd: Out addr (POP Rs to Rd) Note Here both are index
# PUSH_ROOT = push to root node, Rs: In addr, Rd: node addr (PUSH Rs to Rd) 
# PUSH_LEAF = push to leaf node, Rs: In addr, Rd: node addr (PUSH Rs to Rd) Note Here Rs is the value to be pushed


class inter_ipu_bus:
    def __init__(self,a,b):
        self.src=a
        self.dst=b
        self.ins='NOP'
        self.rs=0
        self.rd=0

class forward_bus:
    def __init__(self,a,b):
        self.src=a
        self.dst=b
        self.ins='NOP'
        self.r=0
        self.val=0
        self.clear=False
        
class ipu:
    def __init__(self,id,ivy_pool:ivy_node_pool):
        # Ivy Processing Unit
        # four stages: read, compare, prepare, write like ClubHeap
        # forwarding: intra ipu, inter ipu, need verified
        self.block=False
        self.id=id
        self.in_bus=None
        self.last_bus=None
        self.next_bus=None
        self.forward_to_bus=None
        self.bus_to_forward=None
        
        # TODO length will be set by input,just propose a default
        self.length=8

        self.rc_bus=['NOP',0,0,None] # ins, rs, rd, node
        self.cp_bus=['NOP',0,0,None,0,0,0,0] # ins, rs, rd, node, cmp_result, flag, sub_val/count, valid_signal
        self.pw_bus=['NOP',0,0,None,0,0,0,0,0] # ins, rs, rd, node, cmp_result, flag, sub_val/count, valid_signal, forward_val
        self.write_bus=[-1, -1, math.inf, math.inf, 0, -1, -1,0,0] # valid, addr, lval, rval, count, lchild, rchild, lcvalid, rcvalid
        self.ivy_row=ivy_pool.pool[id]
        

        # Compare stage: register to store last cp bus
        self.reg_cp=['NOP',0,0,None,0,0,0] # ins, rs, rd, node, cmp_result, flag, sub_val/count

    def bind_bus(self,in_bus:inter_ipu_bus,last_bus:inter_ipu_bus,next_bus:inter_ipu_bus,forward_to_bus:forward_bus,bus_to_forward:forward_bus):
        self.in_bus=in_bus
        self.last_bus=last_bus
        self.next_bus=next_bus
        self.forward_to_bus=forward_to_bus
        self.bus_to_forward=bus_to_forward

    def read_stage(self):
        self.rc_bus=['NOP',0,0,None] # ins, rs, rd, node
        if self.in_bus.ins=='NOP':
            self.rc_bus=['NOP',0,0,None]
        else:
            if self.last_bus.ins!='NOP':
                if self.last_bus.ins=='POP_ROOT' or self.last_bus.ins=='POP_LEAF':
                    self.rc_bus[0]=self.last_bus.ins
                    self.rc_bus[1]=self.last_bus.rs
                    self.rc_bus[2]=self.last_bus.rd
                    self.rc_bus[3]=self.ivy_row[self.last_bus.rs]
                elif self.last_bus.ins=='PUSH_ROOT' or self.last_bus.ins=='PUSH_LEAF':
                    self.rc_bus[0]=self.last_bus.ins
                    self.rc_bus[1]=self.last_bus.rs
                    self.rc_bus[2]=self.last_bus.rd
                    self.rc_bus[3]=self.ivy_row[self.last_bus.rd]
                else:
                    print("not supported ins")
            else:
                if self.in_bus.ins=='POP_ROOT' or self.in_bus.ins=='POP_LEAF':
                    self.rc_bus[0]=self.in_bus.ins
                    self.rc_bus[1]=self.in_bus.rs
                    self.rc_bus[2]=self.in_bus.rd
                    self.rc_bus[3]=self.ivy_row[self.in_bus.rs]
                elif self.in_bus.ins=='PUSH_ROOT' or self.in_bus.ins=='PUSH_LEAF':
                    self.rc_bus[0]=self.in_bus.ins
                    self.rc_bus[1]=self.in_bus.rs
                    self.rc_bus[2]=self.in_bus.rd
                    self.rc_bus[3]=self.ivy_row[self.in_bus.rd]
                else:
                    print("not supported ins")
        print(f"ipu{self.id} read stage: {self.rc_bus}")
    def compare_stage(self):
        
        self.cp_bus=['NOP',0,0,None,0,0,0,0]
        self.next_bus.ins='NOP'
        self.next_bus.rs=0
        self.next_bus.rd=0
        self.bus_to_forward.ins='NOP'
        self.bus_to_forward.r=0
        self.bus_to_forward.val=0
        self.bus_to_forward.clear=False
        
        if self.rc_bus[0]=='NOP':
            self.cp_bus=['NOP',0,0,None,0,0,0,0]
        elif self.rc_bus[0]=='POP_ROOT':

            temp_fwd_node=ivy_node(None)
            # POP_ROOT can only corrupt with PUSH_ROOT
            if self.pw_bus[0]=='PUSH_ROOT':
                #if PUSH_ROOT addr is the same, we need to change the compare object
                #in hw, this will be replaced as two muxes of compare.
                if self.pw_bus[2]==self.rc_bus[1]: #push rd=pop rs
                    # self.write_bus[0]=1
                    # self.write_bus[1]=self.pw_bus[2] # addr
                    temp_fwd_node.lvalue=self.pw_bus[4] if self.pw_bus[5]==1 else self.rc_bus[3].lvalue # lval
                    temp_fwd_node.rvalue=self.pw_bus[4] if self.pw_bus[5]==0 else self.rc_bus[3].rvalue # rval
                    temp_fwd_node.count=self.pw_bus[6] # count
                    temp_fwd_node.lchild=self.rc_bus[3].lchild
                    temp_fwd_node.rchild=self.rc_bus[3].rchild

                    temp_fwd_node.lchild_valid=self.pw_bus[7] if self.pw_bus[5]==1 else self.rc_bus[3].lchild_valid
                    temp_fwd_node.rchild_valid=self.pw_bus[7] if self.pw_bus[5]==0 else self.rc_bus[3].rchild_valid
                    self.rc_bus[3]=temp_fwd_node
            cmp_result,flag=self.rc_bus[3].get_min()
            sub_val=self.rc_bus[3].count-1
            if flag==1:
                ni=self.rc_bus[3].lchild
                nf=self.rc_bus[3].lchild_valid
            else:
                ni=self.rc_bus[3].rchild
                nf=self.rc_bus[3].rchild_valid
            
            self.cp_bus[0]='POP_ROOT'
            self.cp_bus[1]=self.rc_bus[1]
            self.cp_bus[2]=self.rc_bus[2]
            self.cp_bus[3]=self.rc_bus[3]
            self.cp_bus[4]=cmp_result
            self.cp_bus[5]=flag
            self.cp_bus[6]=sub_val
            self.cp_bus[7]=nf

            if nf==0:
                self.next_bus.ins='NOP'
                self.next_bus.rs=0
                self.next_bus.rd=0
            else:
                self.next_bus.ins='POP_ROOT' if flag==0 else 'POP_LEAF'
                self.next_bus.rs=ni
                self.next_bus.rd=self.cp_bus[1] # pop to this source

            self.bus_to_forward.ins='POP_ROOT'
            self.bus_to_forward.r=self.rc_bus[2] # the pop rd is which need to be forwarded
            self.bus_to_forward.val=cmp_result
            if self.rc_bus[3].lchild_valid==0 and self.rc_bus[3].rchild_valid==0 and (self.rc_bus[3].lvalue==math.inf or self.rc_bus[3].rvalue==math.inf):
                print(f"ipu{self.id} detect dead node at {self.rc_bus[1]}")
                self.bus_to_forward.clear=1 

        elif self.rc_bus[0]=='POP_LEAF':
            temp_fwd_node=ivy_node(None)
            # POP_ROOT can only corrupt with PUSH_ROOT
            if self.pw_bus[0]=='PUSH_LEAF':
                #if PUSH_ROOT addr is the same, we need to change the compare object
                #in hw, this will be replaced as two muxes of compare.
                if self.pw_bus[2]==self.rc_bus[1]: #push rd=pop rs
                    # self.write_bus[0]=1
                    # self.write_bus[1]=self.pw_bus[2] # addr
                    temp_fwd_node.lvalue=self.pw_bus[4] if self.pw_bus[5]==1 else self.rc_bus[3].lvalue # lval
                    temp_fwd_node.rvalue=self.pw_bus[4] if self.pw_bus[5]==0 else self.rc_bus[3].rvalue # rval
                    temp_fwd_node.count=self.pw_bus[6] # count
                    temp_fwd_node.lchild=self.rc_bus[3].lchild
                    temp_fwd_node.rchild=self.rc_bus[3].rchild

                    temp_fwd_node.lchild_valid=self.pw_bus[7] if self.pw_bus[5]==1 else self.rc_bus[3].lchild_valid
                    temp_fwd_node.rchild_valid=self.pw_bus[7] if self.pw_bus[5]==0 else self.rc_bus[3].rchild_valid
                    self.rc_bus[3]=temp_fwd_node
            cmp_result,flag=self.rc_bus[3].get_min()
            count=self.rc_bus[3].count-1 if flag==1 else self.rc_bus[3].count+1
            if flag==1:
                ni=self.rc_bus[3].lchild
                nf=self.rc_bus[3].lchild_valid
            else:
                ni=self.rc_bus[3].rchild
                nf=self.rc_bus[3].rchild_valid
            
            self.cp_bus[0]='POP_LEAF'
            self.cp_bus[1]=self.rc_bus[1]
            self.cp_bus[2]=self.rc_bus[2]
            self.cp_bus[3]=self.rc_bus[3]
            self.cp_bus[4]=cmp_result
            self.cp_bus[5]=flag
            self.cp_bus[6]=count
            self.cp_bus[7]=nf
            if nf==0: 
                self.next_bus.ins='NOP'
                self.next_bus.rs=0
                self.next_bus.rd=0
            else:
                self.next_bus.ins='POP_LEAF'
                self.next_bus.rs=ni
                self.next_bus.rd=self.cp_bus[1] # pop to this source

            self.bus_to_forward.ins='POP_LEAF'
            self.bus_to_forward.r=self.rc_bus[2] # the pop rd is which need to be forwarded
            self.bus_to_forward.val=cmp_result
            if self.rc_bus[3].lchild_valid==0 and self.rc_bus[3].rchild_valid==0 and (self.rc_bus[3].lvalue==math.inf or self.rc_bus[3].rvalue==math.inf):
                print(f"ipu{self.id} detect dead node at {self.rc_bus[1]}")
                self.bus_to_forward.clear=1
        elif self.rc_bus[0]=='PUSH_ROOT':
            if self.rc_bus[3].count==self.length: # full
                # All Are right
                self.cp_bus[0]='PUSH_ROOT'
                self.cp_bus[1]=self.rc_bus[1]
                self.cp_bus[2]=self.rc_bus[2]
                self.cp_bus[3]=self.rc_bus[3]
                self.cp_bus[7]=1 #in every case the child will be valid.
                self.next_bus.ins='PUSH_ROOT'
                self.next_bus.rd=self.rc_bus[3].rchild
                self.bus_to_forward.ins='PUSH_ROOT'
                self.bus_to_forward.r=self.rc_bus[2] # the push rd is which need to be forwarded
                if self.rc_bus[1]>=self.rc_bus[3].rvalue:
                    # no need to change the node
                    self.cp_bus[4]=self.rc_bus[3].rvalue
                    self.cp_bus[5]=0 # right
                    self.cp_bus[6]=self.rc_bus[3].count
                    self.next_bus.rs=self.rc_bus[1]
                    self.bus_to_forward.val=self.rc_bus[1] # The Modified Value? Or no need forward?
                else:
                    self.cp_bus[4]=self.rc_bus[1]
                    self.cp_bus[5]=0 #right
                    self.cp_bus[6]=self.rc_bus[3].count
                    self.next_bus.rs=self.rc_bus[3].rvalue
                    self.bus_to_forward.val=self.rc_bus[3].rvalue # The Modified Value? Or no need forward?
            else:
                # not full, all goes left otherwise rvalue are inf(this case no create next PUSHLEAF)
                self.cp_bus[0]='PUSH_ROOT'
                self.cp_bus[1]=self.rc_bus[1]
                self.cp_bus[2]=self.rc_bus[2]
                self.cp_bus[3]=self.rc_bus[3]
                self.bus_to_forward.ins='PUSH_ROOT'
                self.bus_to_forward.r=self.rc_bus[2] # the push rd is which need to be forwarded

                if self.rc_bus[3].lvalue==math.inf:
                    self.next_bus.ins='NOP'
                    self.next_bus.rs=0
                    self.next_bus.rd=0
                    self.cp_bus[4]=self.rc_bus[1]
                    self.cp_bus[5]=1 # right
                    self.cp_bus[6]=self.rc_bus[3].count-1
                    self.cp_bus[7]=0 #since lvalue is inf, the left child must be invalid
                    self.bus_to_forward.val=self.rc_bus[1] # The Modified Value? Or no need forward?
                elif self.rc_bus[3].rvalue==math.inf:
                    self.next_bus.ins='NOP'
                    self.next_bus.rs=0
                    self.next_bus.rd=0
                    self.cp_bus[4]=self.rc_bus[1]
                    self.cp_bus[5]=0 # right
                    self.cp_bus[6]=self.rc_bus[3].count-1
                    self.cp_bus[7]=0 #since rvalue is inf, the right child must be invalid
                    self.bus_to_forward.val=self.rc_bus[1] # The Modified Value? Or no need forward?
                else:
                    self.next_bus.ins='PUSH_LEAF'
                    self.next_bus.rd=self.rc_bus[3].lchild
                    if self.rc_bus[1]>=self.rc_bus[3].lvalue:
                        self.cp_bus[4]=self.rc_bus[3].lvalue
                        self.cp_bus[5]=1 # left
                        self.cp_bus[6]=self.rc_bus[3].count+1
                        self.cp_bus[7]=1 # left child will be valid
                        self.next_bus.rs=self.rc_bus[1]
                        self.bus_to_forward.val=self.rc_bus[1] # The Modified Value? Or no need forward?
                    else:
                        self.cp_bus[4]=self.rc_bus[1]
                        self.cp_bus[5]=1 # left
                        self.cp_bus[6]=self.rc_bus[3].count+1
                        self.cp_bus[7]=1 # left child will be valid
                        self.next_bus.rs=self.rc_bus[3].lvalue
                        self.bus_to_forward.val=self.rc_bus[3].lvalue # The Modified Value? Or no need forward?

        elif self.rc_bus[0]=='PUSH_LEAF':
            self.cp_bus[0]='PUSH_LEAF'
            self.cp_bus[1]=self.rc_bus[1]
            self.cp_bus[2]=self.rc_bus[2]
            self.cp_bus[3]=self.rc_bus[3]
            self.bus_to_forward.ins='PUSH_LEAF'
            self.bus_to_forward.r=self.rc_bus[2] # the push rd is which need to be forwarded
            if self.rc_bus[3].lvalue==math.inf: #first write to lvalue and not generate new stuff
                self.cp_bus[4]=self.rc_bus[1]
                self.cp_bus[5]=1 # left
                self.cp_bus[6]=self.rc_bus[3].count+1
                self.cp_bus[7]=0 #since lvalue is inf, the left child must be invalid
                self.next_bus.ins='NOP' 
                self.next_bus.rs=0
                self.next_bus.rd=0
                self.bus_to_forward.val=self.rc_bus[1] # The Modified Value? Or no need forward?
            elif self.rc_bus[3].rvalue==math.inf: #first write to rvalue and not generate new stuff
                self.cp_bus[4]=self.rc_bus[1]
                self.cp_bus[5]=0 # right
                self.cp_bus[6]=self.rc_bus[3].count-1
                self.cp_bus[7]=0 #since rvalue is inf, the right child must be invalid
                self.next_bus.ins='NOP' 
                self.next_bus.rs=0
                self.next_bus.rd=0
                self.bus_to_forward.val=self.rc_bus[1] # The Modified Value? Or no need forward?
            # In Push Leaf, count means difference between left and right
            elif self.rc_bus[3].count<=0: #左边更小，pushleaf左边
                self.cp_bus[5]=1 # left
                self.cp_bus[6]=self.rc_bus[3].count+1
                self.cp_bus[7]=1 #in every case the child will be valid.
                if self.rc_bus[1]>=self.rc_bus[3].lvalue:
                    self.cp_bus[4]=self.rc_bus[3].lvalue
                    self.next_bus.ins='PUSH_LEAF'
                    self.next_bus.rs=self.rc_bus[1]
                    self.next_bus.rd=self.rc_bus[3].lchild
                    self.bus_to_forward.val=self.rc_bus[1] # The Modified Value? Or no need forward?
                else:
                    self.cp_bus[4]=self.rc_bus[1]
                    self.next_bus.ins='PUSH_LEAF'
                    self.next_bus.rs=self.rc_bus[3].lvalue
                    self.next_bus.rd=self.rc_bus[3].lchild
                    self.bus_to_forward.val=self.rc_bus[3].lvalue # The Modified Value? Or no need forward?
            else:
                self.cp_bus[5]=0 # right
                self.cp_bus[6]=self.rc_bus[3].count-1
                self.cp_bus[7]=1 #in every case the child will be valid.
                if self.rc_bus[1]>=self.rc_bus[3].rvalue:
                    self.cp_bus[4]=self.rc_bus[3].rvalue
                    self.next_bus.ins='PUSH_LEAF'
                    self.next_bus.rs=self.rc_bus[1]
                    self.next_bus.rd=self.rc_bus[3].rchild
                    self.bus_to_forward.val=self.rc_bus[1] # The Modified Value? Or no need forward?
                else:
                    self.cp_bus[4]=self.rc_bus[1]
                    self.next_bus.ins='PUSH_LEAF'
                    self.next_bus.rs=self.rc_bus[3].rvalue
                    self.next_bus.rd=self.rc_bus[3].rchild
                    self.bus_to_forward.val=self.rc_bus[3].rvalue # The Modified Value? Or no need forward?
        else:
            print("wait to be further check")
        print(f"ipu{self.id} compare stage: {self.cp_bus}, next bus: {self.next_bus.ins} {self.next_bus.rs} {self.next_bus.rd}, forward bus: {self.bus_to_forward.ins} {self.bus_to_forward.r} {self.bus_to_forward.val}")
        for i in range(7):
            self.reg_cp[i]=self.cp_bus[i]
    def prepare_stage(self):
            self.pw_bus=['NOP',0,0,None,0,0,0,0,0] # ins, rs, rd, node, cmp_result, flag, sub_val/count, valid_signal, forward_val
            if self.cp_bus[0]=='NOP':
                self.pw_bus=['NOP',0,0,None,0,0,0,0,0]
            elif self.cp_bus[0]=='POP_ROOT':
                self.pw_bus[0]='POP_ROOT'
                self.pw_bus[1]=self.cp_bus[1]
                self.pw_bus[2]=self.cp_bus[2]
                self.pw_bus[3]=self.cp_bus[3]
                self.pw_bus[4]=self.cp_bus[4]
                self.pw_bus[5]=self.cp_bus[5]
                self.pw_bus[6]=self.cp_bus[6]
                self.pw_bus[7]=self.cp_bus[7]

            elif self.cp_bus[0]=='POP_LEAF':
                self.pw_bus[0]='POP_LEAF'
                self.pw_bus[1]=self.cp_bus[1]
                self.pw_bus[2]=self.cp_bus[2]
                self.pw_bus[3]=self.cp_bus[3]
                self.pw_bus[4]=self.cp_bus[4]
                self.pw_bus[5]=self.cp_bus[5]
                self.pw_bus[6]=self.cp_bus[6]
                self.pw_bus[7]=self.cp_bus[7]

            elif self.cp_bus[0]=='PUSH_ROOT':
                self.pw_bus[0]='PUSH_ROOT'
                self.pw_bus[1]=self.cp_bus[1]
                self.pw_bus[2]=self.cp_bus[2]
                self.pw_bus[3]=self.cp_bus[3]
                self.pw_bus[4]=self.cp_bus[4]
                self.pw_bus[5]=self.cp_bus[5]
                self.pw_bus[6]=self.cp_bus[6]
                self.pw_bus[7]=self.cp_bus[7]
            
            elif self.cp_bus[0]=='PUSH_LEAF':
                self.pw_bus[0]='PUSH_LEAF'
                self.pw_bus[1]=self.cp_bus[1]
                self.pw_bus[2]=self.cp_bus[2]
                self.pw_bus[3]=self.cp_bus[3]
                self.pw_bus[4]=self.cp_bus[4]
                self.pw_bus[5]=self.cp_bus[5]
                self.pw_bus[6]=self.cp_bus[6]
                self.pw_bus[7]=self.cp_bus[7]
                
            print(f"ipu{self.id} prepare stage: {self.pw_bus}, block: {self.block}")                
    def write_stage(self):
        self.write_bus=[-1, -1, math.inf, math.inf, 0, -1, -1,0,0] # valid, addr, lval, rval, count, lchild, rchild,lcvalid, rcvalid
        clear_flag=0
        if self.pw_bus[0]=='POP_ROOT':
            if self.forward_to_bus.ins == 'POP_ROOT' or self.forward_to_bus.ins == 'POP_LEAF':
                if self.forward_to_bus.r==self.cp_bus[1]: # the pop rd is which need to be forwarded
                    self.pw_bus[8]=self.forward_to_bus.val
                    if self.forward_to_bus.clear==1: # clear flag
                        clear_flag=1                            
                else:

                    self.block=True
                    self.pw_bus[8]=-1 # -1 means invalid
            else:
                self.pw_bus[8]=math.inf
            print(f'POP: {self.pw_bus[4]} from {self.id} addr {self.pw_bus[1]}')
            if self.pw_bus[8]!=-1: # -1 means invalid
                self.write_bus[0]=1
                self.write_bus[1]=self.pw_bus[1] # addr
                if self.pw_bus[5]==1: # left
                    self.write_bus[2]=self.pw_bus[8] # lval
                    self.write_bus[3]=self.pw_bus[3].rvalue # rval
                    self.write_bus[4]=self.pw_bus[6] # count
                    self.write_bus[5]=self.pw_bus[3].lchild # lchild
                    self.write_bus[6]=self.pw_bus[3].rchild # rchild

                    self.write_bus[7]=self.pw_bus[7] & ~clear_flag
                    self.write_bus[8]=self.pw_bus[3].rchild_valid
                else:
                    self.write_bus[2]=self.pw_bus[3].lvalue # lval
                    self.write_bus[3]=self.pw_bus[8] # rval
                    self.write_bus[4]=self.pw_bus[6] # count
                    self.write_bus[5]=self.pw_bus[3].lchild # lchild
                    self.write_bus[6]=-1 if clear_flag else self.pw_bus[3].rchild # rchild
                    self.write_bus[7]=self.pw_bus[3].lchild_valid
                    self.write_bus[8]=self.pw_bus[7] & ~clear_flag
            else:
                self.write_bus[0]=0
                pass # wait to be unblocked
        elif self.pw_bus[0]=='POP_LEAF':
            if self.forward_to_bus.ins == 'POP_ROOT' or self.forward_to_bus.ins == 'POP_LEAF':
                    if self.forward_to_bus.r==self.cp_bus[1]: # the pop rd is which need to be forwarded
                        self.pw_bus[8]=self.forward_to_bus.val
                    else:

                        self.block=True
                        self.pw_bus[8]=-1 # -1 means invalid
            else:
                self.pw_bus[8]=math.inf
            if self.pw_bus[8]!=-1: # -1 means invalid
                self.write_bus[0]=1
                self.write_bus[1]=self.pw_bus[1] # addr
                if self.pw_bus[5]==1: # left
                    self.write_bus[2]=self.pw_bus[8] # lval
                    self.write_bus[3]=self.pw_bus[3].rvalue # rval
                    self.write_bus[4]=self.pw_bus[6] # count
                    self.write_bus[5]=self.pw_bus[3].lchild # lchild
                    self.write_bus[6]=self.pw_bus[3].rchild # rchild
                    self.write_bus[7]=self.pw_bus[7] & ~clear_flag
                    self.write_bus[8]=self.pw_bus[3].rchild_valid
                else:
                    self.write_bus[2]=self.pw_bus[3].lvalue # lval
                    self.write_bus[3]=self.pw_bus[8] # rval
                    self.write_bus[4]=self.pw_bus[6] # count
                    self.write_bus[5]=self.pw_bus[3].lchild # lchild
                    self.write_bus[6]=self.pw_bus[3].rchild # rchild
                    self.write_bus[7]=self.pw_bus[3].lchild_valid
                    self.write_bus[8]=self.pw_bus[7] & ~clear_flag
            else:
                self.write_bus[0]=0
                pass # wait to be unblocked
        elif self.pw_bus[0]=='PUSH_ROOT' or self.pw_bus[0]=='PUSH_LEAF':

            self.write_bus[0]=1
            self.write_bus[1]=self.pw_bus[2] # addr
            self.write_bus[2]=self.pw_bus[4] if self.pw_bus[5]==1 else self.pw_bus[3].lvalue # lval
            self.write_bus[3]=self.pw_bus[4] if self.pw_bus[5]==0 else self.pw_bus[3].rvalue # rval
            self.write_bus[4]=self.pw_bus[6] # count
            self.write_bus[5]=self.pw_bus[3].lchild
            self.write_bus[6]=self.pw_bus[3].rchild

            self.write_bus[7]=self.pw_bus[7] if self.pw_bus[5]==1 else self.pw_bus[3].lchild_valid
            self.write_bus[8]=self.pw_bus[7] if self.pw_bus[5]==0 else self.pw_bus[3].rchild_valid
        else:
            self.write_bus[0]=0
            pass
            
        print(f"ipu{self.id} write stage: {self.write_bus}, block: {self.block}")
    def in_stage(self):
        
        if self.write_bus[0]==1:
            self.ivy_row[self.write_bus[1]].lvalue=self.write_bus[2]
            self.ivy_row[self.write_bus[1]].rvalue=self.write_bus[3]
            self.ivy_row[self.write_bus[1]].count=self.write_bus[4]
            self.ivy_row[self.write_bus[1]].lchild=self.write_bus[5]
            self.ivy_row[self.write_bus[1]].rchild=self.write_bus[6]
            self.ivy_row[self.write_bus[1]].lchild_valid=self.write_bus[7]
            self.ivy_row[self.write_bus[1]].rchild_valid=self.write_bus[8]
            # print(f"ipu{self.id} write back {self.write_bus}")
            self.block=False
        print(f"ipu{self.id} in stage: {self.ivy_row[self.write_bus[1]].lvalue, self.ivy_row[self.write_bus[1]].rvalue, self.ivy_row[self.write_bus[1]].count, self.ivy_row[self.write_bus[1]].lchild, self.ivy_row[self.write_bus[1]].rchild}")
    def run(self):
        self.in_stage()
        self.write_stage()
        self.prepare_stage()
        self.compare_stage()
        self.read_stage()

if __name__ == "__main__":

    # sim init
    bus_01=inter_ipu_bus(0,1)
    bus_12=inter_ipu_bus(1,2)
    bus_23=inter_ipu_bus(2,3)
    bus_30=inter_ipu_bus(3,0)
    bus_in=inter_ipu_bus(-1,0) # from outside to ipu0
    fbus_0=forward_bus(1,0)
    fbus_1=forward_bus(2,1)
    fbus_2=forward_bus(3,2)
    fbus_3=forward_bus(0,3)

    ivy_pool=ivy_node_pool(4,9)
    ivy_pool.ivy_node_pool_load("ivy_node_pool.json")
    ipu_0=ipu(0,ivy_pool)
    ipu_0.bind_bus(bus_in,bus_30,bus_01,fbus_0,fbus_3)
    ipu_1=ipu(1,ivy_pool)
    ipu_1.bind_bus(bus_01,bus_01,bus_12,fbus_1,fbus_0)
    ipu_2=ipu(2,ivy_pool)
    ipu_2.bind_bus(bus_12,bus_12,bus_23,fbus_2,fbus_1)
    ipu_3=ipu(3,ivy_pool)
    ipu_3.bind_bus(bus_23,bus_23,bus_30,fbus_3,fbus_2)

    ins_list=[['PUSH_ROOT',60,0],['POP_ROOT',0,-1]]
    total_cycle=len(ins_list)+7
    clk=0
    while clk<=total_cycle:
        print(f"cycle {clk}:")
        ipu_0.run()
        ipu_1.run()
        ipu_2.run()
        ipu_3.run()
        bus_in.ins=ins_list[clk][0] if clk<len(ins_list) else 'NOP'
        bus_in.rs=ins_list[clk][1] if clk<len(ins_list) else 0
        bus_in.rd=ins_list[clk][2] if clk<len(ins_list) else 0
        clk+=1

    # ins_list=[['POP_ROOT',0,-1]]
    # total_cycle=len(ins_list)+7
    # clk2=clk
    # clk=0
    # while clk<=total_cycle:
    #     print(f"cycle {clk2}:")
    #     ipu_0.run()
    #     ipu_1.run()
    #     ipu_2.run()
    #     ipu_3.run()
    #     bus_in.ins=ins_list[clk][0] if clk<len(ins_list) else 'NOP'
    #     bus_in.rs=ins_list[clk][1] if clk<len(ins_list) else 0
    #     bus_in.rd=ins_list[clk][2] if clk<len(ins_list) else 0
    #     clk+=1
    #     clk2+=1

    ivy_pool.ivy_node_pool_dump("output.json")

                

