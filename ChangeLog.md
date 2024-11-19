## Revision number 1142 (September 26, 2024) 

| Date | 	Changes |
| ----------	 | ----------|
|10/18/2024|	createMat.py, Heuristics.py, mopacamk.py and tag_prod.py have been updated to avoid futurewarning with networkx3.0|
|09/26/2024|	New keyword: <code>timeout</code>. This is used for jobs taking more than a certain time, and known to fail.|
|06/24/2024|	Fixed a bug in <code>IRC.sh</code> and added keyword <code>MaxBO</code> to set the maximum bond order for breaking a bond |
|06/05/2024|    <code>mopacamk</code> changed to make it compatible with ASE's newest version. FutureWarnings from locate_barrless to barrless.err|
| 05/23/2024|   Bugfixes in <code>amk_parallel.sh</code> and <code>sel_mol.sh</code>. locate_barrless modified to allow multiple searchs.| 
| 03/06/2024| 	Removed dependence with <code>zenity</code> and <code>gnuplot</code>|  
| 01/15/2024| 	Fixed some bugs with <code>llcalcs.sh</code> and improved ChemKnow algorithm (new keyword <code>CK_minima</code>)| 
| 11/07/2023| 	Fixed some issues with the HL calcs of fragments| 
| 05/12/2022| 	Fixed some issues with <code>qcore</code> calcs| 
| 04/26/2022| 	Bugfix in <code>utils.sh</code> and improved performace hl calcs| 
| 04/13/2022| 	Removed STOP in <code>diag.f</code>.| 
| 03/17/2022| 	Bugfix in <code>final.sh</code>.| 
| 03/11/2022| 	Interface with <code>Gaussian16</code>.| 
| 02/03/2022| 	Min and Max temperatures for the kinetics set to 100 K and 9999 K, respectively.| 
| 12/10/2021| 	Bugfixes in Python scripts that read inputfile (charge and long mopac inputs were not read correctly).| 
| 12/01/2021| 	Bugfix in <code>LocateTS.py</code>.| 
| 11/18/2021| 	Bugfix in ChemKnow. Improved torsional search| 
| 11/16/2021| 	ChemKnow and barrierless search improved. | 
| 10/17/2021| 	Updated tables with the geometry orientation for normal mode calcls in <code>FINALDIR</code> (low-level one). | 
| 09/17/2021| 	<code>select.sh</code> now exectuted from WRKDIR| 
| 07/24/2021| 	Bugfixes in <code>screening.sh</code>|
| 07/23/2021| 	Barrierless process are now included in the search (not in the kinetics)|
| 06/25/2021| 	Screening and rxnetwork build optimized. Adaptive selection of temp in MD optimized.|
| 06/18/2021| 	Bugfix in select_assoc script|
| 06/17/2021| 	Systems with charge can now be modeled with ChemKnow and BXDE|
| 04/06/2021| 	Bugfixes in <code>irc_analysis.sh</code> (mopac2021) and Heuristics (crossed bonds)|
| 05/28/2021| 	New keyword: <code>Use_LET</code> for mopac TS optimizations|
| 05/27/2021| 	New keywords: <code>recalc</code> and <code>Hookean</code>, and improved efficiency|
| 05/14/2021| 	ChemKnow improved and calcfc in <code>g09</code> ts opt calcs|
| 05/10/2021| 	New keyword <code>tight_ts</code> and bug in bxde|
| 05/02/2021| 	kinetics module improved and bugs corrected|
| 04/07/2021| 	In <code>tors.sh</code> do not consider rotation about bonds that belong to a ring|
| 03/16/2021| 	mopac calculator updated to ase3.21.1|
| 03/14/2021| 	Bugfixes|
| 02/15/2021| 	2021 release. Revision 1007--> qcore high-level calcs available|
| 10/20/2020| 	linked_paths in python and 1D rotors in rrkm|
| 10/14/2020| 	tutorial updated and bug fixes in <code>DVV.py</code>|
| 10/05/2020| 	Density matrix read in freq calc (MOPAC) and new xtb parameters for better convergence|
| 07/15/2020| 	Implemented interface with <code>Entos Qcore</code>|
| 04/21/2020| 	Implemented ExtForce and fixed some bugs|
| 01/28/2020| 	Simplified adjacency matrix from XYZ|
| 01/21/2020| 	2020 version|
| 12/02/2019| 	Bug in <code>FINAL.sh</code>|
| 11/22/2019| 	Maximum number of paths set to 50 (in <code>bbfs.f90</code>).|
| 11/16/2019| 	Check of input structure in <code>amk.sh</code>. Fragmented molecules are no longer valid.|
| 09/16/2019| 	pdfs are now also generated in FINAL_HL|
| 07/09/2019| 	if name of working dir is too long, name--->wrkdir|
| 06/30/2019| 	amk acronym replaces old tsscds acronym|
| 04/18/2019| 	MIT license|
| 04/17/2019| 	The label of the starting min in the kmc simulations is in <code>tsdirll/KMC/starting_minimum</code>|
| 04/15/2019| 	A bug in <code>get_energy_g09_MP2.sh</code> was corrected|
		
