#!/usr/bin/env python3 

import networkx as nx
import numpy as np
import sys
import warnings
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import os.path

warnings.filterwarnings("ignore")

tag=str(sys.argv[1])
molecule=str(sys.argv[2])

file='tsdir'+tag+'_'+molecule+'/KMC/starting_minimum'
if not os.path.isfile(file):
    print("starting minimum unavailable")
    exit()

sm=int(np.loadtxt(file))

dirf='FINAL_'+tag+'_'+molecule
fall=dirf+'/rxn_all.txt'
Gall = nx.read_edgelist(fall, data=(('weight',float),))

###cals for the network stats
n_nodes=Gall.number_of_nodes()
n_edges=Gall.number_of_edges()
n_possible_edges=n_nodes*(n_nodes-1)/2

##calcs of equivalent random networks
av_tt=0
av_cc=0
for i in range(1000):
    Grand=nx.gnm_random_graph(n_nodes,n_edges)
    av_tt+=nx.transitivity(Grand)
    av_cc+=nx.average_clustering(Grand)
av_tt=av_tt/1000
av_cc=av_cc/1000
gamma=0.5772
lrand=(np.log(n_nodes)-gamma)/np.log(av_cc*n_nodes)+.5
###


wall=[]
for edge in Gall.edges(data=True):
    wall.append(edge[2]['weight'])

color_mapa=[]
for node in Gall:
    if node==str(sm):
        color_mapa.append('red')
    else:
        color_mapa.append('skyblue')

pos=nx.shell_layout(Gall)
size=15.+len(Gall.nodes())/np.pi
fig=plt.figure(figsize=(size,size))
nx.draw_networkx_nodes(Gall, pos, node_size=9000,node_color=color_mapa,alpha=0.8)
nx.draw_networkx_edges(Gall, pos, width=wall)
nx.draw_networkx_labels(Gall, pos, font_size=14, font_weight='bold', font_family='sans-serif')
plt.title('Complete Graph',fontsize=40)
plt.axis('off')
plt.savefig(dirf+'/graph_all.pdf')
plt.close(fig)

fw = open(dirf+'/rxn_stats.txt', 'w')
fw.write('#################################################### \n')
fw.write('#                                                  # \n')
fw.write('#        Properties of the reaction network        # \n')
fw.write('#                                                  # \n')
fw.write('#################################################### \n \n ')
fw.write("  Number of nodes = {0:>7} \n".format(n_nodes))
fw.write("   Number of edges = {0:>7} \n".format(n_edges))
fw.write("   Average shortest path length of the current network             = {0:>7} \n".format(nx.average_shortest_path_length(Gall)))
fw.write("   Average shortest path length of the equivalent random network   = {0:>7} \n".format(lrand))
fw.write("   Average clustering coefficient of the current network           = {0:>7} \n".format(nx.average_clustering(Gall)))
fw.write("   Average clustering coefficient of the equivalent random network = {0:>7} \n".format(av_cc))
fw.write("   Transitivity of the current network                             = {0:>7} \n".format(nx.transitivity(Gall)))
fw.write("   Transitivity of the equivalent random network                   = {0:>7} \n".format(av_tt))
fw.write("   Density of edges (edges/possible_edges)                         = {0:>7} \n".format(n_edges/n_possible_edges))
fw.write("   Degree assortativity coefficient                                = {0:>7} \n".format(nx.degree_assortativity_coefficient(Gall)))
fw.close()      


fkin=dirf+'/rxn_kin.txt'
if os.path.isfile(fkin):
    Gkin = nx.read_edgelist(fkin, data=(('weight',float),))
    wkin=[]
    for edge in Gkin.edges(data=True):
        wkin.append(max(50*edge[2]['weight'],0.5))

    color_mapk=[]
    for node in Gkin:
        if node==str(sm):
            color_mapk.append('red')
        else:
            color_mapk.append('skyblue')

    pos=nx.shell_layout(Gkin)
    size=15.+len(Gkin.nodes())/np.pi
    fig=plt.figure(figsize=(size,size))
    nx.draw_networkx_nodes(Gkin, pos, node_size=9000,node_color=color_mapk,alpha=0.8)
    nx.draw_networkx_edges(Gkin, pos, width=wkin)
    nx.draw_networkx_labels(Gkin, pos, font_size=14, font_weight='bold', font_family='sans-serif')
    plt.title('Kinetics Graph',fontsize=40)
    plt.axis('off')
    plt.savefig(dirf+'/graph_kin.pdf')
    plt.close(fig)

