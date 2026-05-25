import matplotlib.pyplot as plt
import matplotlib.patches as patches
single_mem_size = 10880
mem_num=11
mem=[single_mem_size]*mem_num
fill_tree0=[2,4,8,16,32,64,128,256,512,1024,2048]
fill_tree1=[2,2,4,8,16,32,64,128,256,512,1024]
fill_tree2=[2,2,4,8,16,32,64,128,256,512]
fill_tree3=[2,2,4,8,16,32,64,128,256]
def max_percent_diff(list1, list2):

    if len(list1) != len(list2):
        raise ValueError("need same length list.")

    max_diff = 0.0
    for a, b in zip(list1, list2):
        if max(a, b) == 0:
            continue
        diff = (a - b) / max(a, b) * 100
        if diff > max_diff:
            max_diff = diff
    return max_diff

def min_percent_diff(list1, list2):

    if len(list1) != len(list2):
        raise ValueError("need same length list.")

    min_diff = 300.0
    for a, b in zip(list1, list2):
        if max(a, b) == 0:
            continue
        diff = (a - b) / max(a, b) * 100
        if diff <min_diff:
            min_diff = diff
    return min_diff
def fill_tree_num(fill_tree,mem):
    num=0
    temp_mem=mem.copy()
    flag=True
    while flag:
        for i in range(len(fill_tree)):
            temp_mem[(num+i)%11]-=fill_tree[i]
            if temp_mem[(num+i)%11]<0:
                flag=False
                break
        if flag:
            num+=1
    return num

if __name__ == '__main__':

    base_mem_size=4096
    step=1024/8
    mem_num=11
    mem=[base_mem_size]*mem_num

    num_0=[]
    num_1=[]
    num_2=[]
    num_3=[]

    mem_sizes=[]
    cur_mem_size=base_mem_size
    while cur_mem_size<=4096*4:
        mem_sizes.append(cur_mem_size * 11 / 1024)

        mem=[cur_mem_size]*mem_num
        num_0.append(float(fill_tree_num(fill_tree0,mem)*4094/1024))
        num_2.append(float(fill_tree_num(fill_tree2,mem)*1024/1024))
        num_1.append(float(fill_tree_num(fill_tree1,mem)*2048/1024))
        num_3.append(float(fill_tree_num(fill_tree3,mem)*512/1024))
        
        cur_mem_size+=step
    
    print(max_percent_diff(mem_sizes,num_0))
    print(max_percent_diff(mem_sizes,num_2))
    print(max_percent_diff(mem_sizes,num_1))
    print(max_percent_diff(mem_sizes,num_3))
    print(max_percent_diff(num_2,num_0),min_percent_diff(num_2,num_0))
    print(max_percent_diff(num_1,num_0),min_percent_diff(num_1,num_0))
    print(max_percent_diff(num_3,num_0),min_percent_diff(num_3,num_0))

    fig,ax=plt.subplots(figsize=(6, 5))
    plt.plot(mem_sizes, num_0, label='vPIFO',linewidth=2)
    plt.plot(mem_sizes, num_1, label='Ivy(k=2)',linewidth=2)
    plt.plot(mem_sizes, num_2, label='Ivy(k=4)',linewidth=2)
    plt.plot(mem_sizes, num_3, label='Ivy(k=8)',linewidth=2)
    # plt.plot(mem_sizes, num_3, label='Ivy-6',color='black')
    plt.plot(mem_sizes, mem_sizes, label='ideal',linestyle='--',color='black')
    plt.xlabel('Total Node Count (K)',fontsize=18,labelpad=14)
    plt.ylabel('Available Node Count (K)',fontsize=18,labelpad=14)
    plt.xticks(fontsize=16)
    plt.yticks(fontsize=16)


    rect = patches.Rectangle((0, 1.0), 1.0, 0.33, linewidth=1.2, edgecolor='black', 
                            facecolor='white', transform=ax.transAxes, clip_on=False)
    ax.add_patch(rect)


    leg = ax.legend(loc='upper left', 
                    bbox_to_anchor=(0.01, 1.33), 
                    ncol=2, 
                    frameon=False,      
                    columnspacing=4.5,  
                    fontsize=16,
                    handletextpad=0.5,
                    borderaxespad=0)
    for spine in ax.spines.values():
        spine.set_linewidth(1.2)


    plt.subplots_adjust(top=0.75)



    plt.tight_layout()
    plt.savefig('mem_num_2.pdf')
    plt.show()

    

    

        