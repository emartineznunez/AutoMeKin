awk '/Natom=/{natom=$2}
/deg of each vertex/{
i=1
while(i<=natom){
  getline
  print $0
  i++
  }
}' sprint.out 


