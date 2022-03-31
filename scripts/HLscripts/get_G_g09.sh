awk '/Thermal correction to Gibbs Free Energy/{print $7;exit}' $1
