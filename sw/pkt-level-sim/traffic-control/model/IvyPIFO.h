# ifndef IVYPIFO_H
# define IVYPIFO_H

# include <fstream>
# include <sstream>
# include <iostream>
# include <map>
# include <memory>
# include "ns3/ipv4-queue-disc-item.h"
# include "ns3/node.h"
# include "ns3/ptr.h"
# include "ns3/tcp-header.h"
# include "ns3/Tenant-tag.h"
# include "IvyPipeline.h"
# include "MyScheduling.h"

namespace ns3 {
    class IvyPIFO : public QueueDisc{
        public:
            IvyPIFO();
            
            static TypeId GetTypeId(void);
            void InitializeParams(void);
            bool DoEnqueue(Ptr<QueueDiscItem> item);        
            Ptr<QueueDiscItem> DoDequeue(void);
            Ptr<const QueueDiscItem> DoPeek(void) const;
            bool CheckConfig(void);
        
        private:
            // The index of root
            static const int ROOT;
            // The size of a queue
            static const int SIZE;

            std::unordered_map<string, int> flow_map;
            std::unordered_map<int, std::shared_ptr<Scheduling>> sch_tree;
            std::unordered_map<int, std::queue<Ptr<QueueDiscItem>>> queue_map;
            std::queue<Ptr<QueueDiscItem>> bypath_queue;
            int queue_cnt = 1000;
            int root_size;
            
            // int empty_queue = 0;

            IvyPipeline pipe;

            bool IsHadoop(int x);

            std::string GetFlowLabel(Ptr<QueueDiscItem> item); 
    };
}

# endif