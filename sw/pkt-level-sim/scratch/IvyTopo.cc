# include <algorithm>
# include <cstdio>
# include <fstream>
# include <iostream>
# include <map>
# include <unordered_map>

# include "ns3/applications-module.h"
# include "ns3/core-module.h"
# include "ns3/flow-monitor-module.h"
# include "ns3/internet-module.h"
# include "ns3/ipv4-header.h"
# include "ns3/netanim-module.h"
# include "ns3/network-module.h"
# include "ns3/point-to-point-module.h"
# include "ns3/random-variable-stream.h"
# include "ns3/stats-module.h"
# include "ns3/traffic-control-module.h"
# include "ns3/udp-header.h"
# include "ns3/packet.h"
# include "ns3/tag.h"
# include "ns3/Tenant-tag.h"

using namespace ns3;
using namespace std;

NS_LOG_COMPONENT_DEFINE("IvyTopoTCP");

const int LEAF_CNT = 9;
const int SPINE_CNT = 4;
const int SERVER_CNT = 144;
const int LINK_CNT = LEAF_CNT * SPINE_CNT + SERVER_CNT;
const int FLOW_NUM = 5000;
const int TENANT_NUM = 100;
uint32_t totalPktSize = 0;
uint32_t total_send = 0;
const char *ACCESS_RATE = "4.8Gbps";
const char *BACKBONE_RATE = "12Gbps";
const char *DATARATE = "4.8Gbps";
const char *DELAY = "3us";
double simulator_stop_time = 4;
const int PKTSIZE = 1448;

std::unordered_map<string, int> flow_index;
std::unordered_map<uint32_t, uint16_t> flow_port;
uint32_t websearch_count = 0;
struct FlowInfo {
  double time;
  double start_time, e2e_time;
  int tenant, size;
} flow_info[FLOW_NUM];

int FlowComp(FlowInfo x, FlowInfo y) {
  if (x.tenant == y.tenant)
    return x.time < y.time;
  return x.tenant < y.tenant;
}

std::vector<Ipv4InterfaceContainer> interfaces(LINK_CNT);
NodeContainer leafNodes, spineNodes, serverNodes, nodes;


class MyApp : public Application
{
public:
  MyApp();
  virtual ~MyApp();
  static TypeId GetTypeId(void);
  void Setup(Ptr<Socket> socket, uint32_t sip, Ipv4Address saddr, 
      Address address, uint32_t packetSize,
      uint32_t nPackets, DataRate dataRate, uint32_t flowId, uint32_t tenant);

private:
  virtual void StartApplication(void);
  virtual void StopApplication(void);
  void ScheduleTx(void);
  void SendPacket(void);
  Ptr<Socket> m_socket;
  Address m_peer;
  uint32_t m_packetSize;
  uint32_t m_nPackets;
  DataRate m_dataRate;
  EventId m_sendEvent;
  bool m_running;
  uint32_t m_packetsSent;
  uint32_t m_flowId;
  uint32_t m_tenant;
};

MyApp::MyApp()
    : m_socket(0),
      m_peer(),
      m_packetSize(0),
      m_nPackets(0),
      m_dataRate(0),
      m_sendEvent(),
      m_running(false),
      m_packetsSent(0),
      m_tenant(0) {}

MyApp::~MyApp() { m_socket = 0; }

TypeId MyApp::GetTypeId(void)
{
  static TypeId tid = TypeId("MyApp")
                          .SetParent<Application>()
                          .SetGroupName("Tutorial")
                          .AddConstructor<MyApp>();
  return tid;
}

void

MyApp::Setup(Ptr<Socket> socket, uint32_t sip, Ipv4Address saddr,
    Address address, uint32_t packetSize, 
    uint32_t nPackets, DataRate dataRate, uint32_t flowId, uint32_t tenant)
{
  m_socket = socket;
  if (flow_port.count(sip) == 0)
    flow_port[sip] = 49152;
  flow_port[sip]++;
  while (m_socket->Bind(InetSocketAddress(saddr, flow_port[sip])))
    flow_port[sip]++;

  m_peer = address;
  m_packetSize = packetSize;
  m_nPackets = nPackets;
  m_dataRate = dataRate;
  m_flowId = flowId;
  m_tenant = tenant;
}

void MyApp::StartApplication(void)
{
  m_running = true;
  m_packetsSent = 0;
  m_socket->Connect(m_peer);
  SendPacket();
}

void MyApp::StopApplication(void)
{
  m_running = false;
  if (m_sendEvent.IsRunning())
  {
    Simulator::Cancel(m_sendEvent);
  }
  if (m_socket)
  {
    m_socket->Close();
  }
}

void MyApp::SendPacket(void)
{
  Ptr<Packet> packet = Create<Packet>(m_packetSize);
  TenantTag tag;
  tag.SetTenantId(m_tenant);
  packet->AddPacketTag(tag);
  m_socket->Send(packet);    
  total_send += 1;
  if (++m_packetsSent < m_nPackets)
  {
    ScheduleTx();
  }
}

void MyApp::ScheduleTx(void)
{
  if (m_running)
  {
    Time tNext(Seconds(m_packetSize * 8 /
                       static_cast<double>(m_dataRate.GetBitRate())));
    m_sendEvent = Simulator::Schedule(tNext, &MyApp::SendPacket, this);
  }
}

ofstream Output;

class TraceFlow
{
private:
  ifstream flow;
  uint32_t flow_num;
  struct FlowInput
  {
    uint32_t src, dst, packet_count;
    uint16_t dport;
    double start_time;
    uint32_t idx;
    uint32_t tenant;
  };

  FlowInput flow_input = {0};

public:
  enum type
  {
    WebSearch,
    Hadoop
  } flow_type;
  
  TraceFlow(string file_name, type flow_t)
  {
    flow.open(file_name);
    flow >> flow_num;
    cout << "flow_num:" << flow_num << endl;
    if (flow_t == WebSearch)
      websearch_count = flow_num;
    flow_input.idx = 0;
    flow_type = flow_t;
  }

  void ReadFlowInput()
  {
    flow >> flow_input.src >> flow_input.dst >>
        flow_input.dport >> flow_input.packet_count >> flow_input.start_time;
    int tenant = rand() % 100;
    if (flow_type == Hadoop) {
      while (tenant % 10 <= tenant / 10)
        tenant = rand() % 100;
      flow_input.tenant = tenant;
    }
    else {
      while (tenant % 10 > tenant / 10)
        tenant = rand() % 100;
      flow_input.tenant = tenant;
      flow_info[flow_input.idx].tenant = flow_input.tenant;
      flow_info[flow_input.idx].size = flow_input.packet_count;
      flow_info[flow_input.idx].start_time=flow_input.start_time;
    }
    totalPktSize += flow_input.packet_count;
  }

  void ScheduleFlowInput()
  {
    Address sinkAddress(InetSocketAddress(
        interfaces[flow_input.dst].GetAddress(1), flow_input.dport));
    PacketSinkHelper sinkHelper("ns3::TcpSocketFactory", 
      InetSocketAddress(Ipv4Address::GetAny(), flow_input.dport));
    ApplicationContainer sinkApp =
        sinkHelper.Install(serverNodes.Get(flow_input.dst));
    sinkApp.Start(Seconds(0));
    sinkApp.Stop(Seconds(simulator_stop_time));

    TypeId tid = TypeId::LookupByName("ns3::TcpNewReno");
    Config::Set("/NodeList/*/$ns3::TcpL4Protocol/SocketType",
                TypeIdValue(tid));
    Ptr<Socket> ns3TcpSocket = Socket::CreateSocket(
        serverNodes.Get(flow_input.src), TcpSocketFactory::GetTypeId());
    ns3TcpSocket->SetAttribute(
        "SndBufSize", ns3::UintegerValue(1438000000));
    ns3TcpSocket->SetAttribute("InitialCwnd", ns3::UintegerValue(10000));
    Ipv4Address saddr = interfaces[flow_input.src].GetAddress(1);
    uint32_t sip = interfaces[flow_input.src].GetAddress(1).Get();
    Ptr<MyApp> app = CreateObject<MyApp>();
    app->Setup(
        ns3TcpSocket, sip, saddr, sinkAddress, PKTSIZE, flow_input.packet_count,
        DataRate(DATARATE), flow_input.idx, flow_input.tenant);
    serverNodes.Get(flow_input.src)->AddApplication(app);

    if (flow_type == WebSearch) {
      stringstream ss;
      ss << sip << flow_port[sip];
      string flowlabel = ss.str();
      Output << flowlabel.c_str() << " ";
      Output << flow_input.src << " " << flow_input.dst << " ";
      Output << flow_input.packet_count << " " << flow_input.tenant << endl;
      
      flow_index[flowlabel] = flow_input.idx;
    }
    
    app->SetStartTime(Seconds(flow_input.start_time) - Simulator::Now());
  }

  void Input()
  {
    if (flow_type == WebSearch) {
      string path = "IvyResult/flowlabel.txt";
      Output.open(path);
      Output << flow_num << endl;
    }
    while (flow_input.idx < flow_num) {
      ReadFlowInput();
      ScheduleFlowInput();
      flow_input.idx++;
    }
    flow.close();
    if (flow_type == WebSearch)
      Output.close();
  }

} web_search("scratch/traffic_ws.txt", TraceFlow::WebSearch), 
  hadoop("scratch/traffic_hd.txt", TraceFlow::Hadoop);

int main(int argc, char *argv[])
{
  Config::SetDefault("ns3::TcpSocket::DelAckTimeout", TimeValue(Seconds(0.0)));
  Config::SetDefault("ns3::RttEstimator::InitialEstimation",
                     TimeValue(Seconds(0.000012)));
  Config::SetDefault("ns3::TcpSocket::ConnTimeout",
                     TimeValue(Seconds(1e6)));
  Config::SetDefault("ns3::TcpSocketBase::MinRto",
                     TimeValue(MilliSeconds(1e6)));
  Config::SetDefault("ns3::TcpSocketBase::ClockGranularity",
                     TimeValue(MilliSeconds(0.012)));

  Config::SetDefault("ns3::TcpSocket::DataRetries", UintegerValue(100));
  Config::SetDefault("ns3::TcpSocket::ConnCount", UintegerValue(100));
  Config::SetDefault("ns3::TcpSocket::SegmentSize", UintegerValue(1448));
  Config::SetDefault("ns3::TcpSocket::DelAckCount", UintegerValue(0));

  clock_t begint, endt;
  begint = clock();
  CommandLine cmd;
  cmd.Parse(argc, argv);
  Time::SetResolution(Time::NS);

  serverNodes.Create(SERVER_CNT);
  leafNodes.Create(LEAF_CNT);
  spineNodes.Create(SPINE_CNT);
  
  nodes = NodeContainer(leafNodes, spineNodes, serverNodes);

  PointToPointHelper backboneHelper;
  backboneHelper.SetDeviceAttribute("DataRate", StringValue(BACKBONE_RATE));
  backboneHelper.SetChannelAttribute("Delay", StringValue(DELAY));
  backboneHelper.SetQueue("ns3::DropTailQueue",
                              "MaxPackets", UintegerValue(1000));
  PointToPointHelper accessHelper;
  accessHelper.SetDeviceAttribute("DataRate", StringValue(ACCESS_RATE));
  accessHelper.SetChannelAttribute("Delay", StringValue(DELAY));
  accessHelper.SetQueue("ns3::DropTailQueue",
                            "MaxPackets", UintegerValue(1000));

  std::vector<NetDeviceContainer> devices(LINK_CNT);
  int device_cnt = 0;
  for (int i = 0, j; i < SERVER_CNT; ++i)
  {
    j = i / (SERVER_CNT / LEAF_CNT);
    devices[device_cnt] = 
        accessHelper.Install(leafNodes.Get(j), serverNodes.Get(i));
    device_cnt++;
  }
  for (int i = 0; i < LEAF_CNT; ++i)
    for (int j = 0; j < SPINE_CNT; ++j)
    {
      devices[device_cnt] = 
          backboneHelper.Install(leafNodes.Get(i), spineNodes.Get(j));
      device_cnt++;
    }

  InternetStackHelper stack;
  stack.Install(nodes);

  Ipv4AddressHelper address;
  for (uint32_t i = 0; i < LINK_CNT; i++)
  {
    std::ostringstream subset;
    subset << "10.1." << i + 1 << ".0";
    address.SetBase(subset.str().c_str(), "255.255.255.0");
    interfaces[i] = address.Assign(devices[i]);
  }
  
  TrafficControlHelper tch;
  for (int i = 0; i < LINK_CNT; i++)
  {
    tch.Uninstall(devices[i]);
  }
  tch.SetRootQueueDisc("ns3::IvyPIFO");
  for (int i = 0; i < LINK_CNT; ++i)
  {
    tch.Install(devices[i]);
  }

  Ipv4GlobalRoutingHelper::PopulateRoutingTables();

  web_search.Input();
  hadoop.Input();

  FlowMonitorHelper fmhelper;
  Ptr<FlowMonitor> monitor = fmhelper.Install(nodes);

  std::cout << "Running Simulation.\n";
  fflush(stdout);
  NS_LOG_INFO("Run Simulation.");
  Simulator::Stop(Seconds(simulator_stop_time));
  Simulator::Run();
  
  Ptr<Ipv4FlowClassifier> classifier = 
    DynamicCast<Ipv4FlowClassifier> (fmhelper.GetClassifier ());
  FlowMonitor::FlowStatsContainer stats = monitor->GetFlowStats ();

    double total_tx=0,total_rx=0,total_lost=0;
  for (auto &i : stats) {
    total_tx += i.second.txBytes;
    total_rx += i.second.rxBytes;
    total_lost+= i.second.lostPackets;
  }
  cout << "total tx:" << total_tx <<endl;
  cout << "total rx:" << total_rx <<endl;
  cout <<"total lost:" << total_lost <<endl;

  double first=1e9, last=0;
  for (auto &i : stats){
    first=min(first, i.second.timeFirstTxPacket.GetSeconds());
    last= max(last, i.second.timeLastRxPacket.GetSeconds());
  }

  double sim_time=last-first;
  double load= total_rx * 8 /sim_time / (40e9);

  cout <<"sim_time" << sim_time <<endl;
  cout <<"load" << load <<endl;

  for (std::map<FlowId, FlowMonitor::FlowStats>::const_iterator i =
    stats.begin (); i != stats.end (); ++i) {
      Ipv4FlowClassifier::FiveTuple t = classifier->FindFlow (i->first);
      stringstream ss;
      ss << t.sourceAddress.Get() << t.sourcePort;
      string flowlabel = ss.str();
      // skip the hadoop flow
      if (flow_index.count(flowlabel) == 0)
        continue;
      cout
      << "flow="
      << flowlabel
      << " rxPkts="
      << i->second.rxPackets
      << " txPkts="
      << i->second.txPackets
      << " firstRx="
      << i->second.timeFirstRxPacket.GetSeconds()
      << " lastRx="
      << i->second.timeLastRxPacket.GetSeconds()
      << endl;
      int idx = flow_index[flowlabel];
      double start_time = i->second.timeFirstRxPacket.GetSeconds();
      double end_time = i->second.timeLastRxPacket.GetSeconds();
      cout<<flowlabel<<" "<<idx<<" "<<start_time<<" "<<end_time<<endl;
      flow_info[idx].time = end_time - start_time;
      flow_info[idx].e2e_time=end_time-flow_info[idx].start_time;
  }
  
  sort(flow_info, flow_info + websearch_count, FlowComp);

  ofstream ss_fct("IvyResult/AllFct.txt", std::ios::out | std::ios::app);
  for (uint32_t i = 0; i < websearch_count; ++i) {
    ss_fct << flow_info[i].time << " " << flow_info[i].size << " " <<
        flow_info[i].size * 8 * PKTSIZE / (1024 * 1024 * flow_info[i].time) << 
        " " << flow_info[i].tenant << endl; 
  }
  ofstream ss_efct("IvyResult/E2EFct.txt", std::ios::out | std::ios::app);
  for (uint32_t i = 0; i < websearch_count; ++i) {
    ss_efct << flow_info[i].e2e_time << " " << flow_info[i].size << " " <<
        flow_info[i].size * 8 * PKTSIZE / (1024 * 1024 * flow_info[i].time) <<
        " " << flow_info[i].tenant << endl;
  }

  ofstream ss_95("IvyResult/95Fct.txt", std::ios::out | std::ios::app);
  for (uint32_t i = 0, j, k; i < websearch_count;) {
    j = i;
    while (flow_info[j].tenant == flow_info[i].tenant)
      j++;
    if (j == i || j == i + 1)  k = i;
    else
      k = 0.95 * (j - i) + i - 1;
    ss_95 << flow_info[k].tenant <<" "<< k <<" "<< flow_info[k].time << endl; 
    i = j;
  }
  ofstream ss_e95("IvyResult/E2E95Fct.txt", std::ios::out | std::ios::app);
  for (uint32_t i = 0, j, k; i < websearch_count;) {
    j = i;
    while (flow_info[j].tenant == flow_info[i].tenant)
      j++;
    if (j == i || j == i + 1)  k = i;
    else
      k = (int)(0.95 * (j - i) + i - 1);
    ss_e95 << flow_info[k].tenant <<" "<< k <<" "<< flow_info[k].e2e_time << endl;
    ss_e95 << flow_info[k+1].tenant <<" "<< k+1 <<" "<< flow_info[k+1].e2e_time << endl;
    i = j;
  }
  Simulator::Destroy();
  NS_LOG_INFO("Done.");

  endt = clock();
  cout << (double)(endt - begint) / CLOCKS_PER_SEC << "\n";
  cout << "totalPktSize:" << totalPktSize << std::endl;
  cout << "total_send:" << total_send << endl;
  
  return 0;
}
