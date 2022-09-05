#!/bin/bash

export XIL_PA_NO_MYVIVADO_OVERRIDE=1
export MYVIVADO=
###########################################################
# Reset ARGS intentionally, do not use ARGS that was set by
# installer/xic to start this session
###########################################################
ARGS=-Dsun.java2d.d3d=false\ -Duser.dir=${root}

arch=`getconf LONG_BIT`
NOW=`date +%Y-%m-%d-%H-%M-%S-%s`

###########################################################
# SevenZJBind is extracting native libs to java.io.tmpdir
# there is a permission issue if different users run the 
# xsetup on the same machine. 
# here we create a temp. directory (TMP_LD_LIBRARY_PATH) 
# which and later we set java.io.tmpdir will to 
# TMP_LD_LIBRARY_PATH
# Do NOT remove!
###########################################################
TMP_LD_LIBRARY_PATH=/tmp/TMP_LD_LIB_PATH${NOW}
mkdir -p ${TMP_LD_LIBRARY_PATH}  

PLAT_LIB=${root}/lib/lnx64.o
X_JAVA_HOME=${root}/tps/lnx64/jre11.0.11_9
ARGS=${ARGS}\ -DLOAD_64_NATIVE=true
LDLIBPATH_SCRIPT="${root}/bin/ldlibpath.sh"
if [ -x "$LDLIBPATH_SCRIPT" ]; then
 PLAT_LIB="$("$LDLIBPATH_SCRIPT" "$PLAT_LIB")"
fi

export LD_LIBRARY_PATH=${TMP_LD_LIBRARY_PATH}:${PLAT_LIB}:${LD_LIBRARY_PATH}
###########################################################
# DO NOT REMOVE:
# -Djava.io.tmpdir=${TMP_LD_LIBRARY_PATH}
# see above comment!
###########################################################
ARGS=${ARGS}\ -Djava.io.tmpdir=${TMP_LD_LIBRARY_PATH}\ -Djava.library.path=${PLAT_LIB}\ -DDYNAMIC_LANGUAGE_BUNDLE=${root}/data

# if IDATA_FILE_NAME is set then use it otherwise set it to the default one
if [ -f ${root}/data/idata.dat ] ; then
 ARGS=${ARGS}\ -DIDATA_LOCATION_FROM_USER=${root}/data/idata.dat
else
 if [ -f ${root}/data/udata.dat ] ; then
  ARGS=${ARGS}\ -DIDATA_LOCATION_FROM_USER=${root}/data/udata.dat
 fi  
fi

ARGS=${ARGS}\ -DNATIVE_TMP_DIR=${TMP_LD_LIBRARY_PATH}
#LOOK & FEEL
ARGS=${ARGS}\ -DOS_ARCH=${arch}

if [ "${XIC_CLASS_PATH}" == "" ] ; then
 X_CLASS_PATH=${root}/lib/classes/json-simple-1.1.1.jar
 X_CLASS_PATH=${X_CLASS_PATH}:${root}/lib/classes/httpclient-4.2.5.jar
 X_CLASS_PATH=${X_CLASS_PATH}:${root}/lib/classes/commons-codec-1.6.jar
 X_CLASS_PATH=${X_CLASS_PATH}:${root}/lib/classes/httpcore-4.2.4.jar
 X_CLASS_PATH=${X_CLASS_PATH}:${root}/lib/classes/commons-logging-1.1.1.jar
 X_CLASS_PATH=${X_CLASS_PATH}:${root}/lib/classes/slf4j-api-1.7.32.jar
 X_CLASS_PATH=${X_CLASS_PATH}:${root}/lib/classes/logback-core-1.2.8.jar
 X_CLASS_PATH=${X_CLASS_PATH}:${root}/lib/classes/logback-classic-1.2.8.jar
 X_CLASS_PATH=${X_CLASS_PATH}:${root}/lib/classes/xinstaller.jar
 X_CLASS_PATH=${X_CLASS_PATH}:${root}/lib/classes/sevenzipjbinding-AllLinux.jar
 X_CLASS_PATH=${X_CLASS_PATH}:${root}/lib/classes/zip4j-2.2.1.jar
 X_CLASS_PATH=${X_CLASS_PATH}:${root}/lib/classes/jaxb-api-2.3.1.jar
 X_CLASS_PATH=${X_CLASS_PATH}:${root}/lib/classes/jaxb-core-2.3.0.1.jar
 X_CLASS_PATH=${X_CLASS_PATH}:${root}/lib/classes/jaxb-impl-2.3.1.jar
# X_CLASS_PATH=${X_CLASS_PATH}:${root}/lib/classes/javax.activation-api-1.2.0.jar
 X_CLASS_PATH=${X_CLASS_PATH}:${root}/lib/classes/commons-cli-1.4.jar
 X_CLASS_PATH=${X_CLASS_PATH}:${root}
else
 X_CLASS_PATH=${XIC_CLASS_PATH}
fi 

if [ "${XIC_JRE_LOCATION}" != "" ] ; then
 X_JAVA_HOME=${XIC_JRE_LOCATION}
fi 

if [ "${DEBUG_JNI}" == "true" ] ; then
ARGS=${ARGS}\ -XX:+CheckJNICalls
fi
ARGS=${ARGS}\ -XX:HeapDumpPath=${HOME}/.Xilinx/xinstall


