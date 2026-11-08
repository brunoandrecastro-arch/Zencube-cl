// Reads the line fixture exported by the actual GDScript engine.
#include <array>
#include <vector>
#include <random>
#include <iostream>
#include <fstream>
#include <algorithm>
#include <set>
#include <string>
using namespace std;
using Board=array<int,54>;
vector<array<int,4>> lines;
vector<int> incidence[54];
mt19937 rng(20261106);
vector<int> threats(const Board& b,int p){set<int> out;for(auto l:lines){int n=0,e=-1;for(int c:l){n+=b[c]==p;if(!b[c])e=c;}if(n==3&&e>=0)out.insert(e);}return vector<int>(out.begin(),out.end());}
bool win(const Board& b,int p){for(auto l:lines)if(b[l[0]]==p&&b[l[1]]==p&&b[l[2]]==p&&b[l[3]]==p)return true;return false;}
int choose(Board& b,int p,int strategy){
 vector<int> free;for(int i=0;i<54;i++)if(!b[i])free.push_back(i);
 if(strategy==0)return free[rng()%free.size()];
 auto w=threats(b,p);if(w.size())return w[rng()%w.size()];
 auto t=threats(b,3-p);if(t.size())return t[rng()%t.size()];
 if(strategy==1)return free[rng()%free.size()];
 vector<int> best;int high=-100000;
 for(int c:free){int value=0;
  for(int j:incidence[c]){auto l=lines[j];int a=0,o=0;for(int x:l){a+=b[x]==p;o+=b[x]==3-p;}if(!o)value+=a?14:1;if(!a)value+=o?16:1;}
  b[c]=p;if(threats(b,p).size()>=2)value+=400;
  b[c]=3-p;if(threats(b,3-p).size()>=2)value+=180;b[c]=0;
  if(value>high){high=value;best.clear();}if(value==high)best.push_back(c);
 }return best[rng()%best.size()];
}
int main(int argc,char**argv){
 ifstream in(argc>1?argv[1]:"reports/lines.json");string s((istreambuf_iterator<char>(in)),{});string nums;for(char c:s)nums+=isdigit(c)?c:' ';size_t at=0;vector<int> values;while(at<nums.size()){if(nums[at]==' '){at++;continue;}size_t end;values.push_back(stoi(nums.substr(at),&end));at+=end;}
 if(values.size()!=432)return 2;
 for(size_t i=0;i<values.size();i+=4){lines.push_back({values[i],values[i+1],values[i+2],values[i+3]});for(int k=0;k<4;k++)incidence[values[i+k]].push_back(i/4);}
 cout<<"{\"seed\":20261106,\"degree_by_cell\":[";for(int i=0;i<54;i++)cout<<(i?",":"")<<incidence[i].size();cout<<"],\"batches\":[";
 int config[5][2]={{0,0},{1,1},{2,2},{1,2},{2,1}};
 for(int group=0;group<5;group++){
  long wins[3]={0},plies=0,forkgames=0,quick=0;int shortest=54,longest=0;long opener[54][2]={};
  for(int game=0;game<2000;game++){
   Board b{};int p=1,first=-1,steps=0,winner=0;bool fork=false;
   for(;steps<54;){int c=choose(b,p,config[group][p-1]);if(!steps){first=c;}b[c]=p;steps++;if(win(b,p)){winner=p;break;}if(threats(b,p).size()>=2)fork=true;p=3-p;}
   wins[winner]++;plies+=steps;forkgames+=fork;quick+=steps<=7;shortest=min(shortest,steps);longest=max(longest,steps);opener[first][0]++;opener[first][1]+=winner==1;
 
  }
  if(group)cout<<",";cout<<"{\"strategies\":["<<config[group][0]<<","<<config[group][1]<<"],\"games\":2000,\"x_wins\":"<<wins[1]<<",\"o_wins\":"<<wins[2]<<",\"draws\":"<<wins[0]<<",\"mean_plies\":"<<plies/2000.0<<",\"min_plies\":"<<shortest<<",\"max_plies\":"<<longest<<",\"fork_games\":"<<forkgames<<",\"games_at_most_7_plies\":"<<quick;

  cout<<",\"openers\":[";for(int i=0;i<54;i++)cout<<(i?",":"")<<"["<<opener[i][0]<<","<<opener[i][1]<<"]";cout<<"]}";
 }
 cout<<"]}"<<endl;
}
