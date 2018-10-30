export APT_PM_CONDUCTOR_HOSTNAME=caudwdsp02-app
export APT_CONFIG_FILE=/software/IS/Engine/Server/Configurations/default.apt

orchadmin check 2>.check.apt
tail -2 .check.apt


