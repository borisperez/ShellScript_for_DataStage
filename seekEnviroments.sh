for i in `dsjob -lprojects `
do
dsadmin -listenv $i >> .enviroments
done
cat .enviroments | sort | uniq > enviroments

