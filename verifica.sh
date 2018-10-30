cd /software/IS/Engine/Server/Configurations

cat default_edwp.apt | grep fastname | tr -d '\"' | awk '{print $2}' > x

for i in `cat x`
 do
 rsh $i "hostname "
 done