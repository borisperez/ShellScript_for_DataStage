set -x
cat .rel1 | sort -t"|" -k1n | grep "2010-10-14" | \ 
awk -F"|" -v data="2010-10-14" '{ 
        dataini = substr($1,1,10)
	    datafim = substr($2,1,10)
	    dini    = split(dataini,i,"-")
	    diaini  = i[3]	  
	    mesini  = i[2]
	    dfim    = split(datafim,f,"-") 
	    diafim  = f[3]
	    mesfim  = f[2]
            diaparm = split(data,p,"-")
            diapar  = p[3]
	    mespar  = p[2]
	    timeini =  substr($1,12,8)
	    timefim =  substr($2,12,8)
	    tini    =  split(timeini,v,":")
	    tfim    =  split(timefim,y,":")
	    horaini =  v[1]
	    horafim =  y[1]
print "diaini ="diaini
print "diafim ="diafim
print "diapar ="diapar
print "timeini ="timeini
print "timefim ="timefim
print "timepar ="timepar
print "horaini ="horaini
print "horafim ="horafim
print "horapar ="horapar
	    if ( diaini < diapar ){ 
	       horaini = 0
              }
            if ( diafim > diapar ){ 
	       horafim = 23
             }
print horaini , horafim

	    for ( l = horaini ; l <= horafim ; l++ ){
print horaini , horafim
	       print l"|", $0 >> ".rel4" 
	    } 
}'

cat .rel4 | sort -t"|" -k1n

